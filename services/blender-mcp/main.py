#!/usr/bin/env python3
"""
Serveur MCP Blender pour Eloquence RooCode
Permet l'intégration de Blender dans VS Code via RooCode
"""

import sys
import os
import logging
from pathlib import Path

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("BlenderMCPEloquence")

def main():
    """Point d'entrée principal du serveur Blender MCP"""
    try:
        # Import du serveur
        from server import main as server_main
        
        logger.info("🎨 Démarrage du serveur Blender MCP pour Eloquence")
        logger.info("🔧 Optimisé pour l'utilisation avec RooCode dans VS Code")
        
        # Démarrage du serveur MCP
        server_main()
        
    except ImportError as e:
        logger.error(f"❌ Erreur d'import: {e}")
        logger.error("Assurez-vous que les dépendances sont installées:")
        logger.error("pip install -r requirements.txt")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Erreur lors du démarrage: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
