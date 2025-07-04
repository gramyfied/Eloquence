#!/usr/bin/env python3
"""
Diagnostic approfondi du problème AudioEmitter dans LiveKit
"""

import os
import sys
import subprocess
import importlib.util

def check_livekit_version():
    """Vérifier les versions de LiveKit installées"""
    print("\n[1] VERSIONS LIVEKIT INSTALLEES")
    print("="*50)
    
    packages = ['livekit', 'livekit-agents', 'livekit-plugins-openai', 'livekit-plugins-silero']
    
    for package in packages:
        try:
            result = subprocess.run(
                [sys.executable, '-m', 'pip', 'show', package],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                version_line = next((line for line in lines if line.startswith('Version:')), None)
                if version_line:
                    print(f"[OK] {package}: {version_line.split(':')[1].strip()}")
            else:
                print(f"[ERREUR] {package}: Non installé")
        except Exception as e:
            print(f"[ERREUR] {package}: {e}")

def check_tts_source():
    """Examiner le code source du TTS qui cause l'erreur"""
    print("\n[2] ANALYSE DU CODE SOURCE TTS")
    print("="*50)
    
    try:
        import livekit.agents.tts.tts as tts_module
        
        # Localiser le fichier
        file_path = tts_module.__file__
        print(f"Fichier source: {file_path}")
        
        # Lire les lignes autour de l'erreur (ligne 636)
        with open(file_path, 'r') as f:
            lines = f.readlines()
            
        # Afficher le contexte autour de la ligne 636
        start = max(0, 630)
        end = min(len(lines), 640)
        
        print(f"\nCode autour de la ligne 636 (lignes {start+1}-{end}):")
        for i in range(start, end):
            prefix = ">>> " if i == 635 else "    "
            print(f"{prefix}{i+1}: {lines[i].rstrip()}")
            
    except Exception as e:
        print(f"[ERREUR] Impossible de lire le code source: {e}")

def check_audio_emitter_class():
    """Examiner la classe AudioEmitter"""
    print("\n[3] ANALYSE DE LA CLASSE AudioEmitter")
    print("="*50)
    
    try:
        from livekit.agents.tts.tts import AudioEmitter
        
        print(f"Type: {type(AudioEmitter)}")
        print(f"Module: {AudioEmitter.__module__}")
        
        # Méthodes disponibles
        methods = [m for m in dir(AudioEmitter) if not m.startswith('_')]
        print(f"\nMéthodes publiques: {', '.join(methods)}")
        
        # Vérifier si 'start' existe
        if hasattr(AudioEmitter, 'start'):
            print("\n[INFO] La méthode 'start' existe")
        else:
            print("\n[WARNING] La méthode 'start' n'existe pas!")
            
    except Exception as e:
        print(f"[ERREUR] Impossible d'analyser AudioEmitter: {e}")

def check_mistral_config():
    """Vérifier la configuration Mistral"""
    print("\n[4] CONFIGURATION MISTRAL")
    print("="*50)
    
    mistral_key = os.getenv('MISTRAL_API_KEY')
    if mistral_key:
        print(f"[OK] MISTRAL_API_KEY définie: ***{mistral_key[-4:]}")
    else:
        print("[ERREUR] MISTRAL_API_KEY non définie")
    
    # L'URL dans l'erreur suggère Scaleway
    print("\n[INFO] L'erreur montre une URL Scaleway:")
    print("  https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1/chat/completions")
    print("  Cela suggère que Mistral est configuré pour utiliser Scaleway AI")

def suggest_solutions():
    """Proposer des solutions"""
    print("\n[5] SOLUTIONS PROPOSEES")
    print("="*50)
    
    print("\n1. PROBLEME AudioEmitter:")
    print("   - Le framework essaie d'appeler end_input() sur un AudioEmitter non démarré")
    print("   - Cela pourrait être un bug dans LiveKit v1.1.5")
    print("   - Solutions possibles:")
    print("     a) Downgrader à une version antérieure de livekit-agents")
    print("     b) Utiliser VoiceAssistant au lieu d'AgentSession")
    print("     c) Implémenter un wrapper qui gère l'état de l'AudioEmitter")
    
    print("\n2. PROBLEME Mistral API:")
    print("   - L'API retourne une erreur 400 (Bad Request)")
    print("   - Solutions possibles:")
    print("     a) Vérifier la clé API Mistral")
    print("     b) Utiliser OpenAI LLM au lieu de Mistral")
    print("     c) Vérifier le format de la requête envoyée à Mistral")
    
    print("\n3. SOLUTION IMMEDIATE:")
    print("   Utiliser l'implémentation minimale avec VoiceAssistant")
    print("   qui utilise tous les plugins OpenAI (STT, LLM, TTS)")

def main():
    """Fonction principale"""
    print("\n" + "="*60)
    print("DIAGNOSTIC DU PROBLEME AudioEmitter")
    print("="*60)
    
    check_livekit_version()
    check_tts_source()
    check_audio_emitter_class()
    check_mistral_config()
    suggest_solutions()
    
    print("\n" + "="*60)
    print("DIAGNOSTIC TERMINE")
    print("="*60)

if __name__ == "__main__":
    main()