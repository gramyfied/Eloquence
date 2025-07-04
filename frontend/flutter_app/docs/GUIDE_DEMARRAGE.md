# Guide de Démarrage - Frontend Flutter Eloquence

## Prérequis

1. **Flutter SDK** installé (version 3.0+)
2. **Services backend** démarrés via Docker Compose
3. **Permissions** microphone accordées

## Démarrage Rapide

### 1. Vérifier l'installation Flutter
```bash
flutter doctor
```

### 2. Installer les dépendances
```bash
cd frontend/flutter_app
flutter pub get
```

### 3. Démarrer les services backend
```bash
# Depuis la racine du projet
./test-integration-complete.bat
```

### 4. Lancer l'application Flutter
```bash
# Pour Android/iOS
flutter run

# Pour Web (développement)
flutter run -d chrome --web-port 3000
```

## Configuration

### Variables d'environnement (.env)
```
ELOQUENCE_API_BASE_URL=http://localhost:8000
LIVEKIT_URL=ws://localhost:7880
AI_WEB_SOCKET_URL=ws://localhost:8000/ws
```

### Services requis
- **API Backend**: http://localhost:8000
- **LiveKit**: ws://localhost:7880
- **ASR Service**: http://localhost:8001
- **TTS Service**: http://localhost:5002
- **Redis**: localhost:6379

## Test de l'intégration

### 1. Créer une session
```bash
curl -X POST http://localhost:8000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "scenario_id": "coaching_vocal",
    "language": "fr"
  }'
```

### 2. Utiliser le token retourné dans l'app Flutter

### 3. Tester l'audio
- Autoriser l'accès au microphone
- Parler dans le microphone
- Vérifier la réception de la réponse IA

## Dépannage

### Problème de connexion LiveKit
1. Vérifier que LiveKit est accessible: http://localhost:7880
2. Vérifier les logs: `docker-compose logs livekit`
3. Redémarrer les services: `docker-compose restart`

### Problème de permissions microphone
1. Vérifier les permissions dans les paramètres de l'appareil
2. Redémarrer l'application Flutter
3. Tester avec `flutter run --verbose`

### Problème de réseau
1. Vérifier que tous les services sont démarrés
2. Tester la connectivité: `curl http://localhost:8000/health`
3. Vérifier les logs: `docker-compose logs -f`

## Architecture

```
Frontend Flutter ←→ API Backend ←→ LiveKit ←→ Agent IA
                         ↓
                    Redis (Celery)
                         ↓
                   ASR ←→ TTS Services
```

## Fonctionnalités principales

- **Connexion temps réel** via LiveKit WebRTC
- **Reconnaissance vocale** avec Whisper
- **Synthèse vocale** avec Piper TTS
- **Agent IA conversationnel** avec Mistral
- **Interface utilisateur** moderne et responsive

## Support

Pour plus d'informations, consultez:
- `ARCHITECTURE_ELOQUENCE_INTEGRATION_COMPLETE.md`
- `LIVEKIT_AUDIO_FIX_GUIDE.md`
- Logs Docker: `docker-compose logs -f`