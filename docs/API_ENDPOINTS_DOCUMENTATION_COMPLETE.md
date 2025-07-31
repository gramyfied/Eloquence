# 📚 Documentation des Endpoints API - Eloquence (COMPLÈTE ET MISE À JOUR)

## 🌟 Vue d'ensemble

L'API Eloquence est une API REST complète développée avec FastAPI pour l'application Flutter Eloquence. Elle fournit des endpoints pour la gestion des exercices d'élocution, la génération d'histoires, le boost de confiance et les statistiques utilisateur.

**⚠️ MISE À JOUR**: Documentation basée sur les tests réels effectués sur Scaleway (51.159.110.4) le 31/07/2025.

---

## 🌐 Accès aux Endpoints à Distance

### 📍 URLs de Base selon l'Environnement

#### 🏠 Développement Local
```
Backend Principal: http://localhost:8000
API Exercices:     http://localhost:8005
Service Vosk STT:  http://localhost:8002
Service Mistral:   http://localhost:8001
LiveKit Server:    http://localhost:7880
Token Service:     http://localhost:8004
```

#### ☁️ **SCALEWAY (ÉTAT ACTUEL - TESTÉ)**
```
✅ Service Vosk STT:  http://51.159.110.4:8002 (FONCTIONNEL)
❌ Backend Principal: http://51.159.110.4:8080 (HORS LIGNE)
❌ API Exercices:     http://51.159.110.4:8080 (HORS LIGNE)
❌ Service Mistral:   https://api.scaleway.ai/.../v1 (HTTP 403)
🔄 LiveKit Server:    http://51.159.110.4:7880 (NON TESTÉ)
🔄 Token Service:     http://51.159.110.4:8004 (NON TESTÉ)
```

#### 🚀 Production avec Reverse Proxy (Recommandé)
```
API Principale:    https://api.votre-domaine.com
API Exercices:     https://api.votre-domaine.com/exercises
Service STT:       https://api.votre-domaine.com/stt
Service IA:        https://api.votre-domaine.com/ai
LiveKit:           wss://livekit.votre-domaine.com
```

### 🔧 Configuration pour Accès Distant

#### 1. Configuration Flutter (app_config.dart) - MISE À JOUR

**Configuration Actuelle (Scaleway):**
```dart
class AppConfig {
  static const bool useRemoteServer = true; // ✅ ACTIVÉ
  static const String remoteServerIp = '51.159.110.4'; // IP Scaleway
  static const String localServerIp = '192.168.1.44';
  
  // 🎯 API UNIFIÉE ELOQUENCE (Port 8080 selon documentation)
  static String get apiBaseUrl {
    return _buildUrl('http', 8080); // ✅ CORRIGÉ: Port 8080
  }

  // 🎤 SERVICE VOSK STT (Port 8002 selon documentation) 
  static String get voskServiceUrl {
    return _buildUrl('http', 8002); // ✅ CORRIGÉ: Port 8002
  }
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'EloquenceApp/1.0',
  };
}
```

**Pour la production sécurisée:**
```dart
class ApiConfig {
  static const String baseUrl = 'https://api.votre-domaine.com';
  static const String exercisesUrl = 'https://api.votre-domaine.com/exercises';
  static const String sttUrl = 'https://api.votre-domaine.com/stt';
  static const String aiUrl = 'https://api.votre-domaine.com/ai';
  static const String livekitUrl = 'wss://livekit.votre-domaine.com';
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'User-Agent': 'EloquenceApp/1.0',
  };
}
```

#### 2. Test de Connectivité à Distance

**Tests Scaleway (IP: 51.159.110.4):**
```bash
# ✅ Service Vosk STT - FONCTIONNEL
curl -X GET "http://51.159.110.4:8002/health"
# Réponse: 200 OK

# ❌ API Unifiée - HORS LIGNE  
curl -X GET "http://51.159.110.4:8080/health"
# Erreur: Connection refused

# ❌ Création de session - HORS LIGNE
curl -X POST "http://51.159.110.4:8080/api/v1/exercises/sessions" \
  -H "Content-Type: application/json" \
  -d '{"template_id": "ai_scenario_conversation"}'
# Erreur: Connection refused
```

**PowerShell (Windows):**
```powershell
# Test de connectivité Scaleway
Invoke-RestMethod -Uri "http://51.159.110.4:8002/health" -Method Get

# Test avec headers
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
Invoke-RestMethod -Uri "http://51.159.110.4:8080/api/exercises" -Method Get -Headers $headers
```

#### 3. Configuration CORS pour Accès Distant

**Backend FastAPI (main.py):**
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",           # Flutter Web dev
        "https://votre-app.com",           # Production web
        "https://51.159.110.4",            # Scaleway direct
        "capacitor://localhost",           # Capacitor iOS
        "http://localhost",                # Capacitor Android
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
```

---

## 🔧 Endpoints de Base

### 1. Health Check & Status

#### `GET /`
**Description**: Endpoint racine de l'API
**URL Scaleway**: `http://51.159.110.4:8080/`
**État**: ❌ CONNECTION_ERROR
**Réponse attendue**:
```json
{
  "message": "API Backend Python - Déployée avec succès !"
}
```

#### `GET /health`
**Description**: Vérification de l'état de santé du service
**URL Scaleway**: `http://51.159.110.4:8080/health`
**État**: ❌ CONNECTION_ERROR
**Réponse attendue**:
```json
{
  "status": "healthy",
  "service": "backend-api"
}
```

#### `GET /health` (Service Vosk STT)
**Description**: Vérification de l'état de santé du service Vosk
**URL Scaleway**: `http://51.159.110.4:8002/health`
**État**: ✅ FONCTIONNEL (200 OK)
**Réponse**:
```json
{
  "status": "healthy",
  "service": "vosk-stt"
}
```

---

## 🎯 **ENDPOINTS RÉELLEMENT DISPONIBLES (SCALEWAY)**

### Service Vosk STT (Port 8002) - ✅ OPÉRATIONNEL

#### `GET /health`
**URL**: `http://51.159.110.4:8002/health`
**Status**: ✅ FONCTIONNEL
**Test**:
```bash
curl -X GET "http://51.159.110.4:8002/health"
# Réponse: 200 OK
```

#### `POST /transcribe` (Supposé)
**URL**: `http://51.159.110.4:8002/transcribe`
**Description**: Transcription audio avec Vosk
**Body**:
```json
{
  "audio_data": "base64_encoded_audio",
  "language": "fr"
}
```

---

## 🚧 **ENDPOINTS NON-FONCTIONNELS (SCALEWAY)**

### API Unifiée (Port 8080) - ❌ HORS LIGNE

#### `GET /api/v1/exercises/templates`
**URL**: `http://51.159.110.4:8080/api/v1/exercises/templates`
**État**: ❌ CONNECTION_ERROR
**Description**: Récupère les templates d'exercices disponibles

#### `POST /api/v1/exercises/sessions`
**URL**: `http://51.159.110.4:8080/api/v1/exercises/sessions`
**État**: ❌ CONNECTION_ERROR
**Description**: Crée une nouvelle session d'exercice
**Body attendu**:
```json
{
  "template_id": "ai_scenario_conversation",
  "user_id": "user_123",
  "settings": {
    "language": "fr",
    "scenario_type": "presentation",
    "difficulty": "intermediate"
  }
}
```

#### `WS /api/v1/exercises/realtime/{session_id}`
**URL**: `ws://51.159.110.4:8080/api/v1/exercises/realtime/session_123`
**État**: ❌ CONNECTION_ERROR
**Description**: WebSocket pour interaction temps réel

---

## 📦 Gestion des Items (CRUD Générique)

### 2. Items - Liste

#### `GET /api/items`
**Description**: Récupère la liste de tous les items
**URL Scaleway**: `http://51.159.110.4:8080/api/items`
**État**: ❌ CONNECTION_ERROR
**Réponse**: `Array<Item>`
```json
[
  {
    "id": 1,
    "name": "Item exemple",
    "description": "Description de l'item",
    "price": 29.99
  }
]
```

### 3. Items - Création

#### `POST /api/items`
**Description**: Crée un nouvel item
**URL Scaleway**: `http://51.159.110.4:8080/api/items`
**État**: ❌ CONNECTION_ERROR
**Body**:
```json
{
  "name": "string",
  "description": "string (optionnel)",
  "price": "number"
}
```

### 4. Items - Détail

#### `GET /api/items/{item_id}`
**Description**: Récupère un item spécifique par son ID
**URL Scaleway**: `http://51.159.110.4:8080/api/items/{item_id}`
**État**: ❌ CONNECTION_ERROR
**Paramètres**:
- `item_id` (path): ID de l'item

### 5. Items - Mise à jour

#### `PUT /api/items/{item_id}`
**Description**: Met à jour un item existant
**URL Scaleway**: `http://51.159.110.4:8080/api/items/{item_id}`
**État**: ❌ CONNECTION_ERROR

### 6. Items - Suppression

#### `DELETE /api/items/{item_id}`
**Description**: Supprime un item
**URL Scaleway**: `http://51.159.110.4:8080/api/items/{item_id}`
**État**: ❌ CONNECTION_ERROR

---

## 👥 Gestion des Utilisateurs

### 7. Utilisateurs - Liste

#### `GET /api/users`
**Description**: Récupère la liste de tous les utilisateurs
**URL Scaleway**: `http://51.159.110.4:8080/api/users`
**État**: ❌ CONNECTION_ERROR

### 8. Utilisateurs - Création

#### `POST /api/users`
**Description**: Crée un nouvel utilisateur
**URL Scaleway**: `http://51.159.110.4:8080/api/users`
**État**: ❌ CONNECTION_ERROR

---

## 🏃‍♂️ Module Exercices

### 9. Exercices - Liste complète

#### `GET /api/exercises`
**Description**: Récupère tous les exercices disponibles
**URL Scaleway**: `http://51.159.110.4:8080/api/exercises`
**État**: ❌ CONNECTION_ERROR
**Réponse**: `Array<Exercise>`

### 10. Exercices - Détail

#### `GET /api/exercises/{exercise_id}`
**Description**: Récupère un exercice spécifique
**URL Scaleway**: `http://51.159.110.4:8080/api/exercises/{exercise_id}`
**État**: ❌ CONNECTION_ERROR

### 11. Exercices - Par type

#### `GET /api/exercises/type/{exercise_type}`
**Description**: Récupère les exercices filtrés par type
**URL Scaleway**: `http://51.159.110.4:8080/api/exercises/type/{exercise_type}`
**État**: ❌ CONNECTION_ERROR

---

## 💪 Module Confidence Boost

### 12. Confidence Boost - Informations

#### `GET /api/confidence-boost`
**Description**: Informations sur le module Confidence Boost
**URL Scaleway**: `http://51.159.110.4:8080/api/confidence-boost`
**État**: ❌ CONNECTION_ERROR

### 13. Confidence Boost - Créer session

#### `POST /api/confidence-boost/session`
**Description**: Crée une nouvelle session de confidence boost
**URL Scaleway**: `http://51.159.110.4:8080/api/confidence-boost/session`
**État**: ❌ CONNECTION_ERROR

### 14. Confidence Boost - Évaluation

#### `POST /api/confidence-boost/evaluate`
**Description**: Évalue la performance d'une session
**URL Scaleway**: `http://51.159.110.4:8080/api/confidence-boost/evaluate`
**État**: ❌ CONNECTION_ERROR

---

## 📖 Module Story Generator

### 16. Story Generator - Informations

#### `GET /api/story-generator`
**Description**: Informations sur le module Story Generator
**URL Scaleway**: `http://51.159.110.4:8080/api/story-generator`
**État**: ❌ CONNECTION_ERROR

### 17. Story Generator - Liste histoires

#### `GET /api/story-generator/stories`
**Description**: Récupère toutes les histoires disponibles
**URL Scaleway**: `http://51.159.110.4:8080/api/story-generator/stories`
**État**: ❌ CONNECTION_ERROR

### 18. Story Generator - Générer histoire

#### `POST /api/story-generator/generate`
**Description**: Génère une nouvelle histoire personnalisée
**URL Scaleway**: `http://51.159.110.4:8080/api/story-generator/generate`
**État**: ❌ CONNECTION_ERROR

### 19. Story Generator - Analyser narration

#### `POST /api/story-generator/analyze`
**Description**: Analyse la performance de narration d'une histoire
**URL Scaleway**: `http://51.159.110.4:8080/api/story-generator/analyze`
**État**: ❌ CONNECTION_ERROR

---

## 🤖 Service Mistral AI

### 20. Mistral API - Modèles

#### `GET /models`
**Description**: Liste des modèles Mistral disponibles
**URL**: `https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1/models`
**État**: ❌ HTTP 403 (Clé API invalide/expirée)
**Headers requis**:
```json
{
  "Authorization": "Bearer VQ30NR4P1V3AVCZJNKDRNHBCGP2DSNCQ",
  "Content-Type": "application/json"
}
```

---

## 📊 État Actuel des Services (31/07/2025)

### ✅ **SERVICES FONCTIONNELS**
| Service | URL | Port | Status |
|---------|-----|------|--------|
| Vosk STT | http://51.159.110.4:8002 | 8002 | ✅ OK (200) |

### ❌ **SERVICES HORS LIGNE**
| Service | URL | Port | Status |
|---------|-----|------|--------|
| API Unifiée | http://51.159.110.4:8080 | 8080 | ❌ CONNECTION_ERROR |
| Exercices | http://51.159.110.4:8080/api/exercises | 8080 | ❌ CONNECTION_ERROR |
| Sessions | http://51.159.110.4:8080/api/v1/exercises/sessions | 8080 | ❌ CONNECTION_ERROR |
| WebSocket | ws://51.159.110.4:8080/api/v1/exercises/realtime/* | 8080 | ❌ CONNECTION_ERROR |
| Mistral API | https://api.scaleway.ai/.../v1/models | - | ❌ HTTP 403 |

---

## 🚀 Actions Prioritaires

### **URGENCE 1 - Redémarrer API Principale**
```bash
# Sur le serveur Scaleway (51.159.110.4)
sudo docker restart eloquence-api
# ou
sudo docker-compose up eloquence-api -d
```

### **URGENCE 2 - Vérifier Mistral API**
```bash
# Tester avec nouvelle clé API
curl -X GET "https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1/models" \
  -H "Authorization: Bearer NOUVELLE_CLE_API" \
  -H "Content-Type: application/json"
```

### **MOYEN TERME - Monitoring**
```bash
# Vérifier les logs
docker logs eloquence-api-1 -f
docker logs eloquence-vosk-stt-1 -f

# Vérifier l'état des containers
docker ps -a
```

---

## 🔍 Scripts de Test Créés

### 1. `test_scaleway_clean.py`
**Description**: Test complet de connectivité Scaleway sans Unicode
**Usage**:
```bash
python test_scaleway_clean.py
```
**Résultat**: Score 1/7 tests réussis

### 2. `test_correct_endpoints.py`
**Description**: Test avec les vrais endpoints selon documentation
**Usage**:
```bash
python test_correct_endpoints.py
```

### 3. Script de diagnostic rapide
```bash
# Test rapide de tous les services
curl http://51.159.110.4:8002/health  # ✅ OK
curl http://51.159.110.4:8080/health  # ❌ CONNECTION_ERROR
```

---

## 🎯 **CONCLUSION ET RECOMMANDATIONS**

### **État Actuel**
- **Frontend Flutter**: ✅ Complètement fonctionnel avec interface scénarios IA
- **Configuration**: ✅ Mise à jour pour utiliser Scaleway (51.159.110.4)
- **Service Vosk**: ✅ Opérationnel sur port 8002
- **API Principale**: ❌ Hors ligne sur port 8080
- **Mistral IA**: ❌ Clé API expirée (HTTP 403)

### **Impact Utilisateur**
Les scénarios IA fonctionnent en **mode dégradé** avec interface complète mais limitations backend.

### **Solution Rapide**
1. Redémarrer l'API principale sur Scaleway port 8080
2. Renouveler la clé Mistral API
3. Re-tester avec `python test_scaleway_clean.py`

**Score Cible**: 7/7 tests réussis pour fonctionnalité complète des scénarios IA.

---

*Documentation mise à jour le 31/07/2025 basée sur tests réels Scaleway*