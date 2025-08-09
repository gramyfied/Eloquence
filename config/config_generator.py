"""
Générateur de fichiers de configuration dérivés
Génère automatiquement docker-compose.yml, .env, livekit.yaml
"""
import yaml
import os
from pathlib import Path
from config_loader import ConfigLoader
import logging

logger = logging.getLogger(__name__)

class ConfigGenerator:
    """Générateur de fichiers de configuration dérivés"""
    
    def __init__(self):
        self.config_loader = ConfigLoader()
        self.config = self.config_loader.get_full_config()
        self.project_root = self._find_project_root()
    
    def _find_project_root(self) -> Path:
        """Trouve la racine du projet"""
        current_dir = Path.cwd()
        
        for parent in [current_dir] + list(current_dir.parents):
            if (parent / "config" / "eloquence.config.yaml").exists():
                return parent
        
        raise Exception("Racine du projet introuvable")
    
    def generate_docker_compose(self) -> str:
        """Génère le fichier docker-compose.yml"""
        network_config = self.config['network']
        services_config = self.config['services']
        multi_agent_config = self.config.get('multi_agent', {})
        
        compose_config = {
            'version': '3.8',
            'services': {},
            'networks': {
                network_config['docker_network']: {
                    'driver': 'bridge'
                }
            }
        }
        
        # Service Redis
        compose_config['services']['eloquence-redis'] = {
            'image': services_config['redis']['image'],
            'restart': 'unless-stopped',
            'ports': [f"{network_config['ports']['redis']}:6379"],
            'networks': [network_config['docker_network']],
            'healthcheck': {
                'test': ["CMD", "redis-cli", "ping"],
                'interval': '10s',
                'timeout': '5s',
                'retries': 3
            }
        }
        
        # Service LiveKit Server
        livekit_ports = [
            f"{network_config['ports']['livekit_server']}:7880",
            f"{network_config['ports']['livekit_tcp']}:7881",
            f"{network_config['rtc_port_range']['start']}-{network_config['rtc_port_range']['end']}:{network_config['rtc_port_range']['start']}-{network_config['rtc_port_range']['end']}/udp"
        ]
        
        compose_config['services']['livekit-server'] = {
            'image': services_config['livekit_server']['image'],
            'restart': 'unless-stopped',
            'ports': livekit_ports,
            'networks': [network_config['docker_network']],
            'command': ['--config', '/app/livekit.yaml'],
            'volumes': ['./livekit.yaml:/app/livekit.yaml:ro'],
            'depends_on': {
                'eloquence-redis': {'condition': 'service_healthy'}
            },
            'healthcheck': {
                'test': ["CMD", "curl", "-f", "http://localhost:7880/"],
                'interval': '30s',
                'timeout': '10s',
                'retries': 3
            }
        }
        
        # Service HAProxy
        compose_config['services']['haproxy'] = {
            'image': services_config['haproxy']['image'],
            'restart': 'unless-stopped',
            'ports': [f"{network_config['ports']['haproxy']}:8080"],
            'networks': [network_config['docker_network']],
            'volumes': ['./services/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro'],
            'depends_on': [],
            'healthcheck': {
                'test': ["CMD", "curl", "-f", "http://localhost:8080/stats"],
                'interval': '30s',
                'timeout': '10s',
                'retries': 3
            }
        }
        
        # Services Multi-Agents
        if multi_agent_config.get('enabled', False):
            for i in range(1, multi_agent_config['instances'] + 1):
                agent_name = f"livekit-agent-{i}"
                agent_port = multi_agent_config['ports'][f'agent_{i}']
                metrics_port = multi_agent_config['metrics_ports'][f'agent_{i}']
                
                compose_config['services'][agent_name] = {
                    'build': {
                        'context': './services/livekit-agent',
                        'dockerfile': 'Dockerfile.multi'
                    },
                    'restart': 'unless-stopped',
                    'ports': [
                        f"{agent_port}:8080",
                        f"{metrics_port}:9091"
                    ],
                    'networks': [network_config['docker_network']],
                    'environment': [
                        f"AGENT_ID=agent_{i}",
                        f"AGENT_PORT=8080",
                        f"METRICS_PORT=9091",
                        f"LIVEKIT_URL={self.config['urls']['docker']['livekit']}",
                        f"LIVEKIT_API_KEY={self.config['security']['livekit']['api_key']}",
                        f"LIVEKIT_API_SECRET={self.config['security']['livekit']['api_secret']}",
                        f"REDIS_URL={self.config['urls']['docker']['redis']}",
                        f"VOSK_STT_URL={self.config['urls']['docker']['vosk']}",
                        f"MISTRAL_BASE_URL={self.config['urls']['docker']['mistral']}",
                        "AGENT_MODE=multi_agent",
                        "MAX_SESSIONS=3"
                    ],
                    'env_file': ['.env'],
                    'depends_on': {
                        'eloquence-redis': {'condition': 'service_healthy'},
                        'livekit-server': {'condition': 'service_started'}
                    },
                    'healthcheck': {
                        'test': ["CMD", "curl", "-f", "http://localhost:8080/health"],
                        'interval': '30s',
                        'timeout': '10s',
                        'retries': 3
                    }
                }
                
                # Ajouter la dépendance HAProxy
                compose_config['services']['haproxy']['depends_on'].append(agent_name)
        
        return yaml.dump(compose_config, default_flow_style=False, sort_keys=False)
    
    def generate_env_file(self) -> str:
        """Génère le fichier .env"""
        lines = [
            "# =====================================================",
            "# FICHIER .ENV GÉNÉRÉ AUTOMATIQUEMENT",
            "# =====================================================",
            "# ATTENTION: Ce fichier est généré automatiquement",
            "# Ne pas modifier - Utiliser config/eloquence.config.yaml",
            "",
            "# Configuration LiveKit",
            f"LIVEKIT_URL={self.config['urls']['external']['livekit']}",
            f"LIVEKIT_API_KEY={self.config['security']['livekit']['api_key']}",
            f"LIVEKIT_API_SECRET={self.config['security']['livekit']['api_secret']}",
            "",
            "# URLs des services",
            f"REDIS_URL={self.config['urls']['external']['redis']}",
            f"VOSK_STT_URL={self.config['urls']['external']['vosk']}",
            f"MISTRAL_BASE_URL={self.config['urls']['external']['mistral']}",
            "",
            "# OpenAI (à configurer manuellement)",
            "OPENAI_API_KEY=sk-proj-VOTRE_VRAIE_CLE_ICI"
        ]
        
        return "\n".join(lines)
    
    def generate_livekit_yaml(self) -> str:
        """Génère le fichier livekit.yaml"""
        network_config = self.config['network']
        security_config = self.config['security']['livekit']
        
        livekit_config = {
            'port': 7880,
            'log_level': 'info',
            'rtc': {
                'tcp_port': 7881,
                'port_range_start': network_config['rtc_port_range']['start'],
                'port_range_end': network_config['rtc_port_range']['end'],
                'use_external_ip': True
            },
            'redis': {
                'address': f"{self.config['services']['redis']['internal_host']}:6379"
            },
            'keys': {
                security_config['api_key']: security_config['api_secret']
            },
            'turn': {
                'enabled': True,
                'domain': network_config['domain']
            }
        }
        
        return yaml.dump(livekit_config, default_flow_style=False)
    
    def generate_all_files(self):
        """Génère tous les fichiers de configuration dérivés"""
        logger.info("🔄 Génération des fichiers de configuration dérivés...")
        
        # Header de protection
        protection_header = """# =====================================================
# FICHIER GÉNÉRÉ AUTOMATIQUEMENT
# =====================================================
# ATTENTION: Ce fichier est généré automatiquement
# Ne pas modifier - Utiliser config/eloquence.config.yaml
# =====================================================

"""
        
        # Générer docker-compose.yml
        docker_compose_content = self.generate_docker_compose()
        docker_compose_path = self.project_root / "docker-compose.yml"
        
        with open(docker_compose_path, 'w', encoding='utf-8') as f:
            f.write(protection_header + docker_compose_content)
        
        logger.info(f"✅ Généré: {docker_compose_path}")
        
        # Générer .env
        env_content = self.generate_env_file()
        env_path = self.project_root / ".env"
        
        with open(env_path, 'w', encoding='utf-8') as f:
            f.write(env_content)
        
        logger.info(f"✅ Généré: {env_path}")
        
        # Générer livekit.yaml
        livekit_content = self.generate_livekit_yaml()
        livekit_path = self.project_root / "livekit.yaml"
        
        with open(livekit_path, 'w', encoding='utf-8') as f:
            f.write(protection_header + livekit_content)
        
        logger.info(f"✅ Généré: {livekit_path}")
        
        logger.info("🎉 Tous les fichiers générés avec succès!")

if __name__ == "__main__":
    generator = ConfigGenerator()
    generator.generate_all_files()
