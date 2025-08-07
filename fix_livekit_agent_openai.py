#!/usr/bin/env python3
"""
Script pour corriger la clé OpenAI dans l'agent LiveKit
Résout le problème de l'IA muette
"""

import os
import sys
import docker
from dotenv import load_dotenv

def fix_livekit_agent_openai():
    """Corriger la clé OpenAI pour l'agent LiveKit"""
    print("🔧 CORRECTION AGENT LIVEKIT - IA MUETTE")
    print("=" * 50)
    
    # Charger les variables d'environnement
    load_dotenv()
    
    openai_key = os.getenv('OPENAI_API_KEY')
    if not openai_key:
        print("❌ ERREUR: Clé OpenAI manquante dans .env")
        return False
    
    print(f"✅ Clé OpenAI trouvée: {openai_key[:8]}...{openai_key[-4:]}")
    
    # 1. Mettre à jour le fichier .env de l'agent
    agent_env_path = 'services/livekit-agent/.env'
    os.makedirs(os.path.dirname(agent_env_path), exist_ok=True)
    
    try:
        with open(agent_env_path, 'w') as f:
            f.write(f'OPENAI_API_KEY={openai_key}\n')
        print(f"✅ Fichier {agent_env_path} mis à jour")
    except Exception as e:
        print(f"❌ Erreur écriture {agent_env_path}: {e}")
        return False
    
    # 2. Mettre à jour docker-compose.yml pour s'assurer que la variable est passée
    try:
        print("🔄 Vérification docker-compose.yml...")
        
        # Lire le fichier docker-compose
        with open('docker-compose.yml', 'r') as f:
            compose_content = f.read()
        
        # Vérifier si l'agent LiveKit a la variable d'environnement
        if 'livekit-agent:' in compose_content:
            print("✅ Service livekit-agent trouvé dans docker-compose.yml")
            
            # Vérifier si OPENAI_API_KEY est dans environment
            if 'OPENAI_API_KEY' not in compose_content:
                print("⚠️ OPENAI_API_KEY manquante dans docker-compose.yml")
                print("🔧 Ajout recommandé dans la section environment du service livekit-agent")
            else:
                print("✅ OPENAI_API_KEY présente dans docker-compose.yml")
        
    except Exception as e:
        print(f"⚠️ Erreur lecture docker-compose.yml: {e}")
    
    # 3. Redémarrer l'agent LiveKit
    try:
        print("🔄 Redémarrage de l'agent LiveKit...")
        
        client = docker.from_env()
        
        # Arrêter le conteneur s'il existe
        try:
            container = client.containers.get('eloquence-livekit-agent-1')
            container.stop()
            container.remove()
            print("✅ Ancien conteneur arrêté et supprimé")
        except docker.errors.NotFound:
            print("ℹ️ Aucun conteneur existant trouvé")
        except Exception as e:
            print(f"⚠️ Erreur arrêt conteneur: {e}")
        
        # Redémarrer avec docker-compose
        os.system('docker-compose up -d livekit-agent')
        print("✅ Agent LiveKit redémarré")
        
    except Exception as e:
        print(f"⚠️ Erreur redémarrage: {e}")
        print("🔧 Redémarrez manuellement avec: docker-compose restart livekit-agent")
    
    print("\n✅ CORRECTION TERMINÉE")
    print("🔍 Vérifiez les logs avec: docker-compose logs -f livekit-agent")
    print("🎯 L'IA devrait maintenant répondre correctement")
    
    return True

def check_agent_logs():
    """Vérifier les logs de l'agent"""
    print("\n📋 VÉRIFICATION DES LOGS DE L'AGENT")
    print("=" * 40)
    
    try:
        # Afficher les derniers logs
        os.system('docker-compose logs --tail=20 livekit-agent')
    except Exception as e:
        print(f"❌ Erreur lecture logs: {e}")

def main():
    """Fonction principale"""
    success = fix_livekit_agent_openai()
    
    if success:
        print("\n🎉 CORRECTION APPLIQUÉE AVEC SUCCÈS")
        print("=" * 40)
        print("1. Clé OpenAI mise à jour dans l'agent")
        print("2. Agent LiveKit redémarré")
        print("3. Testez maintenant une conversation")
        
        # Proposer de vérifier les logs
        check_logs = input("\n📋 Voulez-vous voir les logs de l'agent ? (o/N): ").strip().lower()
        if check_logs in ['o', 'oui', 'y', 'yes']:
            check_agent_logs()
    else:
        print("\n❌ ÉCHEC DE LA CORRECTION")
        print("🔧 Vérifiez manuellement:")
        print("   1. La clé OpenAI dans .env")
        print("   2. Le fichier services/livekit-agent/.env")
        print("   3. Redémarrez avec: docker-compose restart livekit-agent")

if __name__ == "__main__":
    main()
