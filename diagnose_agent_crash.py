#!/usr/bin/env python3
"""
Script de diagnostic pour identifier pourquoi l'agent IA crash
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

def check_container_status(container_name):
    """Vérifie le statut d'un conteneur"""
    stdout, _ = run_command(f"docker ps -a --filter name={container_name} --format json")
    if stdout:
        try:
            data = json.loads(stdout.strip())
            return {
                "status": data.get("State", "unknown"),
                "created": data.get("CreatedAt", "unknown"),
                "ports": data.get("Ports", "unknown")
            }
        except:
            pass
    return {"status": "not found"}

def analyze_agent_logs(logs):
    """Analyse les logs de l'agent pour identifier les problèmes"""
    issues = []
    
    # Patterns d'erreur à rechercher
    error_patterns = [
        (r"ERROR.*401.*Unauthorized", "Erreur d'authentification API (401)"),
        (r"ERROR.*Mistral.*", "Problème avec l'API Mistral"),
        (r"ERROR.*OpenAI.*", "Problème avec l'API OpenAI"),
        (r"ERROR.*TTS.*", "Problème avec le service TTS"),
        (r"ERROR.*STT.*", "Problème avec le service STT"),
        (r"ERROR.*WebSocket.*", "Problème de connexion WebSocket"),
        (r"ERROR.*timeout.*", "Timeout de connexion"),
        (r"ERROR.*memory.*", "Problème de mémoire"),
        (r"ERROR.*Exception.*", "Exception non gérée"),
        (r"agent worker left the room", "L'agent a quitté la room prématurément"),
        (r"JS_FAILED", "Job de l'agent échoué"),
        (r"KeyError.*", "Erreur de clé manquante"),
        (r"AttributeError.*", "Erreur d'attribut"),
        (r"TypeError.*", "Erreur de type"),
        (r"ImportError.*", "Erreur d'import de module"),
        (r"ConnectionError.*", "Erreur de connexion"),
        (r"aiohttp.*ClientError.*", "Erreur client HTTP"),
    ]
    
    for pattern, description in error_patterns:
        matches = re.findall(pattern, logs, re.IGNORECASE | re.MULTILINE)
        if matches:
            issues.append({
                "type": description,
                "count": len(matches),
                "samples": matches[:3]  # Premiers exemples
            })
    
    # Recherche de messages de succès
    success_patterns = [
        (r"Agent connecté à la room", "Connexion réussie"),
        (r"Session Agent démarrée", "Session démarrée"),
        (r"Message de bienvenue envoyé", "Message de bienvenue OK"),
        (r"Audio généré avec succès", "TTS fonctionnel"),
        (r"Texte transcrit non vide", "STT fonctionnel"),
    ]
    
    successes = []
    for pattern, description in success_patterns:
        if re.search(pattern, logs, re.IGNORECASE):
            successes.append(description)
    
    return issues, successes

def check_environment_variables():
    """Vérifie les variables d'environnement dans le conteneur"""
    container_name = "25eloquence-finalisation-eloquence-agent-v1-1"
    
    env_vars = [
        "LIVEKIT_URL",
        "LIVEKIT_API_KEY",
        "LIVEKIT_API_SECRET",
        "MISTRAL_API_KEY",
        "OPENAI_API_KEY",
        "MISTRAL_MODEL",
        "MISTRAL_BASE_URL"
    ]
    
    env_status = {}
    for var in env_vars:
        stdout, _ = run_command(f"docker exec {container_name} printenv {var} 2>/dev/null")
        if stdout and stdout.strip():
            # Masquer les valeurs sensibles
            if "KEY" in var or "SECRET" in var:
                env_status[var] = "SET (masked)"
            else:
                env_status[var] = stdout.strip()
        else:
            env_status[var] = "NOT SET"
    
    return env_status

def check_network_connectivity():
    """Vérifie la connectivité réseau du conteneur"""
    container_name = "25eloquence-finalisation-eloquence-agent-v1-1"
    
    tests = {
        "LiveKit": "livekit:7880",
        "API Backend": "api-backend:8000",
        "Internet (Google DNS)": "8.8.8.8"
    }
    
    connectivity = {}
    for name, target in tests.items():
        stdout, _ = run_command(f"docker exec {container_name} ping -c 1 -W 2 {target.split(':')[0]} 2>/dev/null")
        connectivity[name] = "OK" if stdout and "1 received" in stdout else "FAILED"
    
    return connectivity

def main():
    print("DIAGNOSTIC DE L'AGENT IA ELOQUENCE")
    print("=" * 50)
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # 1. Vérifier le statut du conteneur
    print("1. STATUT DU CONTENEUR AGENT")
    print("-" * 30)
    container_name = "25eloquence-finalisation-eloquence-agent-v1-1"
    status = check_container_status(container_name)
    print(f"Statut: {status['status']}")
    print()
    
    # 2. Récupérer et analyser les logs
    print("2️⃣ ANALYSE DES LOGS DE L'AGENT")
    print("-" * 30)
    logs = get_container_logs(container_name, 200)
    
    if logs:
        issues, successes = analyze_agent_logs(logs)
        
        print(f"✅ Étapes réussies ({len(successes)}):")
        for success in successes:
            print(f"   - {success}")
        print()
        
        print(f"❌ Problèmes détectés ({len(issues)}):")
        for issue in issues:
            print(f"   - {issue['type']} (x{issue['count']})")
            for sample in issue['samples']:
                print(f"     → {sample[:100]}...")
        print()
    else:
        print("❌ Impossible de récupérer les logs")
        print()
    
    # 3. Vérifier les variables d'environnement
    print("3️⃣ VARIABLES D'ENVIRONNEMENT")
    print("-" * 30)
    try:
        env_status = check_environment_variables()
        for var, value in env_status.items():
            status_icon = "✅" if value != "NOT SET" else "❌"
            print(f"{status_icon} {var}: {value}")
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
    print()
    
    # 4. Vérifier la connectivité réseau
    print("4️⃣ CONNECTIVITÉ RÉSEAU")
    print("-" * 30)
    try:
        connectivity = check_network_connectivity()
        for service, status in connectivity.items():
            status_icon = "✅" if status == "OK" else "❌"
            print(f"{status_icon} {service}: {status}")
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
    print()
    
    # 5. Récupérer les dernières lignes de logs avec timestamps
    print("5️⃣ DERNIERS LOGS DÉTAILLÉS")
    print("-" * 30)
    recent_logs = get_container_logs(container_name, 50)
    if recent_logs:
        # Extraire les lignes avec ERROR ou WARN
        important_lines = []
        for line in recent_logs.split('\n'):
            if any(keyword in line.upper() for keyword in ['ERROR', 'WARN', 'FAIL', 'EXCEPTION']):
                important_lines.append(line)
        
        if important_lines:
            print("Dernières erreurs/warnings:")
            for line in important_lines[-10:]:  # Dernières 10 lignes importantes
                print(f"   {line[:150]}...")
        else:
            print("Aucune erreur récente trouvée dans les logs")
    print()
    
    # 6. Recommandations
    print("6️⃣ RECOMMANDATIONS")
    print("-" * 30)
    
    recommendations = []
    
    # Analyser les problèmes pour faire des recommandations
    if logs:
        if "401" in logs or "Unauthorized" in logs:
            recommendations.append("Vérifier les clés API (Mistral, OpenAI)")
        if "agent worker left the room" in logs:
            recommendations.append("L'agent crash probablement à cause d'une erreur non gérée")
        if "timeout" in logs.lower():
            recommendations.append("Augmenter les timeouts de connexion")
        if "memory" in logs.lower():
            recommendations.append("Vérifier les ressources Docker (mémoire)")
        if not successes:
            recommendations.append("L'agent ne démarre pas correctement")
    
    if recommendations:
        for rec in recommendations:
            print(f"   → {rec}")
    else:
        print("   → Aucune recommandation spécifique")
    
    # Sauvegarder le rapport
    report_file = f"agent_diagnostic_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(f"RAPPORT DE DIAGNOSTIC AGENT IA\n")
        f.write(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"LOGS COMPLETS:\n{logs}\n")
    
    print(f"\n📄 Rapport complet sauvegardé dans: {report_file}")

if __name__ == "__main__":
    main()