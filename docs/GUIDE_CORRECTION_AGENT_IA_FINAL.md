# 🤖 Guide Final de Correction - Agent IA qui Crash

## 🔍 PROBLÈME IDENTIFIÉ

**Situation** : L'agent IA (`eloquence-agent-v1`) crash avec l'erreur :
```
"status": "JS_FAILED", "error": "agent worker left the room"
```

**Cause** : L'agent IA ne peut pas se connecter aux services STT/TTS ou perd la connexion.

---

## 🎯 SOLUTION ÉTAPE PAR ÉTAPE

### 1. **Vérifier l'État Actuel**
```bash
# Vérifier quels services fonctionnent
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Vérifier si l'agent IA est démarré
docker ps --filter "name=eloquence-agent"
```

### 2. **Démarrer les Services de Base** 
```bash
# S'assurer que tous les services de base fonctionnent
docker-compose up -d redis livekit whisper-stt azure-tts api-backend
```

### 3. **Attendre la Stabilisation**
```bash
# Attendre que les services soient prêts (important!)
sleep 30
```

### 4. **Démarrer l'Agent IA**
```bash
# Démarrer l'agent IA avec le bon profil
docker-compose --profile agent-v1 up -d eloquence-agent-v1
```

### 5. **Vérifier les Logs**
```bash
# Surveiller les logs de l'agent IA
docker logs -f eloquence-agent-v1
```

---

## 🔧 COMMANDES DE RÉPARATION RAPIDE

### Option A : Redémarrage Complet
```bash
# 1. Arrêt complet
docker-compose down

# 2. Redémarrage ordonné
docker-compose up -d redis livekit whisper-stt azure-tts api-backend

# 3. Attendre 30 secondes
sleep 30

# 4. Démarrer l'agent IA
docker-compose --profile agent-v1 up -d eloquence-agent-v1
```

### Option B : Redémarrage de l'Agent Seulement
```bash
# Si les autres services fonctionnent
docker stop eloquence-agent-v1
docker rm eloquence-agent-v1
docker-compose --profile agent-v1 up -d eloquence-agent-v1
```

---

## 📊 VÉRIFICATIONS IMPORTANTES

### ✅ Services Requis
Tous ces services doivent être "Up" :
- `redis` (port 6379)
- `livekit` (port 7880) 
- `whisper-stt` (port 8001)
- `azure-tts` (port 5002)
- `api-backend` (port 8000)
- `eloquence-agent-v1` (port 8080)

### ✅ Tests de Connectivité
```bash
# Test Redis
docker exec redis redis-cli ping

# Test Whisper STT
curl -f http://localhost:8001/health

# Test Azure TTS  
curl -f http://localhost:5002/health

# Test API Backend
curl -f http://localhost:8000/health
```

---

## 🚨 SIGNAUX D'ALERTE DANS LES LOGS

### ❌ Problèmes de Connectivité
```
Connection refused
Service not responding
Timeout
```

### ❌ Problèmes d'Agent
```
JS_FAILED
agent worker left the room
Connection closed
ERROR
```

### ✅ Bon Fonctionnement  
```
Agent connected
Room joined
STT/TTS ready
Worker started
```

---

## 🎯 CONFIGURATION REQUISE

### Variables d'Environnement (docker-compose.yml)
```yaml
environment:
  - LIVEKIT_URL=ws://livekit:7880
  - WHISPER_STT_URL=http://whisper-stt:8001
  - PIPER_TTS_URL=http://azure-tts:5002
  - MISTRAL_API_KEY=your_mistral_api_key_here
```

### Ordre de Démarrage Crucial
1. **Redis** (base de données)
2. **LiveKit** (serveur média)
3. **Whisper STT** (reconnaissance vocale)
4. **Azure TTS** (synthèse vocale)
5. **API Backend** (backend Flutter)
6. **Agent IA** (agent conversationnel) ← **EN DERNIER**

---

## 🏆 TEST FINAL

### 1. Vérifier tous les services
```bash
docker ps
```

### 2. Tester l'application Flutter
```bash
cd frontend/flutter_app
flutter run
```

### 3. Dans l'application
1. **Sélectionner un scénario**
2. **Parler dans le microphone**
3. **Attendre la réponse de l'IA** (2-3 secondes)
4. **Vérifier que l'IA répond avec du son**

---

## 📱 SI L'IA NE RÉPOND TOUJOURS PAS

### Diagnostic Avancé
```bash
# 1. Logs détaillés de l'agent
docker logs eloquence-agent-v1 --tail 50

# 2. Vérifier la connectivité réseau Docker
docker network ls
docker network inspect 25eloquence-finalisation_eloquence-network

# 3. Test de connectivité depuis l'agent
docker exec eloquence-agent-v1 curl -f http://whisper-stt:8001/health
docker exec eloquence-agent-v1 curl -f http://azure-tts:5002/health
```

### Actions Correctives
1. **Redémarrer Docker Desktop** (Windows)
2. **Nettoyer les volumes Docker** : `docker system prune -a`
3. **Reconstruire l'agent** : `docker-compose build eloquence-agent-v1`

---

## 🎉 SUCCÈS ATTENDU

**Quand tout fonctionne** :
```
🎤 Voix utilisateur → 📝 Whisper STT → 🧠 Agent IA → 🔊 Azure TTS → 📱 Réponse audio
```

**L'IA devrait** :
- ✅ Entendre et comprendre vos questions
- ✅ Générer des réponses intelligentes
- ✅ Répondre avec une voix naturelle
- ✅ Maintenir la conversation active

---

## 🆘 SUPPORT URGENT

Si le problème persiste :

1. **Copier les logs** : `docker logs eloquence-agent-v1 > agent_logs.txt`
2. **État des services** : `docker ps > services_status.txt`  
3. **Configuration** : `docker-compose config > config_check.txt`

**L'agent IA est la clé pour que votre IA puisse répondre !** 🤖✨
