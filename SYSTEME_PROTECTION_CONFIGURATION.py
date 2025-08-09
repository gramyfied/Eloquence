#!/usr/bin/env python3
"""
🚨 SYSTÈME DE PROTECTION DE CONFIGURATION CENTRALISÉE ELOQUENCE 🚨

Ce système protège contre toute tentative de configuration hardcodée
et garantit que seul config/eloquence.config.yaml est utilisé.

FONCTIONS :
- Détection automatique des violations
- Messages d'avertissement détaillés
- Protection contre les modifications
- Validation de la cohérence
"""

import os
import sys
import re
import yaml
import logging
from pathlib import Path
from typing import List, Dict, Any, Set
import argparse

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ConfigurationProtector:
    """Système de protection de configuration centralisée"""
    
    def __init__(self):
        self.project_root = self._find_project_root()
        self.config_file = self.project_root / "config" / "eloquence.config.yaml"
        self.violations: List[Dict[str, Any]] = []
        
        # Patterns de détection des violations
        self.forbidden_patterns = {
            'ports_hardcoded': [
                r':\s*(7880|7881|8080|6379|8001|8002|8003|8081)\s*',
                r'port\s*=\s*(7880|7881|8080|6379|8001|8002|8003|8081)',
                r'PORT\s*=\s*(7880|7881|8080|6379|8001|8002|8003|8081)',
            ],
            'urls_hardcoded': [
                r'ws://localhost:7880',
                r'http://localhost:8080',
                r'http://mistral-conversation:8001',
                r'http://vosk-stt:8002',
                r'redis://eloquence-redis:6379',
            ],
            'env_vars_direct': [
                r'os\.getenv\(',
                r'os\.environ\[',
                r'os\.environ\.get\(',
            ],
            'config_files_modified': [
                r'docker-compose\.yml',
                r'\.env',
                r'livekit\.yaml',
            ]
        }
        
        # Fichiers à protéger
        self.protected_files = [
            'docker-compose.yml',
            '.env',
            'livekit.yaml',
            'docker-compose.all.yml'
        ]
        
        # Extensions de fichiers à scanner
        self.scannable_extensions = {
            '.py', '.yaml', '.yml', '.json', '.toml', '.ini', '.cfg',
            '.md', '.txt', '.sh', '.ps1', '.bat'
        }
    
    def _find_project_root(self) -> Path:
        """Trouve la racine du projet Eloquence"""
        current_dir = Path.cwd()
        
        for parent in [current_dir] + list(current_dir.parents):
            if (parent / "config" / "eloquence.config.yaml").exists():
                return parent
        
        raise FileNotFoundError(
            "❌ ERREUR FATALE: Projet Eloquence introuvable\n"
            "Assurez-vous d'être dans le répertoire du projet"
        )
    
    def scan_for_violations(self) -> bool:
        """Scanne le projet pour détecter les violations"""
        logger.info("🔍 SCAN DE PROTECTION EN COURS...")
        
        self.violations.clear()
        
        # Scanner tous les fichiers du projet
        for file_path in self._get_all_project_files():
            violations = self._scan_file(file_path)
            if violations:
                self.violations.extend(violations)
        
        # Vérifier les fichiers protégés
        self._check_protected_files()
        
        # Afficher le rapport
        self._display_violations_report()
        
        return len(self.violations) == 0
    
    def _get_all_project_files(self) -> List[Path]:
        """Récupère tous les fichiers du projet à scanner"""
        files = []
        
        # Répertoires à exclure
        exclude_dirs = {
            '__pycache__', '.git', '.vscode', '.idea', 'node_modules',
            'venv', 'env', '.env', 'build', 'dist', 'target'
        }
        
        for root, dirs, filenames in os.walk(self.project_root):
            # Exclure les répertoires non désirés
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for filename in filenames:
                file_path = Path(root) / filename
                
                # Scanner seulement les extensions pertinentes
                if file_path.suffix in self.scannable_extensions:
                    files.append(file_path)
        
        return files
    
    def _scan_file(self, file_path: Path) -> List[Dict[str, Any]]:
        """Scanne un fichier pour détecter les violations"""
        violations = []
        
        try:
            # Ignorer les fichiers de configuration eux-mêmes
            if file_path.name in ['eloquence.config.yaml', 'config_loader.py', 'config_client.py']:
                return violations
            
            # Ignorer les fichiers de sauvegarde
            if '.backup.' in file_path.name or file_path.suffix == '.backup':
                return violations
            
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                lines = content.split('\n')
            
            # Vérifier chaque pattern interdit
            for violation_type, patterns in self.forbidden_patterns.items():
                for pattern in patterns:
                    matches = re.finditer(pattern, content, re.IGNORECASE)
                    
                    for match in matches:
                        # Trouver la ligne correspondante
                        line_num = content[:match.start()].count('\n') + 1
                        line_content = lines[line_num - 1] if line_num <= len(lines) else "Ligne non trouvée"
                        
                        violation = {
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': line_num,
                            'type': violation_type,
                            'pattern': pattern,
                            'match': match.group(),
                            'line_content': line_content.strip(),
                            'severity': 'CRITICAL'
                        }
                        
                        violations.append(violation)
        
        except Exception as e:
            logger.warning(f"⚠️ Impossible de scanner {file_path}: {e}")
        
        return violations
    
    def _check_protected_files(self):
        """Vérifie que les fichiers protégés ne sont pas modifiés manuellement"""
        for protected_file in self.protected_files:
            file_path = self.project_root / protected_file
            
            if file_path.exists():
                # Vérifier si le fichier contient l'en-tête de protection
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if not content.startswith('# ====================================================='):
                        violation = {
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': 1,
                            'type': 'protected_file_modified',
                            'pattern': 'Fichier protégé modifié manuellement',
                            'match': 'Modification manuelle détectée',
                            'line_content': content[:100] + '...' if len(content) > 100 else content,
                            'severity': 'CRITICAL'
                        }
                        
                        self.violations.append(violation)
                
                except Exception as e:
                    logger.warning(f"⚠️ Impossible de vérifier {file_path}: {e}")
    
    def _display_violations_report(self):
        """Affiche le rapport des violations détectées"""
        if not self.violations:
            logger.info("🎉 AUCUNE VIOLATION DÉTECTÉE - Configuration sécurisée !")
            return
        
        logger.error(f"🚨 {len(self.violations)} VIOLATION(S) DÉTECTÉE(S) !")
        logger.error("=" * 80)
        
        # Grouper par type de violation
        violations_by_type = {}
        for violation in self.violations:
            violation_type = violation['type']
            if violation_type not in violations_by_type:
                violations_by_type[violation_type] = []
            violations_by_type[violation_type].append(violation)
        
        # Afficher par type
        for violation_type, violations in violations_by_type.items():
            logger.error(f"\n🔴 TYPE: {violation_type.upper()}")
            logger.error("-" * 40)
            
            for violation in violations:
                logger.error(f"📁 Fichier: {violation['file']}:{violation['line']}")
                logger.error(f"🚫 Violation: {violation['pattern']}")
                logger.error(f"📝 Ligne: {violation['line_content']}")
                logger.error("")
        
        # Afficher les solutions
        self._display_solutions()
    
    def _display_solutions(self):
        """Affiche les solutions pour corriger les violations"""
        logger.error("🔧 SOLUTIONS OBLIGATOIRES:")
        logger.error("=" * 80)
        
        logger.error("""
1. 🚫 SUPPRIMER toutes les configurations hardcodées :
   - Ports (7880, 8080, etc.)
   - URLs (ws://localhost:7880, etc.)
   - Variables d'environnement directes (os.getenv)

2. ✅ UTILISER UNIQUEMENT la configuration centralisée :
   from config_client import get_livekit_config, get_services_urls
   
3. 🔄 RÉGÉNÉRER les fichiers de configuration :
   cd config
   python config_generator.py

4. 🧪 TESTER la configuration :
   python SYSTEME_PROTECTION_CONFIGURATION.py
""")
    
    def create_protection_hooks(self):
        """Crée des hooks de protection Git pour empêcher les violations"""
        hooks_dir = self.project_root / ".git" / "hooks"
        
        if not hooks_dir.exists():
            logger.warning("⚠️ Répertoire .git/hooks non trouvé - Pas de hooks Git créés")
            return
        
        # Hook pre-commit
        pre_commit_hook = hooks_dir / "pre-commit"
        pre_commit_content = """#!/bin/sh
# Hook de protection de configuration Eloquence
# Empêche les commits avec des violations de configuration

echo "🔒 Vérification de la configuration centralisée..."

# Exécuter le système de protection
python SYSTEME_PROTECTION_CONFIGURATION.py

if [ $? -ne 0 ]; then
    echo "❌ VIOLATIONS DÉTECTÉES - Commit refusé !"
    echo "🔧 Corrigez les violations avant de commiter"
    exit 1
fi

echo "✅ Configuration sécurisée - Commit autorisé"
exit 0
"""
        
        with open(pre_commit_hook, 'w') as f:
            f.write(pre_commit_content)
        
        # Rendre le hook exécutable
        os.chmod(pre_commit_hook, 0o755)
        
        logger.info("✅ Hook pre-commit créé avec succès")
    
    def validate_configuration(self) -> bool:
        """Valide la configuration centralisée"""
        logger.info("🔍 VALIDATION DE LA CONFIGURATION CENTRALISÉE...")
        
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            
            if 'eloquence_config' not in config:
                logger.error("❌ Configuration invalide: clé 'eloquence_config' manquante")
                return False
            
            config = config['eloquence_config']
            
            # Vérifications obligatoires
            required_sections = ['network', 'services', 'urls', 'security']
            for section in required_sections:
                if section not in config:
                    logger.error(f"❌ Section manquante: {section}")
                    return False
            
            # Vérifier les ports
            ports = config['network']['ports']
            required_ports = ['livekit_server', 'livekit_tcp', 'agent_http', 'redis']
            for port_name in required_ports:
                if port_name not in ports:
                    logger.error(f"❌ Port manquant: {port_name}")
                    return False
            
            # Vérifier les services
            services = config['services']
            required_services = ['livekit_server', 'livekit_agent', 'redis']
            for service_name in required_services:
                if service_name not in services:
                    logger.error(f"❌ Service manquant: {service_name}")
                    return False
            
            logger.info("✅ Configuration centralisée valide")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erreur de validation: {e}")
            return False
    
    def generate_config_files(self):
        """Génère les fichiers de configuration dérivés"""
        logger.info("🔄 GÉNÉRATION DES FICHIERS DE CONFIGURATION...")
        
        try:
            # Importer et exécuter le générateur
            sys.path.insert(0, str(self.project_root / "config"))
            from config_generator import ConfigGenerator
            
            generator = ConfigGenerator()
            generator.generate_all_files()
            
            logger.info("✅ Fichiers de configuration générés avec succès")
            
        except Exception as e:
            logger.error(f"❌ Erreur de génération: {e}")
            raise

def main():
    """Point d'entrée principal"""
    parser = argparse.ArgumentParser(
        description="Système de protection de configuration centralisée Eloquence"
    )
    
    parser.add_argument(
        '--scan', 
        action='store_true',
        help='Scanner le projet pour détecter les violations'
    )
    
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Valider la configuration centralisée'
    )
    
    parser.add_argument(
        '--generate',
        action='store_true',
        help='Générer les fichiers de configuration dérivés'
    )
    
    parser.add_argument(
        '--create-hooks',
        action='store_true',
        help='Créer les hooks Git de protection'
    )
    
    parser.add_argument(
        '--full-check',
        action='store_true',
        help='Exécuter toutes les vérifications'
    )
    
    args = parser.parse_args()
    
    try:
        protector = ConfigurationProtector()
        
        if args.full_check or not any(vars(args).values()):
            # Mode par défaut : vérification complète
            logger.info("🚀 VÉRIFICATION COMPLÈTE DE LA CONFIGURATION")
            logger.info("=" * 60)
            
            # Validation
            if not protector.validate_configuration():
                sys.exit(1)
            
            # Scan des violations
            if not protector.scan_for_violations():
                sys.exit(1)
            
            logger.info("🎉 TOUTES LES VÉRIFICATIONS RÉUSSIES !")
            
        else:
            # Mode spécifique
            if args.validate:
                if not protector.validate_configuration():
                    sys.exit(1)
            
            if args.scan:
                if not protector.scan_for_violations():
                    sys.exit(1)
            
            if args.generate:
                protector.generate_config_files()
            
            if args.create_hooks:
                protector.create_protection_hooks()
    
    except Exception as e:
        logger.error(f"❌ ERREUR FATALE: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
