# 🎙️ [TTS/STT] Optimisation audio multi-agents - Flux PCM 16kHz + Accents Vosk

## 📋 Résumé
Optimisation majeure de l'expérience audio pour les simulations temps réel :
- **TTS ElevenLabs** : Flux PCM 16kHz end-to-end, trames 20ms précises
- **STT Vosk** : Préservation des accents français (Unicode NFC)
- **Logs diagnostics** : Traçabilité complète du pipeline audio

## 🎯 Problèmes résolus
- ❌ **TTS ralenti** : Voix au ralenti dans les simulations
- ❌ **Drops audio** : Coupures et "radio static" 
- ❌ **STT accents** : "é", "à", "è" non reconnus par Vosk
- ❌ **Debug difficile** : Manque de logs audio détaillés

## ✅ Solutions implémentées

### TTS ElevenLabs Multi-Agents
```python
# services/livekit-agent/multi_agent_main.py
- Forçage PCM 16kHz mono end-to-end (plus de resampling 48kHz)
- Trames exactes de 20ms avec zero-padding
- Limiteur doux (-1.5dBFS) pour éviter clipping
- Warm-up frame de silence pour stabiliser tempo
- Logs détaillés : bytes, frame_bytes, sample_rate
```

### STT Vosk Accents
```python
# services/vosk-stt-analysis/main.py  
- Suppression conversion ASCII (conservation accents)
- Normalisation Unicode NFC maintenue
- Emojis → texte ASCII (pour compatibilité)
- Encodage/décodage UTF-8 explicite
```

## 🧪 Checklist de tests

### TTS (Testez "Studio Situations Pro")
- [ ] **Débit normal** : Plus de voix ralentie
- [ ] **Qualité audio** : Plus de "radio static" ou drops
- [ ] **Réactivité** : Réponses immédiates des agents
- [ ] **Interruptions** : Possibilité d'interrompre naturellement
- [ ] **Logs TTS** : Vérifier `🎚️ [TTS]` dans les logs multiagent

### STT (Prononcez ces phrases)
- [ ] **"C'était l'été"** → "c'était l'été" (pas "cetait lete")
- [ ] **"Élève motivé"** → "élève motivé" (pas "eleve motive") 
- [ ] **"À bientôt"** → "à bientôt" (pas "a bientot")
- [ ] **"Ça va bien"** → "ça va bien" (pas "ca va bien")
- [ ] **Logs STT** : Vérifier `🔧 [STT-TRACE]` dans les logs vosk-stt

### Performance
- [ ] **Latence TTS** : <300ms (objectif <100ms)
- [ ] **Latence STT** : <500ms
- [ ] **CPU/Mémoire** : Pas de surcharge
- [ ] **Stabilité** : Pas de crash après 10min d'usage

## 🔧 Fichiers modifiés
- `services/livekit-agent/multi_agent_main.py` - TTS 16kHz end-to-end
- `services/vosk-stt-analysis/main.py` - Accents Vosk
- `docker/compose/docker-compose.override.yml` - Variables d'environnement

## 🚀 Déploiement
```bash
# Rebuild et restart
docker compose build vosk-stt multiagent
docker compose up -d vosk-stt multiagent

# Vérifier logs
docker compose logs --tail=50 multiagent vosk-stt
```

## 📊 Métriques attendues
- **TTS** : Sample rate 16kHz, frames 20ms, pas de resampling
- **STT** : Accents préservés, normalisation NFC
- **Logs** : Traces `🎚️ [TTS]` et `🔧 [STT-TRACE]` visibles

---

**Testé par** : [Votre nom]  
**Date de test** : [Date]  
**Environnement** : Docker local  
**Résultat** : ✅ Prêt pour merge / ❌ Problèmes détectés
