# 🚨 Guide de Dépannage : IA qui ne répond pas

## 🎯 Problème
L'application Flutter se connecte au backend, les scénarios se chargent, mais l'IA ne répond pas aux messages vocaux.

## 🔍 Diagnostic Rapide

### Étape 1 : Vérification des Services
```bash
# Exécutez le script de test complet
python scripts/test_pipeline_audio_complet.py

# Vérifiez que tous les services sont actifs
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Étape 2 : Vérification de l'Agent IA
```bash
# Surveillez les logs de l'agent en temps réel
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1

# Recherchez ces messages clés :
# - "Connected to room"
# - "Participant connected"
# - "Audio track received"
```

### Étape 3 : Test des Composants Individuels

#### Test STT (Speech-to-Text)
```bash
# Testez Whisper directement
curl -X POST "http://192.168.1.44:8001/v1/audio/transcriptions" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav"
```

#### Test TTS (Text-to-Speech)
```bash
# Testez Azure TTS directement
curl -X POST "http://192.168.1.44:5002/v1/audio/speech" \
  -H "Content-Type: application/json" \
  -d '{"text":"Bonjour test","voice":"fr-FR-DeniseNeural"}'
```

#### Test LiveKit
```bash
# Vérifiez LiveKit
curl http://192.168.1.44:7880
```

## 🔧 Solutions par Ordre de Priorité

### Solution 1 : Redémarrage de l'Agent IA
```bash
# Redémarrez uniquement l'agent
docker restart 25eloquence-finalisation-eloquence-agent-v1-1

# Surveillez le redémarrage
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1
```

### Solution 2 : Vérification des Tokens LiveKit
```python
# Vérifiez la génération de tokens dans l'app Flutter
# Dans votre code Flutter, ajoutez ces logs :

print('[DEBUG] Token LiveKit généré: ${token.substring(0, 50)}...');
print('[DEBUG] URL LiveKit: ${AppConfig.livekitUrl}');
print('[DEBUG] Room name: $roomName');
```

### Solution 3 : Permissions Audio Mobile
```dart
// Vérifiez les permissions dans l'app Flutter
import 'package:permission_handler/permission_handler.dart';

Future<void> checkAudioPermissions() async {
  final status = await Permission.microphone.status;
  print('[DEBUG] Permission microphone: $status');
  
  if (!status.isGranted) {
    final result = await Permission.microphone.request();
    print('[DEBUG] Résultat demande permission: $result');
  }
}
```

### Solution 4 : Configuration WebRTC
```dart
// Dans CleanLiveKitService, ajoutez plus de serveurs STUN
rtcConfiguration: const RTCConfiguration(
  iceServers: [
    RTCIceServer(urls: ['stun:stun.l.google.com:19302']),
    RTCIceServer(urls: ['stun:stun1.l.google.com:19302']),
    RTCIceServer(urls: ['stun:stun.cloudflare.com:3478']),
    RTCIceServer(urls: ['stun:stun.ekiga.net']),
  ],
  iceTransportPolicy: RTCIceTransportPolicy.all,
),
```

### Solution 5 : Redémarrage Complet
```bash
# Redémarrage de tous les services
docker-compose down
docker-compose up -d

# Attendez que tous les services soient prêts
sleep 30

# Vérifiez le statut
docker ps
```

## 🔍 Diagnostic Avancé

### Vérification des Logs en Temps Réel
```bash
# Terminal 1 : Agent IA
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1

# Terminal 2 : LiveKit
docker logs -f 25eloquence-finalisation-livekit-1

# Terminal 3 : Whisper STT
docker logs -f 25eloquence-finalisation-whisper-stt-1

# Terminal 4 : Azure TTS
docker logs -f 25eloquence-finalisation-azure-tts-1
```

### Messages d'Erreur Courants

#### "Connection refused" ou "Network unreachable"
```bash
# Vérifiez la connectivité réseau
ping 192.168.1.44

# Vérifiez les ports ouverts
netstat -an | grep "7880\|8001\|5002\|8000"

# Testez depuis le téléphone (navigateur)
# http://192.168.1.44:5002/health
```

#### "Token invalid" ou "Unauthorized"
```python
# Régénérez le token LiveKit avec les bonnes permissions
import jwt
import time

def generate_token():
    payload = {
        "iss": "devkey",
        "sub": "user-123",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
        "room": "scenario-room",
        "grants": {
            "room": "scenario-room",
            "roomJoin": True,
            "canPublish": True,
            "canSubscribe": True
        }
    }
    return jwt.encode(payload, "secret", algorithm="HS256")
```

#### "Audio track not found" ou "No audio received"
```dart
// Vérifiez la publication audio dans Flutter
Future<void> debugAudioPublication() async {
  final publications = room?.localParticipant?.audioTracks;
  print('[DEBUG] Audio tracks publiés: ${publications?.length ?? 0}');
  
  for (final pub in publications ?? []) {
    print('[DEBUG] Track: ${pub.sid}, Muted: ${pub.muted}');
  }
}
```

## 📋 Checklist de Vérification

### ✅ Services Backend
- [ ] LiveKit accessible (port 7880)
- [ ] Whisper STT accessible (port 8001)
- [ ] Azure TTS accessible (port 5002)
- [ ] API Backend accessible (port 8000)
- [ ] Agent IA en cours d'exécution

### ✅ Configuration Réseau
- [ ] IP correcte dans app_config.dart (192.168.1.44)
- [ ] Téléphone sur le même réseau WiFi
- [ ] Pare-feu Windows désactivé ou configuré
- [ ] Ports accessibles depuis le mobile

### ✅ Application Flutter
- [ ] Permissions microphone accordées
- [ ] Token LiveKit valide
- [ ] Connexion LiveKit établie
- [ ] Audio publié correctement

### ✅ Agent IA
- [ ] Agent connecté à LiveKit
- [ ] Agent reçoit l'audio
- [ ] Agent traite avec Whisper
- [ ] Agent génère réponse TTS
- [ ] Agent renvoie l'audio

## 🚀 Test de Validation

### Script de Test Rapide
```bash
# 1. Testez tous les services
python scripts/test_pipeline_audio_complet.py

# 2. Si tout est OK, testez l'app Flutter
# - Lancez l'app
# - Sélectionnez un scénario
# - Parlez dans le microphone
# - Surveillez les logs

# 3. Vérifiez les logs en temps réel
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1
```

### Indicateurs de Succès
```
✅ App Flutter : "Connexion LiveKit réussie"
✅ Agent IA : "Participant connected: user-xxx"
✅ Agent IA : "Audio track received from: user-xxx"
✅ Whisper : "Transcription: [votre message]"
✅ Agent IA : "Generating response..."
✅ Azure TTS : "Audio generated: xxx bytes"
✅ App Flutter : "Audio reçu de l'agent"
```

## 📞 Support d'Urgence

Si le problème persiste après toutes ces étapes :

1. **Sauvegardez les logs** :
   ```bash
   docker logs 25eloquence-finalisation-eloquence-agent-v1-1 > agent_logs.txt
   docker logs 25eloquence-finalisation-livekit-1 > livekit_logs.txt
   ```

2. **Exécutez le diagnostic complet** :
   ```bash
   python scripts/test_pipeline_audio_complet.py > diagnostic_complet.txt
   ```

3. **Testez sur émulateur** pour éliminer les problèmes mobile

4. **Vérifiez les variables d'environnement** Azure TTS

---

## 🎯 Résolution Rapide (90% des cas)

```bash
# Solution express (résout la plupart des problèmes)
docker restart 25eloquence-finalisation-eloquence-agent-v1-1
sleep 10
python scripts/test_pipeline_audio_complet.py
```

Si cette solution express ne fonctionne pas, suivez le guide complet ci-dessus.