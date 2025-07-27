#!/usr/bin/env python3
"""
Script de validation de la configuration des ports Eloquence
Vérifie la cohérence entre les différents fichiers de configuration
"""

import os
import re
import json
from pathlib import Path

def read_file_content(file_path):
    """Lit le contenu d'un fichier"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"❌ Erreur lecture {file_path}: {e}")
        return None

def extract_ports_from_env(content):
    """Extrait les ports du fichier .env Flutter"""
    ports = {}
    
    # API Backend
    match = re.search(r'API_BACKEND_URL=http://[\d.]+:(\d+)', content)
    if match:
        ports['api_backend'] = int(match.group(1))
    
    # LLM Service
    match = re.search(r'LLM_SERVICE_URL=http://[\d.]+:(\d+)', content)
    if match:
        ports['llm_service'] = int(match.group(1))
    
    # Vosk STT
    match = re.search(r'VOSK_STT_URL=http://[\d.]+:(\d+)', content)
    if match:
        ports['vosk_stt'] = int(match.group(1))
    
    # LiveKit
    match = re.search(r'LIVEKIT_URL=ws://[\d.]+:(\d+)', content)
    if match:
        ports['livekit'] = int(match.group(1))
    
    return ports

def extract_ports_from_docker_compose(content):
    """Extrait les ports du docker-compose.yml"""
    ports = {}
    
    # API Backend
    match = re.search(r'- "(\d+):8000"', content)
    if match:
        ports['api_backend'] = int(match.group(1))
    
    # Mistral LLM
    match = re.search(r'- "(\d+):8001"', content)
    if match:
        ports['llm_service'] = int(match.group(1))
    
    # Vosk STT
    match = re.search(r'- "(\d+):8002"', content)
    if match:
        ports['vosk_stt'] = int(match.group(1))
    
    # LiveKit
    match = re.search(r'- "(\d+):7880"', content)
    if match:
        ports['livekit'] = int(match.group(1))
    
    return ports

def extract_ports_from_firewall_script(content):
    """Extrait les ports du script de pare-feu"""
    ports = {}
    
    # API Backend
    match = re.search(r'name="Eloquence API Backend".*?localport=(\d+)', content)
    if match:
        ports['api_backend'] = int(match.group(1))
    
    # Mistral LLM
    match = re.search(r'name="Eloquence Mistral LLM".*?localport=(\d+)', content)
    if match:
        ports['llm_service'] = int(match.group(1))
    
    # Vosk STT
    match = re.search(r'name="Eloquence Vosk STT".*?localport=(\d+)', content)
    if match:
        ports['vosk_stt'] = int(match.group(1))
    
    # LiveKit
    match = re.search(r'name="Eloquence LiveKit".*?localport=(\d+)', content)
    if match:
        ports['livekit'] = int(match.group(1))
    
    return ports

def main():
    """Fonction principale de validation"""
    print("🔍 Validation de la configuration des ports Eloquence")
    print("=" * 60)
    
    # Chemins des fichiers
    flutter_env = Path("frontend/flutter_app/.env")
    docker_compose = Path("docker-compose.yml")
    firewall_script = Path("scripts/configure_firewall_mobile.bat")
    
    # Lecture des fichiers
    flutter_content = read_file_content(flutter_env)
    docker_content = read_file_content(docker_compose)
    firewall_content = read_file_content(firewall_script)
    
    if not all([flutter_content, docker_content, firewall_content]):
        print("❌ Impossible de lire tous les fichiers de configuration")
        return False
    
    # Extraction des ports
    flutter_ports = extract_ports_from_env(flutter_content)
    docker_ports = extract_ports_from_docker_compose(docker_content)
    firewall_ports = extract_ports_from_firewall_script(firewall_content)
    
    print("📋 Ports détectés:")
    print(f"Flutter .env:     {flutter_ports}")
    print(f"Docker Compose:   {docker_ports}")
    print(f"Script Pare-feu:  {firewall_ports}")
    print()
    
    # Validation de la cohérence
    all_valid = True
    services = ['api_backend', 'llm_service', 'vosk_stt', 'livekit']
    
    for service in services:
        flutter_port = flutter_ports.get(service)
        docker_port = docker_ports.get(service)
        firewall_port = firewall_ports.get(service)
        
        print(f"🔧 Service {service}:")
        
        if flutter_port == docker_port == firewall_port:
            print(f"   ✅ Port {flutter_port} - Configuration cohérente")
        else:
            print(f"   ❌ Incohérence détectée:")
            print(f"      Flutter: {flutter_port}")
            print(f"      Docker:  {docker_port}")
            print(f"      Firewall: {firewall_port}")
            all_valid = False
        print()
    
    # Vérification des services non utilisés
    print("🚫 Vérification des services non utilisés:")
    
    # Whisper ne doit plus être présent
    if 'WHISPER_STT_URL' in flutter_content:
        print("   ❌ WHISPER_STT_URL encore présent dans Flutter .env")
        all_valid = False
    else:
        print("   ✅ WHISPER_STT_URL correctement supprimé")
    
    if 'Whisper STT' in firewall_content:
        print("   ❌ Règle Whisper encore présente dans le script pare-feu")
        all_valid = False
    else:
        print("   ✅ Règle Whisper correctement supprimée du pare-feu")
    
    print()
    
    # Résultat final
    if all_valid:
        print("🎉 Configuration des ports validée avec succès!")
        print("✅ Tous les services utilisent des ports cohérents")
        print("✅ Les services non utilisés ont été supprimés")
        return True
    else:
        print("❌ Des incohérences ont été détectées dans la configuration")
        print("🔧 Veuillez corriger les ports pour assurer la cohérence")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
