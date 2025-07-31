# Guide de Configuration Serveur - Eloquence Frontend

## 🌐 Vue d'ensemble

Ce guide explique comment configurer le frontend Flutter pour switcher entre le serveur local et le serveur distant (51.159.110.4).

## 📁 Fichiers modifiés

### 1. `lib/core/config/app_config.dart`
- **Configuration principale** : Contient la logique de switch entre serveurs
- **Variables importantes** :
  - `useRemoteServer` : `false` = local, `true` = distant
  - `remoteServerIp` : `'51.159.110.4'`
  - `localServerIp` : `'192.168.1.44'`

### 2. `lib/core/config/server_config_widget.dart`
- **Widget de debug** : Interface pour visualiser la configuration
- **Affichage** : Seulement en mode debug
- **Fonctionnalités** : Affiche les URLs actuelles de tous les services

## 🔧 Comment changer de serveur

### Méthode 1 : Modification du code (Recommandée)

1. Ouvrir `frontend/flutter_app/lib/core/config/app_config.dart`
2. Modifier la ligne :
   ```dart
   static const bool useRemoteServer = false; // Pour local
   static const bool useRemoteServer = true;  // Pour distant
   ```
3. Redémarrer l'application

### Méthode 2 : Widget de debug (Développement)

1. En mode debug, le widget de configuration s'affiche automatiquement
2. Utiliser le switch pour voir les URLs qui seraient utilisées
3. Suivre les instructions pour modifier le code et redémarrer

## 🌍 URLs des services

### Serveur Local (192.168.1.44)
```
API Base:           http://192.168.1.44:8000
LiveKit:            ws://192.168.1.44:7880
LiveKit Tokens:     http://192.168.1.44:8004
Exercices API:      http://192.168.1.44:8005
Vosk STT:           http://192.168.1.44:2700
Whisper STT:        http://192.168.1.44:8001
Azure TTS:          http://192.168.1.44:5002
```

### Serveur Distant (51.159.110.4)
```
API Base:           http://51.159.110.4:8000
LiveKit:            ws://51.159.110.4:7880
LiveKit Tokens:     http://51.159.110.4:8004
Exercices API:      http://51.159.110.4:8005
Vosk STT:           http://51.159.110.4:2700
Whisper STT:        http://51.159.110.4:8001
Azure TTS:          http://51.159.110.4:5002
```

## 🔍 Vérification de la configuration

### Dans les logs de debug
Rechercher ces messages :
```
🌐 Utilisation du serveur local: 192.168.1.44
🌐 Utilisation du serveur distant: 51.159.110.4
🌐 URL remplacée: http://localhost:8000 → http://192.168.1.44:8000
```

### Dans l'interface (mode debug)
- Le widget de configuration affiche l'IP actuelle
- L'expansion "URLs des services" montre toutes les URLs résolues

## 🚀 Intégration dans l'app

### Pour ajouter le widget de configuration à un écran :

```dart
import 'package:eloquence_2_0/core/config/server_config_widget.dart';

// Option 1 : Ajouter directement
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ServerConfigWidget(), // Seulement en debug
          // Votre contenu...
        ],
      ),
    );
  }
}

// Option 2 : Utiliser l'extension
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyContent().withServerConfig(),
    );
  }
}
```

## ⚠️ Points importants

### 1. Redémarrage requis
- Les changements de configuration nécessitent un redémarrage complet
- Le hot reload ne suffit pas pour les constantes statiques

### 2. Mode debug uniquement
- Le widget de configuration ne s'affiche qu'en mode debug
- En production, la configuration est fixe

### 3. Services externes
- Mistral API reste sur Scaleway (pas affecté par le switch)
- Les services externes (STUN, etc.) ne changent pas

### 4. Sécurité
- Les clés API restent dans le fichier .env
- Seules les URLs des services internes changent

## 🔧 Dépannage

### Problème : L'app ne se connecte pas au serveur distant
1. Vérifier que `useRemoteServer = true`
2. Vérifier que les services tournent sur 51.159.110.4
3. Vérifier la connectivité réseau

### Problème : Le widget de configuration ne s'affiche pas
1. Vérifier que l'app est en mode debug
2. Vérifier l'import du widget
3. Redémarrer l'app en mode debug

### Problème : Les URLs ne changent pas
1. Redémarrer complètement l'application
2. Vérifier que la constante `useRemoteServer` a été modifiée
3. Nettoyer le cache Flutter : `flutter clean`

## 📝 Exemple d'utilisation

```dart
// Dans votre service
import 'package:eloquence_2_0/core/config/app_config.dart';

class MyApiService {
  static final String baseUrl = AppConfig.apiBaseUrl;
  
  Future<void> callApi() async {
    // L'URL sera automatiquement résolue selon la configuration
    final response = await http.get(Uri.parse('$baseUrl/endpoint'));
    // ...
  }
}
```

## 🎯 Prochaines étapes

1. **Test en local** : Vérifier que tous les services fonctionnent
2. **Test en distant** : Switcher vers le serveur distant et tester
3. **Intégration** : Ajouter le widget de config aux écrans de debug si nécessaire
4. **Documentation** : Mettre à jour la documentation de déploiement

---

*Ce système permet un switch facile entre environnements de développement et facilite les tests sur différents serveurs.*
