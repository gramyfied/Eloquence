#!/usr/bin/env python3
"""
Script de correction automatique du point d'entrée
Corrige le problème Thomas en forçant l'utilisation d'unified_entrypoint
"""

import os
import re

def fix_main_py():
    """Corrige main.py pour utiliser unified_entrypoint"""
    main_path = 'services/livekit-agent/main.py'
    
    print("🔧 Correction de main.py...")
    
    with open(main_path, 'r') as f:
        content = f.read()
    
    # Ajouter l'import si manquant
    if 'from unified_entrypoint import unified_entrypoint' not in content:
        # Trouver une ligne d'import existante pour insérer après
        import_lines = [
            'from livekit.agents import',
            'import logging',
            'import os'
        ]
        
        for import_line in import_lines:
            if import_line in content:
                # Trouver la fin de cette ligne d'import
                import_pos = content.find(import_line)
                line_end = content.find('\n', import_pos)
                if line_end != -1:
                    # Insérer l'import après cette ligne
                    insert_pos = line_end + 1
                    content = content[:insert_pos] + 'from unified_entrypoint import unified_entrypoint\n' + content[insert_pos:]
                    print("✅ Import unified_entrypoint ajouté")
                    break
    
    # Remplacer l'entrypoint
    if 'entrypoint_fnc=robust_entrypoint' in content:
        content = content.replace(
            'entrypoint_fnc=robust_entrypoint',
            'entrypoint_fnc=unified_entrypoint'
        )
        print("✅ Entrypoint remplacé par unified_entrypoint")
    
    with open(main_path, 'w') as f:
        f.write(content)
    
    print("✅ main.py corrigé")

def fix_unified_entrypoint():
    """Ajoute la fonction unified_entrypoint si manquante"""
    unified_path = 'services/livekit-agent/unified_entrypoint.py'
    
    print("🔧 Correction d'unified_entrypoint.py...")
    
    with open(unified_path, 'r') as f:
        content = f.read()
    
    # Ajouter les constantes si manquantes
    if 'MULTI_AGENT_EXERCISES' not in content:
        constants = '''
# Exercices multi-agents
MULTI_AGENT_EXERCISES = [
    'studio_debate_tv',
    'studio_situations_pro'
]
'''
        # Insérer après les imports
        logger_line = 'logger = logging.getLogger(__name__)'
        if logger_line in content:
            import_end = content.find(logger_line)
            line_end = content.find('\n', import_end)
            if line_end != -1:
                insert_pos = line_end + 1
                content = content[:insert_pos] + constants + content[insert_pos:]
                print("✅ Constantes MULTI_AGENT_EXERCISES ajoutées")
    
    # Ajouter la fonction principale si manquante
    if 'async def unified_entrypoint' not in content:
        function_code = '''

async def unified_entrypoint(ctx: JobContext):
    """Point d'entrée unifié principal"""
    logger.info("🎯 DÉMARRAGE UNIFIED ENTRYPOINT")
    
    # Détection automatique de l'exercice
    exercise_type = await detect_exercise_from_context(ctx)
    logger.info(f"✅ Exercise détecté: {exercise_type}")
    
    # Routage automatique
    if exercise_type in MULTI_AGENT_EXERCISES:
        logger.info(f"🎭 Routage vers MULTI-AGENT pour {exercise_type}")
        
        # Transmission exercise_type au contexte
        ctx.exercise_type = exercise_type
        logger.info(f"🔗 EXERCISE_TYPE TRANSMIS AU CONTEXTE: {exercise_type}")
        
        try:
            from multi_agent_main import multiagent_entrypoint
            await multiagent_entrypoint(ctx)
        except ImportError as e:
            logger.error(f"❌ Erreur import multi_agent_main: {e}")
            # Fallback vers individual
            from main import robust_entrypoint
            await robust_entrypoint(ctx)
    else:
        logger.info(f"👤 Routage vers INDIVIDUAL pour {exercise_type}")
        from main import robust_entrypoint
        await robust_entrypoint(ctx)
'''
        content += function_code
        print("✅ Fonction unified_entrypoint ajoutée")
    
    with open(unified_path, 'w') as f:
        f.write(content)
    
    print("✅ unified_entrypoint.py corrigé")

def clean_compiled_files():
    """Nettoie les fichiers compilés"""
    print("🧹 Nettoyage des fichiers compilés...")
    
    import subprocess
    
    # Supprimer tous les .pyc
    subprocess.run(['find', '.', '-name', '*.pyc', '-delete'], capture_output=True)
    
    # Supprimer tous les __pycache__
    subprocess.run(['find', '.', '-name', '__pycache__', '-type', 'd', '-exec', 'rm', '-rf', '{}', '+'], capture_output=True)
    
    print("✅ Fichiers compilés nettoyés")

def main():
    """Fonction principale"""
    print("🔧 CORRECTION AUTOMATIQUE DU POINT D'ENTRÉE")
    print("="*50)
    
    # Vérifier qu'on est dans le bon répertoire
    if not os.path.exists('services/livekit-agent/main.py'):
        print("❌ Erreur: Exécuter depuis le répertoire racine d'Eloquence")
        return False
    
    try:
        # 1. Nettoyer les fichiers compilés
        clean_compiled_files()
        
        # 2. Corriger main.py
        fix_main_py()
        
        # 3. Corriger unified_entrypoint.py
        fix_unified_entrypoint()
        
        print("\n🎉 CORRECTION TERMINÉE !")
        print("✅ main.py utilise maintenant unified_entrypoint")
        print("✅ unified_entrypoint.py a la fonction principale")
        print("✅ Fichiers compilés nettoyés")
        print("\n🚀 PROCHAINES ÉTAPES :")
        print("1. Redémarrer les services : docker-compose restart")
        print("2. Tester avec studio_debatPlateau_test")
        print("3. Vérifier logs : doit afficher 'UNIFIED ENTRYPOINT'")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la correction: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

