# Tests d'Intégration LiveKit + Vosk STT + IA

## Vue d'ensemble

Ce guide détaille les tests d'intégration complets avec audio synthétisé pour valider la cohérence de la chaîne complète : Audio → Vosk STT → IA Mistral.

## 📋 Prérequis

### Services Docker
```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier que les services sont actifs
docker-compose ps
```

### Dépendances Python

**Linux/Mac:**
```bash
chmod +x scripts/install_tts_deps.sh
./scripts/install_tts_deps.sh
```

**Windows:**
```powershell
.\scripts\install_tts_deps.ps1
```

**Installation manuelle:**
```bash
pip install pyttsx3 gtts aiohttp
```

## 🧪 Scripts de Test

### 1. Test des Optimisations Vosk
```bash
python test_vosk_optimizations.py
```

**Fonctionnalités:**
- Test de santé du service Vosk
- Mesure des performances avec pool de recognizers
- Test de charge avec requêtes concurrentes
- Validation de la logique de fallback

### 2. Test d'Intégration Complète avec Audio Synthétisé
```bash
python test_livekit_ia_integration.py
```

**Fonctionnalités:**
- 🎤 **Vosk STT avec Audio Synthétisé**: Génère de l'audio français, teste la transcription
- 🤖 **Mistral IA Conversation**: Teste les réponses contextuelles de l'IA
- 🔄 **Flow d'Intégration Complet**: Audio → Transcription → Réponse IA
- 📊 **Métriques de Cohérence**: Vérifie la cohérence contextuelle des échanges

## 🎯 Scénarios de Test

### Tests Vosk STT
```
✅ "Bonjour, je m'appelle Thomas et je suis votre assistant vocal."
✅ "Comment allez-vous aujourd'hui ? J'espère que tout va bien."
✅ "Pouvez-vous me parler de vos objectifs de confiance en soi ?"
✅ "C'est parfait ! Nous allons travailler ensemble sur votre développement personnel."
✅ "Répétez après moi : Je suis capable et je mérite le succès."
```

### Tests IA Conversation
```
💬 "Bonjour Thomas, comment puis-je améliorer ma confiance en moi ?"
💬 "J'ai peur de parler en public, que me conseillez-vous ?"
💬 "Comment puis-je me préparer à un entretien d'embauche ?"
💬 "Aidez-moi à surmonter mes doutes sur mes compétences."
💬 "Quels exercices puis-je faire pour être plus assertif ?"
```

### Tests d'Intégration Complète
```
🎯 "Bonjour Thomas, j'aimerais travailler sur ma confiance en public"
🎯 "Je me sens stressé avant les présentations importantes"
🎯 "Comment puis-je mieux m'exprimer devant mes collègues ?"
```

## 📊 Métriques Évaluées

### Performance Vosk
- **Temps de réponse** (objectif < 1s)
- **Taux de réussite** transcription
- **Similarité textuelle** (original vs transcrit)
- **Confiance** du modèle Vosk

### Qualité IA
- **Cohérence contextuelle** des réponses
- **Longueur appropriée** des réponses
- **Pertinence** par rapport à la transcription

### Intégration Globale
- **Taux de réussite** end-to-end
- **Latence totale** du flow
- **Préservation du contexte** dans la chaîne

## 🎤 Moteurs TTS Supportés

### pyttsx3 (Local - Recommandé)
- ✅ Fonctionne hors ligne
- ✅ Rapide
- ✅ Qualité acceptable
- ❌ Voix synthétique

### gTTS (Internet - Fallback)
- ✅ Qualité vocale supérieure
- ✅ Voix plus naturelle
- ❌ Nécessite internet
- ❌ Plus lent

## 🔧 Configuration des Services

### URLs de Test
```
Vosk STT:     http://localhost:8002
Mistral IA:   http://localhost:8001
LiveKit:      ws://localhost:7880
Token Service: http://localhost:8004
```

### Variables d'Environnement
```bash
# Vérifier la configuration
docker-compose logs vosk-stt | grep "Model loaded"
docker-compose logs mistral-conversation | grep "Server started"
docker-compose logs livekit-agent | grep "Agent started"
```

## 📈 Résultats Attendus

### Seuils de Performance
- **Vosk STT**: > 80% similarité, < 1s latence
- **Mistral IA**: > 90% réponses cohérentes
- **Intégration**: > 80% succès end-to-end

### Indicateurs de Qualité
```
🟢 Excellent:     > 80% succès global
🟡 Acceptable:    60-80% succès global  
🔴 À améliorer:   < 60% succès global
```

## 🐛 Dépannage

### Service Vosk Inaccessible
```bash
# Vérifier les logs
docker-compose logs vosk-stt

# Redémarrer le service
docker-compose restart vosk-stt
```

### Erreurs TTS
```bash
# Vérifier l'installation
python -c "import pyttsx3; print('pyttsx3 OK')"
python -c "import gtts; print('gTTS OK')"

# Réinstaller si nécessaire
pip install --upgrade pyttsx3 gtts
```

### Problèmes Audio
```bash
# Linux: Vérifier ALSA/PulseAudio
pactl info

# Windows: Vérifier les pilotes audio
# Mac: Vérifier les permissions micro
```

## 🚀 Démarrage Rapide

```bash
# 1. Démarrer les services
docker-compose up -d

# 2. Installer les dépendances TTS
./scripts/install_tts_deps.sh  # Linux/Mac
# ou
.\scripts\install_tts_deps.ps1  # Windows

# 3. Lancer les tests
python test_vosk_optimizations.py
python test_livekit_ia_integration.py

# 4. Voir les logs en temps réel
docker-compose logs -f vosk-stt livekit-agent mistral-conversation
```

## 📝 Interprétation des Résultats

### Exemples de Sortie
```
🧪 TESTS D'INTÉGRATION LIVEKIT + IA AVEC AUDIO SYNTHÉTISÉ
============================================================

📊 RÉSULTATS VOSK STT:
   Tests réussis: 5/5
   Confiance moyenne: 0.85
   Similarité moyenne: 78.2%

📊 RÉSULTATS MISTRAL IA:
   Conversations réussies: 5/5
   Longueur réponse moyenne: 156 caractères

📊 RÉSULTATS INTÉGRATION COMPLÈTE:
   Scénarios réussis: 3/3
   Cohérence contextuelle: 3/3

🎉 RÉSUMÉ GLOBAL:
   Taux de réussite global: 84.6%
   🟢 Système parfaitement opérationnel
```

Cette suite de tests valide la robustesse et la cohérence de l'architecture complète de transcription temps réel optimisée.