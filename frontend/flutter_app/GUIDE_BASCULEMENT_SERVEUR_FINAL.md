# 🔄 Guide de Basculement Serveur Local ↔ Distant

## 📋 Résumé de la Configuration

J'ai configuré le frontend Flutter pour pouvoir basculer facilement entre le serveur local et le serveur distant (51.159.110.4).

## 🛠️ Composants Créés

### 1. Configuration API (`lib/core/config/api_config.dart`)
- **Gestion centralisée** des URLs de serveur
- **Basculement automatique** entre local et distant
- **Persistance** des préférences utilisateur
- **URLs dynamiques** pour tous les services

### 2. Widget de Basculement (`lib/core/config/server_toggle_widget.dart`)
- **Interface utilisateur** pour changer de serveur
- **Indicateur visuel** du serveur actuel
- **Bouton de basculement** simple

### 3. Tests de Connectivité
- `test_server_toggle_simple.dart` - Test complet des deux serveurs
- `test_simple_connectivity.dart` - Test basique de connectivité

## 🎯 Configuration des Serveurs

### Serveur Local
```
Base URL: http://localhost:8000
Services:
- API Exercises: http://localhost:8000/api/exercises
- Confidence Boost: http://localhost:8000/api/confidence-boost
- Story Generator: http://localhost:8000/api/story-generator
- Vosk STT: http://localhost:2700
- Mistral: http://localhost:8001
```

### Serveur Distant
```
Base URL: http://51.159.110.4:8000
Services:
- API Exercises: http://51.159.110.4:8000/api/exercises
- Confidence Boost: http://51.159.110.4:8000/api/confidence-boost
- Story Generator: http://51.159.110.4:8000/api/story-generator
- Vosk STT: http://51.159.110.4:2700
- Mistral: http://51.159.110.4:8001
```

## 🚀 Utilisation

### Dans le Code Flutter

```dart
import 'package:eloquence_2_0/core/config/api_config.dart';

// Obtenir l'URL de base actuelle
String baseUrl = await ApiConfig.baseUrl;

// Obtenir une URL de service spécifique
String exercisesUrl = await ApiConfig.exercisesApiUrl;

// Basculer vers l'autre serveur
await ApiConfig.toggleServer();

// Vérifier le serveur actuel
String serverLabel = await ApiConfig.currentServerLabel;
bool isRemote = await ApiConfig.isUsingRemoteServer;
```

### Dans l'Interface Utilisateur

```dart
import 'package:eloquence_2_0/core/config/server_toggle_widget.dart';

// Ajouter le widget de basculement
ServerToggleWidget()
```

## 🧪 Tests Effectués

### Résultats des Tests
```
✅ Serveur Distant accessible (200)
✅ Serveur Local accessible (200)
✅ /api/exercises - OK sur les deux serveurs
✅ /api/confidence-boost - OK sur les deux serveurs
✅ /api/story-generator - OK sur les deux serveurs
⚠️  /api/vosk-stt - Non trouvé (404) - Normal, service séparé
```

### Lancer les Tests

```bash
# Test complet de basculement
cd frontend/flutter_app
dart run test_server_toggle_simple.dart

# Test simple de connectivité
dart run test_simple_connectivity.dart
```

## 🔧 Configuration Avancée

### Modifier les URLs de Serveur

Dans `lib/core/config/api_config.dart`, modifiez les constantes :

```dart
static const String _localBaseUrl = 'http://localhost:8000';
static const String _remoteBaseUrl = 'http://51.159.110.4:8000';
```

### Ajouter de Nouveaux Services

```dart
// Dans ApiConfig
static Future<String> get monNouveauServiceUrl async {
  final baseUrl = await ApiConfig.baseUrl;
  return '$baseUrl/api/mon-nouveau-service';
}
```

## 📱 Intégration dans l'App

### 1. Écran de Configuration
Ajoutez le `ServerToggleWidget` dans un écran de paramètres :

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres')),
      body: Column(
        children: [
          ServerToggleWidget(),
          // Autres paramètres...
        ],
      ),
    );
  }
}
```

### 2. Services HTTP
Utilisez `ApiConfig` dans vos services :

```dart
class MonService {
  static Future<Response> getData() async {
    final url = await ApiConfig.exercisesApiUrl;
    return http.get(Uri.parse('$url/data'));
  }
}
```

## 🔍 Débogage

### Vérifier la Configuration Actuelle

```dart
// Afficher les informations de configuration
final info = await ApiConfig.serverInfo;
print('Configuration: $info');
```

### Logs de Basculement

Le système affiche automatiquement des logs lors du basculement :
```
🔄 Basculement vers: Serveur Distant
🌐 URL de base: http://51.159.110.4:8000
```

## ⚡ Avantages de cette Solution

1. **Flexibilité** - Basculement facile entre environnements
2. **Persistance** - Les préférences sont sauvegardées
3. **Centralisation** - Une seule source de vérité pour les URLs
4. **Testabilité** - Tests automatisés de connectivité
5. **Interface** - Widget prêt à l'emploi pour l'utilisateur

## 🎉 Prêt à l'Utilisation

Le système est maintenant configuré et testé. Vous pouvez :

1. **Développer en local** avec le serveur localhost
2. **Tester en production** avec le serveur distant
3. **Basculer facilement** selon vos besoins
4. **Intégrer le widget** dans votre interface

Les deux serveurs sont opérationnels et tous les endpoints principaux répondent correctement !
