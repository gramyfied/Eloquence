#!/usr/bin/env python3
"""
Script de diagnostic pour vérifier la compatibilité LiveKit
"""

import subprocess
import sys
import json
import re

def run_command(cmd):
    """Exécute une commande et retourne la sortie"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        return f"Erreur: {e}"

def check_docker_services():
    """Vérifie l'état des services Docker"""
    print("\n🐳 Vérification des services Docker...")
    
    services = ["livekit", "eloquence-agent", "whisper-stt", "piper-tts", "redis"]
    for service in services:
        status = run_command(f"docker ps --filter name={service} --format '{{{{.Status}}}}'")
        if status:
            print(f"  ✅ {service}: {status}")
        else:
            print(f"  ❌ {service}: Non démarré")

def check_livekit_versions():
    """Vérifie les versions LiveKit installées"""
    print("\n📦 Versions LiveKit installées...")
    
    # Vérifier dans le conteneur agent
    cmd = "docker exec eloquence-agent pip list 2>/dev/null | grep -E 'livekit|aiortc|protobuf'"
    output = run_command(cmd)
    
    if output:
        print("  Dans l'agent:")
        for line in output.split('\n'):
            if line.strip():
                print(f"    {line}")
    else:
        print("  ❌ Impossible de vérifier les versions (agent non démarré?)")
    
    # Vérifier la version du serveur LiveKit
    server_info = run_command("docker exec livekit livekit-server --version 2>/dev/null")
    if server_info:
        print(f"\n  Serveur LiveKit: {server_info}")

def check_compatibility_matrix():
    """Affiche la matrice de compatibilité"""
    print("\n📊 Matrice de Compatibilité LiveKit")
    print("=" * 60)
    
    compatibility = {
        "LiveKit Server v1.9.0": {
            "Compatible": ["SDK v1.0.x", "Agents v1.1.x"],
            "Incompatible": ["SDK v0.11.x", "Agents v0.7.x"]
        },
        "LiveKit Server v1.7.x": {
            "Compatible": ["SDK v0.11.x", "Agents v0.7.x"],
            "Incompatible": ["SDK v1.0.x", "Agents v1.1.x"]
        }
    }
    
    for server, compat in compatibility.items():
        print(f"\n  {server}:")
        print(f"    ✅ Compatible: {', '.join(compat['Compatible'])}")
        print(f"    ❌ Incompatible: {', '.join(compat['Incompatible'])}")

def check_network_connectivity():
    """Vérifie la connectivité réseau entre services"""
    print("\n🌐 Test de connectivité réseau...")
    
    tests = [
        ("Agent → LiveKit", "docker exec eloquence-agent ping -c 1 livekit 2>/dev/null"),
        ("Agent → Whisper", "docker exec eloquence-agent ping -c 1 whisper-stt 2>/dev/null"),
        ("Agent → Piper", "docker exec eloquence-agent ping -c 1 piper-tts 2>/dev/null"),
    ]
    
    for test_name, cmd in tests:
        result = run_command(cmd)
        if "1 packets transmitted, 1 received" in result:
            print(f"  ✅ {test_name}: OK")
        else:
            print(f"  ❌ {test_name}: Échec")

def analyze_logs():
    """Analyse les logs pour détecter les erreurs de compatibilité"""
    print("\n📋 Analyse des logs récents...")
    
    # Patterns d'erreurs connues
    error_patterns = [
        (r"wait_pc_connection.*timeout", "Timeout de connexion WebRTC"),
        (r"incompatible.*version", "Incompatibilité de version"),
        (r"WebSocket.*closed", "Fermeture WebSocket prématurée"),
        (r"protocol.*mismatch", "Incompatibilité de protocole"),
        (r"Failed to connect", "Échec de connexion"),
    ]
    
    logs = run_command("docker logs eloquence-agent --tail=100 2>&1")
    
    errors_found = False
    for pattern, description in error_patterns:
        if re.search(pattern, logs, re.IGNORECASE):
            print(f"  ⚠️  {description} détecté")
            errors_found = True
    
    if not errors_found:
        print("  ✅ Aucune erreur de compatibilité détectée")

def generate_recommendation():
    """Génère des recommandations basées sur l'analyse"""
    print("\n💡 Recommandations")
    print("=" * 60)
    
    # Vérifier la version actuelle
    current_sdk = run_command("docker exec eloquence-agent pip show livekit 2>/dev/null | grep Version")
    
    if "0.11" in current_sdk or "0.12" in current_sdk:
        print("\n🚨 MIGRATION URGENTE REQUISE!")
        print("  Votre SDK LiveKit est obsolète et incompatible avec le serveur v1.9.0")
        print("\n  Actions recommandées:")
        print("  1. Exécuter: scripts\\backup_before_migration.bat")
        print("  2. Exécuter: scripts\\test_migration_v1.bat")
        print("  3. Suivre le guide: GUIDE_MIGRATION_LIVEKIT_V1.md")
    elif "1.0" in current_sdk:
        print("\n✅ Versions compatibles détectées")
        print("  Votre configuration utilise les versions récentes de LiveKit")
    else:
        print("\n⚠️  Impossible de déterminer la version du SDK")
        print("  Vérifiez manuellement avec: docker exec eloquence-agent pip list | grep livekit")

def main():
    print("🔍 Diagnostic de Compatibilité LiveKit")
    print("=" * 60)
    
    check_docker_services()
    check_livekit_versions()
    check_compatibility_matrix()
    check_network_connectivity()
    analyze_logs()
    generate_recommendation()
    
    print("\n" + "=" * 60)
    print("Diagnostic terminé!")

if __name__ == "__main__":
    main()