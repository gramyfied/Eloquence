# Configuration audio avec OpenAI TTS

## État actuel (23/06/2025 22:36)

### ✅ Configuration mise à jour

1. **Clé OpenAI configurée** dans `real_time_voice_agent_force_audio.py`
2. **Agent redémarré** avec la nouvelle configuration
3. **OpenAI TTS activé** avec les paramètres suivants :
   - Modèle : `tts-1` (qualité standard, faible latence)
   - Voix : `nova` (voix féminine naturelle)
   - Format : `pcm` (compatible LiveKit)
   - Vitesse : `1.0` (normale)

### 🎯 Avantages d'OpenAI TTS

- **Qualité audio supérieure** : Voix naturelles et expressives
- **Faible latence** : Réponse rapide pour une conversation fluide
- **Support multilingue** : Fonctionne bien en français
- **Format PCM direct** : Pas de conversion nécessaire pour LiveKit

### 🧪 Test immédiat

1. **Lancez l'application Flutter** sur votre appareil
2. **Parlez en français** - l'agent devrait :
   - Transcrire votre parole (Whisper STT)
   - Générer une réponse (Mistral LLM)
   - **Synthétiser avec OpenAI TTS** (voix naturelle)
   - Jouer l'audio sur votre appareil

### 📊 Vérification

```bash
# Suivre les logs en temps réel
docker logs -f 25eloquence-finalisation-api-backend-1

# Chercher les logs OpenAI TTS
docker logs 25eloquence-finalisation-api-backend-1 2>&1 | grep -i "openai tts"
```

### ⚠️ En cas de problème

Si l'audio ne fonctionne toujours pas :

1. **Vérifiez les logs Flutter** pour :
   - `[CRITICAL] Audio IA détecté - ACTIVATION FORCÉE`
   - `[FORCE AUDIO] Configuration terminée`

2. **Vérifiez les logs de l'agent** pour :
   - `Utilisation d'OpenAI TTS`
   - `OpenAI TTS synthétisé: X bytes`

3. **Vérifiez la clé OpenAI** :
   - La clé doit être valide et avoir des crédits
   - L'API audio doit être activée sur votre compte

### 🔧 Options de personnalisation

Vous pouvez modifier la voix dans `real_time_voice_agent_force_audio.py` :

```python
"voice": "nova",  # Options: alloy, echo, fable, onyx, nova, shimmer
```

- `alloy` : Voix neutre
- `echo` : Voix masculine
- `fable` : Voix britannique
- `onyx` : Voix grave masculine
- `nova` : Voix féminine (actuelle)
- `shimmer` : Voix féminine expressive

Pour une meilleure qualité (mais plus de latence), changez :
```python
"model": "tts-1-hd",  # Au lieu de "tts-1"
```

### ✅ Résumé

L'audio devrait maintenant fonctionner avec une voix naturelle de haute qualité grâce à OpenAI TTS. La chaîne complète est :

1. **Voix utilisateur** → Microphone Flutter
2. **Audio** → LiveKit → Agent Python
3. **Transcription** → Whisper STT
4. **IA** → Mistral LLM
5. **Synthèse vocale** → OpenAI TTS ✨
6. **Audio de réponse** → LiveKit → Flutter
7. **Lecture** → Haut-parleur de l'appareil

Testez maintenant avec l'application Flutter !