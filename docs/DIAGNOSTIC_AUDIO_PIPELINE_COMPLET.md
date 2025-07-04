# 🔍 Diagnostic Complet du Pipeline Audio LiveKit

## 📋 Résumé du Problème

L'IA ne produit **AUCUN SON** malgré :
- ✅ Agent LiveKit démarré et connecté
- ✅ Corrections ChatContext.messages appliquées
- ✅ Corrections SynthesizedAudio appliquées
- ❌ **AUCUN SON** audible sur l'appareil

## 🎯 Sources Identifiées du Problème

### 1. **Format Audio Incompatible** (PLUS PROBABLE)
- OpenAI TTS génère du **MP3**
- LiveKit attend du **PCM 16-bit**
- ❌ **Aucune conversion MP3 → PCM implémentée**

### 2. **Pipeline de Publication Audio**
- Le track audio est créé et publié
- Mais les données MP3 ne sont pas converties
- LiveKit ne peut pas décoder le MP3 directement

## 🔧 Modifications Appliquées

### 1. Logs de Diagnostic Détaillés

#### `_stream_tts_audio()` - Diffusion Audio
```python
# Logs ajoutés pour tracer :
- Taille des données audio
- Création de l'AudioSource
- Publication du track
- Statistiques audio (min, max, mean, std)
- Nombre de chunks envoyés
- État final du track
```

#### `_generate_audio()` - Génération TTS
```python
# Logs ajoutés pour :
- Vérification de la clé API
- Paramètres de la requête
- Statut de la réponse
- Analyse du header MP3
- Taille des données générées
```

#### `_call_tts_service()` - Service TTS
```python
# Logs ajoutés pour :
- Nombre de chunks reçus
- Taille totale des données
- Tentative de conversion MP3 → PCM
```

### 2. Script de Test Complet

Créé `test_audio_pipeline.py` qui teste :
1. **Variables d'environnement**
2. **OpenAI TTS** - Génération audio
3. **Connexion LiveKit**
4. **Publication audio**

## 🚨 Problème Principal Identifié

### **CONVERSION AUDIO MANQUANTE**

```
OpenAI TTS → MP3 → ❌ (pas de conversion) → LiveKit (attend PCM)
```

LiveKit ne peut pas lire directement le MP3. Il faut :
1. Décoder le MP3 en PCM
2. Convertir en 16-bit, 24kHz, mono
3. Envoyer les frames PCM à LiveKit

## 📝 Solution Proposée

### Option 1 : Utiliser pydub pour la conversion
```python
from pydub import AudioSegment
import io

async def _convert_mp3_to_pcm(self, mp3_data: bytes) -> bytes:
    """Convertir MP3 en PCM 16-bit pour LiveKit"""
    # Charger le MP3
    audio = AudioSegment.from_mp3(io.BytesIO(mp3_data))
    
    # Convertir en mono, 24kHz, 16-bit
    audio = audio.set_channels(1)
    audio = audio.set_frame_rate(24000)
    audio = audio.set_sample_width(2)  # 16-bit
    
    # Exporter en raw PCM
    return audio.raw_data
```

### Option 2 : Utiliser ffmpeg-python
```python
import ffmpeg

async def _convert_mp3_to_pcm(self, mp3_data: bytes) -> bytes:
    """Convertir MP3 en PCM avec ffmpeg"""
    process = (
        ffmpeg
        .input('pipe:', format='mp3')
        .output('pipe:', format='s16le', acodec='pcm_s16le', ac=1, ar='24k')
        .run_async(pipe_stdin=True, pipe_stdout=True)
    )
    
    stdout, _ = process.communicate(input=mp3_data)
    return stdout
```

### Option 3 : Changer le format TTS
Utiliser un service TTS qui génère directement du PCM au lieu du MP3.

## 🔍 Comment Exécuter le Diagnostic

1. **Lancer le script de test** :
```bash
cd services/api-backend
python test_audio_pipeline.py
```

2. **Vérifier les logs** :
```bash
# Logs de l'agent
docker-compose logs -f api-backend

# Logs du test
cat audio_pipeline_test_*.log
```

3. **Analyser l'audio généré** :
```bash
# Le test crée test_audio_output.mp3
# Vérifier qu'il contient bien de l'audio
```

## ✅ Actions Immédiates

1. **Installer les dépendances pour la conversion** :
```bash
pip install pydub
# ou
pip install ffmpeg-python
```

2. **Implémenter la conversion MP3 → PCM**

3. **Tester avec le script de diagnostic**

4. **Vérifier les logs détaillés**

## 📊 Checklist de Validation

- [ ] OpenAI TTS génère bien du MP3
- [ ] Le MP3 est valide (peut être lu)
- [ ] La conversion MP3 → PCM fonctionne
- [ ] Les frames PCM sont envoyées à LiveKit
- [ ] Le track audio est publié sur la room
- [ ] L'audio est audible côté client

## 🚀 Prochaines Étapes

1. **Implémenter la conversion audio**
2. **Relancer l'agent avec les logs**
3. **Exécuter le script de test**
4. **Valider que l'audio est audible**

---

**Note** : Le problème principal est très probablement le format audio. LiveKit ne peut pas décoder le MP3 directement, il faut absolument convertir en PCM avant l'envoi.