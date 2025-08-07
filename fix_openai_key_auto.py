#!/usr/bin/env python3
# Script de correction automatique de la cle OpenAI

import os
import re

def corriger_cle_openai():
    print("Correction de la cle OpenAI...")
    
    # 1. Verifier la cle actuelle
    cle_actuelle = os.getenv('OPENAI_API_KEY', '')
    print(f"Cle actuelle: {cle_actuelle[:20]}..." if cle_actuelle else "Aucune cle trouvee")
    
    # 2. Demander nouvelle cle
    nouvelle_cle = input("Entrez votre nouvelle cle OpenAI: ").strip()
    
    # 3. Valider le format
    if not nouvelle_cle.startswith('sk-'):
        print("Format invalide - doit commencer par 'sk-'")
        return False
    
    # 4. Mettre a jour les fichiers .env
    fichiers_env = ['.env', 'services/livekit-agent/.env']
    
    for fichier in fichiers_env:
        if os.path.exists(fichier):
            with open(fichier, 'r') as f:
                contenu = f.read()
            
            # Remplacer ou ajouter la cle
            if 'OPENAI_API_KEY=' in contenu:
                contenu = re.sub(r'OPENAI_API_KEY=.*', f'OPENAI_API_KEY={nouvelle_cle}', contenu)
            else:
                contenu += f'\nOPENAI_API_KEY={nouvelle_cle}\n'
            
            with open(fichier, 'w') as f:
                f.write(contenu)
            
            print(f"Fichier {fichier} mis a jour")
    
    print("Cle OpenAI corrigee - Redemarrez les services")
    return True

if __name__ == "__main__":
    corriger_cle_openai()
