"""
Gestionnaire de configuration principal pour Eloquence
Interface unifiée pour gérer toute la configuration du système
"""
import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional, List
import logging
import subprocess
import shutil

# Ajouter le répertoire config au path
config_dir = Path(__file__).parent
if str(config_dir) not in sys.path:
    sys.path.insert(0, str(config_dir))

from config_loader import ConfigLoader, EloquenceConfigError
from config_validator import ConfigValidator
from config_generator import ConfigGenerator

logger = logging.getLogger(__name__)

class ConfigManager:
    """Gestionnaire principal de configuration Eloquence"""
    
    def __init__(self):
        self.config_loader = ConfigLoader()
        self.config = self.config_loader.get_full_config()
        self.project_root = self._find_project_root()
        self.validator = ConfigValidator()
        self.generator = ConfigGenerator()
        
        # État de la configuration
        self._config_files = {}
        self._backup_dir = None
        
    def _find_project_root(self) -> Path:
        """Trouve la racine du projet"""
        current_dir = Path.cwd()
        
        for parent in [current_dir] + list(current_dir.parents):
            if (parent / "config" / "eloquence.config.yaml").exists():
                return parent
        
        raise EloquenceConfigError("Racine du projet introuvable")
    
    def get_project_root(self) -> Path:
        """Retourne la racine du projet"""
        return self.project_root
    
    def get_config_summary(self) -> Dict[str, Any]:
        """Retourne un résumé de la configuration actuelle"""
        return {
            'version': self.config.get('version', 'N/A'),
            'environment': self.config.get('environment', 'N/A'),
            'network': {
                'domain': self.config['network']['domain'],
                'ports_count': len(self.config['network']['ports']),
                'rtc_range': self.config['network']['rtc_port_range']
            },
            'services': {
                'enabled': len([s for s in self.config['services'].values() if s.get('enabled', True)]),
                'total': len(self.config['services'])
            },
            'multi_agent': {
                'enabled': self.config.get('multi_agent', {}).get('enabled', False),
                'instances': self.config.get('multi_agent', {}).get('instances', 0)
            }
        }
    
    def validate_configuration(self) -> tuple[bool, list[str], list[str]]:
        """Valide la configuration complète"""
        logger.info("🔍 Validation de la configuration...")
        return self.validator.validate_all()
    
    def generate_config_files(self, force: bool = False) -> Dict[str, bool]:
        """Génère tous les fichiers de configuration dérivés"""
        logger.info("🔄 Génération des fichiers de configuration...")
        
        results = {}
        
        try:
            # Vérifier si les fichiers existent déjà
            existing_files = {
                'docker-compose.yml': self.project_root / "docker-compose.yml",
                '.env': self.project_root / ".env",
                'livekit.yaml': self.project_root / "livekit.yaml"
            }
            
            if not force:
                for name, path in existing_files.items():
                    if path.exists():
                        logger.warning(f"⚠️ {name} existe déjà. Utiliser force=True pour régénérer")
                        results[name] = False
                        continue
            
            # Générer tous les fichiers
            self.generator.generate_all_files()
            
            # Vérifier la génération
            for name, path in existing_files.items():
                results[name] = path.exists()
                if results[name]:
                    logger.info(f"✅ {name} généré avec succès")
                else:
                    logger.error(f"❌ Échec de génération de {name}")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la génération: {e}")
            raise EloquenceConfigError(f"Échec de génération: {e}")
        
        return results
    
    def backup_configuration(self) -> Path:
        """Crée une sauvegarde de la configuration actuelle"""
        logger.info("💾 Création d'une sauvegarde de configuration...")
        
        # Créer le répertoire de sauvegarde
        timestamp = self._get_timestamp()
        backup_dir = self.project_root / "config_backup" / f"backup_{timestamp}"
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Sauvegarder les fichiers de configuration
        files_to_backup = [
            "config/eloquence.config.yaml",
            "docker-compose.yml",
            ".env",
            "livekit.yaml"
        ]
        
        for file_path in files_to_backup:
            source = self.project_root / file_path
            if source.exists():
                dest = backup_dir / Path(file_path).name
                shutil.copy2(source, dest)
                logger.info(f"✅ Sauvegardé: {file_path}")
        
        self._backup_dir = backup_dir
        logger.info(f"💾 Sauvegarde créée: {backup_dir}")
        
        return backup_dir
    
    def restore_configuration(self, backup_path: str) -> bool:
        """Restaure une configuration depuis une sauvegarde"""
        logger.info(f"🔄 Restauration depuis: {backup_path}")
        
        backup_dir = Path(backup_path)
        if not backup_dir.exists():
            raise EloquenceConfigError(f"Sauvegarde introuvable: {backup_path}")
        
        try:
            # Restaurer les fichiers
            files_to_restore = [
                "eloquence.config.yaml",
                "docker-compose.yml",
                ".env",
                "livekit.yaml"
            ]
            
            for filename in files_to_restore:
                source = backup_dir / filename
                if source.exists():
                    if filename == "eloquence.config.yaml":
                        dest = self.project_root / "config" / filename
                    else:
                        dest = self.project_root / filename
                    
                    shutil.copy2(source, dest)
                    logger.info(f"✅ Restauré: {filename}")
            
            # Recharger la configuration
            self.config_loader = ConfigLoader()
            self.config = self.config_loader.get_full_config()
            
            logger.info("✅ Configuration restaurée avec succès")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la restauration: {e}")
            raise EloquenceConfigError(f"Échec de restauration: {e}")
    
    def check_service_status(self) -> Dict[str, Dict[str, Any]]:
        """Vérifie le statut des services Docker"""
        logger.info("🔍 Vérification du statut des services...")
        
        status = {}
        
        try:
            # Vérifier si Docker est en cours d'exécution
            result = subprocess.run(
                ["docker", "info"], 
                capture_output=True, 
                text=True, 
                timeout=10
            )
            
            if result.returncode != 0:
                logger.warning("⚠️ Docker n'est pas accessible")
                return {"docker": {"status": "unavailable", "error": "Docker non accessible"}}
            
            # Vérifier les services
            services = self.config['services']
            for service_name, service_config in services.items():
                if not service_config.get('enabled', True):
                    continue
                
                container_name = self._get_container_name(service_name)
                service_status = self._check_container_status(container_name)
                status[service_name] = service_status
            
            # Vérifier les agents multi-agents
            multi_agent = self.config.get('multi_agent', {})
            if multi_agent.get('enabled', False):
                for i in range(1, multi_agent['instances'] + 1):
                    agent_name = f"livekit-agent-{i}"
                    agent_status = self._check_container_status(agent_name)
                    status[agent_name] = agent_status
            
        except subprocess.TimeoutExpired:
            logger.error("❌ Timeout lors de la vérification Docker")
            status["error"] = "Timeout Docker"
        except Exception as e:
            logger.error(f"❌ Erreur lors de la vérification: {e}")
            status["error"] = str(e)
        
        return status
    
    def _get_container_name(self, service_name: str) -> str:
        """Retourne le nom du conteneur Docker pour un service"""
        container_names = {
            'livekit_server': 'livekit-server',
            'livekit_agent': 'livekit-agent',
            'redis': 'eloquence-redis',
            'haproxy': 'haproxy',
            'mistral_api': 'mistral-conversation',
            'vosk_stt': 'vosk-stt-analysis'
        }
        
        return container_names.get(service_name, service_name)
    
    def _check_container_status(self, container_name: str) -> Dict[str, Any]:
        """Vérifie le statut d'un conteneur Docker spécifique"""
        try:
            result = subprocess.run(
                ["docker", "ps", "--filter", f"name={container_name}", "--format", "{{.Status}}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0 and result.stdout.strip():
                status_line = result.stdout.strip()
                return {
                    "status": "running",
                    "details": status_line,
                    "healthy": "healthy" in status_line.lower()
                }
            else:
                return {"status": "stopped", "details": "Conteneur non trouvé"}
                
        except Exception as e:
            return {"status": "error", "details": str(e)}
    
    def _get_timestamp(self) -> str:
        """Génère un timestamp pour les sauvegardes"""
        from datetime import datetime
        return datetime.now().strftime("%Y%m%d_%H%M%S")
    
    def get_network_info(self) -> Dict[str, Any]:
        """Retourne les informations réseau détaillées"""
        network = self.config['network']
        
        return {
            'domain': network['domain'],
            'ports': network['ports'],
            'rtc_range': network['rtc_port_range'],
            'docker_network': network['docker_network'],
            'urls': {
                'docker': self.config['urls']['docker'],
                'external': self.config['urls']['external']
            }
        }
    
    def update_config_value(self, path: str, value: Any) -> bool:
        """Met à jour une valeur de configuration spécifique"""
        logger.info(f"🔄 Mise à jour de la configuration: {path} = {value}")
        
        try:
            # Charger le fichier YAML
            config_file = self.project_root / "config" / "eloquence.config.yaml"
            with open(config_file, 'r', encoding='utf-8') as f:
                config_data = yaml.safe_load(f)
            
            # Naviguer vers le chemin spécifié
            keys = path.split('.')
            current = config_data['eloquence_config']
            
            for key in keys[:-1]:
                if key not in current:
                    current[key] = {}
                current = current[key]
            
            # Mettre à jour la valeur
            current[keys[-1]] = value
            
            # Sauvegarder
            with open(config_file, 'w', encoding='utf-8') as f:
                yaml.dump(config_data, f, default_flow_style=False, sort_keys=False)
            
            # Recharger la configuration
            self.config_loader = ConfigLoader()
            self.config = self.config_loader.get_full_config()
            
            logger.info(f"✅ Configuration mise à jour: {path}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la mise à jour: {e}")
            return False
    
    def export_config_schema(self) -> Dict[str, Any]:
        """Exporte le schéma de configuration pour documentation"""
        return {
            'version': '1.0.0',
            'description': 'Schéma de configuration Eloquence',
            'structure': self._generate_schema_structure(self.config),
            'required_fields': self._get_required_fields(),
            'examples': self._get_config_examples()
        }
    
    def _generate_schema_structure(self, config: Dict[str, Any], path: str = "") -> Dict[str, Any]:
        """Génère la structure du schéma de configuration"""
        schema = {}
        
        for key, value in config.items():
            current_path = f"{path}.{key}" if path else key
            
            if isinstance(value, dict):
                schema[key] = {
                    'type': 'object',
                    'path': current_path,
                    'properties': self._generate_schema_structure(value, current_path)
                }
            else:
                schema[key] = {
                    'type': type(value).__name__,
                    'path': current_path,
                    'example': value
                }
        
        return schema
    
    def _get_required_fields(self) -> List[str]:
        """Retourne la liste des champs requis"""
        return [
            'network.ports.livekit_server',
            'network.ports.redis',
            'services.livekit_server.enabled',
            'services.redis.enabled',
            'security.livekit.api_key',
            'security.livekit.api_secret'
        ]
    
    def _get_config_examples(self) -> Dict[str, Any]:
        """Retourne des exemples de configuration"""
        return {
            'network_ports': {
                'livekit_server': 7880,
                'redis': 6379,
                'agent_http': 8080
            },
            'rtc_range': {
                'start': 40000,
                'end': 40100
            },
            'service_config': {
                'enabled': True,
                'internal_host': 'service-name',
                'external_host': 'localhost'
            }
        }

# Instance globale
config_manager = ConfigManager()

# =====================================================
# FONCTIONS D'ACCÈS PUBLIQUES
# =====================================================

def get_config_manager() -> ConfigManager:
    """Retourne l'instance du gestionnaire de configuration"""
    return config_manager

def validate_and_generate() -> bool:
    """Valide et génère la configuration en une seule opération"""
    try:
        # Valider
        is_valid, errors, warnings = config_manager.validate_configuration()
        
        if not is_valid:
            logger.error("❌ Configuration invalide, impossible de générer les fichiers")
            return False
        
        # Générer
        results = config_manager.generate_config_files()
        
        return all(results.values())
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la validation/génération: {e}")
        return False

if __name__ == "__main__":
    # Test du gestionnaire
    try:
        manager = get_config_manager()
        
        print("🔍 Résumé de la configuration:")
        summary = manager.get_config_summary()
        for key, value in summary.items():
            print(f"  {key}: {value}")
        
        print("\n🔍 Validation de la configuration:")
        is_valid, errors, warnings = manager.validate_configuration()
        
        if is_valid:
            print("✅ Configuration valide!")
            
            print("\n🔄 Génération des fichiers...")
            results = manager.generate_config_files()
            for file_name, success in results.items():
                status = "✅" if success else "❌"
                print(f"  {status} {file_name}")
        else:
            print("❌ Configuration invalide:")
            for error in errors:
                print(f"  {error}")
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
