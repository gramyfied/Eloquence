#!/usr/bin/env python3
"""
Moniteur de détection de débat plateau en temps réel
"""

import subprocess
import sys
import time
import re

def monitor_debat_detection():
    """Surveille les logs de détection de débat en temps réel"""
    
    print("🎯 MONITEUR DE DÉTECTION DÉBAT PLATEAU")
    print("=" * 60)
    print("📊 Surveillance des logs livekit-agent-multiagent...")
    print("🔍 Recherche de patterns de détection de débat...")
    print("⏹️  Appuyez sur Ctrl+C pour arrêter")
    print("=" * 60)
    
    # Patterns à surveiller
    patterns = [
        r"🏠 Nom de room:.*debat.*plateau",
        r"🎯 DIAGNOSTIC DÉBAT:",
        r"🎯 PRÉDICTION:",
        r"🎯 DÉBAT PLATEAU DÉTECTÉ DIRECTEMENT:",
        r"🎯 DÉBAT GÉNÉRIQUE DÉTECTÉ:",
        r"✅ Exercice détecté: studio_debate_tv",
        r"🎭 Routage vers MULTI-AGENT",
        r"❌ ERREUR DÉTECTION",
        r"🔧 CORRECTION AUTOMATIQUE"
    ]
    
    try:
        # Commande pour suivre les logs
        cmd = ["docker-compose", "logs", "-f", "livekit-agent-multiagent"]
        
        print("🚀 Démarrage de la surveillance...")
        print("📝 Créez une room 'studio_debatPlateau_1755792176192' pour tester")
        print()
        
        # Lancer le processus
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=1
        )
        
        # Surveiller les logs
        for line in process.stdout:
            # Vérifier si la ligne contient un pattern intéressant
            for pattern in patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    timestamp = time.strftime("%H:%M:%S")
                    print(f"[{timestamp}] 🎯 {line.strip()}")
                    break
            
            # Afficher toutes les lignes de détection d'exercice
            if "Exercice détecté:" in line or "DIAGNOSTIC:" in line:
                timestamp = time.strftime("%H:%M:%S")
                print(f"[{timestamp}] 🔍 {line.strip()}")
    
    except KeyboardInterrupt:
        print("\n⏹️  Surveillance arrêtée par l'utilisateur")
        if 'process' in locals():
            process.terminate()
    
    except Exception as e:
        print(f"❌ Erreur de surveillance: {e}")
        if 'process' in locals():
            process.terminate()

if __name__ == "__main__":
    monitor_debat_detection()
