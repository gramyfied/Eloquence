# 🚀 GUIDE DE DÉMARRAGE - PROJET ELOQUENCE

## 📋 ÉTAPES POUR DÉMARRER VOTRE PROJET

### 1. 🔑 OBTENIR LES CLÉS API (OBLIGATOIRE)

#### A. OpenAI API Key
1. Aller sur https://platform.openai.com/
2. Se connecter/créer un compte
3. Aller dans "API Keys"
4. Cliquer "Create new secret key"
5. Copier la clé (format : `sk-proj-...`)

#### B. Mistral AI API Key
1. Aller sur https://console.mistral.ai/
2. Se connecter/créer un compte
3. Aller dans "API Keys"
4. Cliquer "Create new key"
5. Copier la clé (format UUID)

#### C. LiveKit Credentials
1. Aller sur https://cloud.livekit.io/
2. Se connecter/créer un compte
3. Créer un nouveau projet
4. Dans "Settings" → "Keys", noter :
   - URL du projet (wss://...)
   - API Key
   - API Secret

### 2. 📝 CONFIGURER LES FICHIERS .ENV

#### A. Fichier racine `.env`
```env
# OpenAI Configuration
OPENAI_API_KEY=sk-proj-VOTRE_CLE_OPENAI_ICI

# Mistral AI Configuration  
MISTRAL_API_KEY=VOTRE_CLE_MISTRAL_ICI

# LiveKit Configuration
LIVEKIT_URL=wss://votre-projet.livekit.cloud
LIVEKIT_API_KEY=votre-livekit-api-key
LIVEKIT_API_SECRET=votre-livekit-api-secret
```

#### B. Fichier `frontend/flutter_app/.env`
```env
# LiveKit Configuration for Flutter
LIVEKIT_URL=wss://votre-projet.livekit.cloud
LIVEKIT_API_KEY=votre-livekit-api-key
LIVEKIT_API_SECRET=votre-livekit-api-secret
```

#### C. Fichier `services/api-backend/.env`
```env
# Backend API Configuration
OPENAI_API_KEY=sk-proj-VOTRE_CLE_OPENAI_ICI
MISTRAL_API_KEY=VOTRE_CLE_MISTRAL_ICI
LIVEKIT_URL=wss://votre-projet.livekit.cloud
LIVEKIT_API_KEY=votre-livekit-api-key
LIVEKIT_API_SECRET=votre-livekit-api-secret
```

### 3. 🐳 DÉMARRER LES SERVICES DOCKER

#### A. Vérifier Docker
```bash
docker --version
docker-compose --version
```

#### B. Démarrer tous les services
```bash
# Dans le dossier racine du projet
docker-compose up -d
```

#### C. Vérifier que les services fonctionnent
```bash
docker-compose ps
```

### 4. 📱 DÉMARRER L'APPLICATION FLUTTER

#### A. Vérifier Flutter
```bash
flutter --version
flutter doctor
```

#### B. Installer les dépendances
```bash
cd frontend/flutter_app
flutter pub get
```

#### C. Lancer l'application
```bash
# Pour Android
flutter run

# Pour iOS
flutter run -d ios

# Pour web
flutter run -d web
```

### 5. 🧪 TESTER LES CONNEXIONS

#### A. Test OpenAI
```bash
python services/api-backend/test_openai_connection.py
```

#### B. Test LiveKit
```bash
python services/api-backend/test_livekit_connection.py
```

#### C. Test complet
```bash
python test_all_services.py
```

## 🔧 COMMANDES UTILES

### Docker
```bash
# Voir les logs
docker-compose logs -f

# Redémarrer un service
docker-compose restart nom-du-service

# Arrêter tous les services
docker-compose down

# Reconstruire les images
docker-compose build --no-cache
```

### Flutter
```bash
# Nettoyer le cache
flutter clean
flutter pub get

# Voir les appareils connectés
flutter devices

# Build pour production
flutter build apk
flutter build ios
```

## 🚨 RÉSOLUTION DE PROBLÈMES

### Problème : Services Docker ne démarrent pas
```bash
# Vérifier les ports
netstat -an | findstr :8000
netstat -an | findstr :7880

# Libérer les ports si nécessaire
docker-compose down
```

### Problème : Erreur de clés API
1. Vérifier que les clés sont correctement copiées
2. Vérifier qu'il n'y a pas d'espaces avant/après
3. Redémarrer les services après modification

### Problème : Flutter ne trouve pas l'API
1. Vérifier que Docker fonctionne
2. Vérifier l'IP dans les fichiers .env
3. Tester l'API depuis un navigateur : http://localhost:8000

## 📞 URLS IMPORTANTES

- **API Backend** : http://localhost:8000
- **LiveKit Server** : http://localhost:7880
- **Whisper STT** : http://localhost:8001
- **OpenAI TTS** : http://localhost:5002

## ✅ CHECKLIST DE DÉMARRAGE

- [ ] Clés API obtenues et configurées
- [ ] Fichiers .env créés dans les 3 emplacements
- [ ] Docker installé et fonctionnel
- [ ] Services Docker démarrés (`docker-compose up -d`)
- [ ] Flutter installé et configuré
- [ ] Application Flutter lancée
- [ ] Tests de connexion réussis

## 🎯 ORDRE DE DÉMARRAGE RECOMMANDÉ

1. **Configurer les clés** (étape 1-2)
2. **Démarrer Docker** (étape 3)
3. **Attendre 2-3 minutes** que tous les services soient prêts
4. **Tester les connexions** (étape 5)
5. **Démarrer Flutter** (étape 4)

---
*Une fois ces étapes terminées, votre projet Eloquence sera opérationnel !*