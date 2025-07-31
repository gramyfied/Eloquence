# 📚 DOCUMENTATION COMPLÈTE DES ENDPOINTS ELOQUENCE

## 🎯 Vue d'Ensemble

Cette documentation présente **TOUS** les endpoints disponibles dans l'écosystème Eloquence, incluant le nouveau **Dashboard de Monitoring** ultra-moderne. Chaque service est documenté avec des exemples concrets et des cas d'usage.

---

## 🏗️ ARCHITECTURE DES SERVICES

```
┌─────────────────────────────────────────────────────────────┐
│                    ELOQUENCE ECOSYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│  🌐 Frontend (Flutter Web)           Port: 3000            │
│  🔧 Backend API Principal            Port: 8000            │
│  🎯 Exercices API                    Port: 8005            │
│  🎤 Vosk STT (Speech-to-Text)        Port: 8002            │
│  🤖 Mistral IA Conversation          Port: 8001            │
│  📹 LiveKit Server                   Port: 7880            │
│  🔑 LiveKit Token Service            Port: 8004            │
│  📊 Dashboard Monitoring             Port: 8006            │
│  🗄️ Redis Cache                      Port: 6379            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 DASHBOARD MONITORING (Port 8006)

### **🎯 Endpoints Principaux**

#### **GET /** - Interface Dashboard
```http
GET http://localhost:8006/
Content-Type: text/html
```
**Description** : Interface web complète du dashboard avec métriques en temps réel

**Réponse** : Page HTML avec dashboard interactif

---

#### **GET /health** - Health Check
```http
GET http://localhost:8006/health
```

**Réponse** :
```json
{
  "status": "healthy",
  "timestamp": "2025-01-31T17:45:29.304981",
  "version": "1.0.0",
  "uptime": "2 days, 14:32:15"
}
```

---

#### **GET /api/metrics/all** - Toutes les Métriques
```http
GET http://localhost:8006/api/metrics/all
```

**Réponse Complète** :
```json
{
  "timestamp": "2025-01-31T17:45:46.009722",
  "system": {
    "cpu_percent": 61.2,
    "memory_percent": 38.7,
    "disk_percent": 27.6,
    "uptime": "2 days, 14:32:15",
    "load_average": [0.83, 2.42, 1.55]
  },
  "services": [
    {
      "name": "backend-api",
      "status": "healthy",
      "response_time": 45.9,
      "last_check": "2025-01-31T17:45:46.009790",
      "port": 8000
    },
    {
      "name": "eloquence-exercises-api",
      "status": "healthy",
      "response_time": 78.3,
      "last_check": "2025-01-31T17:45:46.009791",
      "port": 8005
    }
  ],
  "business": {
    "active_users": 23,
    "total_sessions": 156,
    "completed_exercises": 89,
    "avg_session_time": 18.5,
    "retention_rate": 87.3
  },
  "performance": {
    "requests_per_minute": 342,
    "error_rate": 0.8,
    "p95_latency": 125,
    "cache_hit_rate": 94.2
  },
  "alerts": [
    {
      "id": "system_ok",
      "type": "success",
      "title": "Système opérationnel",
      "message": "Tous les services fonctionnent normalement",
      "timestamp": "2025-01-31T17:38:00.000Z"
    }
  ]
}
```

---

#### **GET /api/metrics/system** - Métriques Système
```http
GET http://localhost:8006/api/metrics/system
```

**Réponse** :
```json
{
  "cpu_percent": 45.2,
  "memory_percent": 67.8,
  "disk_percent": 23.1,
  "uptime": "2 days, 14:32:15",
  "load_average": [1.2, 1.5, 1.8]
}
```

---

#### **GET /api/metrics/services** - Statut des Services
```http
GET http://localhost:8006/api/metrics/services
```

**Réponse** :
```json
[
  {
    "name": "backend-api",
    "status": "healthy",
    "response_time": 45.2,
    "last_check": "2025-01-31T17:39:55.000Z",
    "port": 8000
  },
  {
    "name": "eloquence-exercises-api", 
    "status": "healthy",
    "response_time": 78.1,
    "last_check": "2025-01-31T17:39:55.000Z",
    "port": 8005
  }
]
```

---

#### **GET /api/metrics/business** - Métriques Business
```http
GET http://localhost:8006/api/metrics/business
```

**Réponse** :
```json
{
  "active_users": 23,
  "total_sessions": 156,
  "completed_exercises": 89,
  "avg_session_time": 18.5,
  "retention_rate": 87.3
}
```

---

#### **GET /api/metrics/performance** - Métriques Performance
```http
GET http://localhost:8006/api/metrics/performance
```

**Réponse** :
```json
{
  "requests_per_minute": 342,
  "error_rate": 0.8,
  "p95_latency": 125,
  "cache_hit_rate": 94.2
}
```

---

#### **GET /api/alerts** - Alertes Actives
```http
GET http://localhost:8006/api/alerts
```

**Réponse** :
```json
[
  {
    "id": "system_ok",
    "type": "success",
    "title": "Système opérationnel",
    "message": "Tous les services fonctionnent normalement",
    "timestamp": "2025-01-31T17:38:00.000Z"
  },
  {
    "id": "memory_warning",
    "type": "warning", 
    "title": "Utilisation mémoire élevée",
    "message": "Redis utilise 78% de la mémoire allouée",
    "timestamp": "2025-01-31T17:35:00.000Z"
  }
]
```

---

## 🔧 BACKEND API PRINCIPAL (Port 8000)

### **🎯 Endpoints Core**

#### **GET /health** - Health Check
```http
GET http://localhost:8000/health
```

**Réponse** :
```json
{
  "status": "healthy",
  "timestamp": "2025-01-31T17:40:00Z",
  "version": "1.0.0",
  "services": {
    "redis": "connected",
    "database": "operational"
  }
}
```

---

#### **GET /api/exercises** - Liste des Exercices
```http
GET http://localhost:8000/api/exercises
```

**Réponse** :
```json
[
  {
    "id": "confidence_boost_1",
    "title": "Renforcement de la Confiance - Niveau 1",
    "description": "Exercice d'introduction pour développer la confiance en soi",
    "difficulty": "beginner",
    "duration": 300,
    "category": "confidence",
    "tags": ["confiance", "débutant", "introduction"]
  },
  {
    "id": "public_speaking_basic",
    "title": "Prise de Parole en Public - Bases",
    "description": "Fondamentaux de la prise de parole en public",
    "difficulty": "beginner", 
    "duration": 600,
    "category": "public_speaking",
    "tags": ["public", "parole", "bases"]
  }
]
```

---

#### **GET /api/exercises/{exercise_id}** - Détails d'un Exercice
```http
GET http://localhost:8000/api/exercises/confidence_boost_1
```

**Réponse** :
```json
{
  "id": "confidence_boost_1",
  "title": "Renforcement de la Confiance - Niveau 1",
  "description": "Exercice d'introduction pour développer la confiance en soi",
  "difficulty": "beginner",
  "duration": 300,
  "category": "confidence",
  "instructions": [
    "Respirez profondément pendant 30 secondes",
    "Répétez les affirmations positives",
    "Visualisez votre succès"
  ],
  "prompts": [
    "Décrivez une situation où vous vous êtes senti confiant",
    "Quels sont vos points forts principaux ?",
    "Comment vous voyez-vous dans 5 ans ?"
  ],
  "success_criteria": {
    "min_speaking_time": 120,
    "confidence_threshold": 0.7,
    "completion_rate": 0.8
  }
}
```

---

#### **POST /api/sessions** - Créer une Session
```http
POST http://localhost:8000/api/sessions
Content-Type: application/json

{
  "exercise_id": "confidence_boost_1",
  "user_id": "user_123",
  "session_type": "practice"
}
```

**Réponse** :
```json
{
  "session_id": "session_456789",
  "exercise_id": "confidence_boost_1",
  "user_id": "user_123",
  "status": "created",
  "created_at": "2025-01-31T17:40:00Z",
  "livekit_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "room_name": "eloquence_session_456789"
}
```

---

#### **GET /api/sessions/{session_id}** - Détails d'une Session
```http
GET http://localhost:8000/api/sessions/session_456789
```

**Réponse** :
```json
{
  "session_id": "session_456789",
  "exercise_id": "confidence_boost_1",
  "user_id": "user_123",
  "status": "in_progress",
  "created_at": "2025-01-31T17:40:00Z",
  "started_at": "2025-01-31T17:41:00Z",
  "duration": 180,
  "metrics": {
    "speaking_time": 120,
    "confidence_level": 0.75,
    "speech_clarity": 0.82
  }
}
```

---

#### **POST /api/sessions/{session_id}/complete** - Terminer une Session
```http
POST http://localhost:8000/api/sessions/session_456789/complete
Content-Type: application/json

{
  "final_metrics": {
    "speaking_time": 240,
    "confidence_level": 0.85,
    "speech_clarity": 0.88
  },
  "user_feedback": {
    "difficulty_rating": 3,
    "satisfaction": 4,
    "comments": "Exercice très utile pour la confiance"
  }
}
```

**Réponse** :
```json
{
  "session_id": "session_456789",
  "status": "completed",
  "completed_at": "2025-01-31T17:45:00Z",
  "total_duration": 300,
  "success": true,
  "score": 85,
  "achievements": ["first_completion", "confidence_builder"],
  "next_recommended": "confidence_boost_2"
}
```

---

#### **GET /api/stats** - Statistiques Globales
```http
GET http://localhost:8000/api/stats
```

**Réponse** :
```json
{
  "total_sessions": 1247,
  "completed_sessions": 1089,
  "total_users": 156,
  "active_users_today": 23,
  "total_practice_time": 45678,
  "average_session_duration": 285,
  "completion_rate": 0.87,
  "top_exercises": [
    {
      "id": "confidence_boost_1",
      "completions": 234,
      "avg_score": 82
    }
  ],
  "user_progress": {
    "beginner": 45,
    "intermediate": 78,
    "advanced": 33
  }
}
```

---

## 🎯 EXERCICES API (Port 8005)

### **🎯 Endpoints Spécialisés**

#### **GET /health** - Health Check
```http
GET http://localhost:8005/health
```

#### **GET /api/exercises/categories** - Catégories d'Exercices
```http
GET http://localhost:8005/api/exercises/categories
```

**Réponse** :
```json
[
  {
    "id": "confidence",
    "name": "Confiance en Soi",
    "description": "Exercices pour renforcer la confiance",
    "exercise_count": 12,
    "difficulty_levels": ["beginner", "intermediate", "advanced"]
  },
  {
    "id": "public_speaking",
    "name": "Prise de Parole en Public",
    "description": "Maîtriser l'art de parler en public",
    "exercise_count": 8,
    "difficulty_levels": ["beginner", "intermediate", "advanced"]
  }
]
```

---

#### **GET /api/exercises/search** - Recherche d'Exercices
```http
GET http://localhost:8005/api/exercises/search?q=confiance&difficulty=beginner&category=confidence
```

**Réponse** :
```json
{
  "query": "confiance",
  "filters": {
    "difficulty": "beginner",
    "category": "confidence"
  },
  "total_results": 5,
  "exercises": [
    {
      "id": "confidence_boost_1",
      "title": "Renforcement de la Confiance - Niveau 1",
      "relevance_score": 0.95,
      "match_highlights": ["confiance", "renforcement"]
    }
  ]
}
```

---

#### **POST /api/exercises/{exercise_id}/start** - Démarrer un Exercice
```http
POST http://localhost:8005/api/exercises/confidence_boost_1/start
Content-Type: application/json

{
  "user_id": "user_123",
  "session_preferences": {
    "ai_coaching": true,
    "real_time_feedback": true,
    "difficulty_adjustment": "auto"
  }
}
```

**Réponse** :
```json
{
  "session_id": "session_789012",
  "exercise_id": "confidence_boost_1",
  "livekit_room": "eloquence_exercise_789012",
  "livekit_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "ai_agent_enabled": true,
  "initial_prompt": "Bonjour ! Je suis votre coach IA. Commençons par vous présenter brièvement.",
  "session_config": {
    "max_duration": 600,
    "auto_save_interval": 30,
    "feedback_frequency": "real_time"
  }
}
```

---

## 🎤 VOSK STT - SPEECH TO TEXT (Port 8002)

### **🎯 Endpoints de Transcription**

#### **GET /health** - Health Check
```http
GET http://localhost:8002/health
```

#### **POST /transcribe** - Transcription Audio
```http
POST http://localhost:8002/transcribe
Content-Type: multipart/form-data

{
  "audio_file": [fichier audio],
  "language": "fr-FR",
  "format": "wav",
  "sample_rate": 16000
}
```

**Réponse** :
```json
{
  "transcription": "Bonjour, je suis très heureux de participer à cet exercice de confiance en soi.",
  "confidence": 0.92,
  "processing_time": 1.23,
  "word_count": 13,
  "language_detected": "fr-FR",
  "segments": [
    {
      "start": 0.0,
      "end": 2.1,
      "text": "Bonjour, je suis très heureux",
      "confidence": 0.95
    },
    {
      "start": 2.1,
      "end": 4.8,
      "text": "de participer à cet exercice de confiance en soi",
      "confidence": 0.89
    }
  ]
}
```

---

#### **POST /transcribe/stream** - Transcription en Temps Réel
```http
POST http://localhost:8002/transcribe/stream
Content-Type: application/json

{
  "session_id": "session_789012",
  "audio_chunk": "base64_encoded_audio_data",
  "chunk_index": 1,
  "is_final": false
}
```

**Réponse** :
```json
{
  "session_id": "session_789012",
  "chunk_index": 1,
  "partial_transcription": "Bonjour je suis",
  "is_final": false,
  "confidence": 0.78,
  "processing_time": 0.15
}
```

---

#### **GET /transcribe/session/{session_id}** - Historique de Session
```http
GET http://localhost:8002/transcribe/session/session_789012
```

**Réponse** :
```json
{
  "session_id": "session_789012",
  "total_duration": 300.5,
  "total_words": 245,
  "average_confidence": 0.87,
  "full_transcription": "Transcription complète de la session...",
  "analysis": {
    "speaking_rate": 150,
    "pause_frequency": 12,
    "filler_words": 3,
    "clarity_score": 0.89
  }
}
```

---

## 🤖 MISTRAL IA CONVERSATION (Port 8001)

### **🎯 Endpoints d'IA Conversationnelle**

#### **GET /health** - Health Check
```http
GET http://localhost:8001/health
```

#### **POST /chat** - Conversation avec l'IA
```http
POST http://localhost:8001/chat
Content-Type: application/json

{
  "message": "Je me sens nerveux avant de parler en public. Que puis-je faire ?",
  "context": {
    "exercise_id": "public_speaking_basic",
    "user_level": "beginner",
    "session_id": "session_789012"
  },
  "conversation_history": [
    {
      "role": "user",
      "content": "Bonjour, je commence l'exercice"
    },
    {
      "role": "assistant", 
      "content": "Bonjour ! Je suis ravi de vous accompagner dans cet exercice."
    }
  ]
}
```

**Réponse** :
```json
{
  "response": "C'est tout à fait normal de ressentir de la nervosité ! Voici 3 techniques efficaces : 1) Respirez profondément en comptant jusqu'à 4, 2) Visualisez votre succès, 3) Commencez par un sourire. Voulez-vous que nous pratiquions ensemble ?",
  "confidence": 0.94,
  "response_time": 0.85,
  "suggestions": [
    "Pratiquer la respiration",
    "Exercice de visualisation",
    "Techniques de relaxation"
  ],
  "coaching_tips": [
    "La nervosité diminue avec la pratique",
    "Concentrez-vous sur votre message, pas sur votre peur"
  ],
  "next_actions": [
    "start_breathing_exercise",
    "practice_introduction",
    "record_practice_speech"
  ]
}
```

---

#### **POST /analyze** - Analyse de Performance
```http
POST http://localhost:8001/analyze
Content-Type: application/json

{
  "session_id": "session_789012",
  "transcription": "Bonjour tout le monde. Aujourd'hui je vais vous parler de... euh... de l'importance de la confiance en soi.",
  "metrics": {
    "speaking_time": 180,
    "pause_count": 8,
    "filler_words": 3,
    "volume_level": 0.7
  },
  "exercise_context": {
    "exercise_id": "confidence_boost_1",
    "target_duration": 300,
    "difficulty": "beginner"
  }
}
```

**Réponse** :
```json
{
  "overall_score": 78,
  "detailed_analysis": {
    "content_quality": {
      "score": 82,
      "feedback": "Bon début avec une introduction claire. Le message principal est identifiable."
    },
    "delivery": {
      "score": 75,
      "feedback": "Débit approprié, mais quelques hésitations. Travaillez sur la fluidité."
    },
    "confidence": {
      "score": 70,
      "feedback": "Bonne posture générale. Les 'euh' trahissent une légère nervosité."
    }
  },
  "strengths": [
    "Introduction engageante",
    "Volume de voix approprié",
    "Sujet bien choisi"
  ],
  "areas_for_improvement": [
    "Réduire les mots de remplissage",
    "Préparer les transitions",
    "Pratiquer la respiration"
  ],
  "personalized_recommendations": [
    {
      "type": "exercise",
      "title": "Exercice anti-hésitation",
      "description": "Pratiquez en enregistrant des phrases courtes sans 'euh'"
    },
    {
      "type": "technique",
      "title": "Technique de la pause",
      "description": "Remplacez les 'euh' par des pauses silencieuses"
    }
  ],
  "next_session_focus": [
    "Fluidité de parole",
    "Gestion des transitions",
    "Confiance vocale"
  ]
}
```

---

#### **POST /coaching** - Coaching Personnalisé
```http
POST http://localhost:8001/coaching
Content-Type: application/json

{
  "user_profile": {
    "level": "beginner",
    "goals": ["public_speaking", "confidence"],
    "previous_sessions": 3,
    "average_score": 72
  },
  "current_challenge": "fear_of_judgment",
  "session_context": {
    "exercise_id": "confidence_boost_1",
    "current_step": 2,
    "time_remaining": 240
  }
}
```

**Réponse** :
```json
{
  "coaching_message": "Je comprends votre appréhension du jugement. Rappelez-vous : votre audience veut que vous réussissiez ! Concentrons-nous sur votre message plutôt que sur leurs réactions.",
  "motivational_quote": "Le courage n'est pas l'absence de peur, mais l'action malgré la peur.",
  "immediate_actions": [
    {
      "action": "breathing_exercise",
      "duration": 30,
      "instruction": "Respirez profondément 5 fois en comptant jusqu'à 4"
    },
    {
      "action": "positive_affirmation",
      "duration": 60,
      "instruction": "Répétez : 'J'ai quelque chose d'important à partager'"
    }
  ],
  "progress_encouragement": "Vous avez déjà progressé de 15% depuis votre première session !",
  "adaptive_difficulty": {
    "current_level": "beginner",
    "suggested_adjustment": "maintain",
    "reason": "Progression constante, continuez à ce rythme"
  }
}
```

---

## 📹 LIVEKIT SERVER (Port 7880)

### **🎯 Endpoints WebRTC**

#### **GET /** - Status LiveKit
```http
GET http://localhost:7880/
```

#### **WebSocket** - Connexion Temps Réel
```
ws://localhost:7880/
```

**Utilisation** : Connexion WebSocket pour audio/vidéo en temps réel avec tokens JWT

---

## 🔑 LIVEKIT TOKEN SERVICE (Port 8004)

### **🎯 Endpoints de Tokens**

#### **GET /health** - Health Check
```http
GET http://localhost:8004/health
```

#### **POST /token** - Générer un Token
```http
POST http://localhost:8004/token
Content-Type: application/json

{
  "room_name": "eloquence_session_789012",
  "participant_name": "user_123",
  "permissions": {
    "can_publish": true,
    "can_subscribe": true,
    "can_publish_data": true
  },
  "metadata": {
    "exercise_id": "confidence_boost_1",
    "user_level": "beginner"
  }
}
```

**Réponse** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MDY3MjQwMDAsImlzcyI6ImRldmtleSIsIm5iZiI6MTcwNjcyMDQwMCwic3ViIjoidXNlcl8xMjMiLCJ2aWRlbyI6eyJjYW5QdWJsaXNoIjp0cnVlLCJjYW5TdWJzY3JpYmUiOnRydWUsInJvb20iOiJlbG9xdWVuY2Vfc2Vzc2lvbl83ODkwMTIifX0.signature",
  "room_name": "eloquence_session_789012",
  "participant_name": "user_123",
  "expires_at": "2025-01-31T18:40:00Z",
  "server_url": "ws://localhost:7880"
}
```

---

#### **POST /room/create** - Créer une Room
```http
POST http://localhost:8004/room/create
Content-Type: application/json

{
  "room_name": "eloquence_session_789012",
  "max_participants": 2,
  "empty_timeout": 300,
  "metadata": {
    "exercise_id": "confidence_boost_1",
    "session_type": "practice",
    "ai_agent_enabled": true
  }
}
```

**Réponse** :
```json
{
  "room_name": "eloquence_session_789012",
  "status": "created",
  "created_at": "2025-01-31T17:40:00Z",
  "config": {
    "max_participants": 2,
    "empty_timeout": 300,
    "recording_enabled": false
  },
  "access_token": "room_creation_token_here"
}
```

---

## 🗄️ REDIS CACHE (Port 6379)

### **🎯 Commandes Redis**

#### **PING** - Test de Connexion
```redis
PING
```
**Réponse** : `PONG`

#### **Clés de Cache Eloquence**
```redis
# Sessions actives
GET session:session_789012

# Métriques utilisateur
GET user:user_123:stats

# Cache des exercices
GET exercise:confidence_boost_1

# Métriques système
GET system:metrics:latest
```

---

## 🌐 FRONTEND FLUTTER WEB (Port 3000)

### **🎯 Routes Principales**

#### **/** - Page d'Accueil
```http
GET http://localhost:3000/
```

#### **/exercises** - Liste des Exercices
```http
GET http://localhost:3000/exercises
```

#### **/exercise/{id}** - Page d'Exercice
```http
GET http://localhost:3000/exercise/confidence_boost_1
```

#### **/session/{id}** - Session en Cours
```http
GET http://localhost:3000/session/session_789012
```

#### **/dashboard** - Tableau de Bord Utilisateur
```http
GET http://localhost:3000/dashboard
```

---

## 🔧 COMMANDES DE GESTION

### **🚀 Démarrage des Services**

```bash
# Démarrer tous les services
docker-compose up -d

# Démarrer un service spécifique
docker-compose up -d eloquence-dashboard

# Voir les logs en temps réel
docker-compose logs -f eloquence-dashboard

# Vérifier le statut
docker-compose ps
```

### **🔍 Tests des Endpoints**

```bash
# Test du dashboard
curl http://localhost:8006/health

# Test de l'API principale
curl http://localhost:8000/api/exercises

# Test des métriques complètes
curl http://localhost:8006/api/metrics/all

# Test de transcription
curl -X POST http://localhost:8002/health

# Test de l'IA
curl -X POST http://localhost:8001/health
```

### **📊 Monitoring en Temps Réel**

```bash
# Surveiller les métriques
watch -n 5 'curl -s http://localhost:8006/api/metrics/system'

# Surveiller les services
watch -n 10 'curl -s http://localhost:8006/api/metrics/services'

# Logs de tous les services
docker-compose logs -f --tail=50
```

---

## 🎯 CAS D'USAGE COMPLETS

### **🎭 Scénario 1 : Session d'Exercice Complète**

1. **Créer une session**
   ```bash
   curl -X POST http://localhost:8000/api/sessions \
     -H "Content-Type: application/json" \
     -d '{"exercise_id":"confidence_boost_1","user_
