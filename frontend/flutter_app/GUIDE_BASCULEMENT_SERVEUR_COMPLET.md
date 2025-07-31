# 🔄 Guide Complet - Basculement Serveur Local/Distant

## 📋 Vue d'ensemble

Votre application Flutter Eloquence peut maintenant basculer facilement entre :
- **Serveur LOCAL** : `localhost` (développement)
- **Serveur DISTANT** : `51.159.110.4` (production)

## 🚀 Scripts de Basculement Rapide

### ✅ Vérifier le statut actuel
```bash
cd frontend/flutter_app
dart run test_current_server_status.dart
```

### 🌐 Basculer vers le serveur DISTANT
```bash
cd frontend/flutter_app
dart run test_toggle_to_remote.dart
```

### 💻 Basculer vers le serveur LOCAL
```bash
cd frontend/flutter_app
dart run test_toggle_to_local.dart
```

## 📊 Services Configurés

### Serveur DISTANT (51.159.110.4)
- **API Principal** : `http://51.159.110.4:8000`
- **Mistral AI** : `http://51.159.110.4:8001`
- **Vosk STT** : `http://51.159.110.4:2700`
- **LiveKit** : `ws://51.159.110.4:7880`

### Serveur LOCAL (localhost)
- **API Principal** : `http://localhost:8000`
- **Mistral AI** : `http://localhost:8001`
- **Vosk STT** : `http://localhost:2700`
- **LiveKit** : `ws://localhost:7880`

## 🔧 Configuration Technique

### Fichier de Configuration
Le basculement est géré par `lib/core/config/api_config.dart` qui :
- Utilise `SharedPreferences` pour persister le choix
- Fournit des URLs dynamiques selon le mode
- Cache les préférences pour optimiser les performances

### Méthodes Principales
```dart
// Vérifier le mode actuel
final isRemote = await ApiConfig.useRemoteServer;

// Changer de mode
await ApiConfig.setUseRemoteServer(true);  // Distant
await ApiConfig.setUseRemoteServer(false); // Local

// Obtenir les URLs
final baseUrl = await ApiConfig.baseUrl;
final exercisesUrl = await ApiConfig.exercisesApiUrl;
```

## 🧪 Tests de Connectivité

### Tests Disponibles
```bash
# Test simple de connectivité
dart run test_simple_connectivity.dart

# Test des endpoints Vosk
dart run test_vosk_endpoints.dart

# Test de transcription Vosk
dart run test_vosk_transcription.dart

# Test de basculement
dart run test_server_toggle_simple.dart
```

## 🚨 Dépannage

### Serveur Distant Non Accessible
```bash
# Vérifier la connectivité réseau
ping 51.159.110.4

# Tester manuellement
curl http://51.159.110.4:8000/api/exercises
```

### Services Locaux Non Démarrés
```bash
# Démarrer les services Docker
cd services
docker-compose up -d

# Ou utiliser le script
./scripts/dev.ps1
```

### Erreurs de Configuration
```bash
# Réinitialiser la configuration
dart run test_toggle_to_remote.dart
dart run test_current_server_status.dart
```

## 📱 Intégration dans l'Application

### Widget de Basculement
Un widget `ServerToggleWidget` est disponible pour l'interface utilisateur :

```dart
import 'package:eloquence_2_0/core/config/server_toggle_widget.dart';

// Dans votre écran
ServerToggleWidget()
```

### Widget de Statut
Pour afficher le statut actuel :

```dart
import 'package:eloquence_2_0/core/config/server_status_widget.dart';

// Dans votre écran
ServerStatusWidget()
```

## 🔄 Workflow Recommandé

### Développement Local
1. `dart run test_toggle_to_local.dart`
2. Démarrer les services : `./scripts/dev.ps1`
3. Développer et tester localement

### Test en Production
1. `dart run test_toggle_to_remote.dart`
2. Tester avec les services distants
3. Valider le comportement

### Déploiement
1. Configurer par défaut sur distant
2. Tester la connectivité
3. Déployer l'application

## 📈 Avantages

### ✅ Flexibilité
- Basculement instantané sans recompilation
- Configuration persistante
- Tests automatisés

### ✅ Développement
- Développement local rapide
- Tests en conditions réelles
- Debugging facilité

### ✅ Production
- Haute disponibilité
- Performance optimisée
- Monitoring centralisé

## 🔐 Sécurité

### Configuration par Défaut
- **Défaut** : Serveur distant (production)
- **Développement** : Basculement manuel vers local
- **Tests** : Scripts de validation automatique

### Bonnes Pratiques
1. Toujours tester la connectivité après basculement
2. Vérifier les logs en cas d'erreur
3. Utiliser les scripts fournis pour la cohérence

## 📞 Support

### Scripts de Diagnostic
```bash
# Diagnostic complet
dart run test_current_server_status.dart

# Test de connectivité
dart run test_simple_connectivity.dart

# Validation des endpoints
dart run test_vosk_endpoints.dart
```

### Logs et Debugging
- Les scripts affichent des informations détaillées
- Codes de statut HTTP pour diagnostic
- Messages d'erreur explicites

---

🎉 **Votre infrastructure Eloquence est maintenant flexible et robuste !**

Vous pouvez développer localement et déployer en production avec un simple changement de configuration.
