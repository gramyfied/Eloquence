#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de diagnostic pour analyser la connectivité LiveKit entre l'agent et le serveur
"""

import requests
import os
import subprocess
import json
from datetime import datetime

def check_livekit_server_health():
    """Vérifier la santé du serveur LiveKit"""
    print("\n--- Diagnostic du Serveur LiveKit ---")
    
    # Vérifier via l'API health check
    try:
        response = requests.get("http://192.168.1.44:7880/", timeout=5)
        print(f"[+] Serveur LiveKit répond sur le port 7880 (Status: {response.status_code})")
    except Exception as e:
        print(f"[-] Erreur de connexion au serveur LiveKit: {e}")
        
def check_agent_environment():
    """Vérifier les variables d'environnement de l'agent"""
    print("\n--- Variables d'Environnement de l'Agent ---")
    
    result = subprocess.run([
        "docker", "exec", "eloquence-eloquence-agent-v1-1", 
        "env"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        env_vars = result.stdout
        livekit_vars = [line for line in env_vars.split('\n') if 'LIVEKIT' in line.upper()]
        
        if livekit_vars:
            print("[+] Variables LiveKit trouvées:")
            for var in livekit_vars:
                # Masquer les secrets
                if 'SECRET' in var or 'KEY' in var:
                    parts = var.split('=')
                    if len(parts) == 2:
                        print(f"    {parts[0]}=***MASKED***")
                else:
                    print(f"    {var}")
        else:
            print("[-] CRITIQUE: Aucune variable d'environnement LiveKit trouvée!")
    else:
        print(f"[-] Erreur lors de la récupération des variables d'environnement: {result.stderr}")

def check_agent_network_connectivity():
    """Vérifier si l'agent peut joindre le serveur LiveKit"""
    print("\n--- Test de Connectivité Réseau Agent->LiveKit ---")
    
    # Test de ping vers le service livekit par nom Docker
    result = subprocess.run([
        "docker", "exec", "eloquence-eloquence-agent-v1-1",
        "ping", "-c", "3", "livekit"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("[+] L'agent peut ping le service 'livekit' via le réseau Docker")
    else:
        print(f"[-] L'agent ne peut PAS ping le service 'livekit': {result.stderr}")
        
    # Test direct du port
    result = subprocess.run([
        "docker", "exec", "eloquence-eloquence-agent-v1-1",
        "nc", "-zv", "livekit", "7880"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("[+] Le port 7880 du service LiveKit est accessible depuis l'agent")
    else:
        print(f"[-] Le port 7880 du service LiveKit n'est PAS accessible: {result.stderr}")

def check_docker_compose_config():
    """Analyser la configuration docker-compose pour LiveKit"""
    print("\n--- Configuration Docker Compose LiveKit ---")
    
    try:
        with open('docker-compose.yml', 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'livekit' in content:
            print("[+] Service LiveKit trouvé dans docker-compose.yml")
            
            # Extraire la section livekit
            lines = content.split('\n')
            in_livekit_section = False
            livekit_config = []
            
            for line in lines:
                if line.strip().startswith('livekit:'):
                    in_livekit_section = True
                elif in_livekit_section and line.startswith('  ') and not line.startswith('    '):
                    # Nouvelle section de service
                    break
                    
                if in_livekit_section:
                    livekit_config.append(line)
                    
            if livekit_config:
                print("Configuration LiveKit:")
                for line in livekit_config[:10]:  # Première 10 lignes
                    print(f"    {line}")
        else:
            print("[-] Service LiveKit non trouvé dans docker-compose.yml")
            
    except Exception as e:
        print(f"[-] Erreur lors de la lecture de docker-compose.yml: {e}")

if __name__ == "__main__":
    print("=== DIAGNOSTIC DE CONNECTIVITÉ LIVEKIT ===")
    print(f"Heure: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    check_livekit_server_health()
    check_agent_environment()
    check_agent_network_connectivity()
    check_docker_compose_config()
    
    print("\n=== FIN DU DIAGNOSTIC ===")