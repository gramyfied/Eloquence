#!/usr/bin/env python3
"""
Correcteur Automatique des Violations de Configuration Centralisée
Remplace automatiquement tous les ports et URLs hardcodés par la configuration centralisée
"""

import yaml
import re
import os
from pathlib import Path
from typing import List, Dict, Any
import logging
import shutil

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AutoFixViolations:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.config = self._load_config()
        self.fixed_files = []
        self.backup_dir = self.project_root / "config_backup" / "auto_fix_backup"
        
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
    
    def create_backup(self):
        """Crée une sauvegarde avant modification"""
        if self.backup_dir.exists():
            shutil.rmtree(self.backup_dir)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Sauvegarder les fichiers qui vont être modifiés
        files_to_backup = [
            "services/livekit-agent/main.py",
            "services/livekit-agent/agent.py",
            "services/livekit-agent/multi_agent_main.py",
            "services/livekit-agent/multi_agent_worker.py",
            "services/livekit-agent/vosk_stt_interface.py",
            "services/livekit-server/main.py",
            "services/eloquence-api/app.py",
            "services/eloquence-exercises-api/app.py",
            "scripts/test_livekit_connectivity.py"
        ]
        
        for file_path in files_to_backup:
            full_path = self.project_root / file_path
            if full_path.exists():
                backup_path = self.backup_dir / file_path
                backup_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(full_path, backup_path)
                logger.info(f"📦 Sauvegarde: {file_path}")
    
    def fix_livekit_agent_main(self):
        """Corrige le fichier main.py du livekit-agent"""
        file_path = self.project_root / "services" / "livekit-agent" / "main.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer les ports hardcodés
        replacements = [
            (r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]'),
            (r':8004', ':CENTRALIZED_CONFIG["services"]["eloquence_exercises"]'),
        ]
        
        for old, new in replacements:
            content = re.sub(old, new, content)
        
        # Remplacer les URLs hardcodées
        content = re.sub(
            r'ws://localhost:7880',
            'CENTRALIZED_CONFIG["livekit"]["url"]',
            content
        )
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_livekit_agent_agent(self):
        """Corrige le fichier agent.py du livekit-agent"""
        file_path = self.project_root / "services" / "livekit-agent" / "agent.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer les ports et URLs hardcodés
        content = re.sub(r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]', content)
        content = re.sub(
            r'ws://localhost:7880',
            'CENTRALIZED_CONFIG["livekit"]["url"]',
            content
        )
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_multi_agent_files(self):
        """Corrige les fichiers multi-agent"""
        files_to_fix = [
            "multi_agent_main.py",
            "multi_agent_worker.py"
        ]
        
        for filename in files_to_fix:
            file_path = self.project_root / "services" / "livekit-agent" / filename
            if not file_path.exists():
                continue
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Remplacer les ports hardcodés
            replacements = [
                (r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]'),
                (r':8001', ':CENTRALIZED_CONFIG["services"]["mistral"]'),
                (r':8002', ':CENTRALIZED_CONFIG["services"]["vosk"]'),
            ]
            
            for old, new in replacements:
                content = re.sub(old, new, content)
            
            # Remplacer les URLs hardcodées
            content = re.sub(
                r'ws://localhost:7880',
                'CENTRALIZED_CONFIG["livekit"]["url"]',
                content
            )
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.fixed_files.append(str(file_path))
            logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_vosk_interface(self):
        """Corrige le fichier vosk_stt_interface.py"""
        file_path = self.project_root / "services" / "livekit-agent" / "vosk_stt_interface.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer le port hardcodé
        content = re.sub(r':8002', ':CENTRALIZED_CONFIG["services"]["vosk"]', content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_livekit_server(self):
        """Corrige le fichier main.py du livekit-server"""
        file_path = self.project_root / "services" / "livekit-server" / "main.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer le port hardcodé
        content = re.sub(r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]', content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_eloquence_api(self):
        """Corrige le fichier app.py de eloquence-api"""
        file_path = self.project_root / "services" / "eloquence-api" / "app.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer les ports hardcodés
        replacements = [
            (r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]'),
            (r':8001', ':CENTRALIZED_CONFIG["services"]["mistral"]'),
            (r':8002', ':CENTRALIZED_CONFIG["services"]["vosk"]'),
        ]
        
        for old, new in replacements:
            content = re.sub(old, new, content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_eloquence_exercises_api(self):
        """Corrige le fichier app.py de eloquence-exercises-api"""
        file_path = self.project_root / "services" / "eloquence-exercises-api" / "app.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer les ports hardcodés
        replacements = [
            (r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]'),
            (r':8001', ':CENTRALIZED_CONFIG["services"]["mistral"]'),
            (r':8004', ':CENTRALIZED_CONFIG["services"]["eloquence_exercises"]'),
        ]
        
        for old, new in replacements:
            content = re.sub(old, new, content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def fix_test_scripts(self):
        """Corrige les scripts de test"""
        file_path = self.project_root / "scripts" / "test_livekit_connectivity.py"
        if not file_path.exists():
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remplacer les ports et URLs hardcodés
        replacements = [
            (r':7880', ':CENTRALIZED_CONFIG["livekit"]["port"]'),
            (r':8001', ':CENTRALIZED_CONFIG["services"]["mistral"]'),
            (r':8002', ':CENTRALIZED_CONFIG["services"]["vosk"]'),
            (r':8004', ':CENTRALIZED_CONFIG["services"]["eloquence_exercises"]'),
            (r'http://localhost:8001', 'CENTRALIZED_CONFIG["services"]["mistral_url"]'),
            (r'http://localhost:8002', 'CENTRALIZED_CONFIG["services"]["vosk_url"]'),
            (r'http://localhost:8004', 'CENTRALIZED_CONFIG["services"]["eloquence_exercises_url"]'),
        ]
        
        for old, new in replacements:
            content = re.sub(old, new, content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.fixed_files.append(str(file_path))
        logger.info(f"🔧 Corrigé: {file_path}")
    
    def add_config_imports(self):
        """Ajoute les imports de configuration centralisée aux fichiers corrigés"""
        for file_path in self.fixed_files:
            path = Path(file_path)
            if not path.exists():
                continue
            
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Vérifier si l'import est déjà présent
            if "from config_client import" in content:
                continue
            
            # Ajouter l'import au début du fichier (après les commentaires)
            import_statement = """
# IMPORT OBLIGATOIRE DE LA CONFIGURATION CENTRALISÉE
from config_client import (
    get_livekit_config,
    get_services_urls,
    get_agent_config,
    EloquenceConfigError
)

# Chargement de la configuration centralisée
try:
    CENTRALIZED_CONFIG = get_agent_config()
except EloquenceConfigError as e:
    print(f"Erreur configuration: {e}")
    CENTRALIZED_CONFIG = {}

"""
            
            # Insérer après les premiers commentaires
            lines = content.split('\n')
            insert_index = 0
            
            for i, line in enumerate(lines):
                if line.strip().startswith('import ') or line.strip().startswith('from '):
                    insert_index = i
                    break
            
            lines.insert(insert_index, import_statement)
            content = '\n'.join(lines)
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            logger.info(f"📥 Import ajouté: {file_path}")
    
    def run_auto_fix(self):
        """Exécute la correction automatique complète"""
        logger.info("🚀 DÉMARRAGE DE LA CORRECTION AUTOMATIQUE")
        logger.info("=" * 50)
        
        # Créer une sauvegarde
        self.create_backup()
        logger.info("📦 Sauvegarde créée")
        
        # Corriger tous les fichiers
        self.fix_livekit_agent_main()
        self.fix_livekit_agent_agent()
        self.fix_multi_agent_files()
        self.fix_vosk_interface()
        self.fix_livekit_server()
        self.fix_eloquence_api()
        self.fix_eloquence_exercises_api()
        self.fix_test_scripts()
        
        # Ajouter les imports de configuration
        self.add_config_imports()
        
        logger.info("=" * 50)
        logger.info("🎉 CORRECTION AUTOMATIQUE TERMINÉE")
        logger.info("=" * 50)
        logger.info(f"📁 Fichiers corrigés: {len(self.fixed_files)}")
        for file_path in self.fixed_files:
            logger.info(f"   • {Path(file_path).name}")
        
        logger.info(f"\n📦 Sauvegarde disponible dans: {self.backup_dir}")
        logger.info("\n⚠️ IMPORTANT: Vérifiez que les corrections sont correctes avant de redémarrer les services")

if __name__ == "__main__":
    fixer = AutoFixViolations()
    fixer.run_auto_fix()
