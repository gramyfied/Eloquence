# API Eloquence Exercises

API complète pour la gestion d'exercices d'éloquence avec analyse vocale avancée temps réel et batch.

## 🎯 Vue d'ensemble

L'API Eloquence Exercises offre une plateforme complète pour :
- **Gestion d'exercices** d'éloquence personnalisés
- **Analyse vocale batch** avec Vosk pour évaluation complète
- **Analyse vocale temps réel** via WebSocket pour feedback instantané
- **Métriques détaillées** de performance vocale
- **Templates d'exercices** réutilisables
- **Sessions d'entraînement** avec suivi de progression

## 🏗️ Architecture

### Services Intégrés
- **FastAPI** : API REST + WebSocket
- **Redis** : Cache et stockage des sessions
- **Vosk STT** : Service de reconnaissance vocale
- **Docker** : Containerisation complète

### Structure des Données
```
eloquence-exercises-api/
├── app.py                           # API principale FastAPI
├── models/
│   └── exercise_models.py          # Modèles Pydantic
├── test_voice_analysis_simple.py   # Tests REST
├── test_websocket_realtime.py      # Tests WebSocket
├── WEBSOCKET_REALTIME_GUIDE.md     # Guide WebSocket
├── Dockerfile                      # Configuration Docker
└── requirements.txt                # Dépendances Python
```

## ⚡ Fonctionnalités Principales

### 1. API REST Classique

#### Gestion des Exercices
- `POST /api/exercises` - Créer un exercice
- `GET /api/exercises` - Lister les exercices
- `GET /api/exercises/{exercise_id}` - Détails d'un exercice
- `PUT /api/exercises/{exercise_id}` - Modifier un exercice
- `DELETE /api/exercises/{exercise_id}` - Supprimer un exercice

#### Gestion des Sessions
- `POST /api/sessions` - Démarrer une session
- `GET /api/sessions/{session_id}` - État d'une session
- `POST /api/sessions/{session_id}/complete` - Terminer une session

#### Templates d'Exercices
- `POST /api/templates` - Créer un template
- `GET /api/templates` - Lister les templates
- `POST /api/templates/{template_id}/instantiate` - Créer exercice depuis template

### 2. Analyse Vocale Batch

#### Endpoints d'Analyse
- `POST /api/voice-analysis` - Analyse vocale simple
- `POST /api/voice-analysis/detailed` - Analyse détaillée avec Vosk

**Exemple d'utilisation :**
```bash
curl -X POST "http://localhost:8001/api/voice-analysis/detailed" \
  -F "audio=@audio.wav" \
  -F "scenario_type=pronunciation_practice" \
  -F "scenario_context=Exercice de prononciation française"
```

**Réponse typique :**
```json
{
  "analysis_id": "analysis_123",
  "transcription": "bonjour comment allez-vous",
  "confidence": 0.87,
  "metrics": {
    "clarity_score": 0.85,
    "fluency_score": 0.78,
    "pronunciation_accuracy": 0.82
  },
  "feedback": {
    "strengths": ["Excellente clarté"],
    "improvements": ["Travailler l'intonation"],
    "detailed_feedback": "Très bonne prononciation générale..."
  }
}
```

### 3. 🚀 Analyse Vocale Temps Réel (WebSocket)

#### Endpoint WebSocket
```
ws://localhost:8001/ws/voice-analysis/{session_id}
```

#### Protocole de Communication
1. **START_SESSION** - Initialiser la session
2. **AUDIO_CHUNK** - Envoyer chunks audio en continu
3. **PARTIAL_RESULT** - Recevoir transcription partielle
4. **METRICS_UPDATE** - Recevoir métriques temps réel
5. **END_SESSION** - Terminer et obtenir résultat final

**Métriques Temps Réel :**
- `clarity_score` - Clarté de prononciation (0-1)
- `fluency_score` - Fluidité de la parole (0-1)
- `energy_score` - Énergie/dynamisme (0-1)
- `speaking_rate` - Débit en mots/minute
- `pause_ratio` - Ratio de pauses
- `cumulative_confidence` - Confiance moyenne

## 🚀 Installation et Démarrage

### Prérequis
- Docker et Docker Compose
- Python 3.9+ (pour développement local)

### Démarrage avec Docker
```bash
# Cloner le repo et naviguer vers le projet
cd services/eloquence-exercises-api

# Démarrer tous les services
docker-compose up --build

# L'API sera disponible sur :
# - REST API : http://localhost:8001
# - WebSocket : ws://localhost:8001/ws/voice-analysis/{session_id}
# - Documentation : http://localhost:8001/docs
```

### Services Inclus
- **eloquence-exercises-api** : Port 8001
- **vosk-stt-analysis** : Port 8002
- **redis** : Port 6379

### Démarrage en Développement
```bash
# Installer les dépendances
pip install -r requirements.txt

# Variables d'environnement
export REDIS_URL=redis://localhost:6379
export VOSK_SERVICE_URL=http://localhost:8002

# Démarrer l'API
uvicorn app:app --host 0.0.0.0 --port 8001 --reload
```

## 🧪 Tests et Validation

### Tests REST
```bash
# Test des endpoints classiques
python test_voice_analysis_simple.py

# Résultat attendu :
# ✅ Test /api/voice-analysis : SUCCESS (200)
# ✅ Test /api/voice-analysis/detailed : SUCCESS (200)
```

### Tests WebSocket
```bash
# Test analyse temps réel
python test_websocket_realtime.py

# Résultat attendu :
# 🔌 Connexion WebSocket établie
# ✅ Session démarrée avec succès
# 🎤 Chunk 1: 'bonjour' (confiance: 0.87)
# 📊 Métriques: clarté=0.85, fluidité=0.78
# 🎉 Session terminée avec succès!
```

### Tests Manuels
```bash
# Connectivité de base
curl http://localhost:8001/api/health

# Statistiques du système
curl http://localhost:8001/api/statistics
```

## 📖 Documentation API

### Documentation Interactive
- **Swagger UI** : http://localhost:8001/docs
- **ReDoc** : http://localhost:8001/redoc

### Guides Détaillés
- [`WEBSOCKET_REALTIME_GUIDE.md`](./WEBSOCKET_REALTIME_GUIDE.md) - Guide complet WebSocket
- [`test_websocket_realtime.py`](./test_websocket_realtime.py) - Exemples d'utilisation
- [`test_voice_analysis_simple.py`](./test_voice_analysis_simple.py) - Tests REST

## 🔧 Configuration

### Variables d'Environnement
```bash
# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=your_password

# Service Vosk
VOSK_SERVICE_URL=http://localhost:8002

# Logging
LOG_LEVEL=INFO

# CORS (pour frontend)
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080"]
```

### Format Audio Supporté
**Pour WebSocket Temps Réel :**
- Format : WAV (PCM)
- Échantillonnage : 16 kHz
- Channels : 1 (mono)
- Encodage : Base64
- Durée chunk : 0.5s (recommandé)

**Pour REST Batch :**
- Formats : WAV, MP3, M4A, OGG
- Échantillonnage : 8-48 kHz
- Channels : 1-2
- Taille max : 50 MB

## 🔄 Intégration avec d'autres Services

### Avec Frontend Flutter
```dart
// Service d'analyse temps réel
class EloquenceExercisesService {
  static const String baseUrl = 'http://localhost:8001';
  static const String wsUrl = 'ws://localhost:8001';
  
  // REST endpoints
  Future<Map<String, dynamic>> analyzeAudio(File audioFile) async {
    // Implementation REST
  }
  
  // WebSocket temps réel
  Stream<VoiceAnalysisUpdate> startRealtimeAnalysis(String sessionId) {
    // Implementation WebSocket
  }
}
```

### Avec autres APIs
```python
# Intégration avec l'API Streaming existante
import httpx

async def integrate_with_streaming_api():
    # Analyser avec Eloquence Exercises
    response = await httpx.post(
        "http://localhost:8001/api/voice-analysis/detailed",
        files={"audio": audio_data},
        data={"scenario_type": "fluency_training"}
    )
    
    # Utiliser les résultats avec d'autres services
    analysis = response.json()
    # ...
```

## 📊 Monitoring et Métriques

### Endpoints de Monitoring
- `GET /api/health` - Santé du service
- `GET /api/statistics` - Statistiques d'utilisation
  - Nombre d'exercices
  - Sessions actives/complétées
  - Connexions WebSocket actives
  - Analyses vocales effectuées

### Logs Structurés
```bash
# Voir les logs en temps réel
docker-compose logs -f eloquence-exercises-api

# Exemple de logs
2025-01-26 10:30:45 INFO 🎯 Session temps réel démarrée: session_123
2025-01-26 10:30:46 INFO 🎤 Chunk 1 traité avec confiance: 0.87
2025-01-26 10:30:50 INFO 📊 Métriques calculées: clarté=0.85
```

## 🔐 Sécurité et Limitations

### Sécurité
- **Validation** : Tous les inputs sont validés avec Pydantic
- **Rate Limiting** : À implémenter selon les besoins
- **CORS** : Configuré pour les domaines autorisés
- **Authentification** : À ajouter selon l'architecture

### Limitations Performance
- **WebSocket** : ~10-20 chunks/seconde maximum
- **Latence** : ~100-500ms par chunk audio
- **Mémoire** : ~50MB par session WebSocket active
- **Storage** : Redis avec expiration automatique (24h)

### Contraintes Audio
- **Taille max** : 50MB pour batch, 2s max par chunk WebSocket
- **Formats** : WAV recommandé pour meilleure qualité
- **Qualité** : 16kHz minimum pour résultats optimaux

## 🛠️ Développement et Contribution

### Structure du Code
```python
# models/exercise_models.py - Modèles de données
class ExerciseCreate(BaseModel):
    title: str
    description: str
    exercise_type: ExerciseType

# app.py - Endpoints principaux
@app.post("/api/voice-analysis/detailed")
async def analyze_voice_detailed(...)

@app.websocket("/ws/voice-analysis/{session_id}")
async def websocket_voice_analysis_realtime(...)
```

### Ajout de Nouvelles Fonctionnalités
1. **Modèles** : Ajouter dans `models/exercise_models.py`
2. **Endpoints** : Implémenter dans `app.py`
3. **Tests** : Créer scripts de test appropriés
4. **Documentation** : Mettre à jour ce README

### Pipeline de Test
```bash
# Tests unitaires
python -m pytest tests/

# Tests d'intégration
python test_voice_analysis_simple.py
python test_websocket_realtime.py

# Tests de charge (optionnel)
# pip install locust
# locust -f tests/load_test.py
```

## 🚨 Dépannage

### Problèmes Courants

**Connexion WebSocket échoue**
```bash
# Vérifier que les services sont démarrés
docker-compose ps

# Vérifier les logs
docker-compose logs eloquence-exercises-api
```

**Erreur 422 sur l'analyse vocale**
- Vérifier le format audio (WAV recommandé)
- Contrôler la taille du fichier (< 50MB)
- Valider les paramètres requis

**Service Vosk inaccessible**
```bash
# Test de connectivité
curl http://localhost:8002/health

# Redémarrer le service
docker-compose restart vosk-stt-analysis
```

**Performance WebSocket dégradée**
- Réduire la taille des chunks audio
- Vérifier la latence réseau
- Monitorer l'utilisation mémoire

### Support et Contact
- **Issues** : Créer un ticket GitHub
- **Documentation** : Consulter les guides détaillés
- **Tests** : Exécuter les scripts de validation

---

## 📈 Roadmap

### Fonctionnalités à Venir
- [ ] Authentification JWT
- [ ] Rate limiting avancé
- [ ] Métriques Prometheus
- [ ] Support multi-langues
- [ ] IA pour feedback personnalisé
- [ ] Export des résultats (PDF, CSV)

### Améliorations Techniques
- [ ] Cache Redis optimisé
- [ ] Load balancing WebSocket
- [ ] Compression audio adaptative
- [ ] Streaming audio optimisé

---

*API Eloquence Exercises - Version complète avec analyse temps réel*
*Développé avec FastAPI, Vosk, Redis et Docker*