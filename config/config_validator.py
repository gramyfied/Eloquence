"""
Validateur de configuration pour Eloquence
Vérifie la cohérence et la validité de la configuration centralisée
"""
import yaml
from pathlib import Path
from typing import List, Dict, Any, Tuple
import logging

logger = logging.getLogger(__name__)

class ConfigValidationError(Exception):
    """Erreur de validation de configuration"""
    pass

class ConfigValidator:
    """Validateur de configuration centralisée"""
    
    def __init__(self, config_path: str = None):
        self.config_path = config_path or "config/eloquence.config.yaml"
        self.config = None
        self.errors = []
        self.warnings = []
    
    def load_config(self) -> bool:
        """Charge la configuration à valider"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                self.config = yaml.safe_load(f)
            
            if 'eloquence_config' not in self.config:
                self.errors.append("❌ Clé 'eloquence_config' manquante")
                return False
            
            self.config = self.config['eloquence_config']
            return True
            
        except Exception as e:
            self.errors.append(f"❌ Erreur de chargement: {e}")
            return False
    
    def validate_network_config(self) -> bool:
        """Valide la configuration réseau"""
        if 'network' not in self.config:
            self.errors.append("❌ Section 'network' manquante")
            return False
        
        network = self.config['network']
        
        # Vérifier les ports
        required_ports = [
            'livekit_server', 'livekit_tcp', 'agent_http', 
            'redis', 'mistral_api', 'vosk_stt'
        ]
        
        for port_name in required_ports:
            if port_name not in network.get('ports', {}):
                self.errors.append(f"❌ Port '{port_name}' manquant dans network.ports")
            else:
                port_value = network['ports'][port_name]
                if not isinstance(port_value, int) or port_value <= 0 or port_value > 65535:
                    self.errors.append(f"❌ Port '{port_name}' invalide: {port_value}")
        
        # Vérifier la plage RTC
        rtc_range = network.get('rtc_port_range', {})
        if 'start' not in rtc_range or 'end' not in rtc_range:
            self.errors.append("❌ Plage RTC manquante ou incomplète")
        else:
            start = rtc_range['start']
            end = rtc_range['end']
            if start >= end or start < 1024 or end > 65535:
                self.errors.append(f"❌ Plage RTC invalide: {start}-{end}")
        
        return len(self.errors) == 0
    
    def validate_services_config(self) -> bool:
        """Valide la configuration des services"""
        if 'services' not in self.config:
            self.errors.append("❌ Section 'services' manquante")
            return False
        
        services = self.config['services']
        required_services = ['livekit_server', 'livekit_agent', 'redis']
        
        for service_name in required_services:
            if service_name not in services:
                self.errors.append(f"❌ Service '{service_name}' manquant")
            else:
                service = services[service_name]
                if not service.get('enabled', True):
                    self.warnings.append(f"⚠️ Service '{service_name}' désactivé")
                
                if 'internal_host' not in service:
                    self.errors.append(f"❌ internal_host manquant pour '{service_name}'")
        
        return len(self.errors) == 0
    
    def validate_urls_config(self) -> bool:
        """Valide la configuration des URLs"""
        if 'urls' not in self.config:
            self.errors.append("❌ Section 'urls' manquante")
            return False
        
        urls = self.config['urls']
        
        # Vérifier les URLs Docker
        docker_urls = urls.get('docker', {})
        required_docker_urls = ['livekit', 'redis', 'mistral', 'vosk']
        
        for url_name in required_docker_urls:
            if url_name not in docker_urls:
                self.errors.append(f"❌ URL Docker '{url_name}' manquante")
        
        # Vérifier les URLs externes
        external_urls = urls.get('external', {})
        required_external_urls = ['livekit', 'redis', 'mistral', 'vosk']
        
        for url_name in required_external_urls:
            if url_name not in external_urls:
                self.errors.append(f"❌ URL externe '{url_name}' manquante")
        
        return len(self.errors) == 0
    
    def validate_security_config(self) -> bool:
        """Valide la configuration de sécurité"""
        if 'security' not in self.config:
            self.errors.append("❌ Section 'security' manquante")
            return False
        
        security = self.config['security']
        
        if 'livekit' not in security:
            self.errors.append("❌ Configuration LiveKit manquante")
            return False
        
        livekit = security['livekit']
        
        if 'api_key' not in livekit:
            self.errors.append("❌ API key LiveKit manquante")
        
        if 'api_secret' not in livekit:
            self.errors.append("❌ API secret LiveKit manquant")
        
        if 'api_secret' in livekit and len(livekit['api_secret']) < 32:
            self.warnings.append("⚠️ API secret LiveKit trop court (minimum 32 caractères)")
        
        return len(self.errors) == 0
    
    def validate_multi_agent_config(self) -> bool:
        """Valide la configuration multi-agents"""
        multi_agent = self.config.get('multi_agent', {})
        
        if multi_agent.get('enabled', False):
            if 'instances' not in multi_agent:
                self.errors.append("❌ Nombre d'instances multi-agents manquant")
            else:
                instances = multi_agent['instances']
                if not isinstance(instances, int) or instances <= 0 or instances > 10:
                    self.errors.append(f"❌ Nombre d'instances invalide: {instances}")
                
                # Vérifier les ports
                ports = multi_agent.get('ports', {})
                metrics_ports = multi_agent.get('metrics_ports', {})
                
                for i in range(1, instances + 1):
                    port_key = f'agent_{i}'
                    if port_key not in ports:
                        self.errors.append(f"❌ Port manquant pour agent {i}")
                    
                    metrics_key = f'agent_{i}'
                    if metrics_key not in metrics_ports:
                        self.errors.append(f"❌ Port métriques manquant pour agent {i}")
        
        return len(self.errors) == 0
    
    def validate_port_conflicts(self) -> bool:
        """Vérifie les conflits de ports"""
        if 'network' not in self.config:
            return False
        
        ports = self.config['network']['ports']
        port_values = list(ports.values())
        
        # Vérifier les doublons
        if len(port_values) != len(set(port_values)):
            duplicates = [p for p in set(port_values) if port_values.count(p) > 1]
            for dup in duplicates:
                self.errors.append(f"❌ Port dupliqué: {dup}")
        
        # Vérifier les conflits avec la plage RTC
        rtc_range = self.config['network'].get('rtc_port_range', {})
        if 'start' in rtc_range and 'end' in rtc_range:
            for port_name, port_value in ports.items():
                if rtc_range['start'] <= port_value <= rtc_range['end']:
                    self.errors.append(f"❌ Port '{port_name}' ({port_value}) en conflit avec la plage RTC")
        
        return len(self.errors) == 0
    
    def validate_all(self) -> Tuple[bool, List[str], List[str]]:
        """Valide toute la configuration"""
        logger.info("🔍 Début de la validation de configuration...")
        
        if not self.load_config():
            return False, self.errors, self.warnings
        
        # Validation des sections principales
        self.validate_network_config()
        self.validate_services_config()
        self.validate_urls_config()
        self.validate_security_config()
        self.validate_multi_agent_config()
        
        # Validation des conflits
        self.validate_port_conflicts()
        
        # Résumé
        is_valid = len(self.errors) == 0
        
        if is_valid:
            logger.info("✅ Configuration valide!")
        else:
            logger.error(f"❌ Configuration invalide avec {len(self.errors)} erreur(s)")
        
        if self.warnings:
            logger.warning(f"⚠️ {len(self.warnings)} avertissement(s)")
        
        return is_valid, self.errors, self.warnings
    
    def print_validation_report(self):
        """Affiche le rapport de validation"""
        is_valid, errors, warnings = self.validate_all()
        
        print("\n" + "="*60)
        print("🔍 RAPPORT DE VALIDATION DE CONFIGURATION ELOQUENCE")
        print("="*60)
        
        if is_valid:
            print("✅ CONFIGURATION VALIDE")
        else:
            print("❌ CONFIGURATION INVALIDE")
        
        if errors:
            print(f"\n🚨 ERREURS ({len(errors)}):")
            for error in errors:
                print(f"   {error}")
        
        if warnings:
            print(f"\n⚠️ AVERTISSEMENTS ({len(warnings)}):")
            for warning in warnings:
                print(f"   {warning}")
        
        if not errors and not warnings:
            print("\n🎉 Aucun problème détecté!")
        
        print("="*60)
        
        return is_valid

if __name__ == "__main__":
    validator = ConfigValidator()
    validator.print_validation_report()
