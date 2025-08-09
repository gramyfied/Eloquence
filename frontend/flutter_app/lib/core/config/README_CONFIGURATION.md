# Configuration Réseau Unifiée - Eloquence

## Vue d'ensemble

Cette configuration unifiée remplace l'ancien système de configuration dispersé et résout les problèmes de connexion LiveKit en fournissant une approche centralisée et cohérente.

## Fichiers de Configuration

### 1. `environment_config.dart`
Configuration principale de l'environnement qui remplace le fichier `.env` bloqué.

**Fonctionnalités :**
- Configuration centralisée de tous les services
- Détection automatique de l'environnement
- Validation de la configuration
- Diagnostic automatique

**Variables principales :**
```dart
static const String devHostIP = '192.168.1.44';  // IP de votre machine Windows
static const String livekitApiKey = 'devkey';
static const String livekitApiSecret = 'devsecret123456789abcdef0123456789abcdef';
```

### 2. `network_config.dart`
Configuration réseau avancée avec détection automatique de plateforme.

**Fonctionnalités :**
- Détection automatique Android/Web/Desktop
- Configuration WebRTC moderne
- Gestion des fallbacks
- Diagnostic réseau

### 3. `livekit_config_service.dart`
Service spécialisé pour la configuration LiveKit.

**Fonctionnalités :**
- Configuration WebRTC optimisée pour Android
- Gestion des serveurs ICE
- Configuration des salles et identités

## Utilisation

### Configuration de base
```dart
import 'package:eloquence_2_0/core/config/environment_config.dart';

// Utiliser la configuration
final livekitUrl = EnvironmentConfig.livekitUrl;
final apiKey = EnvironmentConfig.livekitApiKey;
```

### Diagnostic de la configuration
```dart
import 'package:eloquence_2_0/core/config/config_test.dart';

// Test rapide
ConfigTest.runQuickConfigTest();

// Test complet avec diagnostic réseau
await ConfigTest.runFullConfigTest();

// Test d'un service spécifique
await ConfigTest.testSpecificService('livekitHttp');
```

### Diagnostic réseau
```dart
import 'package:eloquence_2_0/core/services/network_diagnostic_service.dart';

// Tester tous les services
final results = await NetworkDiagnosticService.testAllServices();

// Générer un rapport
final report = NetworkDiagnosticService.generateDiagnosticReport(results);
print(report);
```

## Configuration des Services

### Ports par défaut
- **LiveKit** : 7880 (WebSocket) et 7880 (HTTP)
- **Token Service** : 8004
- **Exercises API** : 8005
- **Mistral Service** : 8001
- **Vosk Service** : 8002
- **HAProxy** : 8080

### IP de développement
L'IP par défaut est `192.168.1.44`. Pour la modifier :

1. **Méthode 1** : Modifier `EnvironmentConfig.devHostIP`
2. **Méthode 2** : Modifier `NetworkConfig._getLocalNetworkIP()`

## Résolution des Problèmes

### Problème de connexion LiveKit
1. Vérifier que l'IP dans la configuration correspond à votre machine
2. Vérifier que tous les services Docker sont démarrés
3. Exécuter le diagnostic réseau : `ConfigTest.runFullConfigTest()`

### Problème de ports
1. Vérifier que les ports ne sont pas bloqués par le pare-feu
2. Vérifier que les services Docker écoutent sur les bons ports
3. Utiliser `NetworkDiagnosticService.testAllServices()` pour diagnostiquer

### Problème de configuration WebRTC
1. Vérifier la configuration des serveurs ICE
2. Vérifier que l'appareil a accès à Internet pour les serveurs STUN
3. Utiliser `LiveKitConfigService.debugLiveKitConfig()` pour diagnostiquer

## Migration depuis l'ancienne configuration

### Remplacer `AppConfig`
```dart
// Ancien
import 'package:eloquence_2_0/core/config/app_config.dart';
final url = AppConfig.livekitUrl;

// Nouveau
import 'package:eloquence_2_0/core/config/environment_config.dart';
final url = EnvironmentConfig.livekitUrl;
```

### Remplacer `NetworkConfig` (ancien)
```dart
// Ancien
import 'package:eloquence_2_0/core/config/network_config.dart';
final url = NetworkConfig.livekitUrl;

// Nouveau
import 'package:eloquence_2_0/core/config/environment_config.dart';
final url = EnvironmentConfig.livekitUrl;
```

## Tests et Validation

### Tests automatiques
```dart
// Dans votre code de développement
void main() {
  // Test de base
  ConfigTest.runQuickConfigTest();
  
  // Test complet (recommandé avant déploiement)
  ConfigTest.runFullConfigTest();
}
```

### Validation manuelle
1. Vérifier que l'IP est correcte
2. Vérifier que tous les services répondent
3. Tester la connexion LiveKit
4. Vérifier la configuration WebRTC

## Support et Maintenance

### Ajout d'un nouveau service
1. Ajouter la configuration dans `EnvironmentConfig`
2. Ajouter le test dans `NetworkDiagnosticService`
3. Mettre à jour la documentation

### Modification de l'IP
1. Modifier `EnvironmentConfig.devHostIP`
2. Exécuter les tests de validation
3. Vérifier la connectivité des services

### Mise à jour des ports
1. Modifier les getters dans `EnvironmentConfig`
2. Mettre à jour la documentation
3. Exécuter les tests de validation

## Notes Importantes

- **Toujours utiliser `EnvironmentConfig`** pour la configuration principale
- **Exécuter les tests** avant de déployer
- **Vérifier l'IP** si vous changez de réseau
- **Utiliser le diagnostic réseau** en cas de problème
- **Maintenir la cohérence** entre tous les fichiers de configuration
