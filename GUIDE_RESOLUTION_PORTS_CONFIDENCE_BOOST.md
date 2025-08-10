# 🔧 Guide de Résolution des Problèmes de Ports - Confidence Boost

## 🚨 **Problème Identifié**

Votre exercice **Confidence Boost** ne peut pas utiliser LiveKit pour la conversation avec l'IA car le **port 8004** n'est pas exposé dans votre configuration Docker.

## 📊 **Analyse des Ports de Connexion**

### **Ports Configurés et Accessibles :**
- ✅ **7880** - LiveKit WebSocket (serveur principal)
- ✅ **7881** - LiveKit TCP 
- ✅ **40000-40100/udp** - Ports RTC LiveKit
- ✅ **8005** - Eloquence Exercises API
- ✅ **8001** - Mistral Conversation
- ✅ **8002** - Vosk STT
- ✅ **6379** - Redis

### **Ports Manquants :**
- ❌ **8004** - **LiveKit Token API** (NON EXPOSÉ)

## 🔍 **Diagnostic du Problème**

### **1. Vérification de la Configuration Actuelle**

Votre `docker-compose.yml` expose le service `livekit-server` sur les ports 7880 et 7881, mais **pas sur le port 8004** qui est nécessaire pour l'API de génération de tokens.

### **2. Architecture LiveKit**

Le service `livekit-server` a **deux fonctions** :
1. **Serveur LiveKit** (port 7880) - ✅ Fonctionne
2. **API de génération de tokens** (port 8004) - ❌ **Bloqué**

### **3. Flux de Connexion Bloqué**

```
Flutter App → Port 8004 (BLOQUÉ) → Impossible de générer un token
Flutter App → Port 7880 (OK) → Connexion WebSocket réussie
```

## 🛠️ **Solutions**

### **Solution 1 : Exposer le Port 8004 (Recommandée)**

Modifiez votre `docker-compose.yml` :

```yaml
livekit-server:
  image: livekit/livekit-server:latest
  restart: unless-stopped
  ports:
    - "7880:7880"    # Port principal WebSocket
    - "7881:7881"    # Port TCP
    - "8004:8004"    # 🆕 Port API de génération de tokens
    - "40000-40100:40000-40100/udp"  # Ports RTC
```

### **Solution 2 : Redémarrer les Services**

Après modification, redémarrez vos services :

```bash
# Arrêter tous les services
docker-compose down

# Redémarrer avec la nouvelle configuration
docker-compose up -d

# Vérifier que le port 8004 est bien exposé
docker-compose ps
netstat -an | grep 8004
```

### **Solution 3 : Vérifier les Logs**

Si le problème persiste, vérifiez les logs :

```bash
# Logs du service livekit-server
docker-compose logs livekit-server

# Logs en temps réel
docker-compose logs -f livekit-server
```

## 🧪 **Tests de Validation**

### **1. Test de Connectivité des Ports**

Utilisez le script PowerShell créé :

```powershell
# Exécuter le test des ports
.\test_ports_confidence_boost.ps1

# Ou avec une IP spécifique
.\test_ports_confidence_boost.ps1 -HostIP "192.168.1.44"
```

### **2. Test Manuel des Ports**

```bash
# Test du port 8004
telnet 192.168.1.44 8004

# Test du port 7880
telnet 192.168.1.44 7880

# Test HTTP du service de tokens
curl http://192.168.1.44:8004/health
```

### **3. Test de Génération de Token**

```bash
curl -X POST http://192.168.1.44:8004/generate-token \
  -H "Content-Type: application/json" \
  -d '{
    "room_name": "test_confidence_boost",
    "participant_name": "test_user",
    "grants": {
      "roomJoin": true,
      "canPublish": true,
      "canSubscribe": true,
      "canPublishData": true
    }
  }'
```

## 🔧 **Configuration Flutter**

### **Vérification de la Configuration**

Dans `frontend/flutter_app/lib/core/config/app_config.dart`, vérifiez :

```dart
// URL du serveur de tokens LiveKit
static String get livekitTokenUrl {
  final url = dotenv.env['LIVEKIT_TOKEN_URL'] ?? 'http://localhost:8004';
  return isProduction ? "https://your-prod-server.com/livekit-tokens" : _replaceLocalhostWithDevIp(url);
}
```

### **Variables d'Environnement**

Créez ou modifiez votre fichier `.env` :

```env
LIVEKIT_URL=ws://192.168.1.44:7880
LIVEKIT_TOKEN_URL=http://192.168.1.44:8004
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
```

## 🚀 **Redémarrage Complet**

### **1. Arrêt de Tous les Services**

```bash
# Arrêter Docker Compose
docker-compose down

# Arrêter tous les conteneurs Docker
docker stop $(docker ps -aq)

# Nettoyer les réseaux
docker network prune -f
```

### **2. Redémarrage des Services**

```bash
# Redémarrer avec la nouvelle configuration
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Vérifier les ports exposés
docker-compose port livekit-server 8004
```

### **3. Vérification des Logs**

```bash
# Attendre que les services démarrent
sleep 10

# Vérifier les logs de démarrage
docker-compose logs --tail=50 livekit-server
```

## 📱 **Test sur l'App Flutter**

### **1. Nettoyer le Cache**

```bash
# Dans le dossier Flutter
flutter clean
flutter pub get
```

### **2. Redémarrer l'App**

- Arrêter complètement l'app sur l'émulateur/appareil
- Redémarrer l'app
- Tester l'exercice Confidence Boost

### **3. Vérifier les Logs Flutter**

Dans la console de développement, cherchez :

```
🌐 URL remplacée: http://localhost:8004 → http://192.168.1.44:8004
📡 Appel token service: http://192.168.1.44:8004/generate-token
✅ Connexion LiveKit réussie
```

## 🔍 **Dépannage Avancé**

### **Problème : Port 8004 toujours bloqué**

```bash
# Vérifier que le service écoute bien sur le port 8004
docker exec -it $(docker-compose ps -q livekit-server) netstat -tlnp

# Vérifier la configuration du service
docker exec -it $(docker-compose ps -q livekit-server) cat /app/livekit.yaml
```

### **Problème : Erreur de génération de token**

```bash
# Vérifier les clés API LiveKit
docker exec -it $(docker-compose ps -q livekit-server) env | grep LIVEKIT

# Tester la génération de token directement
docker exec -it $(docker-compose ps -q livekit-server) curl -X POST http://localhost:8004/generate-token \
  -H "Content-Type: application/json" \
  -d '{"room_name":"test","participant_name":"test"}'
```

### **Problème : Connexion WebSocket échoue**

```bash
# Vérifier que le service LiveKit est bien démarré
docker-compose ps livekit-server

# Vérifier les logs d'erreur
docker-compose logs livekit-server | grep -i error
```

## ✅ **Checklist de Validation**

- [ ] Port 8004 ajouté dans `docker-compose.yml`
- [ ] Services redémarrés avec `docker-compose down && docker-compose up -d`
- [ ] Port 8004 accessible avec `telnet 192.168.1.44 8004`
- [ ] Endpoint `/health` répond sur `http://192.168.1.44:8004/health`
- [ ] Génération de token réussie avec l'API
- [ ] App Flutter redémarrée et cache nettoyé
- [ ] Exercice Confidence Boost fonctionne avec LiveKit

## 📞 **Support**

Si le problème persiste après avoir suivi ce guide :

1. **Exécutez le script de test** : `.\test_ports_confidence_boost.ps1`
2. **Collectez les logs** : `docker-compose logs > logs.txt`
3. **Vérifiez la configuration** : `docker-compose config`
4. **Testez la connectivité** : `netstat -an | grep 8004`

---

**Dernière mise à jour** : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Version** : 1.0
**Statut** : ✅ Résolu avec exposition du port 8004
