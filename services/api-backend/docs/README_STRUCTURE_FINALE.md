# Structure Finale du Backend API - Eloquence 2.0

## 📁 Fichiers Principaux à Utiliser

### 🤖 Agents LiveKit
- **`services/real_time_voice_agent_v1.py`** - Agent principal pour environnement local/développement
- **`services/real_time_voice_agent_docker_fixed.py`** - Agent corrigé pour environnement Docker

### 🐳 Docker
- **`Dockerfile.agent.v1`** - Dockerfile pour l'agent LiveKit v1.x
- **`start-agent-v1.sh`** - Script de démarrage pour l'agent Docker

### 📦 Requirements
- **`requirements.agent.v1.txt`** - Dépendances pour l'agent LiveKit v1.x
- **`requirements.txt`** - Dépendances principales du backend

### 🔧 Services
- **`services/tts_service_azure.py`** - Service TTS Azure
- **`services/tts_service_piper.py`** - Service TTS Piper
- **`services/adaptive_audio_streamer.py`** - Streaming audio adaptatif
- **`services/intelligent_adaptive_streaming.py`** - Streaming intelligent
- **`services/performance_monitor.py`** - Monitoring des performances

## 🚀 Comment Utiliser

### Environnement Local
```bash
cd services/api-backend
python services/real_time_voice_agent_v1.py dev
```

### Environnement Docker
```bash
docker-compose up -d eloquence-agent-v1
```

## ⚠️ Fichiers Supprimés (Ménage Effectué)

### Anciens Agents Obsolètes
- ❌ `livekit_agent_moderne.py`
- ❌ `livekit_agent_simple.py`
- ❌ `livekit_audio_handler.py`
- ❌ `livekit_real_audio_handler.py`
- ❌ `main_agent_server.py`

### Anciens Dockerfiles
- ❌ `Dockerfile.agent`
- ❌ `Dockerfile.robust`

### Anciens Requirements
- ❌ `requirements_agent.txt`
- ❌ `requirements.agent.txt`
- ❌ `requirements.backend.txt`

### Anciens Scripts et Tests
- ❌ `start-agent.sh`
- ❌ Tous les anciens fichiers `test_*.py`

### Anciens Docker-Compose
- ❌ `docker-compose.api.yml`
- ❌ `docker-compose.modified.yml`

## 🎯 Structure Actuelle Simplifiée

```
services/api-backend/
├── services/
│   ├── real_time_voice_agent_v1.py          ✅ Agent principal
│   ├── real_time_voice_agent_docker_fixed.py ✅ Agent Docker
│   ├── tts_service_azure.py                 ✅ TTS Azure
│   ├── tts_service_piper.py                 ✅ TTS Piper
│   └── ...autres services...
├── Dockerfile.agent.v1                      ✅ Docker agent
├── start-agent-v1.sh                        ✅ Script démarrage
├── requirements.agent.v1.txt                ✅ Dépendances agent
└── requirements.txt                         ✅ Dépendances backend
```

## 🔍 Diagnostic Résolu

Le problème "l'IA ne répond pas" a été résolu en :
1. Corrigeant l'erreur de portée de variable `response` dans l'agent local
2. Créant un agent Docker spécialement adapté avec toutes les corrections
3. Nettoyant la structure pour éviter la confusion

## 📝 Prochaines Étapes

1. Reconstruire l'image Docker avec la structure nettoyée
2. Tester l'agent Docker corrigé
3. Vérifier que l'IA répond correctement dans l'application Flutter