#!/usr/bin/env python3
"""
Script de diagnostic simplifié pour identifier pourquoi l'agent IA crash
"""

import subprocess
import time
import json
import re
from datetime import datetime

def run_command(cmd):
    """Execute une commande et retourne le résultat"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout, result.stderr
    except Exception as e:
        return None, str(e)

def get_container_logs(container_name, lines=100):
    """Récupère les logs d'un conteneur"""
    stdout, stderr = run_command(f"docker logs {container_name} --tail {lines} 2>&1")
    return stdout if stdout else stderr

def main():
    print("DIAGNOSTIC DE L'AGENT IA ELOQUENCE")
    print("=" * 50)
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    container_name = "25eloquence-finalisation-eloquence-agent-v1-1"
    
    # 1. Récupérer les logs complets
    print("1. RECUPERATION DES LOGS")
    print("-" * 30)
    logs = get_container_logs(container_name, 200)
    
    if not logs:
        print("[ERREUR] Impossible de recuperer les logs")
        return
    
    # 2. Rechercher les erreurs spécifiques
    print("\n2. ANALYSE DES ERREURS")
    print("-" * 30)
    
    # Patterns d'erreur à rechercher
    error_patterns = [
        (r"ERROR.*401.*Unauthorized", "Erreur d'authentification API (401)"),
        (r"ERROR.*Mistral.*", "Probleme avec l'API Mistral"),
        (r"ERROR.*OpenAI.*", "Probleme avec l'API OpenAI"),
        (r"ERROR.*TTS.*", "Probleme avec le service TTS"),
        (r"ERROR.*STT.*", "Probleme avec le service STT"),
        (r"ERROR.*WebSocket.*", "Probleme de connexion WebSocket"),
        (r"ERROR.*timeout.*", "Timeout de connexion"),
        (r"ERROR.*memory.*", "Probleme de memoire"),
        (r"ERROR.*Exception.*", "Exception non geree"),
        (r"agent worker left the room", "L'agent a quitte la room prematurement"),
        (r"JS_FAILED", "Job de l'agent echoue"),
        (r"KeyError.*", "Erreur de cle manquante"),
        (r"AttributeError.*", "Erreur d'attribut"),
        (r"TypeError.*", "Erreur de type"),
        (r"ImportError.*", "Erreur d'import de module"),
        (r"ConnectionError.*", "Erreur de connexion"),
        (r"aiohttp.*ClientError.*", "Erreur client HTTP"),
    ]
    
    errors_found = []
    for pattern, description in error_patterns:
        matches = re.findall(pattern, logs, re.IGNORECASE | re.MULTILINE)
        if matches:
            errors_found.append({
                "type": description,
                "count": len(matches),
                "samples": matches[:3]
            })
    
    if errors_found:
        print(f"[ERREUR] {len(errors_found)} types d'erreurs detectes:")
        for error in errors_found:
            print(f"\n   - {error['type']} (x{error['count']})")
            for i, sample in enumerate(error['samples']):
                print(f"     Exemple {i+1}: {sample[:100]}...")
    else:
        print("[OK] Aucune erreur specifique detectee")
    
    # 3. Vérifier les étapes de démarrage
    print("\n\n3. VERIFICATION DES ETAPES DE DEMARRAGE")
    print("-" * 30)
    
    startup_checks = [
        ("Demarrage du job de l'agent", "Demarrage initial"),
        ("Agent connecte a la room", "Connexion a la room"),
        ("Session Agent demarree", "Session demarree"),
        ("Message de bienvenue envoye", "Message de bienvenue"),
        ("Audio genere avec succes", "TTS fonctionnel"),
        ("Texte transcrit non vide", "STT fonctionnel"),
    ]
    
    for pattern, description in startup_checks:
        if re.search(pattern, logs, re.IGNORECASE):
            print(f"[OK] {description}")
        else:
            print(f"[MANQUANT] {description}")
    
    # 4. Extraire les dernières lignes d'erreur
    print("\n\n4. DERNIERES LIGNES D'ERREUR")
    print("-" * 30)
    
    error_lines = []
    for line in logs.split('\n'):
        if any(keyword in line.upper() for keyword in ['ERROR', 'EXCEPTION', 'FAILED', 'CRASH']):
            error_lines.append(line)
    
    if error_lines:
        print("Dernieres erreurs (max 10):")
        for line in error_lines[-10:]:
            print(f"\n{line}")
    else:
        print("Aucune ligne d'erreur trouvee")
    
    # 5. Vérifier les variables d'environnement
    print("\n\n5. VERIFICATION DES VARIABLES D'ENVIRONNEMENT")
    print("-" * 30)
    
    env_vars = [
        "LIVEKIT_URL",
        "LIVEKIT_API_KEY", 
        "LIVEKIT_API_SECRET",
        "MISTRAL_API_KEY",
        "OPENAI_API_KEY"
    ]
    
    for var in env_vars:
        stdout, _ = run_command(f"docker exec {container_name} printenv {var} 2>/dev/null")
        if stdout and stdout.strip():
            if "KEY" in var or "SECRET" in var:
                print(f"[OK] {var}: SET (masked)")
            else:
                print(f"[OK] {var}: {stdout.strip()}")
        else:
            print(f"[MANQUANT] {var}: NOT SET")
    
    # 6. Recommandations
    print("\n\n6. RECOMMANDATIONS")
    print("-" * 30)
    
    if any("401" in str(e.get('samples', [])) for e in errors_found):
        print("-> Verifier les cles API (Mistral, OpenAI)")
    
    if any("agent worker left the room" in str(e.get('samples', [])) for e in errors_found):
        print("-> L'agent crash probablement a cause d'une erreur non geree")
        print("-> Verifier les logs detailles pour identifier l'erreur exacte")
    
    if any("timeout" in str(e.get('samples', [])).lower() for e in errors_found):
        print("-> Augmenter les timeouts de connexion")
    
    if not any("Session Agent demarree" in logs for pattern, _ in startup_checks):
        print("-> L'agent ne demarre pas correctement")
        print("-> Verifier la configuration et les dependances")
    
    # Sauvegarder le rapport
    report_file = f"agent_diagnostic_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(f"RAPPORT DE DIAGNOSTIC AGENT IA\n")
        f.write(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"LOGS COMPLETS:\n{logs}\n")
    
    print(f"\n\nRapport complet sauvegarde dans: {report_file}")

if __name__ == "__main__":
    main()