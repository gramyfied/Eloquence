#!/usr/bin/env python3
"""
Script de mise à jour rapide pour la clé OpenAI
"""

import os
import sys

def update_openai_key():
    """Met à jour la clé OpenAI dans tous les fichiers de configuration"""
    
    print("🔧 MISE À JOUR CLÉ OPENAI ELOQUENCE")
    print("="*45)
    
    # Demander la nouvelle clé
    print("\nPour obtenir une nouvelle clé OpenAI:")
    print("1. Allez sur https://platform.openai.com/account/api-keys")
    print("2. Créez une nouvelle clé secrète")
    print("3. Copiez la clé complète")
    print()
    
    new_key = input("Entrez votre nouvelle clé OpenAI: ").strip()
    
    if not new_key:
        print("❌ Aucune clé fournie. Annulation.")
        return False
    
    if not new_key.startswith('sk-'):
        print("❌ Format de clé invalide. Les clés OpenAI commencent par 'sk-'")
        return False
    
    # Fichiers à mettre à jour
    files_to_update = [
        '.env',
        'services/livekit-agent/.env'
    ]
    
    updated_files = 0
    
    for file_path in files_to_update:
        if os.path.exists(file_path):
            try:
                # Lire le fichier
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Remplacer la clé OpenAI
                lines = content.split('\n')
                updated_lines = []
                key_updated = False
                
                for line in lines:
                    if line.startswith('OPENAI_API_KEY='):
                        updated_lines.append(f'OPENAI_API_KEY={new_key}')
                        key_updated = True
                        print(f"✅ Clé mise à jour dans {file_path}")
                    else:
                        updated_lines.append(line)
                
                if key_updated:
                    # Écrire le fichier mis à jour
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write('\n'.join(updated_lines))
                    updated_files += 1
                else:
                    print(f"⚠️ Ligne OPENAI_API_KEY non trouvée dans {file_path}")
                    
            except Exception as e:
                print(f"❌ Erreur lors de la mise à jour de {file_path}: {e}")
        else:
            print(f"⚠️ Fichier non trouvé: {file_path}")
    
    if updated_files > 0:
        print(f"\n🎉 {updated_files} fichier(s) mis à jour avec succès!")
        print("\n📋 PROCHAINES ÉTAPES:")
        print("1. Redémarrez les services Docker:")
        print("   docker-compose down && docker-compose up -d")
        print("2. Vérifiez les logs de l'agent LiveKit:")
        print("   docker-compose logs -f livekit-agent")
        print("3. Testez une conversation pour confirmer que l'IA répond")
        return True
    else:
        print("\n❌ Aucun fichier n'a pu être mis à jour.")
        return False

if __name__ == "__main__":
    update_openai_key()
