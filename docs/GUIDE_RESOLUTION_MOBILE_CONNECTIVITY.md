# 📱 Guide de Résolution - Connectivité Appareil Physique

## 🎯 Problème
Le pipeline audio fonctionne en local mais pas sur appareil physique.

## 🔍 Causes Identifiées

1. **Configuration ICE manquante** - Les serveurs STUN/TURN n'étaient pas configurés
2. **URLs hardcodées** - L'app utilise `localhost` qui n'est pas accessible depuis l'appareil
3. **Pare-feu Windows** - Les ports peuvent être bloqués
4. **Réseau différent** - L'appareil et le PC ne sont pas sur le même réseau

## ✅ Solutions Appliquées

### 1. Configuration ICE Corrigée
✅ **FAIT** - Ajout des serveurs STUN dans `clean_livekit_service.dart` :
- Google STUN : `stun:stun.l.google.com:19302`
- Google STUN 2 : `stun:stun1.l.google.com:19302`
- Cloudflare STUN : `stun:stun.cloudflare.com:3478`

### 2. Script de Diagnostic Créé
✅ **FAIT** - `scripts/diagnostic_mobile_connectivity.py` qui :
- Détecte automatiquement l'IP de votre machine
- Teste la connectivité vers tous les services
- Génère automatiquement les fichiers de configuration
- Fournit des recommandations personnalisées

### 3. Configuration Automatique
✅ **FAIT** - Le script génère :
- `frontend/flutter_app/lib/core/config/app_config.dart` - Configuration Dart avec les bonnes IPs
- `frontend/flutter_app/.env.mobile` - Variables d'environnement pour l'app

## 🚀 Instructions d'Utilisation

### Étape 1 : Préparer l'Environnement

1. **Assurez-vous que votre PC et l'appareil sont sur le même réseau WiFi**

2. **Démarrez tous les services Docker** :
   ```bash
   docker-compose up -d
   ```

3. **Vérifiez que les services sont actifs** :
   ```bash
   docker ps
   ```

### Étape 2 : Exécuter le Diagnostic

1. **Lancez le script de diagnostic** :
   ```bash
   scripts\diagnostic_mobile.bat
   ```

2. **Le script va** :
   - Détecter votre IP locale (ex: 192.168.1.100)
   - Tester la connectivité vers chaque service
   - Créer les fichiers de configuration
   - Afficher des recommandations

### Étape 3 : Configurer le Pare-feu (si nécessaire)

Si le diagnostic montre des ports bloqués, exécutez PowerShell en admin :

```powershell
# Autoriser LiveKit
New-NetFirewallRule -DisplayName "LiveKit Server" -Direction Inbound -Protocol TCP -LocalPort 7880 -Action Allow

# Autoriser Whisper STT
New-NetFirewallRule -DisplayName "Whisper STT" -Direction Inbound -Protocol TCP -LocalPort 8001 -Action Allow

# Autoriser Azure TTS
New-NetFirewallRule -DisplayName "Azure TTS" -Direction Inbound -Protocol TCP -LocalPort 5002 -Action Allow

# Autoriser Redis
New-NetFirewallRule -DisplayName "Redis" -Direction Inbound -Protocol TCP -LocalPort 6379 -Action Allow
```

### Étape 4 : Mettre à Jour l'Application Flutter

1. **Utilisez la configuration générée** dans votre app :
   ```dart
   // Dans votre code de connexion LiveKit
   import 'package:your_app/core/config/app_config.dart';
   
   // Utiliser l'URL configurée
   final url = AppConfig.livekitUrl;
   final token = "votre_token_ici";
   ```

2. **Ou utilisez le fichier .env.mobile** :
   ```dart
   // Charger les variables d'environnement
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   await dotenv.load(fileName: ".env.mobile");
   final livekitUrl = dotenv.env['LIVEKIT_URL']!;
   ```

### Étape 5 : Tester sur l'Appareil

1. **Connectez votre appareil** via USB ou WiFi
2. **Lancez l'application** :
   ```bash
   cd frontend/flutter_app
   flutter run
   ```

3. **Vérifiez dans l'app** :
   - La connexion LiveKit doit s'établir
   - Le microphone doit fonctionner
   - Vous devez entendre les réponses de l'IA

## 🧪 Tests de Vérification

### Test 1 : Connectivité Basique
Sur votre appareil, ouvrez un navigateur et testez :
- `http://192.168.1.100:7880` (remplacez par votre IP)
- Vous devriez voir une réponse du serveur LiveKit

### Test 2 : Logs LiveKit
Surveillez les logs pour voir la connexion :
```bash
docker logs livekit -f
```

### Test 3 : Test Audio Complet
1. Parlez dans le microphone de l'appareil
2. Vérifiez les logs Whisper : `docker logs whisper-stt -f`
3. Vérifiez les logs Azure TTS : `docker logs azure-tts -f`

## 🔧 Dépannage

### Problème : "Connection refused"
- **Cause** : Pare-feu ou services non démarrés
- **Solution** : Exécutez les commandes PowerShell ci-dessus et redémarrez Docker

### Problème : "Network unreachable"
- **Cause** : Appareil et PC sur réseaux différents
- **Solution** : Connectez les deux au même WiFi

### Problème : "ICE connection failed"
- **Cause** : Configuration ICE incorrecte
- **Solution** : Vérifiez que les serveurs STUN sont bien configurés dans `clean_livekit_service.dart`

### Problème : Pas de son sur l'appareil
- **Cause** : Volume ou permissions
- **Solution** : 
  1. Vérifiez le volume de l'appareil
  2. Autorisez les permissions microphone dans les paramètres
  3. Redémarrez l'application

## 📊 Exemple de Sortie du Diagnostic

```
🔍 Diagnostic de connectivité pour appareil mobile
============================================================

📊 Informations système:
  • Plateforme: Windows
  • Nom d'hôte: PC-USER
  • IP principale: 192.168.1.100

🌐 Interfaces réseau détectées:
  • Wi-Fi: 192.168.1.100 (WiFi)
  • Ethernet: 192.168.1.101 (Ethernet)

🐳 État des services Docker:
  ✅ livekit: running (port 7880)
  ✅ whisper-stt: running (port 8001)
  ✅ azure-tts: running (port 5002)
  ✅ redis: running (port 6379)

🔗 Tests de connectivité:
  Testing livekit on 192.168.1.100:7880
    • TCP: ✅ OK
    • HTTP: ✅ OK
      Status: 200, Time: 0.05s

💡 Recommandations:
  • Tous les services sont accessibles !

📝 Fichier de configuration créé: frontend/flutter_app/lib/core/config/app_config.dart
📝 Fichier .env créé: frontend/flutter_app/.env.mobile
📊 Résultats sauvegardés: diagnostic_mobile_20250623_204500.json

✅ Diagnostic terminé!
```

## ✅ Résumé

Avec ces modifications :
1. ✅ Les serveurs STUN sont configurés pour les appareils physiques
2. ✅ Un script détecte automatiquement votre IP et configure l'app
3. ✅ Les instructions complètes sont fournies pour le pare-feu
4. ✅ La configuration est générée automatiquement

**Votre pipeline audio devrait maintenant fonctionner sur appareil physique !** 🎉