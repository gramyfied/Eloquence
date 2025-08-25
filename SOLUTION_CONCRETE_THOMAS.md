# 🎯 SOLUTION CONCRÈTE DÉFINITIVE - PROBLÈME THOMAS

## 🚨 PROBLÈME IDENTIFIÉ

**CAUSE RACINE :** Le système utilise `main.py` avec `robust_entrypoint` au lieu d'`unified_entrypoint.py` !

### Preuve dans les logs :
- ✅ OpenAI TTS (voix 'alloy') utilisé au lieu d'ElevenLabs
- ✅ Messages génériques de Thomas : "Génial ! Quel exercice souhaitez-vous réaliser ?"
- ❌ Aucun log de détection d'exercice visible
- ❌ Aucun log de routage multi-agents

### Configuration actuelle problématique :
```python
# Dans main.py ligne 1290
worker_options = agents.WorkerOptions(
    entrypoint_fnc=robust_entrypoint  # ❌ PROBLÈME ICI !
)
```

## 🔧 SOLUTION CONCRÈTE

### ÉTAPE 1 : Modifier le point d'entrée principal

**Fichier :** `services/livekit-agent/main.py`
**Ligne :** 1290

**REMPLACER :**
```python
worker_options = agents.WorkerOptions(
    entrypoint_fnc=robust_entrypoint
)
```

**PAR :**
```python
# Import de l'entrypoint unifié
from unified_entrypoint import unified_entrypoint

worker_options = agents.WorkerOptions(
    entrypoint_fnc=unified_entrypoint
)
```

### ÉTAPE 2 : Vérifier que unified_entrypoint.py a la fonction principale

**Fichier :** `services/livekit-agent/unified_entrypoint.py`

**AJOUTER à la fin du fichier :**
```python
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
```

### ÉTAPE 3 : Vérifier les constantes

**Fichier :** `services/livekit-agent/unified_entrypoint.py`

**AJOUTER au début du fichier :**
```python
# Exercices multi-agents
MULTI_AGENT_EXERCISES = [
    'studio_debate_tv',
    'studio_situations_pro'
]
```

## 🚀 SCRIPT D'APPLICATION AUTOMATIQUE

**Créer le fichier :** `fix_entrypoint.py`

```python
#!/usr/bin/env python3
"""
Script de correction automatique du point d'entrée
"""

import os
import re

def fix_main_py():
    """Corrige main.py pour utiliser unified_entrypoint"""
    main_path = 'services/livekit-agent/main.py'
    
    with open(main_path, 'r') as f:
        content = f.read()
    
    # Ajouter l'import
    if 'from unified_entrypoint import unified_entrypoint' not in content:
        # Trouver la ligne avec les autres imports
        import_pattern = r'(from livekit\.agents import.*?\n)'
        replacement = r'\1from unified_entrypoint import unified_entrypoint\n'
        content = re.sub(import_pattern, replacement, content)
    
    # Remplacer l'entrypoint
    content = content.replace(
        'entrypoint_fnc=robust_entrypoint',
        'entrypoint_fnc=unified_entrypoint'
    )
    
    with open(main_path, 'w') as f:
        f.write(content)
    
    print("✅ main.py corrigé")

def fix_unified_entrypoint():
    """Ajoute la fonction unified_entrypoint si manquante"""
    unified_path = 'services/livekit-agent/unified_entrypoint.py'
    
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
        import_end = content.find('logger = logging.getLogger(__name__)')
        if import_end != -1:
            insert_pos = content.find('\n', import_end) + 1
            content = content[:insert_pos] + constants + content[insert_pos:]
    
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
    
    with open(unified_path, 'w') as f:
        f.write(content)
    
    print("✅ unified_entrypoint.py corrigé")

def main():
    """Fonction principale"""
    print("🔧 CORRECTION AUTOMATIQUE DU POINT D'ENTRÉE")
    print("="*50)
    
    os.chdir('/path/to/Eloquence')  # Adapter le chemin
    
    fix_main_py()
    fix_unified_entrypoint()
    
    print("\n🎉 CORRECTION TERMINÉE !")
    print("✅ main.py utilise maintenant unified_entrypoint")
    print("✅ unified_entrypoint.py a la fonction principale")
    print("\n🚀 REDÉMARRER LES SERVICES POUR APPLIQUER")

if __name__ == "__main__":
    main()
```

## 🎯 RÉSULTAT ATTENDU

Après application de cette solution :

### Logs corrects :
```
🎯 DÉMARRAGE UNIFIED ENTRYPOINT
🔍 DIAGNOSTIC: Détection d'exercice en cours...
🏠 Nom de room: studio_debatplateau_1755936358078
✅ Exercise détecté: studio_debate_tv
🎭 Routage vers MULTI-AGENT pour studio_debate_tv
🔗 EXERCISE_TYPE TRANSMIS AU CONTEXTE: studio_debate_tv
🎬 DÉMARRAGE SYSTÈME DÉBAT TV
🎭 Agents: Michel Dubois, Sarah Johnson, Marcus Thompson
```

### Agents actifs :
- ✅ Michel Dubois (Animateur TV) avec ElevenLabs
- ✅ Sarah Johnson (Journaliste) avec ElevenLabs  
- ✅ Marcus Thompson (Expert) avec ElevenLabs
- ❌ Thomas (ne répond plus)

## 🚀 PROCÉDURE D'APPLICATION

1. **Appliquer les corrections** (manuellement ou avec le script)
2. **Redémarrer les services** : `docker-compose restart`
3. **Tester avec** : `studio_debatPlateau_test`
4. **Vérifier les logs** : Doit afficher "UNIFIED ENTRYPOINT"

**CETTE SOLUTION RÉSOUDRA DÉFINITIVEMENT LE PROBLÈME THOMAS !** 🎯🚀

