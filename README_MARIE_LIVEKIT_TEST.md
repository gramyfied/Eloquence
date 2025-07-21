# 🎯 Test Marie via LiveKit WebRTC

## 🎉 **Objectif**
Tester votre agent LiveKit v1 (`eloquence-eloquence-agent-v1-1`) directement via WebRTC :
- **Marie** comme personnalité IA
- **MistralLLM** avec Scaleway 
- **OpenAI TTS** pour la synthèse vocale
- **Silero VAD** pour la détection vocale

## 🚀 **Installation et Exécution**

### Étape 1 : Installer le SDK LiveKit
```bash
pip install livekit
```

### Étape 2 : Démarrer tous les services
```bash
# Arrêter et redémarrer pour les nouvelles configurations
docker-compose down
docker-compose up -d

# Vérifier que l'agent LiveKit v1 est démarré
docker logs eloquence-eloquence-agent-v1-1 --tail 10
```

### Étape 3 : Lancer le test Marie LiveKit
```bash
python test_marie_livekit.py
```

## 🧪 **Ce que fait le test**

### **Phase 1 : Vérification Services**
- ✅ API Backend (token generation)
- ✅ Service LiveKit Token (port 8004)
- ✅ LiveKit Server (port 7880)

### **Phase 2 : Connexion WebRTC**
- 🔗 Génération token JWT automatique
- 🔗 Connexion à la room LiveKit
- 🤖 Détection de l'agent Marie dans la room

### **Phase 3 : Conversation Temps Réel**
- 📤 **Message 1** : "Bonjour Marie, comment allez-vous ?"
- 📤 **Message 2** : "Parlez-moi de vos capacités d'IA"
- 📤 **Message 3** : "Que pensez-vous de LiveKit ?"
- 📤 **Message 4** : "Merci pour cette conversation Marie !"

### **Chaque message teste** :
- ✅ **Envoi via data channel** WebRTC
- ✅ **Réception réponse** de Marie (audio + texte)
- ✅ **Latence** et temps de réponse
- ✅ **Qualité** de la génération Mistral + TTS

## 📊 **Résultats Attendus**

### **🎉 Succès (≥75% réussite)**
```
[SUCCESS] Token généré avec succès ✅
[SUCCESS] Connecté à LiveKit ✅  
[INFO] 🤖 Marie (Agent) détectée dans la room !
[SUCCESS] 💬 Marie dit: 'Bonjour ! Je vais très bien, merci de me demander...'
[SUCCESS] 🔊 Audio reçu de ai_agent_xxx (Marie)
[SUCCESS] Échange 1 réussi ✅
...
🎉 CONVERSATION MARIE VIA LIVEKIT RÉUSSIE !
✅ Votre agent LiveKit v1 avec Marie fonctionne parfaitement
```

### **❌ Échec typique**
```
[ERROR] Service LiveKit Token ❌
[ERROR] Erreur connexion LiveKit: Connection refused
[WARNING] Timeout - Pas de réponse de Marie
❌ Test Marie LiveKit échoué
```

## 🔧 **Debugging en cas de problème**

### **Token non généré**
```bash
# Vérifier service token
curl http://localhost:8004/health
curl http://localhost:8000/api/livekit/health

# Vérifier variables d'environnement
docker logs livekit-token-service
```

### **Marie ne répond pas**
```bash
# Vérifier agent LiveKit v1
docker logs eloquence-eloquence-agent-v1-1

# Vérifier LiveKit server
docker logs livekit

# Vérifier Mistral et TTS
docker logs mistral-conversation
docker logs openai-tts
```

### **Connexion WebRTC échoue**
```bash
# Vérifier ports
netstat -tulpn | grep -E "(7880|8000|8004)"

# Tester connectivité
curl http://localhost:7880  # Devrait rediriger vers WebSocket
```

## 🎯 **Avantages de ce test**

### **Vs Test HTTP Marie**
- ✅ **Teste l'agent LiveKit v1 réel** (pas juste l'API HTTP)
- ✅ **WebRTC temps réel** (comme Flutter le fera)
- ✅ **Audio bidirectionnel** (synthèse + reconnaissance)
- ✅ **Latence réaliste** pour conversations

### **Vs Test Flutter direct**
- ✅ **Plus simple à déboguer** (logs Python clairs)
- ✅ **Contrôle précis** des messages envoyés
- ✅ **Validation rapide** avant Flutter
- ✅ **Isolation des problèmes** backend vs frontend

## 🚀 **Si le test réussit**

Cela confirme que :
- 🎯 **Votre agent LiveKit v1 fonctionne parfaitement**
- 🎯 **Marie + Mistral + TTS** sont opérationnels via WebRTC
- 🎯 **Flutter pourra se connecter** de la même façon
- 🎯 **Toutes vos corrections** (timeouts, tokens, circuit breaker) sont validées

### **Prochaine étape** :
```bash
# Test Flutter avec LiveKit
cd frontend/flutter_app
flutter run
# → Aller dans Confidence Boost → Démarrer session
```

Si Marie répond via LiveKit WebRTC, votre système est **100% opérationnel** ! 🎉