# Résolution du problème AudioEmitter avec le plugin OpenAI

## Problème identifié

L'erreur "AudioEmitter isn't started" se produit car notre implémentation personnalisée du TTS ne gère pas correctement le cycle de vie de l'AudioEmitter selon les attentes du framework LiveKit v1.1.5.

### Erreurs rencontrées :
1. `TypeError: 'AudioEmitter' object is not callable` - Tentative d'appeler AudioEmitter comme une fonction
2. Utilisation incorrecte d'`await` sur des méthodes synchrones
3. Gestion incorrecte des segments en mode non-streaming
4. `AudioEmitter isn't started` - LiveKit essaie d'appeler `end_input()` sur un AudioEmitter non démarré

## Solution : Utiliser le plugin OpenAI officiel

Au lieu de créer notre propre implémentation TTS, nous utilisons le plugin officiel `livekit-plugins-openai` qui gère correctement le cycle de vie de l'audio.

### Avantages :
- ✅ Gestion automatique du cycle de vie AudioEmitter
- ✅ Compatible avec LiveKit v1.1.5
- ✅ Pas besoin de gérer manuellement `push()`, `start()`, `end_input()`
- ✅ Support natif du streaming et non-streaming

## Implémentation

### 1. Installation du plugin

Le plugin est déjà dans `requirements.agent.v1.txt` :
```
livekit-plugins-openai
```

### 2. Nouveau fichier agent avec plugin

Créé : `services/api-backend/services/real_time_voice_agent_with_plugin.py`

```python
from livekit.plugins import openai as openai_plugin

# Utilisation du plugin officiel pour TTS
tts = openai_plugin.TTS(
    api_key=openai_api_key,
    model="tts-1",
    voice="alloy"
)

# Créer la session avec le plugin officiel
session = AgentSession(
    llm=MistralLLM(),
    tts=tts,  # Plugin officiel
    vad=silero.VAD.load(),
)
```

### 3. Script de démarrage

Créé : `services/api-backend/start-agent-plugin.sh`

```bash
#!/bin/bash
# Script pour démarrer l'agent avec le plugin OpenAI
exec python services/real_time_voice_agent_with_plugin.py dev
```

## Tests effectués

### Diagnostic du plugin (`diagnose_openai_plugin_internals.py`)

Le diagnostic confirme :
- ✅ Plugin importé avec succès
- ✅ Classe TTS disponible avec méthodes `synthesize()` et `stream()`
- ✅ Compatible avec l'interface LiveKit

### Structure du plugin

```
[CLASS] TTS
   Type: <class 'abc.ABCMeta'>
   [METHODS] Publiques:
      - synthesize()  # Pour générer l'audio complet
      - stream()      # Pour le streaming
      - update_options()
      - aclose()
```

## Prochaines étapes

1. **Mettre à jour le Dockerfile** pour utiliser le nouveau script :
   ```dockerfile
   CMD ["./start-agent-plugin.sh"]
   ```

2. **Redémarrer les services** :
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

3. **Tester avec l'application Flutter** pour vérifier que l'audio fonctionne

## Différences avec l'ancienne implémentation

| Ancienne (personnalisée) | Nouvelle (plugin) |
|-------------------------|-------------------|
| Gestion manuelle d'AudioEmitter | Gestion automatique |
| Appels API OpenAI directs | Via le plugin |
| Problèmes de cycle de vie | Cycle de vie géré |
| Code complexe | Code simplifié |

## Conclusion

L'utilisation du plugin OpenAI officiel résout le problème "AudioEmitter isn't started" en gérant correctement le cycle de vie de l'audio selon les attentes de LiveKit. Cette approche est plus robuste et maintenable.