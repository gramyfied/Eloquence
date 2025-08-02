# 🏠 Guide de Développement Local - Eloquence

## ✅ Configuration Terminée

Votre environnement de développement local est maintenant configuré et opérationnel sur **192.168.1.44**.

## 📊 État des Services

### Services Opérationnels ✅
- **API Principale** : `http://192.168.1.44:8080` - Status: healthy
- **Vosk STT** : `http://192.168.1.44:8002` - Status: healthy, Model loaded: true
- **Mistral** : `http://192.168.1.44:8001` - Status: unhealthy (mais accessible)
- **LiveKit** : `http://192.168.1.44:7880` - Status: OK

## 🔧 Configuration Flutter

Votre application Flutter est déjà configurée pour utiliser le serveur local par défaut. La configuration se trouve dans :

```dart
// frontend/flutter_app/lib/core/config/api_config.dart
static const String _localApiUrl = 'http://192.168.1.44:8080';
static const String _localVoskUrl = 'http://192.168.1.44:8002';
static const String _localMistralUrl = 'http://192.168.1.44:8001';
static const String _localLivekitUrl = 'ws://192.168.1.44:7880';
```

## 🚀 Commandes de Développement

### Démarrer les Services
```bash
# Démarrer tous les services Docker
docker-compose up -d

# Ou utiliser le script PowerShell
.\scripts\dev.ps1
```

### Tester la Connectivité
```bash
# Test simple des services
dart test_local_connectivity_simple.dart

# Test depuis l'app Flutter
cd frontend/flutter_app
flutter run
```

### Arrêter les Services
```bash
# Arrêter tous les services
docker-compose down

# Ou utiliser le script PowerShell
.\scripts\stop.ps1
```

## 📱 Développement Flutter

### URLs à Utiliser dans l'App
- **API REST** : `http://192.168.1.44:8080/api/`
- **WebSocket** : `ws://192.168.1.44:8080/ws`
- **Vosk STT** : `http://192.168.1.44:8002/transcribe`
- **Mistral Chat** : `http://192.168.1.44:8001/chat`
- **LiveKit** : `ws://192.168.1.44:7880`

### Configuration par Défaut
L'application Flutter utilise automatiquement le serveur local. Vous pouvez basculer vers le serveur distant si nécessaire :

```dart
// Forcer le serveur local
await ApiConfig.useLocalServer();

// Basculer vers le serveur distant (si besoin)
await ApiConfig.useRemoteServerConfig();
```

## 🔄 Basculement Serveur Local/Distant

### Configuration Actuelle
- **Par défaut** : Serveur local (192.168.1.44)
- **Sauvegardé** : Serveur distant (51.159.110.4)

### Commandes de Basculement
```dart
// Dans votre code Flutter
await ApiConfig.toggleServer(); // Bascule entre local/distant
await ApiConfig.useLocalServer(); // Force local
await ApiConfig.useRemoteServerConfig(); // Force distant
```

## 🛠️ Outils de Debug

### Logs des Services
```bash
# Voir les logs en temps réel
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f eloquence-api
docker-compose logs -f vosk-stt-analysis
```

### Test de Connectivité
```bash
# Test rapide
curl http://192.168.1.44:8080/health

# Test complet
dart test_local_connectivity_simple.dart
```

## 📂 Structure des Services

```
Services Locaux (192.168.1.44):
├── 8080 → API Principale (eloquence-api)
├── 8001 → Mistral Conversation
├── 8002 → Vosk STT Analysis
├── 8003 → Eloquence Conversation (si démarré)
├── 8004 → LiveKit Token Server (si démarré)
├── 8005 → Exercises API (si démarré)
└── 7880 → LiveKit Server
```

## 🎯 Avantages du Développement Local

### ✅ Avantages
- **Rapidité** : Pas de latence réseau
- **Stabilité** : Pas de dépendance internet
- **Debug** : Logs accessibles directement
- **Flexibilité** : Modifications en temps réel
- **Économies** : Pas de coûts cloud pendant le dev

### 🔄 Basculement Facile
- Configuration sauvegardée pour le serveur distant
- Basculement en une ligne de code
- Tests automatisés pour vérifier la connectivité

## 🚨 Dépannage

### Service Non Accessible
```bash
# Vérifier l'état des conteneurs
docker-compose ps

# Redémarrer un service
docker-compose restart eloquence-api

# Voir les logs d'erreur
docker-compose logs eloquence-api
```

### Problème de Réseau
```bash
# Vérifier l'IP locale
ipconfig

# Tester la connectivité
ping 192.168.1.44
curl http://192.168.1.44:8080/health
```

### Flutter ne Se Connecte Pas
```dart
// Vérifier la configuration
print(await ApiConfig.serverInfo);
print(await ApiConfig.baseUrl);

// Forcer le serveur local
await ApiConfig.useLocalServer();
```

## 📋 Checklist de Développement

### Avant de Commencer
- [ ] Services Docker démarrés (`docker-compose up -d`)
- [ ] Test de connectivité réussi (`dart test_local_connectivity_simple.dart`)
- [ ] Flutter configuré sur serveur local
- [ ] Logs accessibles (`docker-compose logs -f`)

### Pendant le Développement
- [ ] Surveiller les logs des services
- [ ] Tester régulièrement la connectivité
- [ ] Utiliser les outils de debug Flutter
- [ ] Sauvegarder les changements importants

### Avant de Déployer
- [ ] Tests locaux réussis
- [ ] Basculement vers serveur distant testé
- [ ] Configuration de production vérifiée
- [ ] Documentation mise à jour

## 🎉 Prêt pour le Développement !

Votre environnement local est maintenant opérationnel. Vous pouvez :

1. **Développer** votre app Flutter avec des services locaux rapides
2. **Tester** en temps réel sans dépendance réseau
3. **Débugger** facilement avec les logs Docker
4. **Basculer** vers le serveur distant quand nécessaire

**Commande de test rapide** :
```bash
dart test_local_connectivity_simple.dart
```

Bon développement ! 🚀
