"""
Client de configuration pour les services
Interface simplifiée pour accéder à la configuration centralisée
"""
import sys
from pathlib import Path

# Ajouter le répertoire config au path si nécessaire
config_dir = Path(__file__).parent
if str(config_dir) not in sys.path:
    sys.path.insert(0, str(config_dir))

from config_loader import (
    get_port, 
    get_docker_url, 
    get_external_url,
    get_livekit_credentials,
    get_multi_agent_config,
    EloquenceConfigError
)

import logging
logger = logging.getLogger(__name__)

# =====================================================
# PROTECTION CONTRE LA CONFIGURATION HARDCODÉE
# =====================================================

class ForbiddenConfigAccess:
    """Classe qui lève une erreur si on tente d'accéder à la configuration hardcodée"""
    def __init__(self, name):
        self.name = name
    
    def __getattribute__(self, attr):
        if attr == 'name':
            return object.__getattribute__(self, attr)
        
        raise EloquenceConfigError(f"""
🚨 ERREUR FATALE : CONFIGURATION HARDCODÉE INTERDITE 🚨

❌ VIOLATION : Tentative d'accès à '{self.name}'
📍 PROBLÈME : Vous tentez d'utiliser une configuration hardcodée

🔒 RÈGLE ABSOLUE :
   Utiliser UNIQUEMENT la configuration centralisée

✅ SOLUTION OBLIGATOIRE :
   Remplacer par : from config_client import get_livekit_config, get_services_urls
   
⚠️ CONSÉQUENCES si ignoré :
   - Configuration incohérente
   - Erreurs de connectivité
   - Impossible de changer les ports

🎯 ACTION REQUISE : Utiliser config_client.py au lieu de variables hardcodées
""")

# Variables interdites qui lèveront des erreurs
LIVEKIT_URL = ForbiddenConfigAccess("LIVEKIT_URL")
LIVEKIT_API_KEY = ForbiddenConfigAccess("LIVEKIT_API_KEY") 
LIVEKIT_API_SECRET = ForbiddenConfigAccess("LIVEKIT_API_SECRET")
MISTRAL_BASE_URL = ForbiddenConfigAccess("MISTRAL_BASE_URL")
VOSK_STT_URL = ForbiddenConfigAccess("VOSK_STT_URL")
REDIS_URL = ForbiddenConfigAccess("REDIS_URL")

# =====================================================
# FONCTIONS D'ACCÈS AUTORISÉES
# =====================================================

def get_livekit_config() -> dict:
    """Récupère la configuration LiveKit complète"""
    credentials = get_livekit_credentials()
    
    return {
        'url': get_docker_url('livekit'),
        'api_key': credentials['api_key'],
        'api_secret': credentials['api_secret']
    }

def get_services_urls() -> dict:
    """Récupère toutes les URLs de services"""
    return {
        'livekit': get_docker_url('livekit'),
        'mistral': get_docker_url('mistral'),
        'vosk': get_docker_url('vosk'),
        'redis': get_docker_url('redis')
    }

def get_agent_config() -> dict:
    """Récupère la configuration complète de l'agent"""
    return {
        'port': get_port('agent_http'),
        'livekit': get_livekit_config(),
        'services': get_services_urls()
    }

def get_multi_agent_ports() -> dict:
    """Récupère les ports des agents multi-agents"""
    multi_config = get_multi_agent_config()
    return multi_config.get('ports', {})

def get_multi_agent_metrics_ports() -> dict:
    """Récupère les ports de métriques des agents multi-agents"""
    multi_config = get_multi_agent_config()
    return multi_config.get('metrics_ports', {})

# Message de protection au chargement
logger.info("🔒 Configuration centralisée chargée - Protection active")
