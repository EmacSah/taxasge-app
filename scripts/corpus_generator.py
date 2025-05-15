import json
import os
import random
import argparse
from typing import List, Dict, Any, Tuple

class CorpusGenerator:
    """
    Générateur de corpus d'entraînement pour le modèle NLP de TaxasGE.
    
    Cette classe génère un ensemble de paires question-réponse à partir des
    données fiscales pour entraîner un modèle NLP qui pourra répondre aux
    questions des utilisateurs concernant les taxes.
    """
    
    def __init__(self, input_file: str):
        """
        Initialise le générateur de corpus.
        
        Args:
            input_file: Chemin vers le fichier JSON contenant les données fiscales
        """
        self.input_file = input_file
        self.data = self._load_data()
        self.tax_data = self._flatten_data()
        
    def _load_data(self) -> List[Dict[str, Any]]:
        """Charge les données fiscales depuis le fichier JSON."""
        try:
            with open(self.input_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Erreur lors du chargement des données: {e}")
            return []
    
    def _flatten_data(self) -> List[Dict[str, Any]]:
        """
        Aplatit la structure hiérarchique des données fiscales pour faciliter
        la génération des questions-réponses.
        """
        flattened_data = []
        
        for ministerio in self.data:
            ministerio_id = ministerio.get('id')
            ministerio_nombre = ministerio.get('nombre')
            
            for sector in ministerio.get('sectores', []):
                sector_id = sector.get('id')
                sector_nombre = sector.get('nombre')
                
                for categoria in sector.get('categorias', []):
                    categoria_id = categoria.get('id')
                    categoria_nombre = categoria.get('nombre')
                    
                    for sub_categoria in categoria.get('sub_categorias', []):
                        sub_categoria_id = sub_categoria.get('id')
                        sub_categoria_nombre = sub_categoria.get('nombre')
                        
                        for concepto in sub_categoria.get('conceptos', []):
                            tax_entry = {
                                'concepto_id': concepto.get('id'),
                                'concepto_nombre': concepto.get('nombre'),
                                'tasa_expedicion': concepto.get('tasa_expedicion', ''),
                                'tasa_renovacion': concepto.get('tasa_renovacion', ''),
                                'documentos_requeridos': concepto.get('documentos_requeridos', ''),
                                'procedimiento': concepto.get('procedimiento', ''),
                                'palabras_clave': concepto.get('palabras_clave', ''),
                                'ministerio_id': ministerio_id,
                                'ministerio_nombre': ministerio_nombre,
                                'sector_id': sector_id,
                                'sector_nombre': sector_nombre,
                                'categoria_id': categoria_id,
                                'categoria_nombre': categoria_nombre,
                                'sub_categoria_id': sub_categoria_id,
                                'sub_categoria_nombre': sub_categoria_nombre
                            }
                            flattened_data.append(tax_entry)
        
        return flattened_data
    
    def generate_general_questions(self) -> List[Dict[str, str]]:
        """
        Génère des questions générales sur les taxes et les ministères.
        """
        qa_pairs = []
        
        # Questions sur les ministères
        ministerios = set()
        for item in self.tax_data:
            ministerios.add((item['ministerio_id'], item['ministerio_nombre']))
        
        for ministerio_id, ministerio_nombre in ministerios:
            # Questions sur le ministère
            questions = [
                f"Quelles sont les taxes du {ministerio_nombre}?",
                f"Quels services sont fournis par le {ministerio_nombre}?",
                f"Quels types de taxes sont gérés par le {ministerio_nombre}?",
                f"Parle-moi des taxes du {ministerio_nombre}",
                f"Quelles sont les responsabilités fiscales du {ministerio_nombre}?"
            ]
            
            # Construire la réponse
            taxes_ministerio = [item for item in self.tax_data if item['ministerio_id'] == ministerio_id]
            if taxes_ministerio:
                taxes_list = ", ".join([f"{tax['concepto_nombre']}" for tax in taxes_ministerio[:5]])
                if len(taxes_ministerio) > 5:
                    taxes_list += f" et {len(taxes_ministerio) - 5} autres taxes"
                
                answer = f"Le {ministerio_nombre} gère plusieurs taxes et services, notamment: {taxes_list}. "
                answer += f"Ces taxes concernent {len(taxes_ministerio)} concepts différents dans le domaine."
                
                for question in questions:
                    qa_pairs.append({
                        "question": question,
                        "answer": answer
                    })
        
        # Questions générales sur toutes les taxes
        total_taxes = len(self.tax_data)
        general_questions = [
            "Combien de taxes existent au total?",
            "Quel est le nombre total de taxes fiscales?",
            "Combien de types de taxes y a-t-il dans le système?",
            "Peux-tu me dire le nombre total de taxes disponibles?"
        ]
        
        general_answer = f"Il existe actuellement {total_taxes} taxes différentes dans le système fiscal. Ces taxes sont réparties entre différents ministères et catégories."
        
        for question in general_questions:
            qa_pairs.append({
                "question": question,
                "answer": general_answer
            })
        
        return qa_pairs
    
    def generate_specific_tax_questions(self) -> List[Dict[str, str]]:
        """
        Génère des questions spécifiques pour chaque taxe.
        """
        qa_pairs = []
        
        for tax in self.tax_data:
            tax_name = tax['concepto_nombre']
            
            # Questions sur le coût
            cost_questions = [
                f"Combien coûte {tax_name}?",
                f"Quel est le prix de {tax_name}?",
                f"Quel est le montant à payer pour {tax_name}?",
                f"Combien dois-je payer pour {tax_name}?",
                f"Quel est le tarif pour {tax_name}?"
            ]
            
            # Construire la réponse sur le coût
            cost_answer = f"Pour {tax_name}, "
            has_expedicion = tax['tasa_expedicion'] and tax['tasa_expedicion'] != '0'
            has_renovacion = tax['tasa_renovacion'] and tax['tasa_renovacion'] != '0'
            
            if has_expedicion and has_renovacion:
                cost_answer += f"le coût d'expédition est de {tax['tasa_expedicion']} FCFA et le coût de renouvellement est de {tax['tasa_renovacion']} FCFA."
            elif has_expedicion:
                cost_answer += f"le coût est de {tax['tasa_expedicion']} FCFA."
            elif has_renovacion:
                cost_answer += f"le coût de renouvellement est de {tax['tasa_renovacion']} FCFA."
            else:
                cost_answer += "les informations de coût ne sont pas disponibles."
            
            for question in cost_questions:
                qa_pairs.append({
                    "question": question,
                    "answer": cost_answer
                })
            
            # Questions sur les documents requis
            if tax['documentos_requeridos']:
                doc_questions = [
                    f"Quels documents sont nécessaires pour {tax_name}?",
                    f"Quels documents dois-je fournir pour {tax_name}?",
                    f"Quels papiers faut-il pour {tax_name}?",
                    f"Quels sont les documents requis pour {tax_name}?",
                    f"Documentation nécessaire pour {tax_name}?"
                ]
                
                # Mettre en forme les documents requis
                docs = tax['documentos_requeridos'].split('\n')
                docs_list = ", ".join([doc.strip() for doc in docs if doc.strip()])
                
                doc_answer = f"Pour {tax_name}, vous devez fournir les documents suivants: {docs_list}."
                
                for question in doc_questions:
                    qa_pairs.append({
                        "question": question,
                        "answer": doc_answer
                    })
            
            # Questions sur la procédure
            if tax['procedimiento']:
                proc_questions = [
                    f"Quelle est la procédure pour {tax_name}?",
                    f"Comment obtenir {tax_name}?",
                    f"Quelles sont les étapes pour {tax_name}?",
                    f"Expliquez-moi la procédure pour {tax_name}",
                    f"Comment faire pour obtenir {tax_name}?"
                ]
                
                proc_answer = f"La procédure pour {tax_name} est la suivante: {tax['procedimiento']}"
                
                for question in proc_questions:
                    qa_pairs.append({
                        "question": question,
                        "answer": proc_answer
                    })
            
            # Questions sur le ministère responsable
            ministry_questions = [
                f"Quel ministère est responsable de {tax_name}?",
                f"Qui gère {tax_name}?",
                f"Quel organisme s'occupe de {tax_name}?",
                f"De quel ministère dépend {tax_name}?",
                f"À quel ministère appartient {tax_name}?"
            ]
            
            ministry_answer = f"{tax_name} est géré par le {tax['ministerio_nombre']}, dans le secteur de {tax['sector_nombre']}."
            
            for question in ministry_questions:
                qa_pairs.append({
                    "question": question,
                    "answer": ministry_answer
                })
        
        return qa_pairs
    
    def generate_search_questions(self) -> List[Dict[str, str]]:
        """
        Génère des questions de recherche basées sur des mots-clés ou des thèmes.
        """
        qa_pairs = []
        
        # Regrouper les taxes par mots-clés
        keyword_to_taxes = {}
        for tax in self.tax_data:
            keywords = tax.get('palabras_clave', '').split(',')
            keywords = [k.strip().lower() for k in keywords if k.strip()]
            
            for keyword in keywords:
                if keyword not in keyword_to_taxes:
                    keyword_to_taxes[keyword] = []
                keyword_to_taxes[keyword].append(tax)
        
        # Générer des questions par mot-clé (pour les mots-clés qui ont au moins 2 taxes)
        for keyword, taxes in keyword_to_taxes.items():
            if len(taxes) >= 2:
                search_questions = [
                    f"Quelles taxes concernent {keyword}?",
                    f"Y a-t-il des taxes liées à {keyword}?",
                    f"Parlez-moi des taxes sur {keyword}",
                    f"Quels sont les frais liés à {keyword}?",
                    f"Je cherche des informations sur les taxes de {keyword}"
                ]
                
                tax_names = [tax['concepto_nombre'] for tax in taxes[:5]]
                tax_list = ", ".join(tax_names)
                if len(taxes) > 5:
                    tax_list += f" et {len(taxes) - 5} autres"
                
                search_answer = f"Pour {keyword}, il existe {len(taxes)} taxes associées, notamment: {tax_list}."
                
                for question in search_questions:
                    qa_pairs.append({
                        "question": question,
                        "answer": search_answer
                    })
        
        return qa_pairs
    
    def generate_synthetic_questions(self) -> List[Dict[str, str]]:
        """
        Génère des questions plus naturelles et diverses, incluant des fautes 
        courantes, des reformulations et des questions partielles.
        """
        qa_pairs = []
        
        # Échantillon de taxes pour les questions synthétiques (pour éviter de générer trop de données)
        sample_taxes = random.sample(self.tax_data, min(50, len(self.tax_data)))
        
        for tax in sample_taxes:
            tax_name = tax['concepto_nombre']
            
            # Questions informelles ou mal orthographiées
            informal_questions = [
                f"c koi le prix de {tax_name}?",
                f"combien ça coute {tax_name}",
                f"je veu savoir le prix de {tax_name}",
                f"tarif {tax_name} svp",
                f"info sur {tax_name}"
            ]
            
            # Construire la réponse
            cost_answer = f"Pour {tax_name}, "
            has_expedicion = tax['tasa_expedicion'] and tax['tasa_expedicion'] != '0'
            has_renovacion = tax['tasa_renovacion'] and tax['tasa_renovacion'] != '0'
            
            if has_expedicion and has_renovacion:
                cost_answer += f"le coût d'expédition est de {tax['tasa_expedicion']} FCFA et le coût de renouvellement est de {tax['tasa_renovacion']} FCFA."
            elif has_expedicion:
                cost_answer += f"le coût est de {tax['tasa_expedicion']} FCFA."
            elif has_renovacion:
                cost_answer += f"le coût de renouvellement est de {tax['tasa_renovacion']} FCFA."
            else:
                cost_answer += "les informations de coût ne sont pas disponibles."
            
            ministry_info = f"\nCette taxe est gérée par le {tax['ministerio_nombre']}."
            
            for question in informal_questions:
                qa_pairs.append({
                    "question": question,
                    "answer": cost_answer + ministry_info
                })
        
        # Questions générales vagues ou ambiguës
        vague_questions = [
            "Comment obtenir un passeport?",
            "Combien coûte une carte d'identité?",
            "Documents pour visa",
            "Prix du permis",
            "Où payer les taxes?"
        ]
        
        vague_answers = [
            "Pour obtenir un passeport, vous devez vérifier les frais spécifiques et les documents requis. Pouvez-vous préciser quel type de passeport vous intéresse?",
            "Le coût d'une carte d'identité dépend du type et du ministère concerné. Pouvez-vous préciser quelle carte d'identité vous intéresse?",
            "Les documents requis pour un visa dépendent du type de visa. Pouvez-vous préciser quel visa vous intéresse?",
            "Le prix du permis varie selon le type. Pouvez-vous préciser quel permis vous intéresse?",
            "Les taxes peuvent être payées auprès du ministère concerné. Pour des informations plus précises, veuillez spécifier quelle taxe vous intéresse."
        ]
        
        for i, question in enumerate(vague_questions):
            qa_pairs.append({
                "question": question,
                "answer": vague_answers[i]
            })
        
        return qa_pairs
    
    def generate_conversation_starters(self) -> List[Dict[str, str]]:
        """
        Génère des questions d'ouverture de conversation et des questions de suivi.
        """
        conversation_starters = [
            {
                "question": "Bonjour",
                "answer": "Bonjour! Je suis l'assistant virtuel de TaxasGE. Je peux vous aider à trouver des informations sur les taxes fiscales en Guinée Équatoriale. Que souhaitez-vous savoir?"
            },
            {
                "question": "Salut",
                "answer": "Salut! Je suis là pour vous aider avec les informations sur les taxes fiscales. Comment puis-je vous aider aujourd'hui?"
            },
            {
                "question": "Comment ça va?",
                "answer": "Je vais bien, merci! Je suis prêt à vous aider avec les informations sur les taxes et services fiscaux. Quelle information recherchez-vous?"
            },
            {
                "question": "Qui es-tu?",
                "answer": "Je suis l'assistant virtuel de TaxasGE, conçu pour vous aider à trouver des informations sur les taxes fiscales en Guinée Équatoriale. Je peux vous renseigner sur les coûts, les documents requis et les procédures pour différentes taxes."
            },
            {
                "question": "Comment t'utiliser?",
                "answer": "C'est simple! Vous pouvez me poser des questions sur les taxes fiscales, comme 'Combien coûte un passeport?' ou 'Quels documents sont nécessaires pour un visa?'. Je ferai de mon mieux pour vous répondre avec les informations dont je dispose."
            },
            {
                "question": "Que peux-tu faire?",
                "answer": "Je peux vous fournir des informations sur les taxes fiscales en Guinée Équatoriale, notamment les coûts, les documents requis, les procédures, et les ministères responsables. N'hésitez pas à me poser des questions spécifiques sur la taxe qui vous intéresse."
            },
            {
                "question": "Merci",
                "answer": "Je vous en prie! N'hésitez pas à me poser d'autres questions si vous avez besoin de plus d'informations. Je suis là pour vous aider."
            },
            {
                "question": "Au revoir",
                "answer": "Au revoir! N'hésitez pas à revenir si vous avez d'autres questions sur les taxes fiscales. Bonne journée!"
            }
        ]
        
        return conversation_starters
        
    def translate_to_spanish(self, text):
        """
        Traduit un texte du français vers l'espagnol (simplification basique).
        Cette fonction applique des règles simples de traduction, 
        ce qui est suffisant pour notre cas d'utilisation.
        """
        # Dictionnaire de base français -> espagnol
        fr_to_es = {
            # Mots courants
            "bonjour": "hola",
            "salut": "hola",
            "merci": "gracias",
            "au revoir": "adiós",
            "comment": "cómo",
            "combien": "cuánto",
            "coûte": "cuesta",
            "prix": "precio",
            "documents": "documentos",
            "requis": "requeridos",
            "nécessaires": "necesarios",
            "procédure": "procedimiento",
            "obtenir": "obtener",
            "ministère": "ministerio",
            "responsable": "responsable",
            "taxe": "tasa",
            "taxes": "tasas",
            "fiscales": "fiscales",
            "s'il vous plaît": "por favor",
            "information": "información",
            "je voudrais": "quisiera",
            "besoin": "necesito",
            "savoir": "saber",
            "cherche": "busco",
            "quels": "cuáles",
            "quelles": "cuáles",
            "est": "es",
            "sont": "son",
            "pour": "para",
            "de": "de",
            "du": "del",
            "la": "la",
            "le": "el",
            "les": "los",
            "un": "un",
            "une": "una",
            "des": "de los",
            "et": "y",
            "ou": "o",
            "qui": "qué",
            "quel": "cuál",
            "quelle": "cuál",
            
            # Termes spécifiques aux taxes
            "passeport": "pasaporte",
            "visa": "visado",
            "carte d'identité": "documento de identidad",
            "permis": "permiso",
            "expédition": "expedición",
            "renouvellement": "renovación",
            "montant": "cantidad",
            "paiement": "pago",
            "payer": "pagar",
        }
        
        # Traitement simple: remplacer les mots
        words = text.lower().split()
        translated_words = []
        
        for word in words:
            # Nettoyage pour la comparaison
            clean_word = word.strip(".,;:!?")
            
            # Chercher la traduction
            if clean_word in fr_to_es:
                # Conserver la ponctuation si présente
                if word != clean_word:
                    punctuation = word[len(clean_word):]
                    translated_words.append(fr_to_es[clean_word] + punctuation)
                else:
                    translated_words.append(fr_to_es[clean_word])
            else:
                translated_words.append(word)
        
        # Reconstruction avec la première lettre en majuscule
        translated_text = " ".join(translated_words)
        if translated_text:
            translated_text = translated_text[0].upper() + translated_text[1:]
        
        return translated_text

    def translate_to_english(self, text):
        """
        Traduit un texte du français vers l'anglais (simplification basique).
        Cette fonction applique des règles simples de traduction,
        ce qui est suffisant pour notre cas d'utilisation.
        """
        # Dictionnaire de base français -> anglais
        fr_to_en = {
            # Mots courants
            "bonjour": "hello",
            "salut": "hi",
            "merci": "thank you",
            "au revoir": "goodbye",
            "comment": "how",
            "combien": "how much",
            "coûte": "cost",
            "prix": "price",
            "documents": "documents",
            "requis": "required",
            "nécessaires": "necessary",
            "procédure": "procedure",
            "obtenir": "obtain",
            "ministère": "ministry",
            "responsable": "responsible",
            "taxe": "tax",
            "taxes": "taxes",
            "fiscales": "fiscal",
            "s'il vous plaît": "please",
            "information": "information",
            "je voudrais": "I would like",
            "besoin": "need",
            "savoir": "know",
            "cherche": "looking for",
            "quels": "which",
            "quelles": "which",
            "est": "is",
            "sont": "are",
            "pour": "for",
            "de": "of",
            "du": "of the",
            "la": "the",
            "le": "the",
            "les": "the",
            "un": "a",
            "une": "a",
            "des": "of the",
            "et": "and",
            "ou": "or",
            "qui": "who",
            "quel": "which",
            "quelle": "which",
            
            # Termes spécifiques aux taxes
            "passeport": "passport",
            "visa": "visa",
            "carte d'identité": "identity card",
            "permis": "permit",
            "expédition": "issuance",
            "renouvellement": "renewal",
            "montant": "amount",
            "paiement": "payment",
            "payer": "pay",
        }
        
        # Traitement simple: remplacer les mots
        words = text.lower().split()
        translated_words = []
        
        for word in words:
            # Nettoyage pour la comparaison
            clean_word = word.strip(".,;:!?")
            
            # Chercher la traduction
            if clean_word in fr_to_en:
                # Conserver la ponctuation si présente
                if word != clean_word:
                    punctuation = word[len(clean_word):]
                    translated_words.append(fr_to_en[clean_word] + punctuation)
                else:
                    translated_words.append(fr_to_en[clean_word])
            else:
                translated_words.append(word)
        
        # Reconstruction avec la première lettre en majuscule
        translated_text = " ".join(translated_words)
        if translated_text:
            translated_text = translated_text[0].upper() + translated_text[1:]
        
        return translated_text

    def generate_multilingual_corpus(self, output_file, augmentation_factor=1, include_spanish=True, include_english=True):
        """
        Génère le corpus complet multilingue et le sauvegarde dans un fichier JSON.
        
        Args:
            output_file: Chemin du fichier de sortie
            augmentation_factor: Facteur de multiplication pour l'augmentation des données
            include_spanish: Inclure les traductions en espagnol
            include_english: Inclure les traductions en anglais
        """
        # Générer différents types de questions-réponses
        general_qa = self.generate_general_questions()
        specific_qa = self.generate_specific_tax_questions()
        search_qa = self.generate_search_questions()
        synthetic_qa = self.generate_synthetic_questions()
        conversation_qa = self.generate_conversation_starters()
        
        # Combiner tous les types de QA
        all_qa = general_qa + specific_qa + search_qa + synthetic_qa + conversation_qa
        
        # Augmentation des données: légères variations des questions (si facteur > 1)
        augmented_qa = []
        for _ in range(augmentation_factor - 1):
            for qa in all_qa:
                if 'question' in qa and 'answer' in qa:
                    # Créer une légère variation de la question
                    question = qa['question']
                    words = question.split()
                    
                    # Aléatoirement ajouter/supprimer/modifier quelques mots
                    if len(words) > 3 and random.random() > 0.5:
                        # Supprimer un mot aléatoire
                        idx = random.randint(0, len(words) - 1)
                        words.pop(idx)
                    
                    # Ajouter des préfixes aléatoires
                    prefixes = ["Dites-moi ", "Je voudrais savoir ", "Pourriez-vous me dire ", "J'aimerais connaître "]
                    if random.random() > 0.7:
                        words = [random.choice(prefixes)] + words
                    
                    # Ajouter des suffixes aléatoires
                    suffixes = [" s'il vous plaît", " merci", " si possible", " rapidement"]
                    if random.random() > 0.7:
                        words.append(random.choice(suffixes))
                    
                    new_question = " ".join(words)
                    augmented_qa.append({
                        "question": new_question,
                        "answer": qa['answer']
                    })
        
        # Ajouter les questions augmentées
        all_qa.extend(augmented_qa)
        
        # Ajouter les traductions en espagnol
        if include_spanish:
            spanish_qa = []
            for qa in all_qa:
                if 'question' in qa and 'answer' in qa:
                    spanish_qa.append({
                        "question": self.translate_to_spanish(qa['question']),
                        "answer": self.translate_to_spanish(qa['answer']),
                        "language": "es"
                    })
            all_qa.extend(spanish_qa)
            print(f"Ajout de {len(spanish_qa)} paires question-réponse en espagnol")
        
        # Ajouter les traductions en anglais
        if include_english:
            english_qa = []
            for qa in all_qa:
                if 'question' in qa and 'answer' in qa and not qa.get('language'):  # Ne traduire que les originaux français
                    english_qa.append({
                        "question": self.translate_to_english(qa['question']),
                        "answer": self.translate_to_english(qa['answer']),
                        "language": "en"
                    })
            all_qa.extend(english_qa)
            print(f"Ajout de {len(english_qa)} paires question-réponse en anglais")
        
        # Marquer les originaux comme français
        for qa in all_qa:
            if 'question' in qa and 'answer' in qa and not qa.get('language'):
                qa['language'] = 'fr'
        
        # Mélanger les QA pour une meilleure distribution lors de l'entraînement
        random.shuffle(all_qa)
        
        # Créer le corpus final avec des métadonnées
        corpus = {
            "metadata": {
                "version": "1.0",
                "created_at": "2025-04-14",
                "size": len(all_qa),
                "languages": ["fr"] + (["es"] if include_spanish else []) + (["en"] if include_english else []),
                "description": "Corpus d'entraînement multilingue pour le modèle NLP de l'application TaxasGE"
            },
            "data": all_qa
        }
        
        # Sauvegarder le corpus
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(corpus, f, ensure_ascii=False, indent=2)
        
        print(f"Corpus multilingue généré avec succès: {len(all_qa)} paires question-réponse sauvegardées dans {output_file}")

def main():
    # Parser d'arguments en ligne de commande
    parser = argparse.ArgumentParser(description="Génère un corpus d'entraînement pour le modèle NLP de TaxasGE")
    parser.add_argument("--input", "-i", default="assets/data/taxes.json", help="Chemin vers le fichier JSON d'entrée")
    parser.add_argument("--output", "-o", default="assets/ml/training_corpus.json", help="Chemin vers le fichier JSON de sortie")
    parser.add_argument("--augmentation", "-a", type=int, default=2, help="Facteur d'augmentation des données")
    parser.add_argument("--spanish", "-s", action="store_true", help="Inclure les traductions en espagnol")
    parser.add_argument("--english", "-e", action="store_true", help="Inclure les traductions en anglais")
    parser.add_argument("--all-languages", "-l", action="store_true", help="Inclure toutes les langues (espagnol et anglais)")
    
    args = parser.parse_args()
    
    # Vérifier si le fichier d'entrée existe
    if not os.path.exists(args.input):
        print(f"Erreur: Le fichier d'entrée '{args.input}' n'existe pas.")
        return
    
    # Déterminer les langues à inclure
    include_spanish = args.spanish or args.all_languages
    include_english = args.english or args.all_languages
    
    # Si aucune langue n'est spécifiée, utiliser toutes les langues par défaut
    if not include_spanish and not include_english and not args.all_languages:
        include_spanish = True
        include_english = True
    
    # Générer le corpus
    generator = CorpusGenerator(args.input)
    generator.generate_multilingual_corpus(args.output, args.augmentation, include_spanish, include_english)