# Diagnostic du Problème Audio - Agent LiveKit

## Problème Identifié

L'agent LiveKit démarre correctement mais ne produit aucun son car il ne publie pas d'audio track.

## Analyse des Logs

### Logs LiveKit Server
- ✅ Connexions WebRTC établies
- ❌ Connexions utilisateur échouent (ICE failed)
- ❌ Room fermée après timeout

### Logs Agent
- ✅ Agent démarre correctement
- ❌ Aucun log d'audio processing
- ❌ Aucun log de TTS
- ❌ Aucun log de publication d'audio track

## Causes Possibles

### 1. Configuration Audio Source
L'agent ne configure pas correctement l'audio source pour publier automatiquement.

### 2. Logique de Publication Manquante
Il manque la logique pour publier un audio track même sans input utilisateur.

### 3. Pipeline Audio Non Initialisé
Le pipeline TTS → Audio Track n'est pas correctement initialisé.

## Solutions Recommandées

### Solution 1: Forcer la Publication Audio
Modifier l'agent pour publier automatiquement un audio track au démarrage :

```python
# Dans real_time_voice_agent_force_audio.py
async def entrypoint(ctx: JobContext):
    # Publier immédiatement un audio track
    audio_source = rtc.AudioSource(sample_rate=24000, num_channels=1)
    track = rtc.LocalAudioTrack.create_audio_track("agent-audio", audio_source)
    
    # Publier le track
    await ctx.room.local_participant.publish_track(track, rtc.TrackPublishOptions(
        name="agent-audio",
        source=rtc.TrackSource.SOURCE_MICROPHONE
    ))
    
    # Envoyer un message de bienvenue
    await send_welcome_message(audio_source)
```

### Solution 2: Test Audio Immédiat
Ajouter un test audio au démarrage :

```python
async def send_welcome_message(audio_source):
    """Envoie un message de bienvenue pour tester l'audio"""
    welcome_text = "Bonjour ! Je suis votre coach d'éloquence. Comment puis-je vous aider aujourd'hui ?"
    
    # Générer l'audio via TTS
    tts_response = await generate_tts(welcome_text)
    
    # Publier l'audio
    await publish_audio(audio_source, tts_response)
```

### Solution 3: Configuration Force Audio
Modifier la configuration pour forcer l'audio :

```python
# Configuration forcée
FORCE_AUDIO_PUBLICATION = True
AUTO_WELCOME_MESSAGE = True
AUDIO_SAMPLE_RATE = 24000
AUDIO_CHANNELS = 1
```

## Tests de Validation

### Test 1: Vérifier Publication Audio
```bash
# Vérifier les logs pour la publication
docker logs eloquence-agent-v1 | grep -i "publish.*audio"
```

### Test 2: Vérifier TTS
```bash
# Tester le service TTS directement
curl -X POST http://localhost:5002/synthesize \
  -H "Content-Type: application/json" \
  -d '{"text": "Test audio", "voice": "alloy"}'
```

### Test 3: Vérifier Pipeline Complet
```bash
# Exécuter le test audio pipeline
docker exec eloquence-agent-v1 python test_audio_pipeline.py
```

## Modifications Urgentes Nécessaires

### 1. Modifier l'Agent
- Ajouter publication automatique d'audio track
- Implémenter message de bienvenue
- Forcer l'initialisation du pipeline audio

### 2. Ajouter Logs de Debug
- Logger chaque étape du pipeline audio
- Tracer les publications de tracks
- Monitorer les erreurs TTS

### 3. Configuration Robuste
- Paramètres audio par défaut
- Fallback en cas d'erreur TTS
- Retry automatique

## Commandes de Diagnostic

```bash
# Redémarrer l'agent avec logs verbeux
docker-compose restart eloquence-agent-v1

# Surveiller les logs en temps réel
docker logs -f eloquence-agent-v1

# Tester la connectivité TTS
curl http://localhost:5002/health

# Vérifier l'état des tracks LiveKit
# (nécessite modification du code pour exposer ces infos)
```

## Prochaines Étapes

1. **Immédiat** : Modifier l'agent pour publier automatiquement l'audio
2. **Court terme** : Ajouter des logs de debug détaillés
3. **Moyen terme** : Implémenter un système de monitoring audio
4. **Long terme** : Créer des tests automatisés du pipeline audio

---
*Diagnostic effectué le 30/06/2025 - Problème critique identifié*