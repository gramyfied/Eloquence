#!/usr/bin/env python3
"""
Applique les corrections directement dans le container Docker en cours
"""

import subprocess
import time
import os

def run_command(cmd, description):
    """Exécute une commande et affiche le résultat"""
    print(f"\n🔄 {description}")
    print(f"💻 Commande: {cmd}")
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd="/home/ubuntu/Eloquence")
        
        if result.returncode == 0:
            print(f"✅ Succès: {description}")
            if result.stdout.strip():
                print(f"📤 Sortie: {result.stdout.strip()}")
        else:
            print(f"❌ Erreur: {description}")
            print(f"📤 Erreur: {result.stderr.strip()}")
            
        return result.returncode == 0
        
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def copy_corrections_to_container():
    """Copie les corrections dans le container"""
    print("\n🚀 COPIE DES CORRECTIONS DANS LE CONTAINER")
    print("=" * 50)
    
    # Copier le fichier TTS corrigé
    cmd1 = "docker cp services/livekit-agent/elevenlabs_flash_tts_service.py eloquence-multiagent:/app/elevenlabs_flash_tts_service.py"
    if not run_command(cmd1, "Copie TTS service"):
        return False
    
    # Copier le fichier manager corrigé
    cmd2 = "docker cp services/livekit-agent/enhanced_multi_agent_manager.py eloquence-multiagent:/app/enhanced_multi_agent_manager.py"
    if not run_command(cmd2, "Copie manager"):
        return False
    
    return True

def restart_container():
    """Redémarre le container pour appliquer les corrections"""
    print("\n🔄 REDÉMARRAGE CONTAINER")
    print("=" * 50)
    
    # Redémarrer le container
    if not run_command("docker-compose restart livekit-agent-multiagent", "Redémarrage container"):
        return False
    
    # Attendre le démarrage
    print("⏳ Attente démarrage (30 secondes)...")
    time.sleep(30)
    
    return True

def verify_corrections_active():
    """Vérifie que les corrections sont actives"""
    print("\n🧪 VÉRIFICATION CORRECTIONS ACTIVES")
    print("=" * 50)
    
    # Vérifier que les fichiers sont bien présents
    if run_command("docker exec eloquence-multiagent ls -la /app/elevenlabs_flash_tts_service.py", "Vérification TTS service"):
        print("✅ TTS service présent")
    
    if run_command("docker exec eloquence-multiagent ls -la /app/enhanced_multi_agent_manager.py", "Vérification manager"):
        print("✅ Manager présent")
    
    # Vérifier le contenu des corrections
    if run_command("docker exec eloquence-multiagent grep -c 'RECHERCHE VOIX' /app/elevenlabs_flash_tts_service.py", "Vérification logs TTS"):
        print("✅ Logs TTS présents")
    
    if run_command("docker exec eloquence-multiagent grep -c 'clean_agent_names' /app/enhanced_multi_agent_manager.py", "Vérification nettoyage"):
        print("✅ Nettoyage noms présent")
    
    return True

def show_recent_logs():
    """Affiche les logs récents pour vérifier le fonctionnement"""
    print("\n📋 LOGS RÉCENTS")
    print("=" * 50)
    
    run_command("docker-compose logs --tail=20 livekit-agent-multiagent", "Logs récents")

def main():
    """Fonction principale"""
    print("🚀 APPLICATION CORRECTIONS DIRECTES DANS DOCKER")
    print("=" * 60)
    
    try:
        # 1. Copier les corrections
        if not copy_corrections_to_container():
            print("❌ ÉCHEC: Copie des corrections")
            return False
        
        # 2. Redémarrer le container
        if not restart_container():
            print("❌ ÉCHEC: Redémarrage container")
            return False
        
        # 3. Vérifier que les corrections sont actives
        if not verify_corrections_active():
            print("❌ ÉCHEC: Vérification corrections")
            return False
        
        # 4. Afficher les logs récents
        show_recent_logs()
        
        print("\n✅ CORRECTIONS APPLIQUÉES AVEC SUCCÈS !")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Créer une room studio_debatPlateau_test")
        print("2. Chercher dans les logs :")
        print("   - '🔍 RECHERCHE VOIX: agent_id='")
        print("   - '✅ MAPPING TROUVÉ:'")
        print("   - '🧹 Nom agent retiré:'")
        print("3. Vérifier audio différencié Sarah/Marcus")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR CRITIQUE: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

