#!/usr/bin/env python3
"""
Générateur de configuration HAProxy pour Eloquence
Utilise la configuration centralisée pour éviter les ports hardcodés
"""

import yaml
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HAProxyConfigGenerator:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.config = self._load_config()
    
    def _find_project_root(self) -> Path:
        """Trouve la racine du projet Eloquence"""
        current = Path.cwd()
        while current != current.parent:
            if (current / "config" / "eloquence.config.yaml").exists():
                return current
            current = current.parent
        raise FileNotFoundError("Racine du projet Eloquence non trouvée")
    
    def _load_config(self) -> dict:
        """Charge la configuration centralisée"""
        config_path = self.project_root / "config" / "eloquence.config.yaml"
        with open(config_path, 'r', encoding='utf-8') as f:
            config_data = yaml.safe_load(f)
        return config_data['eloquence_config']
    
    def generate_haproxy_config(self) -> str:
        """Génère la configuration HAProxy depuis la configuration centralisée"""
        network_config = self.config['network']
        multi_agent_config = self.config['multi_agent']
        
        config_lines = [
            "# =====================================================",
            "# CONFIGURATION HAPROXY GÉNÉRÉE AUTOMATIQUEMENT",
            "# =====================================================",
            "# ATTENTION: Ce fichier est généré automatiquement",
            "# Ne pas modifier - Utiliser config/eloquence.config.yaml",
            "# =====================================================",
            "",
            "global",
            "    log stdout local0",
            "    maxconn 4096",
            "    daemon",
            "",
            "defaults",
            "    mode http",
            "    log global",
            "    option httplog",
            "    option dontlognull",
            "    timeout connect 5000ms",
            "    timeout client 50000ms",
            "    timeout server 50000ms",
            "    stats enable",
            "    stats uri /stats",
            "    stats refresh 30s",
            "",
            "# Frontend pour les agents LiveKit",
            f"frontend livekit_agents",
            f"    bind *:{network_config['ports']['haproxy']}",
            "    mode http",
            "    option forwardfor",
            "",
            "    # Routing basé sur les headers",
            "    acl is_health_check path /health",
            "    acl is_metrics path /metrics",
            "    acl is_agent_api path_beg /api/agent",
            "",
            "    # Utiliser le backend approprié",
            "    use_backend agents_health if is_health_check",
            "    use_backend agents_metrics if is_metrics",
            "    default_backend agents_pool",
            "",
            "# Backend pool d'agents avec load balancing",
            "backend agents_pool",
            "    mode http",
            "    balance roundrobin",
            "    option httpchk GET /health",
            ""
        ]
        
        # Ajouter les agents dynamiquement
        for i in range(1, multi_agent_config['instances'] + 1):
            agent_port = multi_agent_config['ports'][f'agent_{i}']
            config_lines.append(f"    server agent{i} livekit-agent-{i}:{network_config['ports']['agent_http']} check inter 5s rise 2 fall 3")
        
        config_lines.extend([
            "",
            "# Backend pour health checks",
            "backend agents_health",
            "    mode http"
        ])
        
        for i in range(1, multi_agent_config['instances'] + 1):
            config_lines.append(f"    server agent{i} livekit-agent-{i}:{network_config['ports']['agent_http']}")
        
        config_lines.extend([
            "",
            "# Backend pour métriques Prometheus",
            "backend agents_metrics",
            "    mode http"
        ])
        
        for i in range(1, multi_agent_config['instances'] + 1):
            metrics_port = multi_agent_config['metrics_ports'][f'agent_{i}']
            config_lines.append(f"    server agent{i}_metrics livekit-agent-{i}:{metrics_port}")
        
        return "\n".join(config_lines)
    
    def generate_config_file(self):
        """Génère le fichier de configuration HAProxy"""
        config_content = self.generate_haproxy_config()
        config_path = self.project_root / "services" / "haproxy" / "haproxy.cfg"
        
        with open(config_path, 'w', encoding='utf-8') as f:
            f.write(config_content)
        
        logger.info(f"✅ Configuration HAProxy générée: {config_path}")

if __name__ == "__main__":
    generator = HAProxyConfigGenerator()
    generator.generate_config_file()
