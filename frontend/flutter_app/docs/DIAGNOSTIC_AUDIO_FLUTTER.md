# 🔊 DIAGNOSTIC PROBLÈME AUDIO FLUTTER

## 📋 RÉSUMÉ DU PROBLÈME
- **Backend** : ✅ Fonctionne parfaitement (agent se connecte, publie audio, envoie 15 chunks TTS)
- **Flutter** : ❌ Pas de son audible malgré la détection correcte des pistes audio
- **Logs Flutter** : Montrent "RemoteAudioTrack de l'IA détectée et stockée" et "Piste audio IA prête pour lecture"

## 🔍 DIAGNOSTICS AJOUTÉS

### 1. Logs détaillés dans `livekit_service.dart`
```dart
// Lignes 508-530 et 568-585
- Track SID, muted, kind, source
- État de la piste audio
- Participant identity
```

### 2. Méthode `enableRemoteAudioPlayback()` améliorée
```dart
// Lignes 753-820
- Diagnostic complet de tous les participants
- Vérification des publications audio
- État final du remoteAudioTrack
```

## 🎯 CAUSES PROBABLES

### 1. **Volume Audio à Zéro** (Plus probable)
- La piste audio est activée mais le volume pourrait être à 0
- LiveKit n'a pas de méthode `setVolume()` directe sur `RemoteAudioTrack`

### 2. **Routing Audio Android**
- L'audio pourrait être routé vers le mauvais périphérique (earpiece vs speaker)
- Configuration `AndroidAudioConfiguration.media` est correcte mais peut nécessiter un ajustement

### 3. **Problème de Souscription**
- La piste est détectée mais pas correctement souscrite
- Le flag `subscribed` des publications doit être vérifié

### 4. **Codec Audio Incompatible**
- Le codec utilisé par le backend (Opus) pourrait ne pas être décodé correctement

## 🛠️ SOLUTIONS À TESTER

### Solution 1 : Forcer le Speaker Audio
```dart
// Dans _configureAndroidAudio()
await webrtc.WebRTC.initialize(options: {
  'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.speakerphone.toMap()
});

webrtc.Helper.setAndroidAudioConfiguration(
  webrtc.AndroidAudioConfiguration.speakerphone
);
```

### Solution 2 : Vérifier la Souscription
```dart
// Dans enableRemoteAudioPlayback()
if (!publication.subscribed) {
  _logger.w('⚠️ Publication non souscrite!');
  // Forcer la souscription si possible
}
```

### Solution 3 : Ajouter un AudioElement (Web)
Pour Flutter Web uniquement :
```dart
if (kIsWeb) {
  // Créer un élément audio HTML pour forcer la lecture
}
```

### Solution 4 : Vérifier les Permissions Audio
```dart
// Ajouter dans pubspec.yaml
permission_handler: ^10.4.3

// Vérifier les permissions
final status = await Permission.microphone.status;
if (!status.isGranted) {
  await Permission.microphone.request();
}
```

## 📱 COMMANDES DE TEST

### 1. Relancer l'application avec les nouveaux logs
```bash
cd frontend/flutter_app
flutter run --release
```

### 2. Observer les logs détaillés
Chercher spécifiquement :
- `[AUDIO_DIAGNOSTIC]` - Nouveaux logs de diagnostic
- `Track muted: true/false` - État muet de la piste
- `Subscribed: true/false` - État de souscription
- `remoteAudioTrack != null` - Présence de la piste

### 3. Tester avec le haut-parleur
Si l'audio sort sur l'écouteur au lieu du haut-parleur, modifier la configuration audio.

## 🚨 ACTIONS IMMÉDIATES

1. **Relancer l'app** avec les logs ajoutés
2. **Copier les logs** `[AUDIO_DIAGNOSTIC]` complets
3. **Tester** en mettant le téléphone sur haut-parleur
4. **Vérifier** le volume système Android n'est pas à 0

## 📊 LOGS À SURVEILLER

```
🔊 [AUDIO_DIAGNOSTIC] === DIAGNOSTIC AUDIO DÉTAILLÉ ===
🔊 [AUDIO_DIAGNOSTIC] Track SID: TR_AMUvHCGRJriYZZ
🔊 [AUDIO_DIAGNOSTIC] Track muted: false  <-- DOIT ÊTRE false
🔊 [AUDIO_DIAGNOSTIC] Track kind: audio
🔊 [AUDIO_DIAGNOSTIC] Track source: microphone
🔊 [AUDIO_DIAGNOSTIC] Publication subscribed: true  <-- DOIT ÊTRE true
🔊 [AUDIO_DIAGNOSTIC] remoteAudioTrack != null: true  <-- DOIT ÊTRE true
```

## 🔧 PROCHAINES ÉTAPES

Si les logs montrent tout correct mais toujours pas de son :
1. Modifier `AndroidAudioConfiguration` vers `speakerphone`
2. Ajouter un listener sur les événements audio
3. Vérifier les codecs supportés
4. Tester sur un autre appareil Android