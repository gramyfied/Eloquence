# Corrections des Erreurs Multi-Agents LiveKit

## Problèmes Identifiés

D'après les logs d'erreur, deux problèmes principaux ont été identifiés :

### 1. Erreur `'EnhancedMultiAgentManager' object has no attribute 'agents'`

**Symptôme :**
```
❌ Erreur orchestration multi-agents: 'EnhancedMultiAgentManager' object has no attribute 'agents'
```

**Cause :**
L'`EnhancedMultiAgentManager` n'avait pas d'attribut `agents`, mais le code dans `multi_agent_main.py` tentait d'y accéder pour récupérer les agents configurés.

**Solution Appliquée :**

1. **Ajout de l'attribut `agents`** dans `EnhancedMultiAgentManager` :
```python
def __init__(self, openai_api_key: str, elevenlabs_api_key: str):
    # Configuration des agents (ajouté pour compatibilité)
    self.agents = {}
    self.config = None
```

2. **Ajout de la méthode `set_config()`** pour configurer les agents :
```python
def set_config(self, config):
    """Configure les agents à partir d'une configuration MultiAgentConfig"""
    self.config = config
    self.agents = {agent.agent_id: agent for agent in config.agents}
    logger.info(f"✅ Configuration multi-agents définie: {len(self.agents)} agents")
```

3. **Ajout de méthodes de compatibilité** :
```python
def set_last_speaker_message(self, speaker_type: str, message: str):
    """Méthode de compatibilité pour la gestion des speakers"""
    
def process_agent_output(self, output: str, agent_id: str):
    """Méthode de compatibilité pour le traitement des sorties d'agents"""
```

4. **Configuration automatique** dans `MultiAgentLiveKitService` :
```python
self.manager = get_enhanced_manager(openai_api_key, elevenlabs_api_key)
# Configurer les agents dans l'EnhancedMultiAgentManager
self.manager.set_config(multi_agent_config)
```

### 2. Erreur API OpenAI Obsolète

**Symptôme :**
```
You tried to access openai.ChatCompletion, but this is no longer supported in openai>=1.0.0
```

**Cause :**
Le code utilisait l'ancienne API OpenAI `openai.ChatCompletion.acreate` qui n'est plus supportée dans openai>=1.0.0.

**Solution Appliquée :**

1. **Migration vers la nouvelle API** dans `gpt4o_naturalness_engine.py` :
```python
# Ancien code (obsolète)
response = await openai.ChatCompletion.acreate(
    messages=[{"role": "user", "content": prompt}],
    **config
)

# Nouveau code (compatible openai>=1.0.0)
from openai import AsyncOpenAI
client = AsyncOpenAI(api_key=self.api_key)

response = await client.chat.completions.create(
    messages=[{"role": "user", "content": prompt}],
    **config
)
```

2. **Suppression de l'ancienne configuration globale** :
```python
def __init__(self, api_key: str):
    self.api_key = api_key
    # Suppression de l'ancienne API key globale
    # openai.api_key = api_key  # Obsolète dans openai>=1.0.0
```

## Fichiers Modifiés

1. **`enhanced_multi_agent_manager.py`**
   - Ajout de l'attribut `agents`
   - Ajout de la méthode `set_config()`
   - Ajout de méthodes de compatibilité

2. **`multi_agent_main.py`**
   - Ajout de l'appel à `manager.set_config()` dans le constructeur

3. **`gpt4o_naturalness_engine.py`**
   - Migration vers la nouvelle API OpenAI
   - Suppression de l'ancienne configuration globale

## Script de Test

Un script de test `test_fixes.py` a été créé pour vérifier que les corrections fonctionnent :

```bash
cd services/livekit-agent
python test_fixes.py
```

Ce script teste :
- La création et configuration de l'`EnhancedMultiAgentManager`
- La migration vers la nouvelle API OpenAI
- La génération de réponses complètes

## Résultats Attendus

Après ces corrections :

1. ✅ L'erreur `'EnhancedMultiAgentManager' object has no attribute 'agents'` devrait être résolue
2. ✅ L'erreur API OpenAI obsolète devrait être résolue
3. ✅ Le système multi-agents devrait fonctionner correctement
4. ✅ Les réponses vocales avec ElevenLabs devraient être générées

## Vérification

Pour vérifier que les corrections fonctionnent :

1. Redémarrer le service LiveKit Agent
2. Lancer une session multi-agents
3. Vérifier les logs pour s'assurer qu'il n'y a plus d'erreurs
4. Tester la génération de réponses vocales

## Notes Importantes

- Les corrections maintiennent la compatibilité avec le code existant
- Aucune modification des interfaces publiques n'a été nécessaire
- Les performances ne devraient pas être impactées
- La migration OpenAI est transparente pour l'utilisateur final
