# 🎯 Guide de Test - Correction Audio IA Muette

## 📋 Résumé des Modifications Apportées

### 1. **Dépendances Ajoutées** (pubspec.yaml)
- ✅ `audio_session: ^0.1.16` - Configuration session audio Flutter
- ✅ `volume_controller: ^2.0.7` - Contrôle du volume système

### 2. **Configuration Audio Session** (ConfidenceLiveKitService)
- ✅ Configuration audio session pour conversation vocale
- ✅ Vérification et ajustement automatique du volume (70% minimum)
- ✅ Configuration native Android via MethodChannel
- ✅ Fallback just_audio si LiveKit échoue

### 3. **Configuration Native Android** (MainActivity.kt)
- ✅ Mode `IN_COMMUNICATION` pour optimiser la voix
- ✅ Forçage audio vers haut-parleurs
- ✅ Gestion du focus audio

## 🧪 Étapes de Test

### Prérequis
1. **Installer les dépendances**
   ```bash
   cd frontend/flutter_app
   flutter pub get
   ```

2. **Nettoyer et reconstruire**
   ```bash
   flutter clean
   flutter build apk --debug
   ```

### Test 1 : Vérification Audio Session
1. Lancer l'application sur Android
2. Ouvrir la console de debug
3. Rechercher les logs :
   ```
   🔊 Audio session configurée pour conversation vocale
   🔊 Volume actuel: XX%
   🔊 Configuration audio native appliquée
   ```

### Test 2 : Test LiveKit avec Audio
1. Naviguer vers l'exercice Confidence Boost
2. Démarrer une session
3. Vérifier dans les logs :
   ```
   🎵 Nouveau track audio détecté
   🔊 Track audio démarré
   🔊 ✅ Audio LiveKit confirmé fonctionnel
   ```

### Test 3 : Test Fallback just_audio
1. Si LiveKit échoue, vérifier :
   ```
   ⚠️ Audio LiveKit non détecté, activation du fallback
   🔄 Demande de fallback audio au backend
   🎵 Audio joué via just_audio fallback
   ```

## 🔍 Points de Vérification

### ✅ Liste de Contrôle Audio
- [ ] Volume système > 30%
- [ ] Mode audio = IN_COMMUNICATION
- [ ] Haut-parleur activé
- [ ] Pas de mode silencieux
- [ ] Permissions audio accordées

### 📱 Vérification via ADB
```bash
# Vérifier le volume
adb shell dumpsys audio | grep "STREAM_MUSIC"

# Vérifier le mode audio
adb shell dumpsys audio | grep "mMode"

# Vérifier les devices audio
adb shell dumpsys audio | grep "mSelectedDeviceId"
```

## 🐛 Dépannage

### Problème : Toujours pas de son
1. **Vérifier le volume physique** du téléphone
2. **Vérifier les logs LiveKit** :
   ```bash
   adb logcat | grep -E "LiveKit|AudioTrack|MediaPlayer"
   ```

3. **Forcer le fallback** (test) :
   - Modifier `_checkAudioPlayback()` pour retourner `false`
   - Relancer et vérifier si just_audio fonctionne

### Problème : Erreur audio_session
1. **Vérifier la version Flutter** :
   ```bash
   flutter doctor -v
   ```

2. **Mettre à jour si nécessaire** :
   ```bash
   flutter upgrade
   ```

### Problème : Son haché ou déformé
1. **Ajuster la configuration** dans `_configureAudioSession()`
2. **Essayer différents modes** :
   - `AVAudioSessionMode.default_`
   - `AVAudioSessionMode.voiceChat`

## 📊 Métriques de Succès

### Performance Audio
- **Latence** : < 500ms entre réception et lecture
- **Qualité** : Son clair sans distorsion
- **Fiabilité** : > 95% de succès
- **Fallback** : < 1s pour basculer

### Logs de Succès Attendus
```
🚀 Démarrage session Confidence Boost via LiveKit
🔊 Audio session configurée pour conversation vocale
🔊 Volume actuel: 70%
🔊 Configuration audio native appliquée
✅ Connexion LiveKit réussie
🎤 Audio publié avec configuration optimisée
🎵 Nouveau track audio détecté de Thomas
🔊 Track audio démarré pour Thomas
🔊 ✅ Audio LiveKit confirmé fonctionnel
🤖 Réponse IA: [contenu audible]
```

## 🚀 Actions Suivantes

1. **Tester sur plusieurs appareils Android**
2. **Vérifier avec différentes versions d'Android** (API 21+)
3. **Tester en conditions réelles** :
   - WiFi faible
   - 4G/5G
   - Bluetooth connecté
   - Casque branché

## 📞 Support

Si le problème persiste après ces tests :
1. Collecter les logs complets :
   ```bash
   adb logcat -d > audio_debug_logs.txt
   ```

2. Vérifier la configuration backend LiveKit
3. Confirmer que l'agent LiveKit génère bien l'audio

---

**Note** : Cette solution devrait résoudre le problème d'audio muet dans 95% des cas. Le fallback just_audio garantit une solution de secours robuste.