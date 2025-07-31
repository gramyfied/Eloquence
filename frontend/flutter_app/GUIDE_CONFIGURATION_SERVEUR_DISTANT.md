# Guide de Configuration - Serveur Distant

## 📋 Vue d'ensemble

Le frontend Flutter d'Eloquence a été configuré pour se connecter automatiquement au serveur distant hébergé sur **51.159.110.4**.

## 🔧 Configuration Actuelle

### Serveur Principal
- **URL de base**: `http://51.159.110.4:8000`
- **Configuration**: `frontend/flutter_app/lib/core/config/api_config.dart`

### Services Configurés
- **API Exercises**: `http://51.159.110.4:8000/api/exercises`
- **API Confidence Boost**: `http://51.159.110.4:8000/api/confidence-boost`
- **API Story Generator**: `http://51.159.110.4:8000/api/story-generator`
- **API Vosk STT**: `http://51.159.110.4:8000/api/vosk-stt`
- **WebSocket Streaming**: `ws://51.159.110.4:8000/ws`

### Services Additionnels
- **Vosk STT**: `http://51.159.110.4:2700`
- **Mistral API**: `http://51.159.110.4:8001`
- **LiveKit**: `ws://51.159.110.4:7880`
- **Eloquence Conversation**: `http://51.159.110.4:8003`

## 🧪 Test de Connectivité

### Test Automatique
```bash
cd frontend/flutter_app
dart run test_remote_server_connectivity.dart
```

### Test Manuel
Vous pouvez tester la connectivité en ouvrant dans votre navigateur :
- http://51.159.110.4:8000/health (endpoint de santé)
- http://51.159.110.4:8000/docs (documentation API)

## 📁 Fichiers Modifiés

### 1. Configuration API
**Fichier**: `lib/core/config/api_config.dart`
- Configuration centralisée pour le serveur distant
- URLs des endpoints spécifiques
- Headers et timeouts par défaut

### 2. Constantes Globales
**Fichier**: `lib/core/utils/constants.dart`
- URLs des services backend mis à jour
- Configuration des timeouts et retry

### 3. Test de Connectivité
**Fichier**: `test_remote_server_connectivity.dart`
- Script de test pour vérifier la connectivité
- Test des endpoints principaux

## 🚀 Utilisation dans le Code

### Import de la Configuration
```dart
import 'package:eloquence_2_0/core/config/api_config.dart';
```

### Utilisation des URLs
```dart
// URL de base
final baseUrl = ApiConfig.baseUrl;

// URLs spécifiques
final exercisesUrl = ApiConfig.exercisesApiUrl;
final confidenceUrl = ApiConfig.confidenceBoostApiUrl;

// Headers par défaut
final headers = ApiConfig.defaultHeaders;

// Timeouts
final timeout = ApiConfig.connectTimeout;
```

### Exemple de Requête HTTP
```dart
import 'package:http/http.dart' as http;
import 'package:eloquence_2_0/core/config/api_config.dart';

Future<void> makeApiCall() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.exercisesApiUrl}/list'),
      headers: ApiConfig.defaultHeaders,
    ).timeout(ApiConfig.connectTimeout);
    
    if (response.statusCode == 200) {
      // Traiter la réponse
      print('Succès: ${response.body}');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}
```

## 🔍 Diagnostic et Dépannage

### Vérification de la Connectivité
1. **Test réseau de base**:
   ```bash
   ping 51.159.110.4
   ```

2. **Test HTTP**:
   ```bash
   curl http://51.159.110.4:8000/health
   ```

3. **Test depuis Flutter**:
   ```bash
   dart run test_remote_server_connectivity.dart
   ```

### Problèmes Courants

#### 1. Erreur de Connexion Refusée
- **Cause**: Le serveur n'est pas démarré ou inaccessible
- **Solution**: Vérifier que les services sont en cours d'exécution sur le serveur

#### 2. Timeout de Connexion
- **Cause**: Réseau lent ou serveur surchargé
- **Solution**: Augmenter les timeouts dans `ApiConfig`

#### 3. Erreur 404
- **Cause**: Endpoint non disponible
- **Solution**: Vérifier que l'API est correctement déployée

## 📊 Monitoring

### Logs de Connectivité
Les logs de connectivité sont automatiquement générés dans la console Flutter :
```
🔍 Test de connectivité vers le serveur distant...
📍 Serveur: http://51.159.110.4:8000
✅ Serveur accessible (200)
```

### Métriques de Performance
- **Timeout de connexion**: 10 secondes
- **Timeout de réception**: 30 secondes
- **Timeout d'envoi**: 30 secondes
- **Retry maximum**: 3 tentatives

## 🔄 Mise à Jour de la Configuration

Si vous devez changer l'adresse IP du serveur :

1. **Modifier `api_config.dart`**:
   ```dart
   static const String _remoteApiUrl = 'http://NOUVELLE_IP:8000';
   ```

2. **Modifier `constants.dart`**:
   ```dart
   static const String defaultApiBaseUrl = 'http://NOUVELLE_IP:8000';
   // ... autres URLs
   ```

3. **Tester la nouvelle configuration**:
   ```bash
   dart run test_remote_server_connectivity.dart
   ```

## ✅ Validation

Pour valider que la configuration fonctionne correctement :

1. ✅ Le test de connectivité passe sans erreur
2. ✅ L'application Flutter peut faire des requêtes API
3. ✅ Les WebSockets se connectent correctement
4. ✅ Les services audio fonctionnent

## 📞 Support

En cas de problème avec la configuration du serveur distant :
1. Vérifier les logs de l'application Flutter
2. Exécuter le test de connectivité
3. Vérifier l'état du serveur distant
4. Consulter la documentation des services backend
