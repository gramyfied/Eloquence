#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de diagnostic pour les erreurs de l'agent Eloquence
"""

import os
import sys
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

print("[DIAGNOSTIC] Analyse des problemes de l'agent Eloquence")
print("="*60)

# 1. Vérifier les clés API
print("\n[1] VERIFICATION DES CLES API:")
print("-"*40)

mistral_key = os.getenv("MISTRAL_API_KEY", "")
openai_key = os.getenv("OPENAI_API_KEY", "")

print(f"MISTRAL_API_KEY: {'[OK]' if mistral_key else '[MANQUANT]'} - {len(mistral_key)} caracteres")
print(f"OPENAI_API_KEY: {'[OK]' if openai_key else '[MANQUANT]'} - {len(openai_key)} caracteres")

# 2. Vérifier les URLs des services
print("\n[2] VERIFICATION DES URLS:")
print("-"*40)

mistral_url = os.getenv("MISTRAL_BASE_URL", "https://api.mistral.ai/v1/chat/completions")
print(f"MISTRAL_BASE_URL: {mistral_url}")

# 3. Analyser les problèmes identifiés
print("\n[3] PROBLEMES IDENTIFIES:")
print("-"*40)

problems = []

# Problème 1: Messages mal formatés pour Mistral
print("\n[PROBLEME 1] Format des messages pour Mistral API:")
print("- Plusieurs messages 'assistant' consecutifs sans messages 'user'")
print("- Presence de contenu mathematique etrange")
print("- Messages vides envoyes")
print("SOLUTION: Nettoyer et valider le contexte de chat avant envoi")

# Problème 2: TTS avec texte vide
print("\n[PROBLEME 2] TTS avec texte vide:")
print("- Le TTS recoit un texte vide a synthetiser")
print("- Cela cause une erreur 400 Bad Request")
print("SOLUTION: Verifier que le texte n'est pas vide avant d'appeler TTS")

# Problème 3: Gestion du contexte de chat
print("\n[PROBLEME 3] Gestion du contexte de chat:")
print("- Messages avec contenu vide pour le role 'user'")
print("- Accumulation de messages d'erreur")
print("SOLUTION: Filtrer et nettoyer le contexte avant chaque requete")

# 4. Recommandations
print("\n[4] RECOMMANDATIONS:")
print("-"*40)
print("1. Ajouter validation du texte avant TTS")
print("2. Nettoyer le contexte de chat pour eviter les messages invalides")
print("3. Implementer un mecanisme de reset du contexte en cas d'erreur")
print("4. Ajouter des logs plus detailles pour le debug")
print("5. Verifier que les cles API sont correctement configurees")

# 5. Actions correctives
print("\n[5] ACTIONS CORRECTIVES PROPOSEES:")
print("-"*40)
print("1. Creer un fichier de correction pour l'agent")
print("2. Ajouter validation des entrees")
print("3. Implementer un contexte de chat plus robuste")
print("4. Tester avec des cles API valides")

print("\n" + "="*60)
print("[OK] Diagnostic termine")