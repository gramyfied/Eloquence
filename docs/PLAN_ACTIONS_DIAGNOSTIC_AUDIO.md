# PLAN D'ACTIONS : DIAGNOSTIC AUDIO RÉSOLUTION FINALE

## 🎯 SITUATION ACTUELLE
Les diagnostics sont maintenant implémentés dans les 3 zones critiques :
- ✅ **Agent Python** : Logs STT→LLM→TTS complets
- ✅ **Connexion Agent** : Logs de connexion détaillés  
- ✅ **Flutter** : Diagnostics audio complets nouvellement ajoutés

## 🚀 ÉTAPES À SUIVRE MAINTENANT

### ÉTAPE 1 : REDÉMARRER L'AGENT AVEC NOUVEAUX DIAGNOSTICS

```bash
# 1. Arrêter les services existants
docker-compose down

# 2. Redémarrer avec les nouveaux diagnostics
docker-compose up --build -d

# 3. Vérifier que l'agent démarre avec les logs
docker logs eloquence-agent -f
```

**CE QUE VOUS DEVEZ VOIR :**
```
🚀 [AGENT BOOTING UP] Agent vocal Eloquence démarré !
🔗 [AGENT CONNECTING TO LIVEKIT] Connexion en cours...
✅ [AGENT CONNECTED] Connexion LiveKit réussie
🔧 [AGENT CONFIG] CustomSTT créé
🔧 [AGENT CONFIG] CustomLLM créé  
🔧 [AGENT CONFIG] CustomTTS créé
```

### ÉTAPE 2 : TESTER AVEC FLUTTER ET ANALYSER LES LOGS

```bash
# Lancer Flutter en mode debug pour voir tous les logs
cd frontend/flutter_app
flutter run --debug
```

**PENDANT LE TEST :**
1. **Connectez-vous** à la room LiveKit depuis Flutter
2. **Parlez dans le micro** (dites quelque chose comme "Bonjour")
3. **Observez les logs** dans les 2 endroits :

**LOGS CÔTÉ AGENT (Terminal Docker) :**
```
🎤 [STT] Début traitement audio...
🎤 [STT] Audio stats: 48000 échantillons, énergie: 1234
🎤 [STT] Envoi à Whisper: 192000 bytes
✅ [STT] Transcription: 'Bonjour'
🧠 [LLM] Début génération réponse...
✅ [LLM] Réponse: 'Bonjour ! Comment puis-je vous aider...'
🔊 [TTS] Début synthèse audio...
✅ [TTS] Audio synthétisé: 48000 bytes
📡 [DIFFUSION] Début diffusion audio...
✅ [DIFFUSION] Audio publié sur LiveKit
```

**LOGS CÔTÉ FLUTTER (Console Flutter) :**
```
🔊 [CRITIQUE] Audio agent détecté - DIAGNOSTIC COMPLET
🔊 [DIAGNOSTIC AGENT AUDIO] Début diagnostic...
🔊 [DIAGNOSTIC] État track: Enabled: true, Muted: false
🔊 [DIAGNOSTIC SYSTÈME] Vérification système audio...
🔊 [ANDROID/iOS] Configuration audio...
🔊 [WEBRTC] Configuration WebRTC audio...
🔊 [STATS] Vérification statistiques audio...
```

### ÉTAPE 3 : ANALYSER LES RÉSULTATS

**SCÉNARIO A : AGENT NE PRODUIT PAS D'AUDIO**
Si vous voyez côté agent :
```
❌ [STT] Erreur Whisper
❌ [LLM] Aucune réponse générée  
❌ [TTS] Audio vide ou trop petit
```
→ **Problème dans le pipeline agent** (STT/LLM/TTS)

**SCÉNARIO B : AGENT PRODUIT L'AUDIO MAIS FLUTTER NE LE REÇOIT PAS**
Si vous voyez côté agent : ✅ Tout OK
Mais côté Flutter : Pas de logs "Audio agent détecté"
→ **Problème de connexion/publication LiveKit**

**SCÉNARIO C : FLUTTER REÇOIT LE TRACK MAIS PAS DE SON**
Si vous voyez côté Flutter :
```
🔊 [CRITIQUE] Audio agent détecté
❌ [DIAGNOSTIC SYSTÈME] Erreur permissions
❌ [ANDROID/iOS] Erreur configuration
```
→ **Problème système audio Flutter**

### ÉTAPE 4 : ACTIONS SELON LE DIAGNOSTIC

**Pour Scénario A (Pipeline Agent) :**
- Vérifier la connexion Whisper : `curl http://localhost:8001/health`
- Vérifier les clés API Mistral et OpenAI
- Vérifier les logs Docker des services

**Pour Scénario B (Connexion LiveKit) :**
- Vérifier les tokens LiveKit
- Vérifier la connectivité réseau
- Vérifier les logs LiveKit server

**Pour Scénario C (Système Audio Flutter) :**
- Vérifier les permissions audio
- Tester sur appareil physique vs émulateur
- Configurer les Platform Channels natifs

## 📋 CHECKLIST DE VALIDATION

### Phase 1 : Démarrage
- [ ] Agent démarre avec logs `🚀 [AGENT BOOTING UP]`
- [ ] Connexion LiveKit réussie `✅ [AGENT CONNECTED]`  
- [ ] Services STT/LLM/TTS créés `✅ [AGENT CONFIG]`

### Phase 2 : Pipeline
- [ ] Audio reçu par agent `🔧 CORRECTION: StreamAdapterContext.push_frame()`
- [ ] STT traitement lancé `🎤 [STT] Début traitement audio`
- [ ] Transcription obtenue `✅ [STT] Transcription: 'texte'`
- [ ] LLM génère réponse `✅ [LLM] Réponse: 'texte'`
- [ ] TTS synthétise audio `✅ [TTS] Audio synthétisé: X bytes`
- [ ] Audio publié LiveKit `✅ [DIFFUSION] Audio publié`

### Phase 3 : Réception Flutter
- [ ] Track détecté Flutter `🔊 [CRITIQUE] Audio agent détecté`
- [ ] Diagnostic système OK `✅ [DIAGNOSTIC SYSTÈME]`
- [ ] Configuration audio OK `✅ [ANDROID/iOS]`
- [ ] Stats WebRTC OK `✅ [STATS]`
- [ ] **AUDIO AUDIBLE** 🎵

## ⚡ COMMANDES RAPIDES

```bash
# Logs agent en temps réel
docker logs eloquence-agent -f | grep -E "(STT|LLM|TTS|DIFFUSION)"

# Logs Flutter filtrés  
flutter logs | grep -E "(CRITIQUE|DIAGNOSTIC|CORRECTION)"

# Redémarrage rapide agent
docker-compose restart eloquence-agent

# Test connectivité Whisper
curl http://localhost:8001/transcribe -F "audio=@test_audio.wav"
```

## 🎯 OBJECTIF FINAL

**RÉSULTAT ATTENDU :** 
- Parler dans le micro Flutter
- Voir tous les logs de diagnostic défiler
- **ENTENDRE la réponse de l'IA** dans le haut-parleur Flutter

**MAINTENANT, COMMENCEZ PAR L'ÉTAPE 1 !** 🚀
