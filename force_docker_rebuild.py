#!/usr/bin/env python3
"""
Script pour forcer la reconstruction Docker avec les corrections
"""

import os
import sys
import subprocess
import time

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

def verify_corrections():
    """Vérifie que les corrections sont présentes dans le code"""
    print("\n🔍 VÉRIFICATION DES CORRECTIONS")
    print("=" * 50)
    
    # Vérification 1: Logs mapping voix
    cmd1 = "grep -c 'RECHERCHE VOIX' services/livekit-agent/elevenlabs_flash_tts_service.py"
    result1 = subprocess.run(cmd1, shell=True, capture_output=True, text=True, cwd="/home/ubuntu/Eloquence")
    
    if result1.returncode == 0 and int(result1.stdout.strip()) > 0:
        print("✅ Logs mapping voix présents")
    else:
        print("❌ Logs mapping voix manquants")
        return False
    
    # Vérification 2: Fonction clean_agent_names
    cmd2 = "grep -c 'clean_agent_names' services/livekit-agent/enhanced_multi_agent_manager.py"
    result2 = subprocess.run(cmd2, shell=True, capture_output=True, text=True, cwd="/home/ubuntu/Eloquence")
    
    if result2.returncode == 0 and int(result2.stdout.strip()) > 0:
        print("✅ Fonction clean_agent_names présente")
    else:
        print("❌ Fonction clean_agent_names manquante")
        return False
    
    print("✅ Toutes les corrections sont présentes dans le code source")
    return True

def force_docker_rebuild():
    """Force la reconstruction complète de Docker"""
    print("\n🚀 RECONSTRUCTION FORCÉE DOCKER")
    print("=" * 50)
    
    # Étape 1: Arrêter tous les services
    if not run_command("docker-compose down", "Arrêt des services Docker"):
        return False
    
    # Étape 2: Supprimer les images pour forcer reconstruction
    if not run_command("docker-compose build --no-cache livekit-agent-multiagent", "Reconstruction sans cache"):
        print("⚠️ Reconstruction échouée, tentative avec build général...")
        if not run_command("docker-compose build --no-cache", "Reconstruction générale sans cache"):
            return False
    
    # Étape 3: Redémarrer les services
    if not run_command("docker-compose up -d", "Redémarrage des services"):
        return False
    
    print("✅ Reconstruction Docker terminée")
    return True

def wait_for_services():
    """Attend que les services soient prêts"""
    print("\n⏳ ATTENTE DÉMARRAGE SERVICES")
    print("=" * 50)
    
    print("⏳ Attente 30 secondes pour le démarrage complet...")
    time.sleep(30)
    
    # Vérifier que les services sont actifs
    if run_command("docker-compose ps", "Statut des services"):
        print("✅ Services démarrés")
        return True
    else:
        print("❌ Problème démarrage services")
        return False

def test_corrections():
    """Teste que les corrections sont actives en consultant les logs"""
    print("\n🧪 TEST DES CORRECTIONS")
    print("=" * 50)
    
    print("📋 Instructions pour tester :")
    print("1. Créer une room 'studio_debatPlateau_test'")
    print("2. Chercher dans les logs :")
    print("   - '🔍 RECHERCHE VOIX: agent_id='")
    print("   - '✅ MAPPING TROUVÉ:'")
    print("   - '🧹 Nom agent retiré:'")
    print("3. Vérifier que Sarah et Marcus ont des voix différentes")
    
    # Afficher les logs récents
    run_command("docker-compose logs --tail=50 livekit-agent-multiagent", "Logs récents")

def main():
    """Fonction principale"""
    print("🚀 FORCE RECONSTRUCTION DOCKER AVEC CORRECTIONS")
    print("=" * 60)
    
    try:
        # 1. Vérifier que les corrections sont dans le code
        if not verify_corrections():
            print("❌ ÉCHEC: Corrections manquantes dans le code source")
            return False
        
        # 2. Forcer reconstruction Docker
        if not force_docker_rebuild():
            print("❌ ÉCHEC: Reconstruction Docker échouée")
            return False
        
        # 3. Attendre démarrage
        if not wait_for_services():
            print("❌ ÉCHEC: Services non démarrés")
            return False
        
        # 4. Instructions de test
        test_corrections()
        
        print("\n✅ RECONSTRUCTION TERMINÉE AVEC SUCCÈS !")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Créer une room studio_debatPlateau_test")
        print("2. Vérifier les logs pour les corrections")
        print("3. Tester audio différencié Sarah/Marcus")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR CRITIQUE: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

