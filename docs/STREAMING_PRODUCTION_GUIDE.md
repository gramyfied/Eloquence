# 🚀 GUIDE STREAMING PRODUCTION - LiveKit Agent v1.1.3

## 📋 RÉSUMÉ

L'agent LiveKit a été **entièrement migré vers une implémentation production** avec streaming temps réel complet pour STT, TTS et LLM.

## ✅ FONCTIONNALITÉS PRODUCTION IMPLÉMENTÉES

### 🎤 **CustomWhisperSTT - Streaming STT Temps Réel**

#### Caractéristiques Production :
- **Buffer audio circulaire** avec chunks de 1 seconde
- **Détection d'activité vocale (VAD)** intégrée
- **Pool de connexions HTTP/2** optimisé (10 connexions)
- **Retry automatique** avec backoff exponentiel (3 tentatives)
- **Filtrage intelligent du bruit** (patterns de bruit, répétitions)
- **Timeouts optimisés** (10s pour temps réel)
- **Validation de qualité audio** (taille minimale, format WAV)

#### Flux de Streaming :
1. **Capture audio** → Buffer circulaire (16kHz, mono, 16-bit)
2. **Détection VAD** → START_OF_SPEECH quand niveau > seuil
3. **Traitement chunks** → Envoi périodique à Whisper HTTP
4. **Transcription** → INTERIM_TRANSCRIPT puis FINAL_TRANSCRIPT
5. **Fin de parole** → END_OF_SPEECH après silence

### 🔊 **CustomAzureTTS - Streaming TTS Intelligent**

#### Caractéristiques Production :
- **Chunking intelligent par phrases** (max 100 caractères)
- **Streaming audio par chunks** de 200ms pour faible latence
- **Sélection automatique de voix** selon le contexte
- **Normalisation audio** pour éviter la saturation
- **Extraction WAV robuste** avec fallback
- **Pool de connexions** optimisé (5 connexions)
- **Retry avec rate limiting** (429 handling)

#### Optimisations Audio :
- **Voix contextuelle** : DeniseNeural (féminine) pour accueil, HenriNeural (masculine) pour coaching
- **Paramètres optimaux** : Volume 0.8, vitesse 1.0, pitch normal
- **Chunks 200ms** pour streaming fluide
- **Normalisation à 80%** du maximum pour éviter saturation

### 🧠 **CustomMistralLLM - Streaming LLM Intelligent**

#### Caractéristiques Production :
- **Cache intelligent** avec correspondance floue et mots-clés
- **Streaming mot par mot** (3 mots par chunk) pour naturalité
- **Extraction robuste** du message utilisateur (4 méthodes fallback)
- **Retry avec backoff** exponentiel (3 tentatives, timeout 30s)
- **Gestion d'historique** optimisée (8 derniers messages)
- **Enrichissement français** automatique avec connecteurs

#### Cache Intelligent :
```python
keywords_cache = {
    "salut|hello|coucou": "Alors, bonjour ! Ravi de vous retrouver...",
    "merci|remercie": "Eh bien, je vous en prie ! C'est un plaisir...",
    "difficile|dur|compliqué": "Bon, je comprends que ce soit délicat...",
    "bien|bon|parfait": "Alors là, c'est parfait ! Vous progressez...",
    "au revoir|bye": "Eh bien, au revoir ! À très bientôt..."
}
```

## 🔧 CONFIGURATION PRODUCTION

### Variables d'Environnement :
```bash
# Services externes (inchangés)
WHISPER_STT_URL=http://whisper-stt:8001
PIPER_TTS_URL=http://azure-tts:5002
MISTRAL_API_KEY=your_api_key
MISTRAL_BASE_URL=https://api.scaleway.ai/.../v1/chat/completions

# Optimisations production
LIVEKIT_LOG_LEVEL=info  # debug pour développement
LIVEKIT_AGENT_NAME=eloquence-coach-production
```

### Paramètres de Performance :
```python
# STT Configuration
CHUNK_DURATION = 1.0  # secondes
SAMPLE_RATE = 16000   # Hz optimal pour Whisper
SILENCE_THRESHOLD = 500  # Niveau de détection VAD
MAX_RETRIES = 3
TIMEOUT = 10.0  # secondes

# TTS Configuration  
CHUNK_SIZE_MS = 200  # millisecondes pour faible latence
MAX_CHUNK_LENGTH = 100  # caractères par chunk
AUDIO_VOLUME = 0.8  # Éviter saturation
SAMPLE_RATE_TTS = 24000  # Hz pour qualité

# LLM Configuration
WORDS_PER_CHUNK = 3  # Mots par chunk streaming
CACHE_TIMEOUT = 300  # secondes
MAX_HISTORY = 8  # Messages dans l'historique
```

## 🚀 DÉPLOIEMENT PRODUCTION

### 1. Démarrage Standard :
```bash
cd services/api-backend
python services/real_time_voice_agent_v1.py
```

### 2. Démarrage avec Docker :
```bash
docker-compose up eloquence-agent-v1
```

### 3. Test de Simulation :
```bash
python services/real_time_voice_agent_v1.py simulate
```

## 📊 MONITORING ET LOGS

### Logs Production :
- `🚀 PRODUCTION:` - Logs de production avec métriques
- `🔍 DIAGNOSTIC:` - Logs de debug (désactivés en production)

### Métriques Importantes :
- **Latence STT** : < 2 secondes par chunk
- **Latence TTS** : < 500ms par chunk audio
- **Latence LLM** : < 3 secondes par réponse
- **Taux de retry** : < 10% des requêtes
- **Qualité audio** : > 1000 bytes par chunk

### Health Checks :
```bash
# Vérifier l'agent
curl http://localhost:8080/health

# Vérifier les services externes
curl http://whisper-stt:8001/health
curl http://azure-tts:5002/health
```

## 🔄 INTÉGRATION FLUTTER

### Configuration LiveKit Flutter :
```dart
// Configuration optimisée pour production
final room = Room(
  roomOptions: RoomOptions(
    adaptiveStream: true,
    dynacast: true,
    audioSettings: AudioSettings(
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
    ),
  ),
);

// Connexion à l'agent
await room.connect(
  'ws://localhost:7880',
  'your-token',
  roomName: 'eloquence-session',
);
```

## 🛠️ MAINTENANCE

### Nettoyage Automatique :
- **Fichiers temporaires** : Suppression automatique après traitement
- **Sessions HTTP** : Pool de connexions avec expiration
- **Cache LLM** : Nettoyage périodique des entrées anciennes

### Surveillance :
- **Connexions actives** : Monitoring du pool HTTP
- **Mémoire audio** : Surveillance des buffers
- **Erreurs réseau** : Alertes sur échecs répétés

## 🎯 PERFORMANCES ATTENDUES

### Latences Cibles :
- **STT** : 1-2 secondes (chunk processing)
- **LLM** : 2-4 secondes (génération + cache)
- **TTS** : 0.2-0.5 secondes (premier chunk audio)
- **End-to-End** : 3-6 secondes (question → réponse audio)

### Throughput :
- **Utilisateurs simultanés** : 10-20 par instance
- **Chunks audio/seconde** : 50-100
- **Requêtes API/minute** : 200-500

## 🔒 SÉCURITÉ PRODUCTION

### Authentification :
- **API Keys** : Rotation automatique recommandée
- **Tokens LiveKit** : Expiration courte (1h)
- **HTTPS** : Obligatoire pour tous les services externes

### Rate Limiting :
- **Whisper STT** : 10 req/sec par utilisateur
- **Azure TTS** : 5 req/sec par utilisateur  
- **Mistral LLM** : 2 req/sec par utilisateur

---

## ✅ VALIDATION

L'implémentation production est **complète et testée** :
- ✅ Streaming STT temps réel avec VAD
- ✅ Streaming TTS avec chunking intelligent
- ✅ Streaming LLM avec cache et retry
- ✅ Gestion d'erreurs robuste
- ✅ Optimisations de performance
- ✅ Monitoring et logs complets

**L'agent est prêt pour la production !** 🚀