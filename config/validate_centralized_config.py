#!/usr/bin/env python3
"""
Validateur de Configuration Centralisée Eloquence
Vérifie que tous les composants utilisent la configuration centralisée
"""

import yaml
import os
import re
from pathlib import Path
from typing import List, Dict, Any
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class CentralizedConfigValidator:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.config = self._load_config()
        self.violations = []
        self.warnings = []
        
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
    
    def validate_file_headers(self) -> Dict[str, bool]:
        """Vérifie que les fichiers générés ont les bons headers de protection"""
        logger.info("🔍 Validation des headers de protection...")
        
        files_to_check = [
            "docker-compose.yml",
            "livekit.yaml",
            "services/haproxy/haproxy.cfg"
        ]
        
        results = {}
        for file_path in files_to_check:
            full_path = self.project_root / file_path
            if full_path.exists():
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                has_protection = (
                    "FICHIER GÉNÉRÉ AUTOMATIQUEMENT" in content or
                    "CONFIGURATION GÉNÉRÉE AUTOMATIQUEMENT" in content or
                    "Ce fichier est généré automatiquement" in content
                )
                results[file_path] = has_protection
                
                if has_protection:
                    logger.info(f"✅ {file_path}: Header de protection présent")
                else:
                    logger.warning(f"⚠️ {file_path}: Header de protection manquant")
                    self.warnings.append(f"Header de protection manquant dans {file_path}")
            else:
                results[file_path] = False
                logger.warning(f"⚠️ {file_path}: Fichier non trouvé")
        
        return results
    
    def scan_for_hardcoded_ports(self) -> List[str]:
        """Scanne le code pour détecter les ports hardcodés"""
        logger.info("🔍 Scan pour ports hardcodés...")
        
        hardcoded_ports = []
        port_pattern = r':(7[8][8][01]|8[0][01][0-9]|9[0][01][0-9])'
        
        # Fichiers à scanner
        scan_dirs = [
            "services",
            "frontend",
            "scripts",
            "tools"
        ]
        
        for scan_dir in scan_dirs:
            scan_path = self.project_root / scan_dir
            if not scan_path.exists():
                continue
                
            for file_path in scan_path.rglob("*.py"):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    matches = re.finditer(port_pattern, content)
                    for match in matches:
                        hardcoded_ports.append(f"{file_path}:{match.group()}")
                        
                except Exception as e:
                    logger.warning(f"Erreur lecture {file_path}: {e}")
        
        if hardcoded_ports:
            logger.warning(f"⚠️ {len(hardcoded_ports)} ports hardcodés détectés")
            for port in hardcoded_ports:
                logger.warning(f"   {port}")
                self.violations.append(f"Port hardcodé: {port}")
        else:
            logger.info("✅ Aucun port hardcodé détecté")
        
        return hardcoded_ports
    
    def scan_for_hardcoded_urls(self) -> List[str]:
        """Scanne le code pour détecter les URLs hardcodées"""
        logger.info("🔍 Scan pour URLs hardcodées...")
        
        hardcoded_urls = []
        url_patterns = [
            r'ws://localhost:7[8][8][01]',
            r'http://localhost:8[0][01][0-9]',
            r'redis://localhost:6379'
        ]
        
        # Fichiers à scanner
        scan_dirs = [
            "services",
            "frontend",
            "scripts",
            "tools"
        ]
        
        for scan_dir in scan_dirs:
            scan_path = self.project_root / scan_dir
            if not scan_path.exists():
                continue
                
            for file_path in scan_path.rglob("*.py"):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    for pattern in url_patterns:
                        matches = re.finditer(pattern, content)
                        for match in matches:
                            hardcoded_urls.append(f"{file_path}:{match.group()}")
                        
                except Exception as e:
                    logger.warning(f"Erreur lecture {file_path}: {e}")
        
        if hardcoded_urls:
            logger.warning(f"⚠️ {len(hardcoded_urls)} URLs hardcodées détectées")
            for url in hardcoded_urls:
                logger.warning(f"   {url}")
                self.violations.append(f"URL hardcodée: {url}")
        else:
            logger.info("✅ Aucune URL hardcodée détectée")
        
        return hardcoded_urls
    
    def validate_config_usage(self) -> Dict[str, bool]:
        """Vérifie que les services utilisent la configuration centralisée"""
        logger.info("🔍 Validation de l'utilisation de la configuration centralisée...")
        
        services_to_check = [
            "services/livekit-agent/main.py",
            "services/livekit-agent/config_client.py"
        ]
        
        results = {}
        for service_path in services_to_check:
            full_path = self.project_root / service_path
            if full_path.exists():
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                uses_config = (
                    "from config_client import" in content or
                    "get_livekit_config" in content or
                    "get_agent_config" in content
                )
                results[service_path] = uses_config
                
                if uses_config:
                    logger.info(f"✅ {service_path}: Utilise la configuration centralisée")
                else:
                    logger.warning(f"⚠️ {service_path}: N'utilise pas la configuration centralisée")
                    self.warnings.append(f"Configuration centralisée non utilisée dans {service_path}")
            else:
                results[service_path] = False
                logger.warning(f"⚠️ {service_path}: Fichier non trouvé")
        
        return results
    
    def validate_config_structure(self) -> bool:
        """Valide la structure de la configuration centralisée"""
        logger.info("🔍 Validation de la structure de configuration...")
        
        required_sections = [
            'network.ports',
            'network.rtc_port_range',
            'services.livekit_server',
            'services.livekit_agent',
            'services.redis',
            'urls.docker',
            'urls.external',
            'security.livekit',
            'multi_agent'
        ]
        
        missing_sections = []
        for section in required_sections:
            keys = section.split('.')
            current = self.config
            try:
                for key in keys:
                    current = current[key]
            except KeyError:
                missing_sections.append(section)
        
        if missing_sections:
            logger.error(f"❌ Sections manquantes dans la configuration: {missing_sections}")
            return False
        else:
            logger.info("✅ Structure de configuration valide")
            return True
    
    def run_full_validation(self) -> Dict[str, Any]:
        """Exécute la validation complète"""
        logger.info("🚀 DÉMARRAGE DE LA VALIDATION COMPLÈTE")
        logger.info("=" * 50)
        
        results = {
            'headers_valid': self.validate_file_headers(),
            'no_hardcoded_ports': len(self.scan_for_hardcoded_ports()) == 0,
            'no_hardcoded_urls': len(self.scan_for_hardcoded_urls()) == 0,
            'config_usage_valid': self.validate_config_usage(),
            'config_structure_valid': self.validate_config_structure(),
            'violations': self.violations,
            'warnings': self.warnings
        }
        
        # Calcul du score global
        total_checks = 5
        passed_checks = sum([
            all(results['headers_valid'].values()),
            results['no_hardcoded_ports'],
            results['no_hardcoded_urls'],
            all(results['config_usage_valid'].values()),
            results['config_structure_valid']
        ])
        
        results['score_percentage'] = (passed_checks / total_checks) * 100
        
        # Affichage du rapport
        logger.info("=" * 50)
        logger.info("📊 RAPPORT DE VALIDATION")
        logger.info("=" * 50)
        
        logger.info(f"Headers de protection: {'✅' if all(results['headers_valid'].values()) else '❌'}")
        logger.info(f"Pas de ports hardcodés: {'✅' if results['no_hardcoded_ports'] else '❌'}")
        logger.info(f"Pas d'URLs hardcodées: {'✅' if results['no_hardcoded_urls'] else '❌'}")
        logger.info(f"Utilisation config centralisée: {'✅' if all(results['config_usage_valid'].values()) else '❌'}")
        logger.info(f"Structure config valide: {'✅' if results['config_structure_valid'] else '❌'}")
        
        logger.info(f"\n🎯 SCORE GLOBAL: {results['score_percentage']:.1f}%")
        
        if self.violations:
            logger.warning(f"\n🚨 VIOLATIONS DÉTECTÉES ({len(self.violations)}):")
            for violation in self.violations:
                logger.warning(f"   • {violation}")
        
        if self.warnings:
            logger.warning(f"\n⚠️ AVERTISSEMENTS ({len(self.warnings)}):")
            for warning in self.warnings:
                logger.warning(f"   • {warning}")
        
        if results['score_percentage'] >= 90:
            logger.info("\n🎉 CONFIGURATION CENTRALISÉE VALIDÉE AVEC SUCCÈS!")
        elif results['score_percentage'] >= 70:
            logger.warning("\n⚠️ CONFIGURATION PARTIELLEMENT VALIDÉE - Améliorations recommandées")
        else:
            logger.error("\n❌ CONFIGURATION NON VALIDÉE - Corrections nécessaires")
        
        return results

if __name__ == "__main__":
    validator = CentralizedConfigValidator()
    results = validator.run_full_validation()
