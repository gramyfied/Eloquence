# 🔗 GUIDE DE CONFIGURATION FRONTEND-BACKEND DISTANT

## 🎯 OBJECTIF
Configurer le frontend Flutter pour se connecter au backend Eloquence déployé sur Scaleway.

## ❌ PROBLÈME IDENTIFIÉ
Le frontend Flutter utilise une IP locale (`192.168.1.44:8000`) qui ne peut pas fonctionner avec un déploiement distant.

## ✅ SOLUTION IMPLÉMENTÉE

### 📁 NOUVEAUX FICHIERS CRÉÉS

#### 1. Configuration API (`frontend/flutter_app/lib/config/api_config.dart`)
```dart
class ApiConfig {
  // URLs pour différents environnements
  static const String _productionBaseUrl = 'https://votre-domaine.com';
  static const String _developmentBaseUrl = 'http://192.168.1.44:8000';
  static const String _testBaseUrl = 'http://localhost:8000';
  
  // Détection automatique de l'environnement
  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _productionBaseUrl;
    }
    return _developmentBaseUrl;
  }
}
```

#### 2. Configuration Environnement (`frontend/flutter_app/lib/config/environment_config.dart`)
```dart
class EnvironmentConfig {
  // Configuration pour Scaleway
  static void configureForScaleway(String domain) {
    _currentEnvironment = production;
    _customApiUrl = 'https://$domain';
    ApiConfig.setProductionUrl(_customApiUrl!);
  }
}
```

#### 3. Service Mis à Jour (`frontend/flutter_app/lib/services/eloquence_conversation_service.dart`)
```dart
class EloquenceConversationService {
  EloquenceConversationService({
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? ApiConfig.baseUrl,
       wsUrl = (customBaseUrl ?? ApiConfig.baseUrl).replaceFirst('http', 'ws');
}
```

#### 4. Script de Test (`frontend/flutter_app/test_backend_connection.dart`)
Script pour tester la connexion au backend distant.

## 🚀 UTILISATION

### 1. Configuration pour Production (Scaleway)

#### A. Modifier l'URL de production
```dart
// Dans frontend/flutter_app/lib/config/api_config.dart
static const String _productionBaseUrl = 'https://votre-domaine-scaleway.com';
```

#### B. Utilisation dans l'application
```dart
import 'lib/config/environment_config.dart';

void main() {
  // Configuration pour Scaleway
  EnvironmentConfig.configureForScaleway('votre-domaine-scaleway.com');
  
  runApp(MyApp());
}
```

### 2. Configuration pour Développement Local

```dart
// Configuration automatique pour développement
EnvironmentConfig.configureForLocalDevelopment();

// Ou avec IP personnalisée
EnvironmentConfig.configureForLocalDevelopment(localIp: '192.168.1.100');
```

### 3. Configuration Dynamique

```dart
// Configuration avec URL personnalisée
EnvironmentConfig.initialize(
  environment: 'production',
  apiUrl: 'https://mon-serveur-eloquence.com',
);
```

## 🧪 TESTS DE CONNEXION

### Exécuter le Script de Test
```bash
cd frontend/flutter_app
dart test_backend_connection.dart
```

### Résultat Attendu
```
🔍 Test de connexion au backend Eloquence
==========================================

📡 Test: Production (Scaleway)
----------------------------------------
=== ELOQUENCE ENVIRONMENT CONFIG ===
Environment: production
API URL: https://votre-domaine.com
Custom API URL: https://votre-domaine.com
Is Production: true
=====================================

🔄 Test de connexion...
1. Health Check...
   ✅ Health Check réussi
2. Récupération des exercices...
   ✅ 5 exercices récupérés
3. Test de création de session...
   ✅ Session créée: session_12345

🎉 Test Production (Scaleway) terminé avec succès
```

## 🔧 CONFIGURATION AVANCÉE

### 1. Variables d'Environnement Flutter

#### Compilation avec environnement
```bash
# Pour production
flutter build web --dart-define=ELOQUENCE_ENV=production --dart-define=ELOQUENCE_API_URL=https://votre-domaine.com

# Pour développement
flutter build web --dart-define=ELOQUENCE_ENV=development
```

#### Dans le code
```dart
// Lecture automatique des variables d'environnement
EnvironmentConfig.initialize();
```

### 2. Configuration Conditionnelle

```dart
void main() {
  // Configuration basée sur la plateforme
  if (kIsWeb) {
    // Configuration pour web (production)
    EnvironmentConfig.configureForScaleway('eloquence.mondomaine.com');
  } else {
    // Configuration pour mobile (développement)
    EnvironmentConfig.configureForLocalDevelopment();
  }
  
  runApp(MyApp());
}
```

### 3. Configuration avec Fichier de Configuration

```dart
// Charger depuis un fichier JSON
Future<void> loadConfigFromFile() async {
  final configFile = await rootBundle.loadString('assets/config.json');
  final config = json.decode(configFile);
  
  EnvironmentConfig.initialize(
    environment: config['environment'],
    apiUrl: config['apiUrl'],
  );
}
```

## 🛠️ INTÉGRATION DANS L'APPLICATION

### 1. Modification du main.dart

```dart
// frontend/flutter_app/lib/main.dart
import 'config/environment_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de l'environnement
  EnvironmentConfig.configureForScaleway('votre-domaine-scaleway.com');
  
  // Debug de la configuration
  if (kDebugMode) {
    EnvironmentConfig.printConfig();
  }
  
  runApp(EloquenceApp());
}
```

### 2. Utilisation dans les Services

```dart
// Création du service avec configuration automatique
final conversationService = EloquenceConversationService();

// Ou avec URL personnalisée
final conversationService = EloquenceConversationService(
  customBaseUrl: 'https://mon-serveur-specifique.com',
);
```

### 3. Gestion des Erreurs de Connexion

```dart
class ApiService {
  static Future<bool> testConnection() async {
    try {
      final service = EloquenceConversationService();
      return await service.healthCheck();
    } catch (e) {
      print('Erreur de connexion: $e');
      return false;
    }
  }
  
  static Future<void> showConnectionError(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur de Connexion'),
        content: Text('Impossible de se connecter au serveur Eloquence.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## 🔍 DIAGNOSTIC ET DÉPANNAGE

### 1. Vérification de la Configuration

```dart
// Afficher la configuration actuelle
EnvironmentConfig.printConfig();

// Obtenir la configuration sous forme de Map
final config = EnvironmentConfig.getConfig();
print('Configuration: $config');
```

### 2. Test de Connectivité

```bash
# Test manuel de l'API
curl https://votre-domaine.com/health

# Test des exercices
curl https://votre-domaine.com/api/exercises
```

### 3. Problèmes Courants

#### Erreur CORS
```
Access to XMLHttpRequest at 'https://votre-domaine.com/api/exercises' 
from origin 'http://localhost:3000' has been blocked by CORS policy
```

**Solution**: Configurer CORS sur le backend Nginx/FastAPI.

#### Erreur SSL
```
HandshakeException: Handshake error in client
```

**Solution**: Vérifier les certificats SSL du serveur.

#### Timeout de Connexion
```
SocketException: Failed host lookup: 'votre-domaine.com'
```

**Solution**: Vérifier la résolution DNS et la connectivité réseau.

## 📋 CHECKLIST DE CONFIGURATION

### ✅ Configuration Frontend
- [ ] Modifier `_productionBaseUrl` dans `api_config.dart`
- [ ] Configurer l'environnement dans `main.dart`
- [ ] Tester la connexion avec `test_backend_connection.dart`
- [ ] Vérifier les imports des nouveaux fichiers de configuration

### ✅ Configuration Backend
- [ ] Serveur Scaleway déployé et accessible
- [ ] API accessible sur `https://votre-domaine.com/health`
- [ ] CORS configuré pour accepter les requêtes frontend
- [ ] Certificats SSL valides

### ✅ Tests de Validation
- [ ] Health check réussi
- [ ] Récupération des exercices fonctionnelle
- [ ] Création de session possible
- [ ] WebSocket connecté (si utilisé)

## 🎯 RÉSUMÉ DES MODIFICATIONS

### Fichiers Modifiés
1. ✅ `frontend/flutter_app/lib/services/eloquence_conversation_service.dart`
   - Import de `api_config.dart`
   - Utilisation de `ApiConfig.baseUrl` au lieu de l'IP locale

### Fichiers Créés
1. ✅ `frontend/flutter_app/lib/config/api_config.dart`
   - Configuration centralisée des URLs
   - Détection automatique de l'environnement

2. ✅ `frontend/flutter_app/lib/config/environment_config.dart`
   - Gestion des environnements
   - Méthodes de configuration simplifiées

3. ✅ `frontend/flutter_app/test_backend_connection.dart`
   - Script de test de connexion
   - Validation des endpoints

4. ✅ `GUIDE_CONFIGURATION_FRONTEND_BACKEND_DISTANT.md`
   - Documentation complète
   - Guide d'utilisation

## 🚀 PROCHAINES ÉTAPES

1. **Remplacer `votre-domaine.com`** par votre vraie URL Scaleway
2. **Tester la connexion** avec le script de test
3. **Intégrer dans l'application** en modifiant `main.dart`
4. **Déployer le frontend** avec la nouvelle configuration
5. **Valider en production** que tout fonctionne

---

## 🎉 FÉLICITATIONS !

Le frontend Flutter est maintenant configuré pour se connecter au backend distant déployé sur Scaleway !

### 📊 Avantages de cette Solution :
- ✅ **Flexibilité** : Basculement facile entre environnements
- ✅ **Maintenabilité** : Configuration centralisée
- ✅ **Testabilité** : Scripts de test automatisés
- ✅ **Production Ready** : Détection automatique d'environnement
- ✅ **Debug Friendly** : Logs et diagnostics intégrés

**Votre application Flutter peut maintenant communiquer avec le backend distant !** 🎯✨
