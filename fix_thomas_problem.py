#!/usr/bin/env python3
"""
Script de correction définitive du problème Thomas
Nettoie les fichiers compilés et force la recompilation
"""

import os
import shutil
import subprocess
import sys

def clean_compiled_files():
    """Nettoie tous les fichiers Python compilés"""
    print("🧹 Nettoyage des fichiers compilés...")
    
    # Supprimer tous les .pyc
    result = subprocess.run([
        'find', '.', '-name', '*.pyc', '-delete'
    ], capture_output=True, text=True)
    
    # Supprimer tous les __pycache__
    result = subprocess.run([
        'find', '.', '-name', '__pycache__', '-type', 'd', '-exec', 'rm', '-rf', '{}', '+'
    ], capture_output=True, text=True)
    
    print("✅ Fichiers compilés supprimés")

def verify_code_correctness():
    """Vérifie que le code source est correct"""
    print("🔍 Vérification du code source...")
    
    # Vérifier unified_entrypoint.py
    with open('services/livekit-agent/unified_entrypoint.py', 'r') as f:
        content = f.read()
        
    if 'ctx.exercise_type = exercise_type' in content:
        print("✅ unified_entrypoint.py : Transmission exercise_type OK")
    else:
        print("❌ unified_entrypoint.py : Transmission exercise_type MANQUANTE")
        return False
    
    # Vérifier multi_agent_main.py
    with open('services/livekit-agent/multi_agent_main.py', 'r') as f:
        content = f.read()
        
    if 'exercise_type = getattr(ctx, \'exercise_type\', None)' in content:
        print("✅ multi_agent_main.py : Récupération exercise_type OK")
    else:
        print("❌ multi_agent_main.py : Récupération exercise_type MANQUANTE")
        return False
    
    if 'if exercise_type == \'studio_debate_tv\':' in content:
        print("✅ multi_agent_main.py : Routage studio_debate_tv OK")
    else:
        print("❌ multi_agent_main.py : Routage studio_debate_tv MANQUANT")
        return False
    
    return True

def create_restart_script():
    """Crée un script de redémarrage propre"""
    restart_script = '''#!/bin/bash
# Script de redémarrage propre pour Eloquence

echo "🔄 Redémarrage propre d'Eloquence..."

# Arrêt des services
docker-compose down

# Nettoyage des fichiers compilés
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Redémarrage des services
docker-compose up -d

echo "✅ Redémarrage terminé"
echo "🎯 Le problème Thomas devrait être résolu"
'''
    
    with open('restart_clean.sh', 'w') as f:
        f.write(restart_script)
    
    os.chmod('restart_clean.sh', 0o755)
    print("✅ Script de redémarrage créé : restart_clean.sh")

def main():
    """Fonction principale"""
    print("🎯 CORRECTION DÉFINITIVE DU PROBLÈME THOMAS")
    print("="*50)
    
    # 1. Nettoyer les fichiers compilés
    clean_compiled_files()
    
    # 2. Vérifier le code source
    if not verify_code_correctness():
        print("❌ Code source incorrect - Correction nécessaire")
        return False
    
    # 3. Créer le script de redémarrage
    create_restart_script()
    
    print("\n🎉 CORRECTION TERMINÉE !")
    print("✅ Fichiers compilés nettoyés")
    print("✅ Code source vérifié")
    print("✅ Script de redémarrage créé")
    print("\n🚀 PROCHAINES ÉTAPES :")
    print("1. Exécuter : ./restart_clean.sh")
    print("2. Tester avec studio_debatPlateau")
    print("3. Vérifier que Michel/Sarah/Marcus répondent (pas Thomas)")
    
    return True

if __name__ == "__main__":
    os.chdir('/home/ubuntu/Eloquence')
    success = main()
    sys.exit(0 if success else 1)

