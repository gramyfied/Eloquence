#!/usr/bin/env python3
"""
Script de diagnostic et correction de la clé OpenAI
"""

import os
import sys
import requests
from dotenv import load_dotenv

def main():
    print("🔧 DIAGNOSTIC ET CORRECTION CLÉ OPENAI")
    print("=" * 50)
    
    # Charger les variables d'environnement
    load_dotenv()
    
    # Récupérer la clé OpenAI
    openai_key = os.getenv('OPENAI_API_KEY')
    
    if not openai_key:
        print("❌ Aucune clé OpenAI trouvée dans les variables d'environnement")
        return False
    
    print(f"🔑 Clé OpenAI trouvée: {openai_key[:20]}...{openai_key[-4:]}")
    print(f"📏 Longueur de la clé: {len(openai_key)} caractères")
    
    # Vérifier le format de la clé
    if not openai_key.startswith('sk-'):
        print("❌ Format de clé invalide (doit commencer par 'sk-')")
        return False
    
    print("✅ Format de clé valide")
    
    # Test de connectivité avec l'API OpenAI
    print("\n🧪 Test de connectivité avec l'API OpenAI...")
    
    headers = {
        'Authorization': f'Bearer {openai_key}',
        'Content-Type': 'application/json'
    }
    
    # Test simple avec l'endpoint models
    try:
        response = requests.get(
            'https://api.openai.com/v1/models',
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ Clé OpenAI valide et fonctionnelle")
            models = response.json()
            print(f"📊 {len(models.get('data', []))} modèles disponibles")
            return True
        elif response.status_code == 401:
            print("❌ Clé OpenAI invalide (401 Unauthorized)")
            print(f"🔍 Réponse: {response.text}")
            return False
        else:
            print(f"⚠️ Réponse inattendue: {response.status_code}")
            print(f"🔍 Réponse: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
        return False

def fix_env_files():
    """Corrige les fichiers .env avec une nouvelle clé"""
    print("\n🔧 CORRECTION DES FICHIERS .ENV")
    print("=" * 40)
    
    # Demander une nouvelle clé à l'utilisateur
    print("Pour corriger le problème, veuillez:")
    print("1. Aller sur https://platform.openai.com/account/api-keys")
    print("2. Créer une nouvelle clé API")
    print("3. Copier la clé complète")
    
    new_key = input("\n🔑 Entrez votre nouvelle clé OpenAI: ").strip()
    
    if not new_key or not new_key.startswith('sk-'):
        print("❌ Clé invalide")
        return False
    
    # Mettre à jour le fichier .env principal
    env_files = ['.env', 'services/livekit-agent/.env']
    
    for env_file in env_files:
        if os.path.exists(env_file):
            print(f"📝 Mise à jour de {env_file}...")
            
            # Lire le contenu
            with open(env_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Remplacer la clé OpenAI
            lines = content.split('\n')
            updated_lines = []
            
            for line in lines:
                if line.startswith('OPENAI_API_KEY='):
                    updated_lines.append(f'OPENAI_API_KEY={new_key}')
                    print(f"✅ Clé mise à jour dans {env_file}")
                else:
                    updated_lines.append(line)
            
            # Écrire le nouveau contenu
            with open(env_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(updated_lines))
        else:
            print(f"⚠️ Fichier {env_file} non trouvé")
    
    return True

if __name__ == "__main__":
    success = main()
    
    if not success:
        print("\n🔧 Voulez-vous corriger la clé OpenAI? (y/n)")
        if input().lower().startswith('y'):
            fix_env_files()
            print("\n🔄 Relancez le script pour vérifier la correction")
        else:
            print("\n💡 Pour corriger manuellement:")
            print("1. Obtenez une nouvelle clé sur https://platform.openai.com/account/api-keys")
            print("2. Mettez à jour OPENAI_API_KEY dans .env et services/livekit-agent/.env")
            print("3. Redémarrez les services Docker")
    else:
        print("\n🎉 La clé OpenAI fonctionne correctement!")
        print("Le problème vient probablement d'ailleurs dans la configuration.")
