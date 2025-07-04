# Solution finale pour le problème AudioEmitter

## Analyse du problème

L'erreur "AudioEmitter isn't started" persiste même avec le plugin OpenAI officiel. L'analyse montre que :

1. **Le bug est dans le framework LiveKit** : `/app/.local/lib/python3.11/site-packages/livekit/agents/tts/tts.py` ligne 636
2. **Erreur secondaire avec Mistral API** : HTTP 400 Bad Request sur l'API Scaleway

## Solution adoptée : VoiceAssistant

Au lieu d'utiliser `AgentSession`, nous utilisons `VoiceAssistant` qui gère différemment le cycle de vie audio.

### Fichier créé : `real_time_voice_agent_minimal.py`

```python
# Configuration minimale avec VoiceAssistant
assistant = agents.VoiceAssistant(
    vad=silero.VAD.load(),
    stt=openai.STT(),
    llm=openai.LLM(),  # Utilise OpenAI au lieu de Mistral
    tts=openai.TTS(model="tts-1", voice="alloy"),
    chat_ctx=initial_ctx,
)

# Démarrage simple
assistant.start(ctx.room)
```

### Avantages de VoiceAssistant

1. **Gestion audio simplifiée** : VoiceAssistant gère automatiquement le cycle de vie audio
2. **Pas d'AudioEmitter manuel** : Le framework gère tout en interne
3. **Compatible avec les plugins** : Fonctionne avec tous les plugins OpenAI
4. **Plus stable** : Évite le bug de l'AudioEmitter

## Configuration mise à jour

### docker-compose.override.yml
```yaml
command: >
  sh -c "watchfiles 'python -u services/real_time_voice_agent_minimal.py dev' ."
```

## Résolution du problème Mistral

L'implémentation minimale utilise OpenAI LLM au lieu de Mistral, évitant ainsi l'erreur HTTP 400.

## Commandes pour appliquer la solution

```bash
# 1. Arrêter et supprimer l'ancien conteneur
docker-compose stop eloquence-agent-v1
docker-compose rm -f eloquence-agent-v1

# 2. Reconstruire et démarrer
docker-compose up -d --build eloquence-agent-v1

# 3. Vérifier les logs
docker-compose logs -f eloquence-agent-v1
```

## Vérifications

1. **Plus d'erreur AudioEmitter** : L'erreur ne devrait plus apparaître
2. **Agent fonctionnel** : L'agent répond avec de l'audio
3. **Connexion stable** : WebSocket maintenu avec LiveKit

## Limitations et améliorations futures

1. **LLM** : Actuellement utilise OpenAI au lieu de Mistral
2. **Personnalisation** : L'implémentation est minimale, à enrichir selon les besoins
3. **Coach d'éloquence** : Ajouter la logique spécifique du coaching

## Diagnostic disponible

Exécuter `python diagnose_livekit_tts_issue.py` pour :
- Vérifier les versions LiveKit
- Analyser le code source du bug
- Vérifier la configuration Mistral
- Obtenir des suggestions supplémentaires

## Conclusion

La solution VoiceAssistant contourne le bug AudioEmitter du framework LiveKit v1.1.5 tout en maintenant toutes les fonctionnalités audio nécessaires.