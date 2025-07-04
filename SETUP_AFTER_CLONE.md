# 🚀 GUIDE DE CONFIGURATION POST-CLONE - ELOQUENCE

## ⚠️ ÉTAPES OBLIGATOIRES APRÈS CLONE GITHUB

### 1. **Créer le fichier .env principal**
```bash
# Copier le template
cp .env.example .env
```

Puis éditer `.env` avec vos vraies valeurs :
```bash
# =================================================
# ELOQUENCE - VARIABLES D'ENVIRONNEMENT
# =================================================

# --- LiveKit Configuration ---
LIVEKIT_API_KEY=votre_vraie_cle_livekit
LIVEKIT_API_SECRET=votre_vraie_cle_secrete_livekit_32_caracteres_minimum
LIVEKIT_URL=ws://localhost:7880

# --- Services API Keys ---
OPENAI_API_KEY=sk-votre_vraie_cle_openai
AZURE_TTS_API_KEY=votre_cle_azure_tts
MISTRAL_API_KEY=votre_vraie_cle_mistral

# --- Backend Services URLs ---
STT_SERVICE_URL=http://eloquence-whisper-stt:8001
LLM_SERVICE_URL=http://eloquence-llm-service:8002
TTS_SERVICE_URL=http://eloquence-tts-service:8003
OPENAI_TTS_SERVICE_URL=http://openai-tts:5002/synthesize

# --- Database Configuration ---
POSTGRES_USER=eloquence_user
POSTGRES_PASSWORD=votre_mot_de_passe_fort
POSTGRES_DB=eloquence_db

# --- Redis Configuration ---
REDIS_HOST=eloquence-redis
REDIS_PORT=6379
```

### 2. **Créer le fichier .env pour le backend**
```bash
# Créer services/api-backend/.env
mkdir -p services/api-backend
```

Contenu de `services/api-backend/.env` :
```bash
# Variables d'environnement LiveKit
LIVEKIT_URL=ws://localhost:7880
LIVEKIT_API_KEY=votre_vraie_cle_livekit
LIVEKIT_API_SECRET=votre_vraie_cle_secrete_livekit_32_caracteres_minimum

# Variables d'environnement pour les services IA
MISTRAL_BASE_URL=https://api.mistral.ai/v1/chat/completions
MISTRAL_API_KEY=votre_vraie_cle_mistral
MISTRAL_MODEL=mistral-small-latest
OPENAI_API_KEY=votre_vraie_cle_openai

# Configuration pour les tests locaux
ENVIRONMENT=development
DEBUG=true
```

### 3. **Configurer Flutter**
Éditer `frontend/flutter_app/.env` avec vos vraies valeurs :
```bash
LIVEKIT_API_KEY=votre_vraie_cle_livekit
LIVEKIT_API_SECRET=votre_vraie_cle_secrete_livekit
WHISPER_STT_URL=http://whisper-stt:8001
OPENAI_TTS_URL=http://openai-tts:5002
OPENAI_API_KEY=votre_vraie_cle_openai
MISTRAL_API_KEY=votre_vraie_cle_mistral
MISTRAL_BASE_URL=https://api.mistral.ai/v1/chat/completions
MISTRAL_MODEL=mistral-small-latest
```

## 🔑 OÙ OBTENIR LES CLÉS API

### LiveKit
1. Aller sur https://cloud.livekit.io/
2. Créer un compte gratuit
3. Créer un nouveau projet
4. Copier `API Key` et `API Secret`

### OpenAI
1. Aller sur https://platform.openai.com/api-keys
2. Créer une nouvelle clé API
3. Format : `sk-...`

### Mistral AI
1. Aller sur https://console.mistral.ai/
2. Créer un compte
3. Générer une clé API
4. Format : UUID (ex: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

## 🚀 DÉMARRAGE RAPIDE

### Option 1 : Docker (Recommandé)
```bash
# 1. Cloner le repo
git clone https://github.com/gramyfied/Eloquence.git
cd Eloquence

# 2. Configurer les .env (voir ci-dessus)

# 3. Démarrer tous les services
docker-compose up -d

# 4. Vérifier que tout fonctionne
docker-compose logs -f
```

### Option 2 : Développement local
```bash
# 1. Backend Python
cd services/api-backend
pip install -r requirements.txt
python app.py

# 2. Frontend Flutter
cd frontend/flutter_app
flutter pub get
flutter run
```

## 🔧 VÉRIFICATION POST-INSTALLATION

### Test des services
```bash
# Vérifier LiveKit
curl http://localhost:7880/

# Vérifier Backend
curl http://localhost:8000/health

# Vérifier Whisper STT
curl http://localhost:8001/health

# Vérifier OpenAI TTS
curl http://localhost:5002/health
```

### Test de l'agent IA
```bash
# Voir les logs de l'agent
docker-compose logs -f eloquence-agent-v1
```

## ⚠️ PROBLÈMES COURANTS

### 1. Erreur "LIVEKIT_API_KEY not found"
- Vérifiez que le fichier `.env` existe
- Vérifiez que les variables sont bien définies
- Redémarrez Docker : `docker-compose restart`

### 2. Erreur "Connection refused"
- Vérifiez que tous les services sont démarrés : `docker-compose ps`
- Vérifiez les ports : `netstat -an | findstr "7880\|8000\|8001"`

### 3. Agent IA ne répond pas
- Vérifiez les clés API OpenAI et Mistral
- Vérifiez les logs : `docker-compose logs eloquence-agent-v1`

## 📞 SUPPORT

Si vous rencontrez des problèmes :
1. Vérifiez les logs : `docker-compose logs`
2. Vérifiez la configuration réseau : `docker network ls`
3. Redémarrez complètement : `docker-compose down && docker-compose up -d`

## 🔒 SÉCURITÉ

- **JAMAIS** commiter les fichiers `.env` avec de vraies clés
- Utilisez des clés API avec des permissions minimales
- Changez régulièrement vos clés API
- En production, utilisez des secrets managers (Azure Key Vault, AWS Secrets Manager, etc.)