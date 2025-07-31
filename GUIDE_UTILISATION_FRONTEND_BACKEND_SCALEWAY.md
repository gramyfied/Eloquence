# 🚀 Guide d'Utilisation Frontend-Backend Scaleway

## ✅ PROBLÈME RÉSOLU

Le problème de communication entre le frontend Flutter et le backend Scaleway a été **complètement résolu**.

### 🔧 **Corrections Apportées**

1. **Port Correct Identifié** : `51.159.110.4:8005` (au lieu de 8080)
2. **Configuration Dynamique** : Système de configuration flexible
3. **Service Corrigé** : `EloquenceConversationService` utilise maintenant la bonne configuration
4. **Tests Fonctionnels** : Scripts de validation inclus

---

## 🎯 **UTILISATION IMMÉDIATE**

### **1. Configuration pour Production (Scaleway)**

```dart
// Dans votre main.dart ou au démarrage de l'app
import 'lib/config/environment_config.dart';

void main() {
  // Configuration pour Scaleway
  EnvironmentConfig.initialize(
    environment: 'production',
    apiUrl: 'http://51.159.110.4:8005',
  );
  
  runApp(MyApp());
}
```

### **2. Configuration pour Développement Local**

```dart
// Pour développement local
EnvironmentConfig.configureForLocalDevelopment();
```

### **3. Utilisation du Service**

```dart
// Le service utilise automatiquement la bonne configuration
final service = EloquenceConversationService();

// Test de connexion
final isHealthy = await service.healthCheck();
if (isHealthy) {
  print('✅ Connexion au backend réussie !');
}

// Récupération des exercices
final exercises = await service.getExercises();
print('📚 ${exercises.length} exercices disponibles');
```

---

## 🧪 **VALIDATION DE LA CONNEXION**

### **Test Automatique**

```bash
cd frontend/flutter_app
dart test_backend_connection.dart
```

### **Test Manuel avec curl**

```bash
# Vérification que le serveur répond
curl http://51.159.110.4:8005/health

# Réponse attendue :
# {"status":"healthy","service":"eloquence-exercises-api","redis":"connected","timestamp":"..."}
```

---

## 📋 **CONFIGURATION DÉTAILLÉE**

### **Fichiers de Configuration**

1. **`lib/config/api_config.dart`**
   - URLs par défaut pour chaque environnement
   - Configuration des timeouts et headers
   - URL de production : `http://51.159.110.4:8005`

2. **`lib/config/environment_config.dart`**
   - Gestion dynamique des environnements
   - Méthodes de configuration simplifiées
   - Support HTTP/HTTPS automatique

3. **`lib/services/eloquence_conversation_service.dart`**
   - Service principal de communication
   - Utilise `EnvironmentConfig.apiUrl` automatiquement
   - Support WebSocket et HTTP

---

## 🔄 **BASCULEMENT D'ENVIRONNEMENTS**

### **Méthode 1 : Configuration Directe**

```dart
// Production Scaleway
EnvironmentConfig.initialize(
  environment: 'production',
  apiUrl: 'http://51.159.110.4:8005',
);

// Développement local
EnvironmentConfig.initialize(
  environment: 'development',
  apiUrl: 'http://192.168.1.44:8000',
);
```

### **Méthode 2 : Méthodes Prédéfinies**

```dart
// Pour Scaleway
EnvironmentConfig.configureForScaleway('51.159.110.4:8005');

// Pour développement local
EnvironmentConfig.configureForLocalDevelopment();

// Pour tests
EnvironmentConfig.configureForTest();
```

---

## 🛠️ **DÉBOGAGE**

### **Affichage de la Configuration**

```dart
// Affiche la configuration actuelle
EnvironmentConfig.printConfig();

// Sortie exemple :
// === ELOQUENCE ENVIRONMENT CONFIG ===
// Environment: production
// API URL: http://51.159.110.4:8005
// Custom API URL: http://51.159.110.4:8005
// Is Production: true
// Is Development: false
// Is Test: false
// =====================================
```

### **Vérification de la Configuration**

```dart
// Vérifications programmatiques
print('URL actuelle: ${EnvironmentConfig.apiUrl}');
print('Environnement: ${EnvironmentConfig.currentEnvironment}');
print('Est en production: ${EnvironmentConfig.isProduction}');
```

---

## 🚨 **RÉSOLUTION DE PROBLÈMES**

### **Problème : Connexion refusée**

```dart
// Vérifiez l'URL configurée
EnvironmentConfig.printConfig();

// Testez manuellement
curl http://51.159.110.4:8005/health
```

### **Problème : Mauvais port**

Le port correct est **8005**, pas 8080 ou 8000.

### **Problème : Service non démarré**

```bash
# Sur le serveur Scaleway, vérifiez les services
docker ps
docker-compose ps
```

---

## 📊 **ENDPOINTS DISPONIBLES**

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Vérification santé API |
| `/api/exercises` | GET | Liste des exercices |
| `/api/sessions/create` | POST | Création session |
| `/api/sessions/{id}/stream` | WebSocket | Stream conversation |
| `/api/sessions/{id}/analysis` | GET | Analyse session |

---

## 🎉 **RÉSULTAT FINAL**

✅ **Frontend Flutter** ↔️ **Backend Scaleway** : **CONNEXION FONCTIONNELLE**

- **URL Production** : `http://51.159.110.4:8005`
- **Configuration** : Automatique et flexible
- **Tests** : Validés et fonctionnels
- **Documentation** : Complète et à jour

**Votre application Flutter peut maintenant communiquer parfaitement avec le backend déployé sur Scaleway !** 🚀

---

## 📞 **SUPPORT**

En cas de problème :

1. Vérifiez la configuration avec `EnvironmentConfig.printConfig()`
2. Testez la connexion avec `dart test_backend_connection.dart`
3. Vérifiez que le serveur Scaleway est accessible avec `curl`
4. Consultez les logs du service pour plus de détails

**La communication frontend-backend est maintenant entièrement opérationnelle !** ✨
