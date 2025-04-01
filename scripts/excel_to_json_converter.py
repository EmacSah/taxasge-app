#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Excel to JSON Converter for TaxasGE Project
-------------------------------------------
Ce script convertit les données du fichier TASAS.xlsx en format JSON structuré
selon la hiérarchie spécifiée dans le cahier des charges du projet TaxasGE.

Utilisation:
    python excel_to_json_converter.py [--input EXCEL_FILE] [--output JSON_FILE]

Arguments:
    --input EXCEL_FILE   Chemin vers le fichier Excel d'entrée (défaut: TASAS.xlsx)
    --output JSON_FILE   Chemin vers le fichier JSON de sortie (défaut: ../assets/data/taxes.json)
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, List, Any, Tuple, Optional, Union

import pandas as pd
import numpy as np

# Configuration des identifiants
ID_PREFIXES = {
    "ministere": "min_",
    "secteur": "sec_",
    "service": "srv_",
    "taxe": "tax_",
}

# Mots-clés pour aider le chatbot
KEYWORDS_MAPPING = {
    "passeport": ["passeport", "voyage", "document", "identité"],
    "visa": ["visa", "entrée", "séjour", "frontiére"],
    "carte": ["carte", "identité", "identification"],
    "certificat": ["certificat", "document", "attestation"],
    "autorisation": ["autorisation", "permission", "accord"],
    "licence": ["licence", "permis", "autorisation"],
    "matricul": ["immatriculation", "enregistrement", "numéro"],
    "taxe": ["taxe", "impôt", "frais", "coût", "paiement"],
    "document": ["document", "papier", "formulaire"],
    "renouvellement": ["renouvellement", "prolongation", "extension"],
    "exportation": ["exportation", "export", "expédition", "international"],
    "importation": ["importation", "import", "introduction", "international"],
}

def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Convertit un fichier Excel en JSON selon le format TaxasGE")
    parser.add_argument("--input", default="TASAS.xlsx", help="Fichier Excel d'entrée")
    parser.add_argument("--output", default="../assets/data/taxes.json", help="Fichier JSON de sortie")
    return parser.parse_args()

def clean_text(text: Any) -> str:
    """Nettoie et normalise les textes."""
    if pd.isna(text) or text is None:
        return ""
    
    # Convertir en string si ce n'est pas déjà le cas
    text = str(text).strip()
    
    # Supprimer les espaces multiples
    text = re.sub(r'\s+', ' ', text)
    
    # Supprimer les caractères de contrôle et autres caractères problématiques
    text = re.sub(r'[\x00-\x1F\x7F]', '', text)
    
    return text

def is_numeric(value: Any) -> bool:
    """Vérifie si une valeur est numérique."""
    if pd.isna(value) or value is None:
        return False
    
    if isinstance(value, (int, float)):
        return True
    
    if isinstance(value, str):
        # Supprimer les espaces, points et virgules
        clean_value = value.strip().replace('.', '').replace(',', '').replace(' ', '')
        return clean_value.isdigit()
    
    return False

def parse_amount(value: Any) -> Optional[int]:
    """Convertit une valeur en montant (entier)."""
    if not is_numeric(value):
        return None
    
    if pd.isna(value) or value is None:
        return None
    
    try:
        if isinstance(value, (int, float)):
            return int(value)
        
        # Nettoyer la chaîne: supprimer les espaces, points et remplacer les virgules par des points
        value_str = str(value).strip().replace(' ', '').replace('.', '').replace(',', '.')
        
        # Convertir en float puis en int
        return int(float(value_str))
    except (ValueError, TypeError):
        return None

def generate_keywords(tax_name: str) -> List[str]:
    """Génère des mots-clés pertinents pour une taxe basée sur son nom."""
    tax_name_lower = tax_name.lower()
    keywords = []
    
    # Ajouter des mots-clés basés sur les correspondances
    for key, related_words in KEYWORDS_MAPPING.items():
        if key in tax_name_lower:
            keywords.extend(related_words)
    
    # Ajouter les mots significatifs du nom lui-même (plus de 3 caractères)
    words = [word for word in re.split(r'\W+', tax_name_lower) if len(word) > 3]
    keywords.extend(words)
    
    # Éliminer les doublons et trier
    keywords = sorted(list(set(keywords)))
    
    return keywords[:10]  # Limiter à 10 mots-clés

def create_tax_id(ministry_id: str, sector_id: str, service_id: str, tax_index: int) -> str:
    """Crée un identifiant unique pour une taxe."""
    return f"{ID_PREFIXES['taxe']}{ministry_id[4:]}_{sector_id[4:]}_{service_id[4:]}_{str(tax_index+1).zfill(3)}"

def format_procedure(name: str) -> str:
    """Génère une procédure de base pour une taxe."""
    return f"Pour obtenir {name}, veuillez vous présenter au bureau compétent avec les documents requis et payer le montant de la taxe."

def read_excel_data(file_path: str) -> pd.DataFrame:
    """Lit les données du fichier Excel."""
    try:
        # Vérifier que le fichier existe
        if not os.path.exists(file_path):
            print(f"Erreur: Le fichier {file_path} n'existe pas.")
            sys.exit(1)
            
        # Lire le fichier Excel
        df = pd.read_excel(file_path, sheet_name=0)
        
        # Vérifier que les données sont présentes
        if df.empty:
            print("Erreur: Le fichier Excel ne contient aucune donnée.")
            sys.exit(1)
            
        # Nettoyer les noms de colonnes
        df.columns = [str(col).strip() for col in df.columns]
        
        return df
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier Excel: {e}")
        sys.exit(1)

def process_excel_data(df: pd.DataFrame) -> Dict[str, Any]:
    """Traite les données Excel et les convertit en structure JSON."""
    ministeres_data = []
    current_ministere = None
    current_secteur = None
    current_service = None
    
    ministry_counter = 1
    sector_counter = 1
    service_counter = 1
    
    grouped_taxes = {}
    
    # Première passe: identifier les ministères, secteurs et services
    for index, row in df.iterrows():
        # Extraire les valeurs pertinentes de la ligne
        ministere_val = clean_text(row.get('MINISTERE', ""))
        secteur_val = clean_text(row.get('SECTEUR', ""))
        service_val = clean_text(row.get('SERVICE', ""))
        concept_val = clean_text(row.get('CONCEPT', ""))
        expedition_val = row.get('TASA DE EXPEDICIÓN', None)
        renovation_val = row.get('TASA DE RENOVACIÓN', None)
        
        # Ignorer les lignes sans données utiles
        if not any([ministere_val, secteur_val, service_val, concept_val]):
            continue
        
        # Traiter le ministère
        if ministere_val and ministere_val != current_ministere:
            current_ministere = ministere_val
            ministry_id = f"{ID_PREFIXES['ministere']}{str(ministry_counter).zfill(3)}"
            ministry_counter += 1
            ministeres_data.append({
                "id": ministry_id,
                "nom": current_ministere,
                "secteurs": []
            })
            sector_counter = 1
        
        # S'assurer qu'un ministère est défini
        if not current_ministere or not ministeres_data:
            continue
        
        # Traiter le secteur
        if secteur_val and secteur_val != current_secteur:
            current_secteur = secteur_val
            sector_id = f"{ID_PREFIXES['secteur']}{str(ministry_counter-1).zfill(3)}_{str(sector_counter).zfill(3)}"
            sector_counter += 1
            ministeres_data[-1]["secteurs"].append({
                "id": sector_id,
                "nom": current_secteur,
                "services": []
            })
            service_counter = 1
        
        # S'assurer qu'un secteur est défini
        if not current_secteur or not ministeres_data[-1]["secteurs"]:
            continue
        
        # Traiter le service
        if service_val and service_val != current_service:
            current_service = service_val
            service_id = f"{ID_PREFIXES['service']}{str(ministry_counter-1).zfill(3)}_{str(sector_counter-1).zfill(3)}_{str(service_counter).zfill(3)}"
            service_counter += 1
            ministeres_data[-1]["secteurs"][-1]["services"].append({
                "id": service_id,
                "nom": current_service,
                "taxes": []
            })
        
        # S'assurer qu'un service est défini
        if not current_service or not ministeres_data[-1]["secteurs"][-1]["services"]:
            continue
        
        # Traiter la taxe
        if concept_val:
            # Créer un ID unique pour cette taxe
            ministry_id = ministeres_data[-1]["id"]
            sector_id = ministeres_data[-1]["secteurs"][-1]["id"]
            service_id = ministeres_data[-1]["secteurs"][-1]["services"][-1]["id"]
            
            # Calculer les montants
            montant_expedition = parse_amount(expedition_val)
            montant_renouvellement = parse_amount(renovation_val)
            
            # Ajouter cette taxe au groupe pour le service actuel
            if service_id not in grouped_taxes:
                grouped_taxes[service_id] = []
            
            grouped_taxes[service_id].append({
                "nom": concept_val,
                "montant_expedition": montant_expedition,
                "montant_renouvellement": montant_renouvellement,
                "documents_requis": ["Formulaire de demande", "Pièce d'identité"],
                "procedure": format_procedure(concept_val),
                "mots_cles": generate_keywords(concept_val)
            })
    
    # Deuxième passe: ajouter les taxes groupées aux services
    for ministere in ministeres_data:
        for secteur in ministere["secteurs"]:
            for service in secteur["services"]:
                service_id = service["id"]
                if service_id in grouped_taxes:
                    for i, tax in enumerate(grouped_taxes[service_id]):
                        tax_id = create_tax_id(ministere["id"], secteur["id"], service_id, i)
                        service["taxes"].append({
                            "id": tax_id,
                            **tax
                        })
    
    # Nettoyer les structures vides
    # Supprimer les services sans taxes
    for ministere in ministeres_data:
        for secteur in ministere["secteurs"]:
            secteur["services"] = [service for service in secteur["services"] if service["taxes"]]
    
    # Supprimer les secteurs sans services
    for ministere in ministeres_data:
        ministere["secteurs"] = [secteur for secteur in ministere["secteurs"] if secteur["services"]]
    
    # Supprimer les ministères sans secteurs
    ministeres_data = [ministere for ministere in ministeres_data if ministere["secteurs"]]
    
    return {"ministeres": ministeres_data}

def save_json_data(data: Dict[str, Any], output_path: str) -> None:
    """Sauvegarde les données JSON dans un fichier."""
    try:
        # Créer le répertoire de destination s'il n'existe pas
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Écrire le fichier JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"Données JSON sauvegardées avec succès dans {output_path}")
    except Exception as e:
        print(f"Erreur lors de la sauvegarde du fichier JSON: {e}")
        sys.exit(1)

def main():
    """Fonction principale du script."""
    args = parse_arguments()
    
    print(f"Lecture du fichier Excel: {args.input}")
    df = read_excel_data(args.input)
    
    print("Traitement des données...")
    json_data = process_excel_data(df)
    
    print(f"Sauvegarde des données JSON: {args.output}")
    save_json_data(json_data, args.output)
    
    # Afficher des statistiques
    ministeres_count = len(json_data["ministeres"])
    secteurs_count = sum(len(ministere["secteurs"]) for ministere in json_data["ministeres"])
    services_count = sum(
        sum(len(secteur["services"]) for secteur in ministere["secteurs"])
        for ministere in json_data["ministeres"]
    )
    taxes_count = sum(
        sum(
            sum(len(service["taxes"]) for service in secteur["services"])
            for secteur in ministere["secteurs"]
        )
        for ministere in json_data["ministeres"]
    )
    
    print("\nStatistiques de conversion:")
    print(f"- Ministères: {ministeres_count}")
    print(f"- Secteurs: {secteurs_count}")
    print(f"- Services: {services_count}")
    print(f"- Taxes: {taxes_count}")
    
    print("\nConversion terminée avec succès!")

if __name__ == "__main__":
    main()
