# 📱 Guide de Configuration Android pour Studio Situations Pro

## 🚀 Démarrage Rapide

### 1. Vérifier les Services Docker
```powershell
# Vérifier que tous les services sont actifs
docker compose -f docker-compose.all.yml ps

# Si les services ne sont pas démarrés
docker compose -f docker-compose.all.yml up -d
```

### 2. Identifier l'Adresse IP de votre Machine Windows
```powershell
# Obtenir votre adresse IP locale
ipconfig | findstr IPv4

# Cherchez l'adresse sur le réseau 192.168.x.x (généralement 192.168.1.x)
```

### 3. Configurer l'Application Flutter

Modifiez le fichier `lib/core/config/network_config.dart` :

```dart
class NetworkConfig {
  static String get baseUrl {
    // Remplacez par votre adresse IP Windows
    return '192.168.1.44';  // ⬅️ VOTRE IP ICI
  }
}
```

### 4. Lancer l'Application sur Android

```bash
cd frontend/flutter_app
flutter run
```

## 🔧 Résolution des Problèmes

### Erreur : "Connection refused"

✅ **Solutions :**

1. **Vérifier que les services Docker sont actifs :**
   ```powershell
   docker compose -f docker-compose.all.yml ps
   ```
   Tous les services doivent avoir le statut "Up" et "healthy"

2. **Vérifier le pare-feu Windows :**
   - Ouvrir le Pare-feu Windows
   - Autoriser les ports : 7880, 8080, 8001-8014
   - Ou désactiver temporairement le pare-feu pour tester

3. **Vérifier que le téléphone et le PC sont sur le même réseau WiFi**

4. **Tester la connectivité depuis le téléphone :**
   - Ouvrir un navigateur sur le téléphone
   - Aller à : `http://192.168.1.44:8080/stats`
   - Vous devriez voir la page de stats HAProxy

### Erreur : "Timeout en attente des agents"

✅ **Solutions :**

1. **Vérifier les logs des agents :**
   ```powershell
   docker logs eloquence-agent-1
   docker logs eloquence-agent-2
   ```

2. **Redémarrer les services :**
   ```powershell
   docker compose -f docker-compose.all.yml restart
   ```

### Configuration Émulateur Android

Si vous utilisez un émulateur Android au lieu d'un téléphone physique :

```dart
// Dans network_config.dart
static String get baseUrl {
  const bool isPhysicalDevice = false;  // ⬅️ Mettre à false
  
  if (isPhysicalDevice) {
    return '192.168.1.44';
  } else {
    return '10.0.2.2';  // Alias émulateur pour localhost
  }
}
```

## 📊 Test du Système Complet

### 1. Test Backend Multi-Agents
```powershell
python test_studio_situations_pro_final.py
```

### 2. Test depuis Android
1. Lancer l'app Flutter sur votre téléphone
2. Aller dans "Studio Situations Pro"
3. Sélectionner une simulation (ex: "Réunion de Direction")
4. Uploader un document (optionnel)
5. Cliquer sur "Commencer la Simulation"

### 3. Vérifier les Logs
```powershell
# Logs HAProxy (load balancing)
docker logs eloquence-haproxy --tail 50

# Logs LiveKit
docker logs eloquence-livekit-server --tail 50

# Logs d'un agent
docker logs eloquence-agent-1 --tail 50
```

## 🎯 Points Clés à Retenir

1. **Android ne peut pas accéder à `localhost`** - Utilisez l'IP de votre machine
2. **Le téléphone et le PC doivent être sur le même réseau**
3. **Le pare-feu peut bloquer les connexions** - Autorisez les ports nécessaires
4. **Les services Docker doivent être "healthy"** avant de lancer l'app

## 📡 Ports Utilisés

| Service | Port | Description |
|---------|------|-------------|
| LiveKit Server | 7880 | WebRTC signaling |
| LiveKit Server | 7881 | WebRTC admin |
| HAProxy | 8080 | Load balancer (agents) |
| HAProxy Stats | 8404 | Monitoring |
| Agent 1 | 8011 | Agent instance 1 |
| Agent 2 | 8012 | Agent instance 2 |
| Agent 3 | 8013 | Agent instance 3 |
| Agent 4 | 8014 | Agent instance 4 |

## 🔒 Configuration Pare-feu Windows

```powershell
# Autoriser les ports (en admin)
netsh advfirewall firewall add rule name="LiveKit" dir=in action=allow protocol=TCP localport=7880,7881
netsh advfirewall firewall add rule name="HAProxy" dir=in action=allow protocol=TCP localport=8080,8404
netsh advfirewall firewall add rule name="Agents" dir=in action=allow protocol=TCP localport=8011-8014

# Pour UDP (WebRTC)
netsh advfirewall firewall add rule name="WebRTC UDP" dir=in action=allow protocol=UDP localport=40000-40100
```

## ✨ Fonctionnalités Disponibles

- ✅ 5 types de simulations professionnelles
- ✅ Jusqu'à 60 agents IA simultanés
- ✅ Avatars animés avec effet de lueur
- ✅ Analyse de documents en temps réel
- ✅ Métriques de performance
- ✅ Load balancing sur 4 instances

## 📞 Support

En cas de problème :
1. Vérifiez les logs Docker
2. Assurez-vous que l'IP est correcte dans `network_config.dart`
3. Testez avec le pare-feu désactivé temporairement
4. Vérifiez la connexion réseau entre le téléphone et le PC