#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script d'entraînement du modèle NLP pour le chatbot TaxasGE.

Ce script charge le corpus d'entraînement généré, construit et entraîne un modèle optimisé
de compréhension du langage naturel avec TensorFlow, puis le convertit en format TFLite
pour une utilisation sur appareils mobiles avec une taille < 15MB.

Le modèle utilise une architecture hybride combinant Transformer et LSTM, optimisée pour :
- La taille (< 15MB après conversion TFLite)
- Les performances sur mobile 
- Le support multilingue (ES, FR, EN)
- Les réponses contextuelles

Usage:
    python train_model.py [-h] [--input INPUT] [--output-dir OUTPUT_DIR]
                         [--model-name MODEL_NAME] [--vocab-size VOCAB_SIZE]
                         [--embedding-dim EMBEDDING_DIM] [--lstm-units LSTM_UNITS]
                         [--max-length MAX_LENGTH] [--batch-size BATCH_SIZE]
                         [--epochs EPOCHS] [--patience PATIENCE]
                         [--dropout-rate DROPOUT_RATE] [--verbose]
"""

import json
import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from pathlib import Path
import argparse
import pickle
import logging
from typing import Dict, List, Optional, Tuple, Union
from sklearn.model_selection import train_test_split

# Configuration du logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Constantes globales
MAX_VOCAB_SIZE = 10000
MAX_SEQUENCE_LENGTH = 50
EMBEDDING_DIM = 128
ENCODER_LAYERS = 2
ATTENTION_HEADS = 4
FF_DIM = 256
LSTM_UNITS = 256
BATCH_SIZE = 32
EPOCHS = 50
PATIENCE = 5
DROPOUT_RATE = 0.2

class TransformerBlock(layers.Layer):
    """Bloc Transformer optimisé pour une utilisation mobile."""
    
    def __init__(self, embed_dim: int, num_heads: int, ff_dim: int, rate: float = 0.1):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.ff_dim = ff_dim
        self.rate = rate
        
        self.att = layers.MultiHeadAttention(num_heads=num_heads, key_dim=embed_dim)
        self.ffn = keras.Sequential([
            layers.Dense(ff_dim, activation="relu"),
            layers.Dense(embed_dim),
        ])
        
        self.layernorm1 = layers.LayerNormalization(epsilon=1e-6)
        self.layernorm2 = layers.LayerNormalization(epsilon=1e-6)
        self.dropout1 = layers.Dropout(rate)
        self.dropout2 = layers.Dropout(rate)
        
    def call(self, inputs: tf.Tensor, training: bool) -> tf.Tensor:
        attn_output = self.att(inputs, inputs)
        attn_output = self.dropout1(attn_output, training=training)
        out1 = self.layernorm1(inputs + attn_output)
        
        ffn_output = self.ffn(out1)
        ffn_output = self.dropout2(ffn_output, training=training)
        return self.layernorm2(out1 + ffn_output)
    
    def get_config(self) -> Dict:
        config = super().get_config()
        config.update({
            "embed_dim": self.embed_dim,
            "num_heads": self.num_heads,
            "ff_dim": self.ff_dim,
            "rate": self.rate,
        })
        return config

class PositionalEncoding(layers.Layer):
    """Encodage positionnel pour le Transformer."""
    
    def __init__(self, position: int, d_model: int):
        super().__init__()
        self.position = position
        self.d_model = d_model
        self.pos_encoding = self.positional_encoding(position, d_model)
    
    def get_angles(self, pos: tf.Tensor, i: tf.Tensor, d_model: int) -> tf.Tensor:
        angle_rates = 1 / np.power(10000, (2 * (i//2)) / np.float32(d_model))
        return pos * angle_rates
    
    def positional_encoding(self, position: int, d_model: int) -> tf.Tensor:
        angle_rads = self.get_angles(
            np.arange(position)[:, np.newaxis],
            np.arange(d_model)[np.newaxis, :],
            d_model
        )
        
        angle_rads[:, 0::2] = np.sin(angle_rads[:, 0::2])
        angle_rads[:, 1::2] = np.cos(angle_rads[:, 1::2])
        
        pos_encoding = angle_rads[np.newaxis, ...]
        return tf.cast(pos_encoding, dtype=tf.float32)
    
    def call(self, inputs: tf.Tensor) -> tf.Tensor:
        return inputs + self.pos_encoding[:, :tf.shape(inputs)[1], :]
    
    def get_config(self) -> Dict:
        config = super().get_config()
        config.update({
            "position": self.position,
            "d_model": self.d_model,
        })
        return config

class CustomLossLayer(layers.Layer):
    """Couche de perte personnalisée avec pondération des tokens."""
    
    def __init__(self, vocab_size: int):
        super().__init__()
        self.vocab_size = vocab_size
        
    def call(self, y_true: tf.Tensor, y_pred: tf.Tensor) -> tf.Tensor:
        # Masque pour ignorer le padding
        mask = tf.cast(tf.not_equal(y_true, 0), tf.float32)
        
        # Cross-entropy avec pondération
        loss = tf.keras.losses.sparse_categorical_crossentropy(y_true, y_pred)
        
        # Appliquer le masque et normaliser
        loss = tf.reduce_sum(loss * mask) / tf.reduce_sum(mask)
        return loss
    
    def get_config(self) -> Dict:
        config = super().get_config()
        config.update({"vocab_size": self.vocab_size})
        return config

class ChatbotModel:
    """Modèle de chatbot optimisé pour TaxasGE."""
    
    def __init__(
        self,
        vocab_size: int,
        max_length: int,
        embedding_dim: int,
        num_layers: int,
        num_heads: int,
        ff_dim: int,
        lstm_units: int,
        dropout_rate: float
    ):
        self.vocab_size = vocab_size
        self.max_length = max_length
        self.embedding_dim = embedding_dim
        self.num_layers = num_layers
        self.num_heads = num_heads
        self.ff_dim = ff_dim
        self.lstm_units = lstm_units
        self.dropout_rate = dropout_rate
        
        # Construire le modèle
        self.model = self._build_model()
    
    def _build_encoder(self, inputs: tf.Tensor) -> tf.Tensor:
        """Construit l'encodeur avec Transformer + LSTM."""
        
        # Embedding + encodage positionnel
        x = layers.Embedding(self.vocab_size, self.embedding_dim)(inputs)
        x = PositionalEncoding(self.max_length, self.embedding_dim)(x)
        x = layers.Dropout(self.dropout_rate)(x)
        
        # Couches Transformer
        for _ in range(self.num_layers):
            x = TransformerBlock(
                self.embedding_dim, 
                self.num_heads,
                self.ff_dim,
                self.dropout_rate
            )(x)
        
        # LSTM bidirectionnel
        x = layers.Bidirectional(layers.LSTM(
            self.lstm_units,
            return_sequences=True,
            dropout=self.dropout_rate,
            recurrent_dropout=self.dropout_rate/2
        ))(x)
        
        return x
    
    def _build_decoder(self, inputs: tf.Tensor, encoder_outputs: tf.Tensor) -> tf.Tensor:
        """Construit le décodeur avec attention croisée."""
        
        # Embedding + encodage positionnel
        x = layers.Embedding(self.vocab_size, self.embedding_dim)(inputs)
        x = PositionalEncoding(self.max_length, self.embedding_dim)(x)
        x = layers.Dropout(self.dropout_rate)(x)
        
        # Attention croisée avec sortie de l'encodeur
        x = layers.MultiHeadAttention(
            num_heads=self.num_heads,
            key_dim=self.embedding_dim
        )(x, encoder_outputs)
        
        # LSTM avec attention
        x = layers.LSTM(
            self.lstm_units,
            return_sequences=True,
            dropout=self.dropout_rate,
            recurrent_dropout=self.dropout_rate/2
        )(x)
        
        # Couche de sortie
        x = layers.Dense(self.vocab_size, activation='softmax')(x)
        
        return x
    
    def _build_model(self) -> keras.Model:
        """Construit le modèle complet."""
        
        # Entrées
        encoder_inputs = layers.Input(shape=(self.max_length,))
        decoder_inputs = layers.Input(shape=(self.max_length,))
        
        # Encodeur
        encoder_outputs = self._build_encoder(encoder_inputs)
        
        # Décodeur
        outputs = self._build_decoder(decoder_inputs, encoder_outputs)
        
        # Modèle complet
        model = keras.Model([encoder_inputs, decoder_inputs], outputs)
        
        # Compilation avec perte personnalisée
        loss_layer = CustomLossLayer(self.vocab_size)
        model.compile(
            optimizer='adam',
            loss=loss_layer,
            metrics=['accuracy']
        )
        
        return model
    
    def save_model(self, path: str):
        """Sauvegarde le modèle au format h5."""
        self.model.save(path)
    
    def convert_to_tflite(self, path: str, quantize: bool = True) -> None:
        """Convertit le modèle en format TFLite optimisé."""
        
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        
        if quantize:
            # Optimisations pour réduire la taille
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]
            
            # Quantification post-entraînement
            converter.post_training_quantize = True
            
            # Support des opérations essentielles
            converter.target_spec.supported_ops = [
                tf.lite.OpsSet.TFLITE_BUILTINS,
                tf.lite.OpsSet.SELECT_TF_OPS
            ]
        
        # Conversion
        tflite_model = converter.convert()
        
        # Sauvegarde
        with open(path, 'wb') as f:
            f.write(tflite_model)
        
        # Vérification de la taille
        size_mb = os.path.getsize(path) / (1024 * 1024)
        logging.info(f'Taille du modèle TFLite: {size_mb:.2f} MB')
        
        if size_mb > 15:
            logging.warning(
                f'Le modèle dépasse la limite de 15MB. Taille actuelle: {size_mb:.2f} MB'
            )

class ModelTrainer:
    """Gère l'entraînement et l'optimisation du modèle."""
    
    def __init__(
        self,
        corpus_path: str,
        output_dir: str,
        model_name: str = "taxasge_model",
        vocab_size: int = MAX_VOCAB_SIZE,
        max_length: int = MAX_SEQUENCE_LENGTH,
        embedding_dim: int = EMBEDDING_DIM,
        num_layers: int = ENCODER_LAYERS,
        num_heads: int = ATTENTION_HEADS,
        ff_dim: int = FF_DIM,
        lstm_units: int = LSTM_UNITS,
        batch_size: int = BATCH_SIZE,
        epochs: int = EPOCHS,
        patience: int = PATIENCE,
        dropout_rate: float = DROPOUT_RATE,
        verbose: bool = False
    ):
        self.corpus_path = corpus_path
        self.output_dir = output_dir
        self.model_name = model_name
        self.vocab_size = vocab_size
        self.max_length = max_length
        self.embedding_dim = embedding_dim
        self.num_layers = num_layers
        self.num_heads = num_heads
        self.ff_dim = ff_dim
        self.lstm_units = lstm_units
        self.batch_size = batch_size
        self.epochs = epochs
        self.patience = patience
        self.dropout_rate = dropout_rate
        self.verbose = verbose
        
        # Configuration du logging
        if verbose:
            logging.getLogger().setLevel(logging.DEBUG)
        
        # Création du répertoire de sortie
        os.makedirs(output_dir, exist_ok=True)
        
        # Initialisation des attributs
        self.corpus = None
        self.tokenizer = None
        self.model = None
        self.training_history = None
    
    def load_and_preprocess_data(self) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """Charge et prétraite les données d'entraînement."""
        
        logging.info("Chargement du corpus...")
        
        # Chargement du corpus
        with open(self.corpus_path, 'r', encoding='utf-8') as f:
            self.corpus = json.load(f)
        
        # Extraction des questions et réponses
        questions = []
        answers = []
        
        for example in self.corpus:
            questions.append(example['question'].lower())
            answers.append(example['answer'].lower())
        
        # Tokenization
        self.tokenizer = Tokenizer(num_words=self.vocab_size, oov_token="<OOV>")
        self.tokenizer.fit_on_texts(questions + answers)
        
        # Conversion en séquences
        question_sequences = self.tokenizer.texts_to_sequences(questions)
        answer_sequences = self.tokenizer.texts_to_sequences(answers)
        
        # Padding
        question_data = pad_sequences(
            question_sequences,
            maxlen=self.max_length,
            padding='post'
        )
        answer_data = pad_sequences(
            answer_sequences,
            maxlen=self.max_length,
            padding='post'
        )
        
        # Séparation train/validation
        X_train, X_val, y_train, y_val = train_test_split(
            question_data,
            answer_data,
            test_size=0.2,
            random_state=42
        )
        
        # Sauvegarde du tokenizer
        tokenizer_path = os.path.join(self.output_dir, f"{self.model_name}_tokenizer.pickle")
        with open(tokenizer_path, 'wb') as f:
            pickle.dump(self.tokenizer, f)
        
        logging.info(f"Données prétraitées: {len(X_train)} exemples d'entraînement")
        
        return X_train, X_val, y_train, y_val
    
    def train(self) -> None:
        """Entraîne le modèle."""
        
        # Chargement des données
        X_train, X_val, y_train, y_val = self.load_and_preprocess_data()
        
        # Création du modèle
        self.model = ChatbotModel(
            vocab_size=self.vocab_size,
            max_length=self.max_length,
            embedding_dim=self.embedding_dim,
            num_layers=self.num_layers,
            num_heads=self.num_heads,
            ff_dim=self.ff_dim,
            lstm_units=self.lstm_units,
            dropout_rate=self.dropout_rate
        )
        
        # Callbacks
        callbacks = [
            EarlyStopping(
                monitor='val_loss',
                patience=self.patience,
                restore_best_weights=True
            ),
            ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=self.patience//2,
                min_lr=1e-6
            ),
            ModelCheckpoint(
                os.path.join(self.output_dir, f"{self.model_name}_best.h5"),
                monitor='val_loss',
                save_best_only=True
            )
        ]
        
        # Entraînement
        logging.info("Début de l'entraînement...")
        
        self.training_history = self.model.model.fit(
            [X_train, X_train],  # Entrées: questions pour l'encodeur et décodeur
            y_train,            # Sorties: réponses décalées pour teacher forcing
            validation_data=([X_val, X_val], y_val),
            batch_size=self.batch_size,
            epochs=self.epochs,
            callbacks=callbacks,
            verbose=self.verbose
        )
        
        # Sauvegarde du modèle final
        model_path = os.path.join(self.output_dir, f"{self.model_name}.h5")
        self.model.save_model(model_path)
        
        logging.info(f"Modèle sauvegardé: {model_path}")
    
    def optimize_and_convert(self) -> None:
        """Optimise et convertit le modèle en format TFLite."""
        
        logging.info("Conversion du modèle en format TFLite...")
        
        # Chemin du modèle TFLite
        tflite_path = os.path.join(self.output_dir, f"{self.model_name}.tflite")
        
        # Conversion avec quantification
        self.model.convert_to_tflite(tflite_path, quantize=True)
        
        logging.info(f"Modèle TFLite sauvegardé: {tflite_path}")
    
    def run_pipeline(self) -> None:
        """Exécute le pipeline complet d'entraînement et conversion."""
        
        try:
            # Entraînement
            self.train()
            
            # Optimisation et conversion
            self.optimize_and_convert()
            
            logging.info("Pipeline terminé avec succès!")
            
        except Exception as e:
            logging.error(f"Erreur durant l'exécution du pipeline: {str(e)}")
            raise

def main():
    """Point d'entrée principal."""
    
    parser = argparse.ArgumentParser(description='Entraîne le modèle NLP pour TaxasGE')
    
    parser.add_argument('--input', '-i',
                       default='assets/ml/training_corpus.json',
                       help='Chemin du corpus d\'entraînement')
    
    parser.add_argument('--output-dir', '-o',
                       default='assets/ml',
                       help='Répertoire de sortie')
    
    parser.add_argument('--model-name', '-m',
                       default='taxasge_model',
                       help='Nom de base du modèle')
    
    parser.add_argument('--vocab-size',
                       type=int,
                       default=MAX_VOCAB_SIZE,
                       help='Taille du vocabulaire')
    
    parser.add_argument('--embedding-dim',
                       type=int,
                       default=EMBEDDING_DIM,
                       help='Dimension des embeddings')
    
    parser.add_argument('--lstm-units',
                       type=int,
                       default=LSTM_UNITS,
                       help='Unités LSTM')
    
    parser.add_argument('--batch-size',
                       type=int,
                       default=BATCH_SIZE,
                       help='Taille des batchs')
    
    parser.add_argument('--epochs',
                       type=int,
                       default=EPOCHS,
                       help='Nombre d\'époques')
    
    parser.add_argument('--verbose', '-v',
                       action='store_true',
                       help='Mode verbeux')
    
    args = parser.parse_args()
    
    # Conversion des chemins relatifs en absolus
    base_dir = Path(__file__).resolve().parent.parent
    input_path = str(base_dir / args.input)
    output_dir = str(base_dir / args.output_dir)
    
    logging.info(f"Démarrage de l'entraînement...")
    logging.info(f"Corpus: {input_path}")
    logging.info(f"Sortie: {output_dir}")
    
    # Création et exécution du trainer
    trainer = ModelTrainer(
        corpus_path=input_path,
        output_dir=output_dir,
        model_name=args.model_name,
        vocab_size=args.vocab_size,
        embedding_dim=args.embedding_dim,
        lstm_units=args.lstm_units,
        batch_size=args.batch_size,
        epochs=args.epochs,
        verbose=args.verbose
    )
    
    trainer.run_pipeline()
    
    logging.info("Terminé!")

if __name__ == "__main__":
    main()