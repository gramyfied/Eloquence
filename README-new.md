# 🎙️ Eloquence - Plateforme d'Exercices Vocaux

## 📖 Description

Eloquence est une plateforme moderne d'exercices vocaux utilisant l'IA pour améliorer la confiance en soi, l'articulation et les compétences de prise de parole.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Eloquence API  │    │   Services IA   │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│  Vosk + Mistral │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    LiveKit      │
                       │  (Temps Réel)   │
                       └─────────────────┘
```

## 🚀 Démarrage Rapide

```bash
# Cloner le projet
git clone <repo-url>
cd eloquence

# Démarrer l'environnement
chmod +x scripts/dev.sh
./scripts/dev.sh

# Accéder à l'application
# API: http://localhost:8080
# Frontend: flutter run (dans frontend/flutter_app)
```

## 🎯 Exercices Disponibles

### 1. Boost de Confiance
- **Type**: Conversation IA
- **Durée**: 10 minutes
- **Objectif**: Développer l'assurance en prise de parole

### 2. Roulette des Virelangues
- **Type**: Articulation
- **Durée**: 3 minutes
- **Objectif**: Améliorer la diction et la précision

### 3. Prise de Parole Improvisée
- **Type**: Expression spontanée
- **Durée**: 5 minutes
- **Objectif**: Développer la spontanéité et la structure

## 🔧 Configuration

### Variables d'Environnement

```bash
# .env
MISTRAL_API_KEY=your_mistral_key
SCALEWAY_MISTRAL_URL=your_scaleway_url
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef
```

## 📱 Développement Frontend

```bash
cd frontend/flutter_app
flutter pub get
flutter run
```

## 🐳 Services Docker

- **eloquence-api**: API principale (port 8080)
- **vosk-stt**: Reconnaissance vocale (port 8002)
- **mistral**: IA conversationnelle (port 8001)
- **livekit**: Communication temps réel (port 7880)
- **redis**: Cache et sessions (port 6379)

## 🔍 Monitoring

```bash
# Logs de tous les services
./scripts/logs.sh

# Logs d'un service spécifique
./scripts/logs.sh eloquence-api

# Santé des services
curl http://localhost:8080/health
```

## 🛠️ Développement

### Structure du Projet

```
eloquence/
├── frontend/flutter_app/     # Application Flutter
├── services/
│   ├── eloquence-api/        # API principale
│   ├── vosk-stt-analysis/    # Reconnaissance vocale
│   └── mistral-conversation/ # IA conversationnelle
├── scripts/                  # Scripts de développement
└── docs/                     # Documentation
```

### API Endpoints

```
GET  /api/v1/exercises/templates          # Lister exercices
POST /api/v1/exercises/sessions           # Créer session
WS   /api/v1/exercises/realtime/{id}      # Analyse temps réel
GET  /api/v1/exercises/analytics/user/{id} # Statistiques
```

## 📋 Scripts Utiles

```bash
# Démarrer l'environnement de développement
./scripts/dev.sh

# Voir les logs
./scripts/logs.sh [service_name]

# Arrêter l'environnement
./scripts/stop.sh
```

## 🧹 Nettoyage du Projet

Le projet a été refactorisé pour une architecture plus propre :

- ✅ **Code mort supprimé** - Imports et fonctions inutiles éliminés
- ✅ **Documentation obsolète supprimée** - Seule la doc utile conservée
- ✅ **API unifiée** - Endpoints cohérents et structure RESTful claire
- ✅ **Configuration simplifiée** - Docker-compose optimisé

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Commit les changements
4. Push vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

MIT License - voir LICENSE file

---

## 🔄 Migration depuis l'ancienne architecture

Si vous utilisez l'ancienne architecture, voici les étapes de migration :

1. **Sauvegarder vos données** importantes
2. **Arrêter l'ancien environnement** : `docker-compose down -v`
3. **Utiliser la nouvelle configuration** : `./scripts/dev.sh`
4. **Mettre à jour votre frontend** pour utiliser les nouveaux endpoints

### Changements principaux :

- **API unifiée** : Un seul service `eloquence-api` au lieu de multiples APIs
- **Endpoints simplifiés** : Structure RESTful cohérente
- **Configuration Docker simplifiée** : Moins de services, plus de stabilité
- **Scripts de développement** : 3 scripts essentiels seulement

Pour plus de détails, consultez `docs/IMPLEMENTATION_EXERCICES.md`.
