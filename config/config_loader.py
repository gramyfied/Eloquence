"""
Chargeur de configuration centralisée pour Eloquence
SEULE interface autorisée pour accéder à la configuration
"""
import yaml
import os
import sys
from typing import Dict, Any, Optional
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class EloquenceConfigError(Exception):
    """Erreur de configuration Eloquence"""
    pass

class ConfigLoader:
    """Chargeur de configuration centralisée - SINGLETON"""
    
    _instance = None
    _config = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ConfigLoader, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        if self._config is None:
            self._load_config()
    
    def _find_config_file(self) -> Path:
        """Trouve le fichier de configuration maître"""
        current_dir = Path.cwd()
        
        for parent in [current_dir] + list(current_dir.parents):
            config_file = parent / "config" / "eloquence.config.yaml"
            if config_file.exists():
                return config_file
        
        raise EloquenceConfigError(
            "❌ ERREUR FATALE: Fichier de configuration maître introuvable\n"
            "Fichier requis: config/eloquence.config.yaml"
        )
    
    def _load_config(self):
        """Charge la configuration maître"""
        try:
            config_file_path = self._find_config_file()
            
            with open(config_file_path, 'r', encoding='utf-8') as f:
                self._config = yaml.safe_load(f)
            
            if 'eloquence_config' not in self._config:
                raise EloquenceConfigError("Configuration invalide: clé 'eloquence_config' manquante")
            
            self._config = self._config['eloquence_config']
            logger.info(f"✅ Configuration chargée depuis: {config_file_path}")
            
        except Exception as e:
            raise EloquenceConfigError(f"❌ ERREUR FATALE: {e}")
    
    def get_port(self, service_name: str) -> int:
        """Récupère un port de service (SEULE méthode autorisée)"""
        try:
            return self._config['network']['ports'][service_name]
        except KeyError:
            raise EloquenceConfigError(f"Port non défini: {service_name}")
    
    def get_docker_url(self, service_name: str) -> str:
        """Récupère une URL Docker (SEULE méthode autorisée)"""
        try:
            return self._config['urls']['docker'][service_name]
        except KeyError:
            raise EloquenceConfigError(f"URL Docker non définie: {service_name}")
    
    def get_external_url(self, service_name: str) -> str:
        """Récupère une URL externe (SEULE méthode autorisée)"""
        try:
            return self._config['urls']['external'][service_name]
        except KeyError:
            raise EloquenceConfigError(f"URL externe non définie: {service_name}")
    
    def get_livekit_credentials(self) -> Dict[str, str]:
        """Récupère les credentials LiveKit"""
        return self._config['security']['livekit']
    
    def get_multi_agent_config(self) -> Dict[str, Any]:
        """Récupère la configuration multi-agents"""
        return self._config.get('multi_agent', {})
    
    def get_full_config(self) -> Dict[str, Any]:
        """Récupère la configuration complète"""
        return self._config.copy()

# Instance globale singleton
_config_loader = ConfigLoader()

# =====================================================
# FONCTIONS D'ACCÈS PUBLIQUES (SEULES AUTORISÉES)
# =====================================================

def get_port(service_name: str) -> int:
    """Récupère un port - SEULE FONCTION AUTORISÉE"""
    return _config_loader.get_port(service_name)

def get_docker_url(service_name: str) -> str:
    """Récupère une URL Docker - SEULE FONCTION AUTORISÉE"""
    return _config_loader.get_docker_url(service_name)

def get_external_url(service_name: str) -> str:
    """Récupère une URL externe - SEULE FONCTION AUTORISÉE"""
    return _config_loader.get_external_url(service_name)

def get_livekit_credentials() -> Dict[str, str]:
    """Récupère les credentials LiveKit"""
    return _config_loader.get_livekit_credentials()

def get_multi_agent_config() -> Dict[str, Any]:
    """Récupère la configuration multi-agents"""
    return _config_loader.get_multi_agent_config()
