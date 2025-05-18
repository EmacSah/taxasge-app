#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Générateur de corpus d'entraînement pour le modèle NLP du chatbot TaxasGE
Ce script génère automatiquement un corpus d'entraînement à partir des données fiscales 
extraites du fichier JSON et le sauvegarde dans assets/ml/training_corpus.json.

Avec support pour l'augmentation des données:
- Génération de questions avec des fautes typographiques
- Suppression d'accents
- Questions incomplètes/raccourcies
- Variantes informelles
"""

import json
import os
import random
import re
import unicodedata
from pathlib import Path
import argparse

# Templates de questions en plusieurs langues
QUESTION_TEMPLATES = {
    "es": [  # Espagnol (langue par défaut)
        "¿Cuánto cuesta {concepto}?",
        "¿Cuál es el precio de {concepto}?",
        "¿Cuánto tengo que pagar por {concepto}?",
        "¿Cuál es la tasa de {concepto}?",
        "¿Qué documentos necesito para {concepto}?",
        "¿Qué documentos se requieren para {concepto}?",
        "¿Qué documentación debo presentar para {concepto}?",
        "¿Cuáles son los requisitos para {concepto}?",
        "¿Cuál es el procedimiento para {concepto}?",
        "¿Cómo puedo obtener {concepto}?",
        "¿Cuál es el proceso para {concepto}?",
        "¿Dónde puedo tramitar {concepto}?",
        "¿A qué ministerio pertenece {concepto}?",
        "¿Qué ministerio se encarga de {concepto}?",
        "¿Qué departamento gestiona {concepto}?",
        "Necesito información sobre {concepto}",
        "Háblame de {concepto}",
        "Explícame {concepto}",
        "¿Cuánto cuesta renovar {concepto}?",
        "¿Cuál es el costo de renovación de {concepto}?",
        "¿Cuál es la tasa de renovación para {concepto}?",
    ],
    "fr": [  # Français
        "Combien coûte {concepto}?",
        "Quel est le prix de {concepto}?",
        "Combien dois-je payer pour {concepto}?",
        "Quel est le montant de la taxe pour {concepto}?",
        "Quels documents sont nécessaires pour {concepto}?",
        "Quels documents sont requis pour {concepto}?",
        "Quelle documentation dois-je présenter pour {concepto}?",
        "Quelles sont les conditions requises pour {concepto}?",
        "Quelle est la procédure pour {concepto}?",
        "Comment puis-je obtenir {concepto}?",
        "Quel est le processus pour {concepto}?",
        "Où puis-je faire la demande de {concepto}?",
        "À quel ministère appartient {concepto}?",
        "Quel ministère est en charge de {concepto}?",
        "Quel département gère {concepto}?",
        "J'ai besoin d'informations sur {concepto}",
        "Parlez-moi de {concepto}",
        "Expliquez-moi {concepto}",
        "Combien coûte le renouvellement de {concepto}?",
        "Quel est le coût de renouvellement de {concepto}?",
        "Quel est le montant pour renouveler {concepto}?",
    ],
    "en": [  # Anglais
        "How much does {concepto} cost?",
        "What is the price of {concepto}?",
        "How much do I have to pay for {concepto}?",
        "What is the fee for {concepto}?",
        "What documents do I need for {concepto}?",
        "What documents are required for {concepto}?",
        "What documentation should I submit for {concepto}?",
        "What are the requirements for {concepto}?",
        "What is the procedure for {concepto}?",
        "How can I obtain {concepto}?",
        "What is the process for {concepto}?",
        "Where can I apply for {concepto}?",
        "Which ministry handles {concepto}?",
        "Which ministry is in charge of {concepto}?",
        "Which department manages {concepto}?",
        "I need information about {concepto}",
        "Tell me about {concepto}",
        "Explain {concepto} to me",
        "How much does it cost to renew {concepto}?",
        "What is the renewal cost for {concepto}?",
        "What is the renewal fee for {concepto}?",
    ]
}

# Templates de questions générales (sans mention spécifique d'un concept)
GENERAL_QUESTION_TEMPLATES = {
    "es": [
        "¿Qué trámites puedo hacer en el Ministerio de {ministerio}?",
        "¿Qué servicios ofrece el Ministerio de {ministerio}?",
        "¿Cuáles son las tasas del Ministerio de {ministerio}?",
        "¿Qué documentos emite el Ministerio de {ministerio}?",
        "¿Cómo contactar al Ministerio de {ministerio}?",
        "¿Qué categorías de tasas existen en {ministerio}?",
    ],
    "fr": [
        "Quelles démarches puis-je faire au Ministère de {ministerio}?",
        "Quels services propose le Ministère de {ministerio}?",
        "Quelles sont les taxes du Ministère de {ministerio}?",
        "Quels documents sont émis par le Ministère de {ministerio}?",
        "Comment contacter le Ministère de {ministerio}?",
        "Quelles catégories de taxes existent au {ministerio}?",
    ],
    "en": [
        "What procedures can I do at the Ministry of {ministerio}?",
        "What services does the Ministry of {ministerio} offer?",
        "What are the fees at the Ministry of {ministerio}?",
        "What documents are issued by the Ministry of {ministerio}?",
        "How can I contact the Ministry of {ministerio}?",
        "What categories of fees exist in {ministerio}?",
    ]
}

# Templates pour les questions sur les mots-clés
KEYWORD_QUESTION_TEMPLATES = {
    "es": [
        "¿Dónde puedo obtener documentos relacionados con {palabra_clave}?",
        "¿Qué trámites existen para {palabra_clave}?",
        "Busco información sobre {palabra_clave}",
        "¿Qué tasas están relacionadas con {palabra_clave}?",
        "Necesito hacer un trámite de {palabra_clave}",
    ],
    "fr": [
        "Où puis-je obtenir des documents liés à {palabra_clave}?",
        "Quelles procédures existent pour {palabra_clave}?",
        "Je cherche des informations sur {palabra_clave}",
        "Quelles taxes sont liées à {palabra_clave}?",
        "J'ai besoin de faire une démarche concernant {palabra_clave}",
    ],
    "en": [
        "Where can I get documents related to {palabra_clave}?",
        "What procedures exist for {palabra_clave}?",
        "I'm looking for information about {palabra_clave}",
        "What fees are related to {palabra_clave}?",
        "I need to do a procedure related to {palabra_clave}",
    ]
}

# Templates pour les réponses
RESPONSE_TEMPLATES = {
    "precio": {
        "es": "El costo de {concepto} es {tasa_expedicion} para expedición y {tasa_renovacion} para renovación.",
        "fr": "Le coût de {concepto} est de {tasa_expedicion} pour l'émission et {tasa_renovacion} pour le renouvellement.",
        "en": "The cost of {concepto} is {tasa_expedicion} for issuance and {tasa_renovacion} for renewal."
    },
    "documentos": {
        "es": "Los documentos requeridos para {concepto} son: {documentos_requeridos}",
        "fr": "Les documents requis pour {concepto} sont: {documentos_requeridos}",
        "en": "The required documents for {concepto} are: {documentos_requeridos}"
    },
    "procedimiento": {
        "es": "El procedimiento para {concepto} es: {procedimiento}",
        "fr": "La procédure pour {concepto} est: {procedimiento}",
        "en": "The procedure for {concepto} is: {procedimiento}"
    },
    "ministerio": {
        "es": "{concepto} es gestionado por el Ministerio de {ministerio}.",
        "fr": "{concepto} est géré par le Ministère de {ministerio}.",
        "en": "{concepto} is managed by the Ministry of {ministerio}."
    },
    "informacion_general": {
        "es": "{concepto} es un trámite del Ministerio de {ministerio}. El costo es {tasa_expedicion} para expedición y {tasa_renovacion} para renovación.",
        "fr": "{concepto} est une démarche du Ministère de {ministerio}. Le coût est de {tasa_expedicion} pour l'émission et {tasa_renovacion} pour le renouvellement.",
        "en": "{concepto} is a procedure of the Ministry of {ministerio}. The cost is {tasa_expedicion} for issuance and {tasa_renovacion} for renewal."
    },
    "ministerio_general": {
        "es": "El Ministerio de {ministerio} gestiona varios trámites, entre ellos: {conceptos}.",
        "fr": "Le Ministère de {ministerio} gère plusieurs démarches, notamment: {conceptos}.",
        "en": "The Ministry of {ministerio} manages several procedures, including: {conceptos}."
    },
    "keyword": {
        "es": "Para trámites relacionados con {palabra_clave}, puede consultar: {conceptos}.",
        "fr": "Pour les démarches liées à {palabra_clave}, vous pouvez consulter: {conceptos}.",
        "en": "For procedures related to {palabra_clave}, you can check: {conceptos}."
    }
}

# Réponses génériques quand l'information n'est pas disponible
FALLBACK_RESPONSES = {
    "es": [
        "No tengo información específica sobre {concepto}. Por favor, consulte directamente con el ministerio correspondiente.",
        "Lo siento, no puedo proporcionar información detallada sobre {concepto}.",
        "No dispongo de datos sobre {concepto}. Recomiendo consultar en la página web oficial del gobierno."
    ],
    "fr": [
        "Je n'ai pas d'informations spécifiques sur {concepto}. Veuillez consulter directement le ministère concerné.",
        "Désolé, je ne peux pas fournir d'informations détaillées sur {concepto}.",
        "Je ne dispose pas de données sur {concepto}. Je recommande de consulter le site web officiel du gouvernement."
    ],
    "en": [
        "I don't have specific information about {concepto}. Please consult directly with the corresponding ministry.",
        "Sorry, I cannot provide detailed information about {concepto}.",
        "I don't have data about {concepto}. I recommend checking the official government website."
    ]
}

# Templates pour les salutations et remerciements
GREETING_TEMPLATES = {
    "es": [
        "Hola", "Buenos días", "Buenas tardes", "Buenas noches", "Saludos"
    ],
    "fr": [
        "Bonjour", "Salut", "Bonsoir", "Coucou", "Salutations"
    ],
    "en": [
        "Hello", "Hi", "Good morning", "Good afternoon", "Good evening", "Greetings"
    ]
}

THANKS_TEMPLATES = {
    "es": [
        "Gracias", "Muchas gracias", "Te agradezco", "Gracias por la información", "Excelente, gracias"
    ],
    "fr": [
        "Merci", "Merci beaucoup", "Je vous remercie", "Merci pour l'information", "Excellent, merci"
    ],
    "en": [
        "Thanks", "Thank you", "Thank you very much", "Thanks for the information", "Great, thanks"
    ]
}

GREETING_RESPONSES = {
    "es": [
        "Hola, ¿en qué puedo ayudarte?",
        "Buenos días, ¿qué información sobre tasas fiscales necesitas?",
        "Hola, soy el asistente virtual de TaxasGE. ¿Cómo puedo ayudarte?",
        "Saludos, estoy aquí para responder tus preguntas sobre tasas fiscales en Guinea Ecuatorial."
    ],
    "fr": [
        "Bonjour, comment puis-je vous aider?",
        "Bonjour, quelle information sur les taxes fiscales vous faut-il?",
        "Bonjour, je suis l'assistant virtuel de TaxasGE. Comment puis-je vous aider?",
        "Salutations, je suis là pour répondre à vos questions sur les taxes fiscales en Guinée Équatoriale."
    ],
    "en": [
        "Hello, how can I help you?",
        "Good day, what information about fiscal taxes do you need?",
        "Hi, I'm the TaxasGE virtual assistant. How can I help you?",
        "Greetings, I'm here to answer your questions about fiscal taxes in Equatorial Guinea."
    ]
}

THANKS_RESPONSES = {
    "es": [
        "De nada, estoy aquí para ayudar.",
        "Un placer. ¿Necesitas algo más?",
        "No hay problema. ¿Puedo ayudarte con algo más?",
        "A tu servicio. ¿Hay algo más en lo que pueda asistirte?"
    ],
    "fr": [
        "De rien, je suis là pour aider.",
        "Avec plaisir. Avez-vous besoin d'autre chose?",
        "Pas de problème. Puis-je vous aider avec autre chose?",
        "À votre service. Y a-t-il autre chose dont vous avez besoin?"
    ],
    "en": [
        "You're welcome, I'm here to help.",
        "My pleasure. Do you need anything else?",
        "No problem. Can I help you with something else?",
        "At your service. Is there anything else I can assist you with?"
    ]
}

# Expressions informelles et localismes pour Guinée Équatoriale
GE_LOCALISMS = {
    "es": [
        "documento", "papel", "carnet", "cédula", "recibo", "comprobante",
        "pagar", "abonar", "cotizar", "plata", "efectivo",
        "ayuda", "dato", "info", "consulta"
    ],
    "fr": [
        "papier", "carte", "facture", "reçu",
        "payer", "régler", "cotiser", "fric", "argent", "cash",
        "aide", "renseignement", "info"
    ],
    "en": [
        "paper", "card", "bill", "receipt",
        "pay", "settle", "fee", "money", "cash",
        "help", "info"
    ]
}

class CorpusGenerator:
    def __init__(self, json_file_path, output_file_path, num_examples_per_concept=5, 
                 augmentation_enabled=True, augmentation_prob=0.3, verbose=False):
        """
        Initialise le générateur de corpus.
        
        Args:
            json_file_path (str): Chemin vers le fichier JSON avec les données fiscales
            output_file_path (str): Chemin où enregistrer le corpus généré
            num_examples_per_concept (int): Nombre d'exemples à générer par concept
            augmentation_enabled (bool): Activer l'augmentation des données
            augmentation_prob (float): Probabilité d'application de chaque type d'augmentation
            verbose (bool): Afficher les détails du processus
        """
        self.json_file_path = json_file_path
        self.output_file_path = output_file_path
        self.num_examples_per_concept = num_examples_per_concept
        self.augmentation_enabled = augmentation_enabled
        self.augmentation_prob = augmentation_prob
        self.verbose = verbose
        self.corpus = []
        self.stats = {
            "total_examples": 0, 
            "concepts": 0, 
            "languages": {},
            "augmented_examples": 0  # Compteur pour les exemples augmentés
        }
        
        for lang in QUESTION_TEMPLATES.keys():
            self.stats["languages"][lang] = 0
    
    def augment_question(self, question, language, augmentation_prob=None):
        """
        Augmente la question avec des variations naturelles et des erreurs typiques
        
        Args:
            question: Question originale
            language: Code de langue
            augmentation_prob: Probabilité d'appliquer chaque type d'augmentation (utilise self.augmentation_prob si None)
        
        Returns:
            Question augmentée
        """
        # Si l'augmentation n'est pas activée, retourner la question originale
        if not self.augmentation_enabled:
            return question
        
        # Utiliser la probabilité par défaut si non spécifiée
        if augmentation_prob is None:
            augmentation_prob = self.augmentation_prob
        
        # Ne pas augmenter toutes les questions pour garder certaines "propres"
        if random.random() > 0.5:
            return question
        
        # Version originale
        original = question
        
        # 1. Créer des questions incomplètes
        if random.random() < augmentation_prob:
            # Supprimer les préfixes communs comme "Quel est" ou "Comment"
            prefixes = {
                "es": ["¿Cuál es", "¿Cuánto", "¿Qué", "¿Cómo", "¿Dónde", "¿A qué"],
                "fr": ["Quel est", "Combien", "Comment", "Quels sont", "Où", "À quel"],
                "en": ["What is", "How much", "How", "What are", "Where", "Which"]
            }
            
            for prefix in prefixes.get(language, []):
                if question.startswith(prefix):
                    question = question[len(prefix):].strip()
                    if language == "es" and question.startswith(("el ", "la ", "los ", "las ")):
                        question = question[3:].strip()
                    elif language == "fr" and question.startswith(("le ", "la ", "les ", "l'")):
                        question = question[3:].strip() if not question.startswith("l'") else question[2:].strip()
                    elif language == "en" and question.startswith("the "):
                        question = question[4:].strip()
                    break
        
        # 2. Introduire des fautes d'orthographe
        if random.random() < augmentation_prob:
            chars = list(question)
            if len(chars) > 3:
                # Choix aléatoire entre différents types d'erreurs
                error_type = random.choice(["replace", "swap", "omit", "double"])
                
                if error_type == "replace" and len(chars) > 0:
                    # Remplacer un caractère par un autre
                    index = random.randint(0, len(chars) - 1)
                    chars[index] = random.choice("abcdefghijklmnopqrstuvwxyz")
                elif error_type == "swap" and len(chars) > 2:
                    # Inverser deux caractères adjacents
                    index = random.randint(0, len(chars) - 2)
                    chars[index], chars[index + 1] = chars[index + 1], chars[index]
                elif error_type == "omit" and len(chars) > 3:
                    # Omettre un caractère
                    index = random.randint(0, len(chars) - 1)
                    chars.pop(index)
                elif error_type == "double" and len(chars) > 1:
                    # Doubler un caractère
                    index = random.randint(0, len(chars) - 1)
                    chars.insert(index, chars[index])
                
                question = ''.join(chars)
        
        # 3. Supprimer des accents
        if random.random() < augmentation_prob and (language == "es" or language == "fr"):
            accents = {
                'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 
                'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
                'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
                'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u',
                'ñ': 'n', 'ç': 'c'
            }
            for accent, replace in accents.items():
                question = question.replace(accent, replace)
        
        # 4. Supprimer la ponctuation finale
        if random.random() < augmentation_prob:
            if language == "es" and question.startswith("¿"):
                question = question[1:]
            if question.endswith('?') or question.endswith('.'):
                question = question[:-1]
        
        # 5. Parfois raccourcir davantage pour créer des questions très concises
        if random.random() < augmentation_prob/2:  # Plus rare
            words = question.split()
            if len(words) > 2:
                # Garder soit le début, soit la fin de la question
                if random.random() < 0.5:
                    question = ' '.join(words[:2])  # Deux premiers mots
                else:
                    question = ' '.join(words[-2:])  # Deux derniers mots
        
        # 6. Ajouter des expressions locales de Guinée Équatoriale
        if random.random() < augmentation_prob/3 and language in GE_LOCALISMS:  # Encore plus rare
            # Remplacer un mot par son équivalent local
            words = question.split()
            if len(words) > 2:
                index = random.randint(0, len(words) - 1)
                words[index] = random.choice(GE_LOCALISMS[language])
                question = ' '.join(words)
        
        # Ne retourner la version augmentée que si elle diffère significativement
        if question != original and len(question) > 3:
            # Capitaliser la première lettre si nécessaire
            if question and question[0].isalpha():
                question = question[0].upper() + question[1:]
            return question
        else:
            return original
    
    def load_data(self):
        """Charge les données fiscales à partir du fichier JSON"""
        if self.verbose:
            print(f"Chargement des données depuis {self.json_file_path}...")
        
        try:
            with open(self.json_file_path, 'r', encoding='utf-8') as file:
                return json.load(file)
        except Exception as e:
            print(f"Erreur lors du chargement du fichier JSON: {e}")
            return []
    
    def _capitalize_first_letter(self, text):
        """Capitalise la première lettre d'une chaîne de caractères"""
        if not text:
            return text
        return text[0].upper() + text[1:]
    
    def _format_list(self, items, lang):
        """Formate une liste en chaîne de caractères selon la langue"""
        if not items:
            return ""
        
        if lang == "es":
            return ", ".join(items[:-1]) + (" y " + items[-1] if len(items) > 1 else items[0])
        elif lang == "fr":
            return ", ".join(items[:-1]) + (" et " + items[-1] if len(items) > 1 else items[0])
        else:  # en
            return ", ".join(items[:-1]) + (" and " + items[-1] if len(items) > 1 else items[0])
    
    def _process_concepto(self, concepto, ministerio_nombre, languages=None):
        """
        Génère des exemples pour un concept donné
        
        Args:
            concepto: Objet concept avec les détails de la taxe
            ministerio_nombre: Nom du ministère associé
            languages: Liste des langues à utiliser (si None, utilise toutes)
        
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(QUESTION_TEMPLATES.keys())
        
        # Extraire les données du concept
        concepto_id = concepto.get("id", "")
        concepto_nombre = concepto.get("nombre", "")
        tasa_expedicion = concepto.get("tasa_expedicion", "N/A")
        tasa_renovacion = concepto.get("tasa_renovacion", "N/A")
        documentos_requeridos = concepto.get("documentos_requeridos", "")
        procedimiento = concepto.get("procedimiento", "")
        palabras_clave = concepto.get("palabras_clave", "").split(",") if isinstance(concepto.get("palabras_clave", ""), str) else []
        
        # Adapter les données selon le format (ancien ou nouveau multilingue)
        concepto_nombres = {}
        if isinstance(concepto_nombre, dict):
            # Format multilingue
            concepto_nombres = concepto_nombre
        else:
            # Format non multilingue
            concepto_nombres = {"es": concepto_nombre}
            
            # Tentative de récupération des traductions individuelles
            for lang in languages:
                lang_key = f"nombre_{lang}"
                if lang_key in concepto:
                    concepto_nombres[lang] = concepto[lang_key]
        
        # Traiter de manière similaire pour documentos_requeridos et procedimiento
        documentos_dict = {}
        if isinstance(documentos_requeridos, dict):
            documentos_dict = documentos_requeridos
        else:
            documentos_dict = {"es": documentos_requeridos}
            for lang in languages:
                lang_key = f"documentos_requeridos_{lang}"
                if lang_key in concepto:
                    documentos_dict[lang] = concepto[lang_key]
        
        procedimiento_dict = {}
        if isinstance(procedimiento, dict):
            procedimiento_dict = procedimiento
        else:
            procedimiento_dict = {"es": procedimiento}
            for lang in languages:
                lang_key = f"procedimiento_{lang}"
                if lang_key in concepto:
                    procedimiento_dict[lang] = concepto[lang_key]
        
        # Traiter également les mots-clés multilangues
        palabras_clave_dict = {}
        if isinstance(concepto.get("palabras_clave", ""), dict):
            palabras_clave_dict = concepto["palabras_clave"]
        else:
            for lang in languages:
                if palabras_clave:
                    palabras_clave_dict[lang] = palabras_clave
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # S'assurer qu'il y a des traductions pour cette langue, sinon utiliser l'espagnol
            nombre = concepto_nombres.get(lang, concepto_nombres.get("es", concepto_id))
            
            # Remplacer les valeurs manquantes
            if not nombre:
                continue
            
            docs = documentos_dict.get(lang, documentos_dict.get("es", ""))
            proc = procedimiento_dict.get(lang, procedimiento_dict.get("es", ""))
            ministerio_traducido = ministerio_nombre
            
            # Générer des exemples avec les templates de questions/réponses
            for i in range(self.num_examples_per_concept):
                # Prendre un template aléatoire
                question_template = random.choice(QUESTION_TEMPLATES[lang])
                question = question_template.format(concepto=nombre)
                
                # Créer différentes variantes de réponses selon le type de question
                if any(keyword in question_template.lower() for keyword in ["cuesta", "precio", "pagar", "tasa", "coût", "cost", "pay", "fee"]):
                    response_template = RESPONSE_TEMPLATES["precio"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        tasa_expedicion=tasa_expedicion, 
                        tasa_renovacion=tasa_renovacion
                    )
                elif any(keyword in question_template.lower() for keyword in ["ministerio", "departamento", "ministère", "ministry", "department"]):
                    response_template = RESPONSE_TEMPLATES["ministerio"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        ministerio=ministerio_traducido
                    )
                else:
                    # Réponse générale incluant les informations principales
                    response_template = RESPONSE_TEMPLATES["informacion_general"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        ministerio=ministerio_traducido,
                        tasa_expedicion=tasa_expedicion, 
                        tasa_renovacion=tasa_renovacion
                    )
                
                # Capitaliser la première lettre
                question = self._capitalize_first_letter(question)
                response = self._capitalize_first_letter(response)
                
                # Exemple original
                example_original = {
                    "id": f"{concepto_id}_{lang}_{i}_orig",
                    "language": lang,
                    "concept_id": concepto_id,
                    "question": question,
                    "answer": response,
                    "metadata": {
                        "ministry": ministerio_traducido,
                        "query_type": "concepto",
                        "augmented": False
                    }
                }
                
                examples.append(example_original)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
                
                # Générer une version augmentée si l'augmentation est activée
                if self.augmentation_enabled:
                    augmented_question = self.augment_question(question, lang)
                    
                    # Si la question augmentée est différente, créer un exemple supplémentaire
                    if augmented_question != question:
                        example_augmented = {
                            "id": f"{concepto_id}_{lang}_{i}_aug",
                            "language": lang,
                            "concept_id": concepto_id,
                            "question": augmented_question,
                            "answer": response,
                            "metadata": {
                                "ministry": ministerio_traducido,
                                "query_type": "concepto",
                                "augmented": True
                            }
                        }
                        
                        examples.append(example_augmented)
                        self.stats["augmented_examples"] = self.stats.get("augmented_examples", 0) + 1
                        self.stats["languages"][lang] += 1
                        self.stats["total_examples"] += 1
            
            # Générer quelques exemples avec les mots-clés
            keywords = palabras_clave_dict.get(lang, palabras_clave_dict.get("es", []))
            if isinstance(keywords, str):
                keywords = [k.strip() for k in keywords.split(",")]
            
            if keywords:
                for _ in range(min(2, len(keywords))):  # Limiter à 2 exemples par concept
                    keyword = random.choice(keywords)
                    if not keyword.strip():
                        continue
                    
                    template = random.choice(KEYWORD_QUESTION_TEMPLATES[lang])
                    question = template.format(palabra_clave=keyword.strip())
                    
                    response_template = RESPONSE_TEMPLATES["keyword"][lang]
                    response = response_template.format(
                        palabra_clave=keyword.strip(),
                        conceptos=nombre
                    )
                    
                    # Capitaliser la première lettre
                    question = self._capitalize_first_letter(question)
                    response = self._capitalize_first_letter(response)
                    
                    # Exemple original
                    example = {
                        "id": f"{concepto_id}_{lang}_kw_{keywords.index(keyword) if keyword in keywords else 0}_orig",
                        "language": lang,
                        "concept_id": concepto_id,
                        "question": question,
                        "answer": response,
                        "metadata": {
                            "ministry": ministerio_traducido,
                            "query_type": "keyword",
                            "keyword": keyword,
                            "augmented": False
                        }
                    }
                    
                    examples.append(example)
                    self.stats["languages"][lang] += 1
                    self.stats["total_examples"] += 1
                    
                    # Générer une version augmentée si l'augmentation est activée
                    if self.augmentation_enabled:
                        augmented_question = self.augment_question(question, lang)
                        
                        # Si la question augmentée est différente, créer un exemple supplémentaire
                        if augmented_question != question:
                            example_augmented = {
                                "id": f"{concepto_id}_{lang}_kw_{keywords.index(keyword) if keyword in keywords else 0}_aug",
                                "language": lang,
                                "concept_id": concepto_id,
                                "question": augmented_question,
                                "answer": response,
                                "metadata": {
                                    "ministry": ministerio_traducido,
                                    "query_type": "keyword",
                                    "keyword": keyword,
                                    "augmented": True
                                }
                            }
                            
                            examples.append(example_augmented)
                            self.stats["augmented_examples"] = self.stats.get("augmented_examples", 0) + 1
                            self.stats["languages"][lang] += 1
                            self.stats["total_examples"] += 1
        
        return examples
    
    def _process_ministerio(self, ministerio, languages=None):
        """
        Génère des exemples pour un ministère donné
        
        Args:
            ministerio: Objet ministère avec les données
            languages: Liste des langues à utiliser (si None, utilise toutes)
        
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(GENERAL_QUESTION_TEMPLATES.keys())
        
        # Extraire les données du ministère
        ministerio_id = ministerio.get("id", "")
        ministerio_nombre = ministerio.get("nombre", "")
        
        # Adapter les données selon le format (ancien ou nouveau multilingue)
        ministerio_nombres = {}
        if isinstance(ministerio_nombre, dict):
            # Format multilingue
            ministerio_nombres = ministerio_nombre
        else:
            # Format non multilingue
            ministerio_nombres = {"es": ministerio_nombre}
            
            # Tentative de récupération des traductions individuelles
            for lang in languages:
                lang_key = f"nombre_{lang}"
                if lang_key in ministerio:
                    ministerio_nombres[lang] = ministerio[lang_key]
        
        # Collecter tous les concepts sous ce ministère
        all_concepts = []
        
        for sector in ministerio.get("sectores", []):
            for categoria in sector.get("categorias", []):
                for sub_categoria in categoria.get("sub_categorias", []):
                    for concepto in sub_categoria.get("conceptos", []):
                        # Extraire le nom du concept pour chaque langue
                        concepto_nombre = concepto.get("nombre", "")
                        concepto_nombres = {}
                        
                        if isinstance(concepto_nombre, dict):
                            concepto_nombres = concepto_nombre
                        else:
                            concepto_nombres = {"es": concepto_nombre}
                            
                            for lang in languages:
                                lang_key = f"nombre_{lang}"
                                if lang_key in concepto:
                                    concepto_nombres[lang] = concepto[lang_key]
                        
                        # Ajouter le concept avec ses traductions
                        all_concepts.append(concepto_nombres)
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # S'assurer qu'il y a des traductions pour cette langue, sinon utiliser l'espagnol
            ministerio_nombre_lang = ministerio_nombres.get(lang, ministerio_nombres.get("es", ministerio_id))
            
            # Extraire les noms des concepts pour cette langue
            concept_names = []
            for concept_dict in all_concepts:
                name = concept_dict.get(lang, concept_dict.get("es", ""))
                if name and name not in concept_names:
                    concept_names.append(name)
            
            if not concept_names:
                continue
                
            # Limiter la liste à 5 concepts maximum pour la réponse
            sample_concepts = random.sample(concept_names, min(5, len(concept_names)))
            concepts_formatted = self._format_list(sample_concepts, lang)
            
            # Générer quelques exemples avec les templates généraux
            templates = GENERAL_QUESTION_TEMPLATES[lang]
            
            for i, template in enumerate(templates[:2]):  # Limiter à 2 exemples par ministère
                question = template.format(ministerio=ministerio_nombre_lang)
                
                response_template = RESPONSE_TEMPLATES["ministerio_general"][lang]
                response = response_template.format(
                    ministerio=ministerio_nombre_lang,
                    conceptos=concepts_formatted
                )
                
                # Capitaliser la première lettre
                question = self._capitalize_first_letter(question)
                response = self._capitalize_first_letter(response)
                
                # Exemple original
                example = {
                    "id": f"{ministerio_id}_{lang}_general_{i}_orig",
                    "language": lang,
                    "concept_id": ministerio_id,
                    "question": question,
                    "answer": response,
                    "metadata": {
                        "ministry": ministerio_nombre_lang,
                        "query_type": "ministerio_general",
                        "augmented": False
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
                
                # Générer une version augmentée si l'augmentation est activée
                if self.augmentation_enabled:
                    augmented_question = self.augment_question(question, lang)
                    
                    # Si la question augmentée est différente, créer un exemple supplémentaire
                    if augmented_question != question:
                        example_augmented = {
                            "id": f"{ministerio_id}_{lang}_general_{i}_aug",
                            "language": lang,
                            "concept_id": ministerio_id,
                            "question": augmented_question,
                            "answer": response,
                            "metadata": {
                                "ministry": ministerio_nombre_lang,
                                "query_type": "ministerio_general",
                                "augmented": True
                            }
                        }
                        
                        examples.append(example_augmented)
                        self.stats["augmented_examples"] = self.stats.get("augmented_examples", 0) + 1
                        self.stats["languages"][lang] += 1
                        self.stats["total_examples"] += 1
        
        return examples
    
    def _generate_greeting_examples(self, languages=None):
        """
        Génère des exemples de salutations et remerciements
        
        Args:
            languages: Liste des langues à utiliser (si None, utilise toutes)
            
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(GREETING_TEMPLATES.keys())
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # Salutations
            for i, greeting in enumerate(GREETING_TEMPLATES[lang]):
                response = random.choice(GREETING_RESPONSES[lang])
                
                # Exemple original
                example = {
                    "id": f"greeting_{lang}_{i}_orig",
                    "language": lang,
                    "concept_id": "greeting",
                    "question": greeting,
                    "answer": response,
                    "metadata": {
                        "query_type": "greeting",
                        "augmented": False
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
                
                # Générer une version augmentée si l'augmentation est activée
                # Pour les salutations, utiliser une probabilité d'augmentation plus faible
                if self.augmentation_enabled:
                    augmented_greeting = self.augment_question(greeting, lang, augmentation_prob=self.augmentation_prob/2)
                    
                    # Si la salutation augmentée est différente, créer un exemple supplémentaire
                    if augmented_greeting != greeting:
                        example_augmented = {
                            "id": f"greeting_{lang}_{i}_aug",
                            "language": lang,
                            "concept_id": "greeting",
                            "question": augmented_greeting,
                            "answer": response,
                            "metadata": {
                                "query_type": "greeting",
                                "augmented": True
                            }
                        }
                        
                        examples.append(example_augmented)
                        self.stats["augmented_examples"] = self.stats.get("augmented_examples", 0) + 1
                        self.stats["languages"][lang] += 1
                        self.stats["total_examples"] += 1
            
            # Remerciements
            for i, thanks in enumerate(THANKS_TEMPLATES[lang]):
                response = random.choice(THANKS_RESPONSES[lang])
                
                # Exemple original
                example = {
                    "id": f"thanks_{lang}_{i}_orig",
                    "language": lang,
                    "concept_id": "thanks",
                    "question": thanks,
                    "answer": response,
                    "metadata": {
                        "query_type": "thanks",
                        "augmented": False
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
                
                # Générer une version augmentée si l'augmentation est activée
                if self.augmentation_enabled:
                    augmented_thanks = self.augment_question(thanks, lang, augmentation_prob=self.augmentation_prob/2)
                    
                    # Si le remerciement augmenté est différent, créer un exemple supplémentaire
                    if augmented_thanks != thanks:
                        example_augmented = {
                            "id": f"thanks_{lang}_{i}_aug",
                            "language": lang,
                            "concept_id": "thanks",
                            "question": augmented_thanks,
                            "answer": response,
                            "metadata": {
                                "query_type": "thanks",
                                "augmented": True
                            }
                        }
                        
                        examples.append(example_augmented)
                        self.stats["augmented_examples"] = self.stats.get("augmented_examples", 0) + 1
                        self.stats["languages"][lang] += 1
                        self.stats["total_examples"] += 1
        
        return examples
    
    def generate_corpus(self):
        """Génère le corpus complet d'entraînement"""
        if self.verbose:
            print("Génération du corpus d'entraînement...")
            if self.augmentation_enabled:
                print(f"Augmentation des données activée (probabilité: {self.augmentation_prob})")
            else:
                print("Augmentation des données désactivée")
        
        # Charger les données
        data = self.load_data()
        
        # Vérifier que les données ont été chargées correctement
        if not data:
            print("Aucune donnée n'a été chargée. Vérifiez le fichier JSON.")
            return False
        
        # Parcourir les ministères
        for ministerio in data:
            ministerio_id = ministerio.get("id", "")
            ministerio_nombre = ministerio.get("nombre", "")
            
            if self.verbose:
                print(f"Traitement du ministère: {ministerio_id}")
            
            # Générer des exemples spécifiques au ministère
            ministerio_examples = self._process_ministerio(ministerio)
            self.corpus.extend(ministerio_examples)
            
            # Parcourir les secteurs, catégories, sous-catégories et concepts
            for sector in ministerio.get("sectores", []):
                for categoria in sector.get("categorias", []):
                    for sub_categoria in categoria.get("sub_categorias", []):
                        for concepto in sub_categoria.get("conceptos", []):
                            # Générer des exemples pour ce concept
                            if isinstance(ministerio_nombre, dict):
                                # Utiliser le nom espagnol par défaut
                                ministerio_nombre_str = ministerio_nombre.get("es", ministerio_id)
                            else:
                                ministerio_nombre_str = ministerio_nombre
                                
                            concepto_examples = self._process_concepto(concepto, ministerio_nombre_str)
                            self.corpus.extend(concepto_examples)
                            
                            # Incrémenter le compteur de concepts
                            self.stats["concepts"] += 1
        
        # Ajouter des exemples de salutations et remerciements
        greeting_examples = self._generate_greeting_examples()
        self.corpus.extend(greeting_examples)
        
        if self.verbose:
            print(f"Corpus généré avec succès: {self.stats['total_examples']} exemples pour {self.stats['concepts']} concepts")
            print(f"  Exemples originaux: {self.stats['total_examples'] - self.stats.get('augmented_examples', 0)}")
            print(f"  Exemples augmentés: {self.stats.get('augmented_examples', 0)}")
            for lang, count in self.stats["languages"].items():
                print(f"  Langue {lang}: {count} exemples")
        
        return True
    
    def save_corpus(self):
        """Sauvegarde le corpus généré dans un fichier JSON"""
        if not self.corpus:
            print("Le corpus est vide. Exécutez generate_corpus() d'abord.")
            return False
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = os.path.dirname(self.output_file_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # Écrire le corpus dans le fichier de sortie
        try:
            with open(self.output_file_path, 'w', encoding='utf-8') as file:
                json.dump(self.corpus, file, ensure_ascii=False, indent=2)
            
            if self.verbose:
                print(f"Corpus sauvegardé dans {self.output_file_path}")
            
            return True
        except Exception as e:
            print(f"Erreur lors de la sauvegarde du corpus: {e}")
            return False

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description='Générateur de corpus pour le modèle NLP du chatbot TaxasGE')
    parser.add_argument('--input', '-i', type=str, default='assets/data/taxes.json',
                        help='Chemin vers le fichier JSON contenant les données fiscales')
    parser.add_argument('--output', '-o', type=str, default='assets/ml/training_corpus.json',
                        help='Chemin où sauvegarder le corpus généré')
    parser.add_argument('--examples', '-e', type=int, default=5,
                        help='Nombre d\'exemples à générer par concept')
    parser.add_argument('--augment', '-a', action='store_true',
                        help='Activer l\'augmentation des données')
    parser.add_argument('--augment-prob', '-p', type=float, default=0.3,
                        help='Probabilité d\'augmentation pour chaque type')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Afficher des informations détaillées pendant l\'exécution')
    
    args = parser.parse_args()
    
    # Obtenir le chemin absolu basé sur le répertoire du projet
    base_dir = Path(__file__).resolve().parent.parent
    input_path = base_dir / args.input
    output_path = base_dir / args.output
    
    print(f"Génération du corpus d'entraînement...")
    print(f"Fichier d'entrée: {input_path}")
    print(f"Fichier de sortie: {output_path}")
    print(f"Nombre d'exemples par concept: {args.examples}")
    print(f"Augmentation des données: {'Activée' if args.augment else 'Désactivée'}")
    if args.augment:
        print(f"Probabilité d'augmentation: {args.augment_prob}")
    
    # Générer le corpus
    generator = CorpusGenerator(
        json_file_path=str(input_path),
        output_file_path=str(output_path),
        num_examples_per_concept=args.examples,
        augmentation_enabled=args.augment,
        augmentation_prob=args.augment_prob,
        verbose=args.verbose
    )
    
    generator.generate_corpus()
    generator.save_corpus()
    
    print("Terminé!")

if __name__ == "__main__":
    main() for keyword in ["documento", "requisito", "document", "requirement"]):
                    if docs:
                        response_template = RESPONSE_TEMPLATES["documentos"][lang]
                        response = response_template.format(
                            concepto=nombre, 
                            documentos_requeridos=docs
                        )
                    else:
                        response = random.choice(FALLBACK_RESPONSES[lang]).format(concepto=nombre)
                elif any(keyword in question_template.lower() for keyword in ["procedimiento", "obtener", "proceso", "procédure", "obtenir", "procedure", "process"]):
                    if proc:
                        response_template = RESPONSE_TEMPLATES["procedimiento"][lang]
                        response = response_template.format(
                            concepto=nombre, 
                            procedimiento=proc
                        )
                    else:
                        response = random.choice(FALLBACK_RESPONSES[lang]).format(concepto=nombre)
                elif any(keyword in question_template.lower()#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Générateur de corpus d'entraînement pour le modèle NLP du chatbot TaxasGE
Ce script génère automatiquement un corpus d'entraînement à partir des données fiscales 
extraites du fichier JSON et le sauvegarde dans assets/ml/training_corpus.json.
"""

import json
import os
import random
import re
from pathlib import Path
import argparse

# Templates de questions en plusieurs langues
QUESTION_TEMPLATES = {
    "es": [  # Espagnol (langue par défaut)
        "¿Cuánto cuesta {concepto}?",
        "¿Cuál es el precio de {concepto}?",
        "¿Cuánto tengo que pagar por {concepto}?",
        "¿Cuál es la tasa de {concepto}?",
        "¿Qué documentos necesito para {concepto}?",
        "¿Qué documentos se requieren para {concepto}?",
        "¿Qué documentación debo presentar para {concepto}?",
        "¿Cuáles son los requisitos para {concepto}?",
        "¿Cuál es el procedimiento para {concepto}?",
        "¿Cómo puedo obtener {concepto}?",
        "¿Cuál es el proceso para {concepto}?",
        "¿Dónde puedo tramitar {concepto}?",
        "¿A qué ministerio pertenece {concepto}?",
        "¿Qué ministerio se encarga de {concepto}?",
        "¿Qué departamento gestiona {concepto}?",
        "Necesito información sobre {concepto}",
        "Háblame de {concepto}",
        "Explícame {concepto}",
        "¿Cuánto cuesta renovar {concepto}?",
        "¿Cuál es el costo de renovación de {concepto}?",
        "¿Cuál es la tasa de renovación para {concepto}?",
    ],
    "fr": [  # Français
        "Combien coûte {concepto}?",
        "Quel est le prix de {concepto}?",
        "Combien dois-je payer pour {concepto}?",
        "Quel est le montant de la taxe pour {concepto}?",
        "Quels documents sont nécessaires pour {concepto}?",
        "Quels documents sont requis pour {concepto}?",
        "Quelle documentation dois-je présenter pour {concepto}?",
        "Quelles sont les conditions requises pour {concepto}?",
        "Quelle est la procédure pour {concepto}?",
        "Comment puis-je obtenir {concepto}?",
        "Quel est le processus pour {concepto}?",
        "Où puis-je faire la demande de {concepto}?",
        "À quel ministère appartient {concepto}?",
        "Quel ministère est en charge de {concepto}?",
        "Quel département gère {concepto}?",
        "J'ai besoin d'informations sur {concepto}",
        "Parlez-moi de {concepto}",
        "Expliquez-moi {concepto}",
        "Combien coûte le renouvellement de {concepto}?",
        "Quel est le coût de renouvellement de {concepto}?",
        "Quel est le montant pour renouveler {concepto}?",
    ],
    "en": [  # Anglais
        "How much does {concepto} cost?",
        "What is the price of {concepto}?",
        "How much do I have to pay for {concepto}?",
        "What is the fee for {concepto}?",
        "What documents do I need for {concepto}?",
        "What documents are required for {concepto}?",
        "What documentation should I submit for {concepto}?",
        "What are the requirements for {concepto}?",
        "What is the procedure for {concepto}?",
        "How can I obtain {concepto}?",
        "What is the process for {concepto}?",
        "Where can I apply for {concepto}?",
        "Which ministry handles {concepto}?",
        "Which ministry is in charge of {concepto}?",
        "Which department manages {concepto}?",
        "I need information about {concepto}",
        "Tell me about {concepto}",
        "Explain {concepto} to me",
        "How much does it cost to renew {concepto}?",
        "What is the renewal cost for {concepto}?",
        "What is the renewal fee for {concepto}?",
    ]
}

# Templates de questions générales (sans mention spécifique d'un concept)
GENERAL_QUESTION_TEMPLATES = {
    "es": [
        "¿Qué trámites puedo hacer en el Ministerio de {ministerio}?",
        "¿Qué servicios ofrece el Ministerio de {ministerio}?",
        "¿Cuáles son las tasas del Ministerio de {ministerio}?",
        "¿Qué documentos emite el Ministerio de {ministerio}?",
        "¿Cómo contactar al Ministerio de {ministerio}?",
        "¿Qué categorías de tasas existen en {ministerio}?",
    ],
    "fr": [
        "Quelles démarches puis-je faire au Ministère de {ministerio}?",
        "Quels services propose le Ministère de {ministerio}?",
        "Quelles sont les taxes du Ministère de {ministerio}?",
        "Quels documents sont émis par le Ministère de {ministerio}?",
        "Comment contacter le Ministère de {ministerio}?",
        "Quelles catégories de taxes existent au {ministerio}?",
    ],
    "en": [
        "What procedures can I do at the Ministry of {ministerio}?",
        "What services does the Ministry of {ministerio} offer?",
        "What are the fees at the Ministry of {ministerio}?",
        "What documents are issued by the Ministry of {ministerio}?",
        "How can I contact the Ministry of {ministerio}?",
        "What categories of fees exist in {ministerio}?",
    ]
}

# Templates pour les questions sur les mots-clés
KEYWORD_QUESTION_TEMPLATES = {
    "es": [
        "¿Dónde puedo obtener documentos relacionados con {palabra_clave}?",
        "¿Qué trámites existen para {palabra_clave}?",
        "Busco información sobre {palabra_clave}",
        "¿Qué tasas están relacionadas con {palabra_clave}?",
        "Necesito hacer un trámite de {palabra_clave}",
    ],
    "fr": [
        "Où puis-je obtenir des documents liés à {palabra_clave}?",
        "Quelles procédures existent pour {palabra_clave}?",
        "Je cherche des informations sur {palabra_clave}",
        "Quelles taxes sont liées à {palabra_clave}?",
        "J'ai besoin de faire une démarche concernant {palabra_clave}",
    ],
    "en": [
        "Where can I get documents related to {palabra_clave}?",
        "What procedures exist for {palabra_clave}?",
        "I'm looking for information about {palabra_clave}",
        "What fees are related to {palabra_clave}?",
        "I need to do a procedure related to {palabra_clave}",
    ]
}

# Templates pour les réponses
RESPONSE_TEMPLATES = {
    "precio": {
        "es": "El costo de {concepto} es {tasa_expedicion} para expedición y {tasa_renovacion} para renovación.",
        "fr": "Le coût de {concepto} est de {tasa_expedicion} pour l'émission et {tasa_renovacion} pour le renouvellement.",
        "en": "The cost of {concepto} is {tasa_expedicion} for issuance and {tasa_renovacion} for renewal."
    },
    "documentos": {
        "es": "Los documentos requeridos para {concepto} son: {documentos_requeridos}",
        "fr": "Les documents requis pour {concepto} sont: {documentos_requeridos}",
        "en": "The required documents for {concepto} are: {documentos_requeridos}"
    },
    "procedimiento": {
        "es": "El procedimiento para {concepto} es: {procedimiento}",
        "fr": "La procédure pour {concepto} est: {procedimiento}",
        "en": "The procedure for {concepto} is: {procedimiento}"
    },
    "ministerio": {
        "es": "{concepto} es gestionado por el Ministerio de {ministerio}.",
        "fr": "{concepto} est géré par le Ministère de {ministerio}.",
        "en": "{concepto} is managed by the Ministry of {ministerio}."
    },
    "informacion_general": {
        "es": "{concepto} es un trámite del Ministerio de {ministerio}. El costo es {tasa_expedicion} para expedición y {tasa_renovacion} para renovación.",
        "fr": "{concepto} est une démarche du Ministère de {ministerio}. Le coût est de {tasa_expedicion} pour l'émission et {tasa_renovacion} pour le renouvellement.",
        "en": "{concepto} is a procedure of the Ministry of {ministerio}. The cost is {tasa_expedicion} for issuance and {tasa_renovacion} for renewal."
    },
    "ministerio_general": {
        "es": "El Ministerio de {ministerio} gestiona varios trámites, entre ellos: {conceptos}.",
        "fr": "Le Ministère de {ministerio} gère plusieurs démarches, notamment: {conceptos}.",
        "en": "The Ministry of {ministerio} manages several procedures, including: {conceptos}."
    },
    "keyword": {
        "es": "Para trámites relacionados con {palabra_clave}, puede consultar: {conceptos}.",
        "fr": "Pour les démarches liées à {palabra_clave}, vous pouvez consulter: {conceptos}.",
        "en": "For procedures related to {palabra_clave}, you can check: {conceptos}."
    }
}

# Réponses génériques quand l'information n'est pas disponible
FALLBACK_RESPONSES = {
    "es": [
        "No tengo información específica sobre {concepto}. Por favor, consulte directamente con el ministerio correspondiente.",
        "Lo siento, no puedo proporcionar información detallada sobre {concepto}.",
        "No dispongo de datos sobre {concepto}. Recomiendo consultar en la página web oficial del gobierno."
    ],
    "fr": [
        "Je n'ai pas d'informations spécifiques sur {concepto}. Veuillez consulter directement le ministère concerné.",
        "Désolé, je ne peux pas fournir d'informations détaillées sur {concepto}.",
        "Je ne dispose pas de données sur {concepto}. Je recommande de consulter le site web officiel du gouvernement."
    ],
    "en": [
        "I don't have specific information about {concepto}. Please consult directly with the corresponding ministry.",
        "Sorry, I cannot provide detailed information about {concepto}.",
        "I don't have data about {concepto}. I recommend checking the official government website."
    ]
}

# Templates pour les salutations et remerciements
GREETING_TEMPLATES = {
    "es": [
        "Hola", "Buenos días", "Buenas tardes", "Buenas noches", "Saludos"
    ],
    "fr": [
        "Bonjour", "Salut", "Bonsoir", "Coucou", "Salutations"
    ],
    "en": [
        "Hello", "Hi", "Good morning", "Good afternoon", "Good evening", "Greetings"
    ]
}

THANKS_TEMPLATES = {
    "es": [
        "Gracias", "Muchas gracias", "Te agradezco", "Gracias por la información", "Excelente, gracias"
    ],
    "fr": [
        "Merci", "Merci beaucoup", "Je vous remercie", "Merci pour l'information", "Excellent, merci"
    ],
    "en": [
        "Thanks", "Thank you", "Thank you very much", "Thanks for the information", "Great, thanks"
    ]
}

GREETING_RESPONSES = {
    "es": [
        "Hola, ¿en qué puedo ayudarte?",
        "Buenos días, ¿qué información sobre tasas fiscales necesitas?",
        "Hola, soy el asistente virtual de TaxasGE. ¿Cómo puedo ayudarte?",
        "Saludos, estoy aquí para responder tus preguntas sobre tasas fiscales en Guinea Ecuatorial."
    ],
    "fr": [
        "Bonjour, comment puis-je vous aider?",
        "Bonjour, quelle information sur les taxes fiscales vous faut-il?",
        "Bonjour, je suis l'assistant virtuel de TaxasGE. Comment puis-je vous aider?",
        "Salutations, je suis là pour répondre à vos questions sur les taxes fiscales en Guinée Équatoriale."
    ],
    "en": [
        "Hello, how can I help you?",
        "Good day, what information about fiscal taxes do you need?",
        "Hi, I'm the TaxasGE virtual assistant. How can I help you?",
        "Greetings, I'm here to answer your questions about fiscal taxes in Equatorial Guinea."
    ]
}

THANKS_RESPONSES = {
    "es": [
        "De nada, estoy aquí para ayudar.",
        "Un placer. ¿Necesitas algo más?",
        "No hay problema. ¿Puedo ayudarte con algo más?",
        "A tu servicio. ¿Hay algo más en lo que pueda asistirte?"
    ],
    "fr": [
        "De rien, je suis là pour aider.",
        "Avec plaisir. Avez-vous besoin d'autre chose?",
        "Pas de problème. Puis-je vous aider avec autre chose?",
        "À votre service. Y a-t-il autre chose dont vous avez besoin?"
    ],
    "en": [
        "You're welcome, I'm here to help.",
        "My pleasure. Do you need anything else?",
        "No problem. Can I help you with something else?",
        "At your service. Is there anything else I can assist you with?"
    ]
}

class CorpusGenerator:
    def __init__(self, json_file_path, output_file_path, num_examples_per_concept=5, verbose=False):
        """
        Initialise le générateur de corpus.
        
        Args:
            json_file_path (str): Chemin vers le fichier JSON avec les données fiscales
            output_file_path (str): Chemin où enregistrer le corpus généré
            num_examples_per_concept (int): Nombre d'exemples à générer par concept
            verbose (bool): Afficher les détails du processus
        """
        self.json_file_path = json_file_path
        self.output_file_path = output_file_path
        self.num_examples_per_concept = num_examples_per_concept
        self.verbose = verbose
        self.corpus = []
        self.stats = {"total_examples": 0, "concepts": 0, "languages": {}}
        
        for lang in QUESTION_TEMPLATES.keys():
            self.stats["languages"][lang] = 0
    
    def load_data(self):
        """Charge les données fiscales à partir du fichier JSON"""
        if self.verbose:
            print(f"Chargement des données depuis {self.json_file_path}...")
        
        try:
            with open(self.json_file_path, 'r', encoding='utf-8') as file:
                return json.load(file)
        except Exception as e:
            print(f"Erreur lors du chargement du fichier JSON: {e}")
            return []
    
    def _capitalize_first_letter(self, text):
        """Capitalise la première lettre d'une chaîne de caractères"""
        if not text:
            return text
        return text[0].upper() + text[1:]
    
    def _format_list(self, items, lang):
        """Formate une liste en chaîne de caractères selon la langue"""
        if not items:
            return ""
        
        if lang == "es":
            return ", ".join(items[:-1]) + (" y " + items[-1] if len(items) > 1 else items[0])
        elif lang == "fr":
            return ", ".join(items[:-1]) + (" et " + items[-1] if len(items) > 1 else items[0])
        else:  # en
            return ", ".join(items[:-1]) + (" and " + items[-1] if len(items) > 1 else items[0])
    
    def _process_concepto(self, concepto, ministerio_nombre, languages=None):
        """
        Génère des exemples pour un concept donné
        
        Args:
            concepto: Objet concept avec les détails de la taxe
            ministerio_nombre: Nom du ministère associé
            languages: Liste des langues à utiliser (si None, utilise toutes)
        
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(QUESTION_TEMPLATES.keys())
        
        # Extraire les données du concept
        concepto_id = concepto.get("id", "")
        concepto_nombre = concepto.get("nombre", "")
        tasa_expedicion = concepto.get("tasa_expedicion", "N/A")
        tasa_renovacion = concepto.get("tasa_renovacion", "N/A")
        documentos_requeridos = concepto.get("documentos_requeridos", "")
        procedimiento = concepto.get("procedimiento", "")
        palabras_clave = concepto.get("palabras_clave", "").split(",") if isinstance(concepto.get("palabras_clave", ""), str) else []
        
        # Adapter les données selon le format (ancien ou nouveau multilingue)
        concepto_nombres = {}
        if isinstance(concepto_nombre, dict):
            # Format multilingue
            concepto_nombres = concepto_nombre
        else:
            # Format non multilingue
            concepto_nombres = {"es": concepto_nombre}
            
            # Tentative de récupération des traductions individuelles
            for lang in languages:
                lang_key = f"nombre_{lang}"
                if lang_key in concepto:
                    concepto_nombres[lang] = concepto[lang_key]
        
        # Traiter de manière similaire pour documentos_requeridos et procedimiento
        documentos_dict = {}
        if isinstance(documentos_requeridos, dict):
            documentos_dict = documentos_requeridos
        else:
            documentos_dict = {"es": documentos_requeridos}
            for lang in languages:
                lang_key = f"documentos_requeridos_{lang}"
                if lang_key in concepto:
                    documentos_dict[lang] = concepto[lang_key]
        
        procedimiento_dict = {}
        if isinstance(procedimiento, dict):
            procedimiento_dict = procedimiento
        else:
            procedimiento_dict = {"es": procedimiento}
            for lang in languages:
                lang_key = f"procedimiento_{lang}"
                if lang_key in concepto:
                    procedimiento_dict[lang] = concepto[lang_key]
        
        # Traiter également les mots-clés multilangues
        palabras_clave_dict = {}
        if isinstance(concepto.get("palabras_clave", ""), dict):
            palabras_clave_dict = concepto["palabras_clave"]
        else:
            for lang in languages:
                if palabras_clave:
                    palabras_clave_dict[lang] = palabras_clave
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # S'assurer qu'il y a des traductions pour cette langue, sinon utiliser l'espagnol
            nombre = concepto_nombres.get(lang, concepto_nombres.get("es", concepto_id))
            
            # Remplacer les valeurs manquantes
            if not nombre:
                continue
            
            docs = documentos_dict.get(lang, documentos_dict.get("es", ""))
            proc = procedimiento_dict.get(lang, procedimiento_dict.get("es", ""))
            ministerio_traducido = ministerio_nombre
            
            # Générer des exemples avec les templates de questions/réponses
            for i in range(self.num_examples_per_concept):
                # Prendre un template aléatoire
                question_template = random.choice(QUESTION_TEMPLATES[lang])
                question = question_template.format(concepto=nombre)
                
                # Créer différentes variantes de réponses selon le type de question
                if any(keyword in question_template.lower() for keyword in ["cuesta", "precio", "pagar", "tasa", "coût", "cost", "pay", "fee"]):
                    response_template = RESPONSE_TEMPLATES["precio"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        tasa_expedicion=tasa_expedicion, 
                        tasa_renovacion=tasa_renovacion
                    )
                elif any(keyword in question_template.lower() for keyword in ["documento", "requisito", "document", "requirement"]):
                    if docs:
                        response_template = RESPONSE_TEMPLATES["documentos"][lang]
                        response = response_template.format(
                            concepto=nombre, 
                            documentos_requeridos=docs
                        )
                    else:
                        response = random.choice(FALLBACK_RESPONSES[lang]).format(concepto=nombre)
                elif any(keyword in question_template.lower() for keyword in ["procedimiento", "obtener", "proceso", "procédure", "obtenir", "procedure", "process"]):
                    if proc:
                        response_template = RESPONSE_TEMPLATES["procedimiento"][lang]
                        response = response_template.format(
                            concepto=nombre, 
                            procedimiento=proc
                        )
                    else:
                        response = random.choice(FALLBACK_RESPONSES[lang]).format(concepto=nombre)
                elif any(keyword in question_template.lower() for keyword in ["ministerio", "departamento", "ministère", "ministry", "department"]):
                    response_template = RESPONSE_TEMPLATES["ministerio"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        ministerio=ministerio_traducido
                    )
                else:
                    # Réponse générale incluant les informations principales
                    response_template = RESPONSE_TEMPLATES["informacion_general"][lang]
                    response = response_template.format(
                        concepto=nombre, 
                        ministerio=ministerio_traducido,
                        tasa_expedicion=tasa_expedicion, 
                        tasa_renovacion=tasa_renovacion
                    )
                
                # Capitaliser la première lettre
                question = self._capitalize_first_letter(question)
                response = self._capitalize_first_letter(response)
                
                # Créer l'exemple et l'ajouter au corpus
                example = {
                    "id": f"{concepto_id}_{lang}_{i}",
                    "language": lang,
                    "concept_id": concepto_id,
                    "question": question,
                    "answer": response,
                    "metadata": {
                        "ministry": ministerio_traducido,
                        "query_type": "concepto"
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
            
            # Générer quelques exemples avec les mots-clés
            keywords = palabras_clave_dict.get(lang, palabras_clave_dict.get("es", []))
            if isinstance(keywords, str):
                keywords = [k.strip() for k in keywords.split(",")]
            
            if keywords:
                for _ in range(min(2, len(keywords))):  # Limiter à 2 exemples par concept
                    keyword = random.choice(keywords)
                    if not keyword.strip():
                        continue
                    
                    template = random.choice(KEYWORD_QUESTION_TEMPLATES[lang])
                    question = template.format(palabra_clave=keyword.strip())
                    
                    response_template = RESPONSE_TEMPLATES["keyword"][lang]
                    response = response_template.format(
                        palabra_clave=keyword.strip(),
                        conceptos=nombre
                    )
                    
                    # Capitaliser la première lettre
                    question = self._capitalize_first_letter(question)
                    response = self._capitalize_first_letter(response)
                    
                    example = {
                        "id": f"{concepto_id}_{lang}_kw_{keywords.index(keyword) if keyword in keywords else 0}",
                        "language": lang,
                        "concept_id": concepto_id,
                        "question": question,
                        "answer": response,
                        "metadata": {
                            "ministry": ministerio_traducido,
                            "query_type": "keyword",
                            "keyword": keyword
                        }
                    }
                    
                    examples.append(example)
                    self.stats["languages"][lang] += 1
                    self.stats["total_examples"] += 1
        
        return examples
    
    def _process_ministerio(self, ministerio, languages=None):
        """
        Génère des exemples pour un ministère donné
        
        Args:
            ministerio: Objet ministère avec les données
            languages: Liste des langues à utiliser (si None, utilise toutes)
        
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(GENERAL_QUESTION_TEMPLATES.keys())
        
        # Extraire les données du ministère
        ministerio_id = ministerio.get("id", "")
        ministerio_nombre = ministerio.get("nombre", "")
        
        # Adapter les données selon le format (ancien ou nouveau multilingue)
        ministerio_nombres = {}
        if isinstance(ministerio_nombre, dict):
            # Format multilingue
            ministerio_nombres = ministerio_nombre
        else:
            # Format non multilingue
            ministerio_nombres = {"es": ministerio_nombre}
            
            # Tentative de récupération des traductions individuelles
            for lang in languages:
                lang_key = f"nombre_{lang}"
                if lang_key in ministerio:
                    ministerio_nombres[lang] = ministerio[lang_key]
        
        # Collecter tous les concepts sous ce ministère
        all_concepts = []
        
        for sector in ministerio.get("sectores", []):
            for categoria in sector.get("categorias", []):
                for sub_categoria in categoria.get("sub_categorias", []):
                    for concepto in sub_categoria.get("conceptos", []):
                        # Extraire le nom du concept pour chaque langue
                        concepto_nombre = concepto.get("nombre", "")
                        concepto_nombres = {}
                        
                        if isinstance(concepto_nombre, dict):
                            concepto_nombres = concepto_nombre
                        else:
                            concepto_nombres = {"es": concepto_nombre}
                            
                            for lang in languages:
                                lang_key = f"nombre_{lang}"
                                if lang_key in concepto:
                                    concepto_nombres[lang] = concepto[lang_key]
                        
                        # Ajouter le concept avec ses traductions
                        all_concepts.append(concepto_nombres)
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # S'assurer qu'il y a des traductions pour cette langue, sinon utiliser l'espagnol
            ministerio_nombre_lang = ministerio_nombres.get(lang, ministerio_nombres.get("es", ministerio_id))
            
            # Extraire les noms des concepts pour cette langue
            concept_names = []
            for concept_dict in all_concepts:
                name = concept_dict.get(lang, concept_dict.get("es", ""))
                if name and name not in concept_names:
                    concept_names.append(name)
            
            if not concept_names:
                continue
                
            # Limiter la liste à 5 concepts maximum pour la réponse
            sample_concepts = random.sample(concept_names, min(5, len(concept_names)))
            concepts_formatted = self._format_list(sample_concepts, lang)
            
            # Générer quelques exemples avec les templates généraux
            templates = GENERAL_QUESTION_TEMPLATES[lang]
            
            for i, template in enumerate(templates[:2]):  # Limiter à 2 exemples par ministère
                question = template.format(ministerio=ministerio_nombre_lang)
                
                response_template = RESPONSE_TEMPLATES["ministerio_general"][lang]
                response = response_template.format(
                    ministerio=ministerio_nombre_lang,
                    conceptos=concepts_formatted
                )
                
                # Capitaliser la première lettre
                question = self._capitalize_first_letter(question)
                response = self._capitalize_first_letter(response)
                
                example = {
                    "id": f"{ministerio_id}_{lang}_general_{i}",
                    "language": lang,
                    "concept_id": ministerio_id,
                    "question": question,
                    "answer": response,
                    "metadata": {
                        "ministry": ministerio_nombre_lang,
                        "query_type": "ministerio_general"
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
        
        return examples
    
    def _generate_greeting_examples(self, languages=None):
        """
        Génère des exemples de salutations et remerciements
        
        Args:
            languages: Liste des langues à utiliser (si None, utilise toutes)
            
        Returns:
            Liste d'exemples générés
        """
        examples = []
        
        # Si aucune langue n'est spécifiée, utiliser toutes les langues disponibles
        if languages is None:
            languages = list(GREETING_TEMPLATES.keys())
        
        # Pour chaque langue, générer des exemples
        for lang in languages:
            # Salutations
            for i, greeting in enumerate(GREETING_TEMPLATES[lang]):
                response = random.choice(GREETING_RESPONSES[lang])
                
                example = {
                    "id": f"greeting_{lang}_{i}",
                    "language": lang,
                    "concept_id": "greeting",
                    "question": greeting,
                    "answer": response,
                    "metadata": {
                        "query_type": "greeting"
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
            
            # Remerciements
            for i, thanks in enumerate(THANKS_TEMPLATES[lang]):
                response = random.choice(THANKS_RESPONSES[lang])
                
                example = {
                    "id": f"thanks_{lang}_{i}",
                    "language": lang,
                    "concept_id": "thanks",
                    "question": thanks,
                    "answer": response,
                    "metadata": {
                        "query_type": "thanks"
                    }
                }
                
                examples.append(example)
                self.stats["languages"][lang] += 1
                self.stats["total_examples"] += 1
        
        return examples
    
    def generate_corpus(self):
        """Génère le corpus complet d'entraînement"""
        if self.verbose:
            print("Génération du corpus d'entraînement...")
        
        # Charger les données
        data = self.load_data()
        
        # Vérifier que les données ont été chargées correctement
        if not data:
            print("Aucune donnée n'a été chargée. Vérifiez le fichier JSON.")
            return False
        
        # Parcourir les ministères
        for ministerio in data:
            ministerio_id = ministerio.get("id", "")
            ministerio_nombre = ministerio.get("nombre", "")
            
            if self.verbose:
                print(f"Traitement du ministère: {ministerio_id}")
            
            # Générer des exemples spécifiques au ministère
            ministerio_examples = self._process_ministerio(ministerio)
            self.corpus.extend(ministerio_examples)
            
            # Parcourir les secteurs, catégories, sous-catégories et concepts
            for sector in ministerio.get("sectores", []):
                for categoria in sector.get("categorias", []):
                    for sub_categoria in categoria.get("sub_categorias", []):
                        for concepto in sub_categoria.get("conceptos", []):
                            # Générer des exemples pour ce concept
                            if isinstance(ministerio_nombre, dict):
                                # Utiliser le nom espagnol par défaut
                                ministerio_nombre_str = ministerio_nombre.get("es", ministerio_id)
                            else:
                                ministerio_nombre_str = ministerio_nombre
                                
                            concepto_examples = self._process_concepto(concepto, ministerio_nombre_str)
                            self.corpus.extend(concepto_examples)
                            
                            # Incrémenter le compteur de concepts
                            self.stats["concepts"] += 1
        
        # Ajouter des exemples de salutations et remerciements
        greeting_examples = self._generate_greeting_examples()
        self.corpus.extend(greeting_examples)
        
        if self.verbose:
            print(f"Corpus généré avec succès: {self.stats['total_examples']} exemples pour {self.stats['concepts']} concepts")
            for lang, count in self.stats["languages"].items():
                print(f"  Langue {lang}: {count} exemples")
        
        return True
    
    def save_corpus(self):
        """Sauvegarde le corpus généré dans un fichier JSON"""
        if not self.corpus:
            print("Le corpus est vide. Exécutez generate_corpus() d'abord.")
            return False
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = os.path.dirname(self.output_file_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # Écrire le corpus dans le fichier de sortie
        try:
            with open(self.output_file_path, 'w', encoding='utf-8') as file:
                json.dump(self.corpus, file, ensure_ascii=False, indent=2)
            
            if self.verbose:
                print(f"Corpus sauvegardé dans {self.output_file_path}")
            
            return True
        except Exception as e:
            print(f"Erreur lors de la sauvegarde du corpus: {e}")
            return False

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description='Générateur de corpus pour le modèle NLP du chatbot TaxasGE')
    parser.add_argument('--input', '-i', type=str, default='assets/data/taxes.json',
                        help='Chemin vers le fichier JSON contenant les données fiscales')
    parser.add_argument('--output', '-o', type=str, default='assets/ml/training_corpus.json',
                        help='Chemin où sauvegarder le corpus généré')
    parser.add_argument('--examples', '-e', type=int, default=5,
                        help='Nombre d\'exemples à générer par concept')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Afficher des informations détaillées pendant l\'exécution')
    
    args = parser.parse_args()
    
    # Obtenir le chemin absolu basé sur le répertoire du projet
    base_dir = Path(__file__).resolve().parent.parent
    input_path = base_dir / args.input
    output_path = base_dir / args.output
    
    print(f"Génération du corpus d'entraînement...")
    print(f"Fichier d'entrée: {input_path}")
    print(f"Fichier de sortie: {output_path}")
    
    # Générer le corpus
    generator = CorpusGenerator(
        json_file_path=str(input_path),
        output_file_path=str(output_path),
        num_examples_per_concept=args.examples,
        verbose=args.verbose
    )
    
    generator.generate_corpus()
    generator.save_corpus()
    
    print("Terminé!")

if __name__ == "__main__":
    main()