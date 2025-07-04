# Résolution du Crash Agent - AudioEmitter TypeError

## Problème Identifié

**Erreur** : `TypeError: 'AudioEmitter' object is not callable`

**Localisation** : `services/api-backend/services/real_time_voice_agent_force_audio_fixed.py`, ligne 292

**Cause** : Le code tentait d'appeler `output_emitter()` comme une fonction, alors que `AudioEmitter` est un objet avec des méthodes spécifiques.

## Diagnostic Effectué

1. **Analyse des logs** :
   - L'erreur se produisait lors de la génération TTS
   - Le crash empêchait l'agent de répondre avec de l'audio

2. **Inspection de l'API AudioEmitter** :
   - `AudioEmitter` n'est pas directement callable
   - Méthodes disponibles : `push()`, `initialize()`, `start_segment()`, `end_segment()`, `flush()`

3. **Identification de la source** :
   - Mauvaise utilisation de l'API dans la méthode `_run()` de `LocalOpenAITTSStream`
   - Code incorrect : `await output_emitter(audio_data)`
   - Code correct : `await output_emitter.push(audio_data)`

## Correction Appliquée

### Changements dans `real_time_voice_agent_force_audio_fixed.py`

1. **Méthode `_run()` corrigée** (lignes 247-329) :
   ```python
   async def _run(self, output_emitter: 'AudioEmitter') -> None:
       # Ajout de logs de debug
       logger.debug(f"🔍 [TTS] Type d'output_emitter: {type(output_emitter)}")
       
       # Initialisation si nécessaire
       if hasattr(output_emitter, 'initialize'):
           await output_emitter.initialize()
       
       # Démarrage du segment audio
       if hasattr(output_emitter, 'start_segment'):
           await output_emitter.start_segment()
       
       # Envoi des chunks audio avec push()
       for i in range(0, len(audio_data), chunk_size):
           chunk = audio_data[i : i + chunk_size]
           await output_emitter.push(chunk)  # ✅ Utilisation correcte
           await asyncio.sleep(0.01)
       
       # Fin du segment et flush
       if hasattr(output_emitter, 'end_segment'):
           await output_emitter.end_segment()
       if hasattr(output_emitter, 'flush'):
           await output_emitter.flush()
   ```

2. **Gestion d'erreur améliorée** :
   - Utilisation de `push()` aussi pour l'envoi du silence en cas d'erreur
   - Ajout de try/catch autour des appels à l'AudioEmitter

## Vérification de la Correction

### Commandes de vérification :

```bash
# Vérifier que le fichier est bien mis à jour dans le conteneur
docker exec 25eloquence-finalisation-eloquence-agent-v1-1 grep -n "push(" /app/services/real_time_voice_agent_force_audio_fixed.py

# Surveiller les logs pour l'absence de l'erreur
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1 --tail 50

# Rechercher spécifiquement les erreurs AudioEmitter
docker logs 25eloquence-finalisation-eloquence-agent-v1-1 2>&1 | grep -i "audioemitter"
```

### Indicateurs de succès :

1. ✅ Plus d'erreur `TypeError: 'AudioEmitter' object is not callable`
2. ✅ Logs montrant : `✅ [TTS] Audio généré avec succès: X bytes`
3. ✅ L'agent répond avec de l'audio dans l'application

## Impact de la Correction

- **Avant** : L'agent crashait lors de la génération TTS, pas de réponse audio
- **Après** : L'agent peut générer et envoyer l'audio correctement

## Recommandations

1. **Test complet** : Tester avec l'application Flutter pour confirmer la réception audio
2. **Monitoring** : Surveiller les logs pendant 24h pour s'assurer de la stabilité
3. **Documentation** : Mettre à jour la documentation de l'API custom si nécessaire

## Leçons Apprises

1. **Toujours vérifier l'API** : Les objets peuvent avoir des méthodes spécifiques plutôt que d'être directement callables
2. **Logs de debug** : Ajouter des logs pour identifier le type et les méthodes disponibles
3. **Gestion d'erreur robuste** : Prévoir des fallbacks même dans les gestionnaires d'erreur

---

**Date de résolution** : 03/07/2025
**Version livekit-agents** : 1.1.5
**Fichier modifié** : `services/api-backend/services/real_time_voice_agent_force_audio_fixed.py`