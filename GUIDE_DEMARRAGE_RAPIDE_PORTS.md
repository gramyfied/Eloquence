# 🚀 Guide de Démarrage Rapide - Configuration des Ports Eloquence

## ✅ Configuration des Ports Corrigée

Votre configuration des ports a été automatiquement vérifiée et corrigée. Voici le résumé :

### 📋 Ports Utilisés par Eloquence

| Port | Service | Description |
|------|---------|-------------|
| **6379** | Redis | Base de données cache |
| **7880** | LiveKit | Serveur WebRTC temps réel |
| **8000** | API Backend | API principale |
| **8001** | Mistral Conversation | Service IA conversationnelle |
| **8002** | Vosk STT | Reconnaissance vocale |
| **8003** | Eloquence Conversation | Service conversation |
| **8004** | LiveKit Token Service | Génération tokens LiveKit |
| **8080** | Eloquence Agent V1 | Agent IA temps réel |
| **5002** | OpenAI TTS | Synthèse vocale |

## 🔧 Corrections Appliquées

### 1. Docker Compose
- ✅ **Corrigé** : Port LiveKit 7880 dupliqué supprimé
- ✅ **Ajouté** : Service eloquence-conversation sur le port 8003

### 2. Variables d'Environnement (.env)
- ✅ **Corrigé** : `STT_SERVICE_URL` de 2700 → 8002
- ✅ **Corrigé** : `VOSK_STT_URL` de 2700 → 8002
- ✅ **Corrigé** : `VOSK_URL` de 2700 → 8002
- ✅ **Corrigé** : `FALLBACK_VOSK_URL` de 2700 → 8002

### 3. Constantes Flutter
- ✅ **Ajouté** : `defaultEloquenceConversationUrl = 'http://localhost:8003'`
- ✅ **Vérifié** : Tous les autres ports sont cohérents

## 🚀 Démarrage des Services

### Option 1 : Démarrage Complet
```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier le statut
docker-compose ps
```

### Option 2 : Démarrage Sélectif
```bash
# Services essentiels seulement
docker-compose up -d redis livekit vosk-stt mistral-conversation api-backend

# Ajouter les services avancés si nécessaire
docker-compose up -d livekit-token-service eloquence-conversation
```

## 🔍 Vérification de la Configuration

### Test de Connectivité
```bash
# Vérifier que tous les ports sont accessibles
python scripts/validate_ports_configuration.py
```

### Test des Services Individuels
```bash
# Redis
curl http://localhost:6379

# API Backend
curl http://localhost:8000/health

# Vosk STT
curl http://localhost:8002/health

# Mistral Conversation
curl http://localhost:8001/health

# LiveKit Token Service
curl http://localhost:8004/health

# Eloquence Conversation
curl http://localhost:8003/health
```

## 📱 Configuration Flutter

Les constantes Flutter sont maintenant synchronisées :

```dart
class AppConstants {
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String defaultVoskUrl = 'http://localhost:8002';
  static const String defaultMistralUrl = 'http://localhost:8001';
  static const String defaultLivekitUrl = 'ws://localhost:7880';
  static const String defaultEloquenceConversationUrl = 'http://localhost:8003';
}
```

## 🛠️ Dépannage

### Problèmes de Ports
Si vous rencontrez des conflits de ports :

1. **Vérifier les ports utilisés** :
   ```bash
   netstat -tulpn | grep :8000
   ```

2. **Arrêter les services conflictuels** :
   ```bash
   docker-compose down
   ```

3. **Relancer la validation** :
   ```bash
   python scripts/validate_ports_configuration.py
   ```

### Logs des Services
```bash
# Voir les logs de tous les services
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f vosk-stt
docker-compose logs -f api-backend
```

## 🔄 Maintenance

### Re-validation Périodique
Exécutez régulièrement le script de validation :
```bash
python scripts/validate_ports_configuration.py
```

### Mise à Jour des Ports
Si vous devez modifier un port :

1. Modifiez `docker-compose.yml`
2. Modifiez `.env`
3. Modifiez `frontend/flutter_app/lib/core/utils/constants.dart`
4. Exécutez la validation : `python scripts/validate_ports_configuration.py`

## ✅ Statut Actuel

- ✅ Configuration des ports cohérente
- ✅ Aucun conflit de port détecté
- ✅ Services prêts au démarrage
- ✅ Flutter synchronisé avec les services backend

Votre configuration Eloquence est maintenant optimisée et prête à l'utilisation !
