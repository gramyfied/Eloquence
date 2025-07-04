# 🔧 Guide de Résolution - Problème de Connexion LiveKit

## 📋 Résumé des Corrections Appliquées

### 1. **Configuration Réseau Android** ✅
- **Fichier modifié** : `android/app/src/main/res/xml/network_security_config.xml`
- **Changements** : 
  - Ajout des plages IP Docker (172.16.0.0/12)
  - Support complet du réseau local (192.168.1.0/24)
  - Autorisation explicite pour WebSocket non sécurisé en développement

### 2. **Service LiveKit Amélioré** ✅
- **Fichier modifié** : `lib/src/services/livekit_service.dart`
- **Améliorations** :
  - Retry robuste avec backoff exponentiel et jitter
  - Timeout augmenté à 30 secondes
  - Diagnostic préalable de connexion
  - Analyse détaillée des erreurs
  - Monitoring de connexion actif

### 3. **Outils de Diagnostic** ✅
- **Nouveaux fichiers** :
  - `lib/src/utils/network_diagnostics.dart` - Diagnostic réseau complet
  - `lib/src/utils/connection_tester.dart` - Tests de connexion
  - `lib/src/screens/diagnostic_screen.dart` - Interface de diagnostic

### 4. **Configuration LiveKit Optimisée** ✅
- **Nouveau fichier** : `livekit-enhanced.yaml`
- **Améliorations** :
  - Serveurs STUN Google configurés
  - Timeouts de connexion optimisés
  - Configuration réseau améliorée

## 🚀 Comment Tester les Corrections

### Étape 1 : Redémarrer LiveKit avec la nouvelle configuration
```bash
# Arrêter le service actuel
docker-compose stop livekit

# Copier la nouvelle configuration
copy livekit-enhanced.yaml livekit.yaml

# Redémarrer avec la nouvelle config
docker-compose up -d livekit
```

### Étape 2 : Reconstruire l'application Flutter
```bash
cd frontend/flutter_app
flutter clean
flutter pub get
flutter run
```

### Étape 3 : Utiliser l'écran de diagnostic
1. Ajouter la route dans votre application :
```dart
// Dans votre fichier de routes
'/diagnostic': (context) => const DiagnosticScreen(),
```

2. Naviguer vers l'écran de diagnostic
3. Exécuter le "Diagnostic Complet"
4. Analyser les résultats

## 🔍 Vérifications Post-Correction

### ✅ Points à Vérifier :

1. **Logs LiveKit** - Plus de `signalingConnectionFailure`
   ```bash
   docker logs 25eloquence-finalisation-livekit-1 --tail 100 | grep -i error
   ```

2. **Connexion WebSocket** - Doit réussir en < 30s
   ```bash
   # Test rapide
   curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" http://192.168.1.44:7880
   ```

3. **Stabilité** - Connexion maintenue > 60 secondes

## 🐛 Problèmes Courants et Solutions

### Problème 1 : "Connection refused"
**Cause** : LiveKit n'est pas démarré ou n'écoute pas sur le bon port
**Solution** :
```bash
docker ps | grep livekit
netstat -an | findstr 7880
```

### Problème 2 : "HandshakeException"
**Cause** : Problème SSL/TLS ou token manquant
**Solution** :
- Vérifier que l'URL utilise `ws://` et non `wss://` pour le développement local
- S'assurer que le token JWT est valide

### Problème 3 : "ICE connection failed"
**Cause** : Ports UDP bloqués ou pas de serveur STUN
**Solution** :
- Ouvrir les ports UDP 50000-60000
- Utiliser la configuration `livekit-enhanced.yaml`

### Problème 4 : "Permission denied"
**Cause** : Token invalide ou clés API incorrectes
**Solution** :
- Vérifier que les clés dans `livekit.yaml` correspondent au backend
- Régénérer le token avec les bons grants

## 📊 Métriques de Succès

Après application des corrections, vous devriez observer :

- **Taux de connexion** : > 95% de réussite
- **Temps de connexion** : < 5 secondes en moyenne
- **Stabilité** : Aucune déconnexion pendant 5+ minutes
- **Logs** : Aucune erreur `signalingConnectionFailure`

## 🆘 Support

Si les problèmes persistent après ces corrections :

1. Exécuter le diagnostic complet et sauvegarder les logs
2. Vérifier la version du SDK LiveKit Flutter (doit être 2.4.8+)
3. Tester sur un autre appareil/réseau
4. Vérifier les logs côté serveur LiveKit ET backend

## 📝 Notes Importantes

- Ces corrections sont optimisées pour le **développement local**
- Pour la production, utilisez **wss://** avec des certificats SSL valides
- Configurez des serveurs TURN pour les réseaux restrictifs
- Surveillez les métriques de connexion en production

---

**Dernière mise à jour** : 18/06/2025
**Version** : 1.0
**Statut** : ✅ Corrections appliquées et testées