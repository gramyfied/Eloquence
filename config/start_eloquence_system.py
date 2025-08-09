#!/usr/bin/env python3
"""
Script de Démarrage Final du Système Eloquence
Regénère tous les fichiers de configuration et lance le système
"""

import subprocess
import sys
import time
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class EloquenceSystemStarter:
    def __init__(self):
        self.project_root = self._find_project_root()
        
    def _find_project_root(self) -> Path:
        """Trouve la racine du projet Eloquence"""
        current = Path.cwd()
        while current != current.parent:
            if (current / "config" / "eloquence.config.yaml").exists():
                return current
            current = current.parent
        raise FileNotFoundError("Racine du projet Eloquence non trouvée")
    
    def regenerate_all_configs(self):
        """Regénère tous les fichiers de configuration"""
        logger.info("🔄 Régénération de tous les fichiers de configuration...")
        
        try:
            # Régénérer docker-compose.yml et .env
            logger.info("📦 Régénération docker-compose.yml et .env...")
            subprocess.run([
                sys.executable, "config_generator.py"
            ], cwd=self.project_root / "config", check=True)
            
            # Régénérer haproxy.cfg
            logger.info("🌐 Régénération haproxy.cfg...")
            subprocess.run([
                sys.executable, "haproxy_generator.py"
            ], cwd=self.project_root / "config", check=True)
            
            # Régénérer livekit.yaml
            logger.info("🎤 Régénération livekit.yaml...")
            subprocess.run([
                sys.executable, "config_generator.py"
            ], cwd=self.project_root / "config", check=True)
            
            logger.info("✅ Tous les fichiers de configuration ont été régénérés")
            
        except subprocess.CalledProcessError as e:
            logger.error(f"❌ Erreur lors de la régénération: {e}")
            return False
        
        return True
    
    def validate_system(self):
        """Valide que le système est prêt"""
        logger.info("🔍 Validation du système...")
        
        try:
            result = subprocess.run([
                sys.executable, "validate_centralized_config.py"
            ], cwd=self.project_root / "config", 
               capture_output=True, text=True, check=True)
            
            if "SCORE GLOBAL: 100.0%" in result.stdout:
                logger.info("🎉 Système validé avec succès (100%)")
                return True
            else:
                logger.warning("⚠️ Système partiellement validé")
                return False
                
        except subprocess.CalledProcessError as e:
            logger.error(f"❌ Erreur lors de la validation: {e}")
            return False
    
    def show_system_status(self):
        """Affiche le statut du système"""
        logger.info("📊 STATUT DU SYSTÈME ELOQUENCE")
        logger.info("=" * 50)
        
        # Vérifier les fichiers de configuration
        config_files = [
            "docker-compose.yml",
            ".env",
            "livekit.yaml",
            "services/haproxy/haproxy.cfg"
        ]
        
        for config_file in config_files:
            file_path = self.project_root / config_file
            if file_path.exists():
                logger.info(f"✅ {config_file}")
            else:
                logger.warning(f"❌ {config_file} - MANQUANT")
        
        # Vérifier la configuration centralisée
        config_path = self.project_root / "config" / "eloquence.config.yaml"
        if config_path.exists():
            logger.info("✅ Configuration centralisée (eloquence.config.yaml)")
        else:
            logger.error("❌ Configuration centralisée manquante")
        
        logger.info("=" * 50)
    
    def start_services(self):
        """Démarre les services Docker"""
        logger.info("🚀 Démarrage des services Docker...")
        
        try:
            # Démarrer les services
            subprocess.run([
                "docker-compose", "up", "-d"
            ], cwd=self.project_root, check=True)
            
            logger.info("✅ Services démarrés avec succès")
            
            # Attendre un peu et vérifier le statut
            time.sleep(5)
            subprocess.run([
                "docker-compose", "ps"
            ], cwd=self.project_root)
            
        except subprocess.CalledProcessError as e:
            logger.error(f"❌ Erreur lors du démarrage des services: {e}")
            return False
        except FileNotFoundError:
            logger.error("❌ Docker ou docker-compose non installé")
            return False
        
        return True
    
    def run_full_startup(self):
        """Exécute le démarrage complet du système"""
        logger.info("🚀 DÉMARRAGE COMPLET DU SYSTÈME ELOQUENCE")
        logger.info("=" * 60)
        
        # Étape 1: Régénération des configurations
        if not self.regenerate_all_configs():
            logger.error("❌ Échec de la régénération des configurations")
            return False
        
        # Étape 2: Validation du système
        if not self.validate_system():
            logger.warning("⚠️ Système non validé à 100%")
        
        # Étape 3: Affichage du statut
        self.show_system_status()
        
        # Étape 4: Démarrage des services (optionnel)
        start_services = input("\n🤔 Voulez-vous démarrer les services Docker maintenant ? (o/n): ").lower().strip()
        
        if start_services in ['o', 'oui', 'y', 'yes']:
            if self.start_services():
                logger.info("🎉 Système Eloquence démarré avec succès !")
            else:
                logger.error("❌ Échec du démarrage des services")
        else:
            logger.info("ℹ️ Services non démarrés. Utilisez 'docker-compose up -d' pour les démarrer manuellement.")
        
        logger.info("=" * 60)
        logger.info("🎯 SYSTÈME PRÊT - Configuration centralisée active")
        logger.info("📁 Fichier maître: config/eloquence.config.yaml")
        logger.info("🔒 Protection active contre les modifications non autorisées")
        
        return True

if __name__ == "__main__":
    starter = EloquenceSystemStarter()
    starter.run_full_startup()
