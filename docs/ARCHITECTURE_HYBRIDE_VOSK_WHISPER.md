# Architecture Hybride VOSK + Whisper - Documentation Technique

## Vue d'Ensemble du Système

### Mission
Le **Système d'Évaluation Hybride VOSK + Whisper** remplace complètement l'ancienne technologie Kaldi dans l'application Eloquence. Il combine la reconnaissance vocale temps réel (VOSK) avec la transcription haute précision (Whisper large-v3-turbo) pour offrir une expérience utilisateur optimale.

### Philosophie Architecturale
- **Temps réel** : Feedback immédiat pendant l'enregistrement vocal via VOSK
- **Précision finale** : Analyse détaillée post-enregistrement via Whisper
- **Robustesse** : Mécanismes de fallback multicouches
- **Performance** : Architecture asynchrone optimisée pour la concurrence

---

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION ELOQUENCE                        │
├─────────────────────────────────────────────────────────────────┤
│                    FRONTEND FLUTTER                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Realtime VOSK   │  │ Prosody Monitor │  │ Hybrid Service  │ │
│  │ Feedback Widget │  │ Widget          │  │ Integration     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                   COMMUNICATION LAYER                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ WebSocket       │  │ HTTP REST       │  │ Fallback        │ │
│  │ Temps Réel      │  │ API             │  │ Mechanism       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    BACKEND HYBRIDE                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ VOSK Realtime   │  │ Whisper Client  │  │ Hybrid          │ │
│  │ Service         │  │ Service         │  │ Orchestrator    │ │
│  │ Port: 8002      │  │ Port: 8001      │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                   SERVICES EXTERNES                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ VOSK Model      │  │ Whisper         │  │ Mistral         │ │
│  │ Français        │  │ large-v3-turbo  │  │ Emergency       │ │
│  │ (Local)         │  │ (Existing)      │  │ Fallback        │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Composants Principaux

### 1. **Service Hybride Principal** (`main.py`)

**Responsabilités** :
- Point d'entrée unique sur port 8002
- Coordination WebSocket et REST API
- Gestion des sessions temps réel
- Orchestration des services VOSK et Whisper

**Endpoints Clés** :
```python
# WebSocket Temps Réel
GET /ws/realtime
# Sessions et évaluation
POST /start-realtime-session
POST /process-realtime-audio  
POST /finish-realtime-session
# Monitoring
GET /health
GET /status
```

### 2. **Service VOSK Temps Réel** (`vosk_realtime_service.py`)

**Caractéristiques** :
- Modèle français : `vosk-model-fr-0.22`
- Traitement streaming : chunks audio 16kHz
- Métriques prosodiques : WPM, énergie, pauses
- Gestion sessions concurrentes

**Métriques Calculées** :
```python
{
    'speech_rate': float,        # Mots par minute
    'energy_level': float,       # Niveau d'énergie [0-1]
    'pause_detected': bool,      # Détection de pause
    'hesitation_count': int,     # Nombre d'hésitations
    'confidence': float          # Confiance globale [0-1]
}
```

### 3. **Service Client Whisper** (`whisper_client_service.py`)

**Fonctionnalités** :
- Connexion au service Whisper existant (port 8001)
- Retry automatique avec backoff exponentiel
- Streaming de gros fichiers audio
- Validation et nettoyage des transcriptions

**Configuration Retry** :
```python
max_retries = 3
backoff_factor = 2.0
timeout = 30.0
```

### 4. **Orchestrateur Hybride** (`hybrid_orchestrator.py`)

**Rôle Central** :
- Coordination VOSK ↔ Whisper
- Gestion du cycle de vie des sessions
- Mécanismes de fallback
- Agrégation des résultats

**Workflow Session** :
```python
1. start_realtime_session() → session_id
2. process_realtime_audio() → feedback VOSK
3. finish_realtime_session() → analyse Whisper + résultat final
```

---

## Architecture Flutter

### 1. **Service d'Intégration Hybride**

**Fichier** : `hybrid_speech_evaluation_service.dart`

**Responsabilités** :
- Gestion WebSocket temps réel
- Fallback automatique intelligent
- Gestion des états de connexion
- Cache des résultats

**Fallback en Cascade** :
```dart
Service Hybride (8002) 
    ↓ (si échec)
Backend Classique 
    ↓ (si échec)  
Mistral d'Urgence
```

### 2. **Widgets Temps Réel**

#### **Widget Feedback VOSK** (`realtime_vosk_feedback_widget.dart`)
- Visualisation transcription partielle
- Indicateurs de confiance animés
- Métriques prosodiques temps réel
- Alertes qualité vocale

#### **Widget Monitoring Prosodique** (`prosody_metrics_monitor_widget.dart`)
- Graphiques temps réel (WPM, énergie)
- Détection de pauses visuelles
- Historique des métriques
- Recommandations adaptatives

### 3. **Provider État Global**

**Fichier** : `confidence_boost_provider.dart`

**États Gérés** :
```dart
enum HybridEvaluationState {
  idle,
  connecting,
  realtime_active,
  processing_final,
  completed,
  error
}
```

---

## Protocoles de Communication

### 1. **WebSocket Temps Réel**

#### **Connexion**
```
ws://localhost:8002/ws/realtime
```

#### **Messages Client → Serveur**
```json
// Démarrage session
{
  "type": "start_session",
  "config": {
    "language": "fr",
    "sample_rate": 16000
  }
}

// Chunk audio
{
  "type": "audio_chunk",
  "session_id": "session_123",
  "audio_data": "base64_encoded_audio",
  "chunk_index": 0
}

// Fin session
{
  "type": "end_session",
  "session_id": "session_123"
}
```

#### **Messages Serveur → Client**
```json
// Session démarrée
{
  "type": "session_started",
  "session_id": "session_123",
  "status": "success"
}

// Feedback temps réel
{
  "type": "realtime_feedback",
  "session_id": "session_123",
  "vosk_result": {
    "partial": "transcription partielle",
    "confidence": 0.85
  },
  "prosody_metrics": {
    "speech_rate": 150,
    "energy_level": 0.7,
    "pause_detected": false
  },
  "timestamp": 1698765432.123
}

// Résultat final
{
  "type": "session_ended",
  "session_id": "session_123",
  "final_result": {
    "transcription": "Transcription finale complète",
    "confidence": 0.92,
    "prosody_score": 0.88,
    "analysis": {
      "total_duration": 45.2,
      "word_count": 89,
      "average_wpm": 118,
      "pause_ratio": 0.15
    }
  }
}
```

### 2. **API REST Complémentaire**

#### **Démarrage Session**
```http
POST /start-realtime-session
Content-Type: application/json

{
  "config": {
    "language": "fr",
    "sample_rate": 16000
  }
}

Response:
{
  "session_id": "session_123",
  "websocket_url": "ws://localhost:8002/ws/realtime"
}
```

#### **Monitoring Santé**
```http
GET /health

Response:
{
  "status": "healthy",
  "services": {
    "vosk": "operational",
    "whisper": "operational"
  },
  "active_sessions": 3,
  "uptime": 7200
}
```

---

## Mécanismes de Fallback

### 1. **Niveaux de Fallback**

#### **Niveau 1 : Service Principal**
- **Service** : Hybride VOSK + Whisper (port 8002)
- **Capacités** : Temps réel + Analyse finale
- **Performance** : Optimale

#### **Niveau 2 : Backend Classique**
- **Service** : Analyse Whisper seule (port 8001)
- **Capacités** : Analyse finale uniquement
- **Performance** : Dégradée (pas de temps réel)

#### **Niveau 3 : Urgence Mistral**
- **Service** : Fallback d'urgence
- **Capacités** : Transcription basique
- **Performance** : Minimale

### 2. **Détection de Panne**

#### **Critères de Basculement**
```python
# Timeout de connexion
connection_timeout = 5.0

# Échecs consécutifs
max_consecutive_failures = 3

# Latence excessive
max_acceptable_latency = 2.0

# Taux d'erreur
max_error_rate = 0.1  # 10%
```

#### **Mécanisme de Récupération**
```python
async def attempt_recovery():
    for attempt in range(max_recovery_attempts):
        try:
            await test_service_health()
            return True
        except Exception:
            await asyncio.sleep(backoff_delay * (2 ** attempt))
    return False
```

### 3. **Stratégies de Fallback**

#### **Fallback Gracieux**
- Notification utilisateur transparente
- Conservation des données de session
- Basculement automatique sans interruption

#### **Mode Dégradé**
- Fonctionnalité réduite mais opérationnelle
- Métriques de qualité adaptées
- Indication claire du mode dégradé

#### **Récupération Automatique**
- Surveillance continue des services
- Basculement automatique vers service principal
- Restauration graduelle des fonctionnalités

---

## Métriques et Monitoring

### 1. **Métriques de Performance**

#### **Latence Temps Réel**
- Délai WebSocket : < 100ms
- Traitement VOSK : < 50ms  
- Feedback total : < 200ms

#### **Précision**
- VOSK temps réel : ~80-85%
- Whisper finale : ~92-95%
- Combinaison hybride : ~90-94%

#### **Débit**
- Sessions concurrentes : 50+
- Chunks audio/seconde : 100+
- Throughput WebSocket : 10 MB/s

### 2. **Métriques Prosodiques**

#### **Vitesse de Parole**
```python
speech_rate = (word_count / duration_seconds) * 60  # WPM
normal_range = (120, 180)  # WPM acceptable
```

#### **Niveau d'Énergie**
```python
energy_level = rms_amplitude / max_possible_amplitude
confidence_threshold = 0.3  # Seuil minimal
```

#### **Détection de Pauses**
```python
pause_threshold = 0.5  # secondes
hesitation_markers = ["euh", "hum", "alors"]
```

### 3. **Monitoring Santé Système**

#### **Indicateurs Clés**
- Utilisation CPU/mémoire
- Nombre de sessions actives
- Taux d'erreur par service
- Temps de réponse moyen

#### **Alertes Automatiques**
- Service indisponible
- Performance dégradée
- Utilisation ressources excessive
- Taux d'erreur élevé

---

## Sécurité et Performance

### 1. **Sécurité**

#### **Validation des Entrées**
```python
# Validation taille audio
max_chunk_size = 1024 * 1024  # 1MB
max_session_duration = 300  # 5 minutes

# Validation format
allowed_formats = ["wav", "mp3", "ogg"]
required_sample_rate = 16000
```

#### **Gestion des Sessions**
```python
# Nettoyage automatique
session_timeout = 1800  # 30 minutes
cleanup_interval = 300  # 5 minutes

# Limitation concurrence
max_concurrent_sessions = 100
```

### 2. **Optimisation Performance**

#### **Cache et Mémoire**
- Cache résultats VOSK récents
- Pool de connexions réutilisables
- Nettoyage automatique des ressources

#### **Traitement Asynchrone**
- WebSocket non-bloquant
- Pool de workers pour audio
- Parallélisation des services

#### **Optimisation Réseau**
- Compression audio
- Batching des chunks
- Keep-alive des connexions

---

## Configuration et Déploiement

### 1. **Variables d'Environnement**

```bash
# Service hybride
HYBRID_SERVICE_PORT=8002
HYBRID_SERVICE_HOST=0.0.0.0

# Services externes
WHISPER_SERVICE_URL=http://localhost:8001
VOSK_MODEL_PATH=/opt/vosk/models/vosk-model-fr-0.22

# Configuration performance
MAX_CONCURRENT_SESSIONS=100
SESSION_TIMEOUT=1800
CHUNK_SIZE_LIMIT=1048576

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
```

### 2. **Configuration Docker**

#### **Dockerfile Hybride**
```dockerfile
FROM python:3.11-slim

# Installation dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Installation dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Modèle VOSK
RUN wget -O vosk-model.zip \
    https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip && \
    unzip vosk-model.zip && \
    rm vosk-model.zip

# Code application
COPY . /app
WORKDIR /app

EXPOSE 8002
CMD ["python", "main.py"]
```

#### **Docker Compose Integration**
```yaml
version: '3.8'
services:
  hybrid-speech-evaluation:
    build: ./services/hybrid-speech-evaluation
    ports:
      - "8002:8002"
    environment:
      - WHISPER_SERVICE_URL=http://whisper-large-v3-turbo:8001
      - VOSK_MODEL_PATH=/opt/vosk/models/vosk-model-fr-0.22
    depends_on:
      - whisper-large-v3-turbo
    volumes:
      - vosk_models:/opt/vosk/models
    restart: unless-stopped
```

### 3. **Dépendances Système**

#### **Requirements Production**
```
fastapi>=0.104.1
uvicorn[standard]>=0.24.0
websockets>=12.0
vosk>=0.3.45
aiohttp>=3.9.0
numpy>=1.24.0
scipy>=1.11.0
pydantic>=2.5.0
```

#### **Requirements Test**
```
pytest>=7.4.0
pytest-asyncio>=0.21.0
aioresponses>=0.7.4
coverage>=7.3.0
pytest-cov>=4.1.0
```

---

## Troubleshooting

### 1. **Problèmes Courants**

#### **Service VOSK ne démarre pas**
```bash
# Vérifier modèle VOSK
ls -la /opt/vosk/models/
# Télécharger si manquant
wget https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip
```

#### **WebSocket se déconnecte**
```python
# Vérifier configuration réseau
websocket_timeout = 60.0
keepalive_interval = 30.0
```

#### **Performance dégradée**
```bash
# Monitoring ressources
docker stats hybrid-speech-evaluation
# Ajuster limites
docker update --memory=2g --cpus=2 hybrid-speech-evaluation
```

### 2. **Debugging**

#### **Logs Structurés**
```python
import logging
import json

logger = logging.getLogger(__name__)
logger.info(json.dumps({
    "event": "session_started",
    "session_id": session_id,
    "timestamp": time.time()
}))
```

#### **Métriques Prometheus**
```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('requests_total', 'Total requests')
REQUEST_DURATION = Histogram('request_duration_seconds', 'Request duration')
```

---

## Tests et Qualité

### 1. **Suite de Tests**

#### **Tests Unitaires** (1284 lignes)
- `test_vosk_realtime_service.py` : Tests service VOSK
- `test_whisper_client_service.py` : Tests client Whisper
- `test_hybrid_orchestrator.py` : Tests orchestrateur

#### **Tests d'Intégration** (517 lignes)
- `test_websocket_integration.py` : Tests WebSocket

#### **Tests Robustesse** (604 lignes)
- `test_fallback_robustness.py` : Tests fallback et charge

### 2. **Couverture et Qualité**

#### **Objectifs Couverture**
- Code coverage : > 80%
- Branch coverage : > 75%
- Tests critiques : 100%

#### **Exécution Tests**
```bash
# Tests complets
pytest services/hybrid-speech-evaluation/tests/ -v

# Avec couverture
pytest --cov=services --cov-report=html

# Tests performance
pytest -m performance --maxfail=1
```

---

## Roadmap et Évolutions

### 1. **Améliorations Prévues**

#### **Performance**
- Cache distribué Redis
- Load balancing multi-instances
- Optimisation modèles IA

#### **Fonctionnalités**
- Support multi-langues
- Détection émotions vocales
- Analytics avancées

#### **Infrastructure**
- Kubernetes deployment
- Monitoring Grafana/Prometheus
- CI/CD automatisé

### 2. **Migration Kaldi → Hybride**

#### **Plan de Migration**
1. **Phase 1** : Déploiement service hybride ✅
2. **Phase 2** : Tests parallèles Kaldi/Hybride ✅
3. **Phase 3** : Basculement progressif utilisateurs
4. **Phase 4** : Suppression complète Kaldi
5. **Phase 5** : Optimisation post-migration

#### **Critères de Succès**
- Performance ≥ Kaldi
- Fiabilité > 99.5%
- Satisfaction utilisateur maintenue
- Coût infrastructure optimisé

---

Cette documentation technique fournit une vue complète de l'architecture hybride VOSK + Whisper. Elle sert de référence pour le développement, la maintenance et l'évolution du système.