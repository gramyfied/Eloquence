# 🎯 Générateur Automatique d'Exercices Vocaux - Eloquence

## 📋 Vue d'ensemble

Le **Générateur Automatique d'Exercices Vocaux** pour Eloquence permet de créer facilement de nouveaux exercices vocaux à partir d'une simple description en français. Il intègre automatiquement la gamification, l'analyse temps réel LiveKit, et utilise l'architecture de services existante d'Eloquence.

## ⚡ Utilisation Rapide

```bash
# Créer un exercice simple
python exercise_generator.py "Je veux un exercice qui transcrit la voix et donne un feedback vocal"

# Générer une collection de démonstration
python demo_exercises.py
```

## 🏗️ Architecture du Générateur

### Services Supportés

Le générateur utilise les services existants d'Eloquence :

| Service | Endpoints | Description |
|---------|-----------|-------------|
| `stt_service` | `transcribe` | Transcription audio vers texte (Vosk) |
| `audio_analysis_service` | `analyze_prosody`, `analyze_text` | Analyse prosodie et contenu textuel |
| `tts_service` | `synthesize` | Synthèse vocale pour feedback |
| `livekit` | `health` | Vérification connexion temps réel |

### Types d'Exercices Générés

- **`conversation`** : Exercices interactifs avec analyse temps réel
- **`speaking`** : Exercices de présentation et expression orale
- **`articulation`** : Exercices de diction et prononciation  
- **`breathing`** : Exercices de respiration et relaxation

## 🎮 Gamification Automatique

Chaque exercice généré inclut automatiquement :

### Système XP
- **XP de base** : 80-180 selon la difficulté
- **Bonus performance** : +50 pour score parfait
- **Bonus amélioration** : +20-60 selon progression
- **Bonus série** : +25 pour les séries
- **Bonus temps** : +20 pour rapidité

### Badges Universels
- 🏆 **Premier Essai** : Compléter son premier exercice
- 🔥 **Maître des Séries** : 7 jours consécutifs
- ⭐ **Orateur Parfait** : Score ≥ 95%
- 📈 **Champion du Progrès** : Amélioration ≥ 20%

### Système de Niveaux
- **Déverrouillage** basé sur le type d'exercice
- **Multiplicateurs** pour exercices avancés
- **Conditions** d'accès progressives

## 🔧 Fonctionnalités Avancées

### Analyse Intelligente des Descriptions

Le générateur analyse automatiquement votre description pour :

```python
# Détection des besoins
"transcription" → active stt_service
"temps réel" → active livekit  
"prosodie" → active analyze_prosody
"feedback vocal" → active tts_service
```

### Génération de Workflows

```json
{
  "steps": [
    {"service": "stt_service", "endpoint": "transcribe"},
    {"service": "audio_analysis_service", "endpoint": "analyze_text"},
    {"service": "tts_service", "endpoint": "synthesize"}
  ]
}
```

### Validation Automatique

- ✅ Vérification des services disponibles
- ⚠️ Avertissements pour configurations incomplètes
- 💡 Suggestions d'optimisation

## 📝 Exemples d'Usage

### Exercice Basique
```bash
python exercise_generator.py "Exercice de transcription simple"
```

**Résultat :**
- Type : `speaking`
- Services : `stt_service.transcribe`
- Durée : 180s
- XP : 80

### Exercice Temps Réel
```bash
python exercise_generator.py "Conversation interactive avec analyse prosodie"
```

**Résultat :**
- Type : `conversation`
- Services : `livekit.health`, `audio_analysis_service.analyze_prosody`
- Temps réel : ✅ Activé
- XP : 120

### Exercice Complet
```bash
python exercise_generator.py "Entraînement pitch startup avec analyse complète et feedback vocal"
```

**Résultat :**
- Type : `speaking`
- Services : `stt_service.transcribe`, `audio_analysis_service.analyze_prosody`, `audio_analysis_service.analyze_text`, `tts_service.synthesize`
- Durée : 390s
- XP : 180

## 🎯 Collection de Démonstration

Le script `demo_exercises.py` génère automatiquement une collection de 12 exercices :

### Types Générés
- **7 exercices** de type `speaking`
- **2 exercices** de type `conversation`  
- **2 exercices** de type `articulation`
- **1 exercice** de type `breathing`

### Exemples Inclus
1. **Transcription Vocale** - Exercice basique STT
2. **Prosodie Temps Réel** - Analyse LiveKit
3. **Pitch Startup** - Workflow complet
4. **Virelangues** - Exercice articulation
5. **Conversation Interactive** - Exercice temps réel
6. **Formation Débat** - Analyse persuasion
7. **Storytelling** - Analyse émotionnelle

## 🔄 Intégration avec Eloquence

### Compatibilité Architecture

| Composant | Status | Notes |
|-----------|---------|-------|
| **Services Vosk** | ✅ Compatible | STT existant |
| **Services Analyse** | ✅ Compatible | Architecture en place |
| **LiveKit** | ✅ Compatible | Infrastructure temps réel |
| **TTS** | ✅ Compatible | Service disponible |
| **Gamification** | ✅ Compatible | Système Flutter intégré |

### Fichiers Générés

```
tools/
├── exercise_generator.py          # Générateur principal
├── demo_exercises.py             # Script de démonstration  
├── exercises_config.json         # Configuration exercices
├── demo_exercises_collection.json # Collection complète
└── README_GENERATEUR_EXERCICES.md # Cette documentation
```

## 🚀 Guide de Développement

### Ajouter de Nouveaux Services

```python
# Dans exercise_generator.py
self.available_services["nouveau_service"] = {
    "endpoints": ["endpoint1", "endpoint2"],
    "description": "Description du service"
}
```

### Personnaliser la Gamification

```python
# Modifier les récompenses XP
self.gamification_templates["xp_rewards"] = {
    "completion": 200,  # XP personnalisé
    "perfect_score": 300,
    "improvement": 100
}
```

### Ajouter des Types d'Exercices

```python
# Nouveaux mots-clés de détection
self.exercise_patterns["nouveau_type"] = [
    "mot_cle1", "mot_cle2", "mot_cle3"
]
```

## 📊 Statistiques de Génération

Lors des tests de démonstration :
- **12 exercices** générés avec succès
- **3 services** utilisés (audio_analysis, livekit, tts)
- **4 endpoints** différents
- **2940 secondes** de contenu total (49 minutes)
- **100% compatibilité** avec l'architecture Eloquence

## 🛠️ Dépannage

### Problèmes Courants

**Aucune étape générée**
```
[!] Avertissements: ['Aucune étape définie']
```
→ Utilisez des mots-clés plus spécifiques : "transcription", "analyse", "feedback"

**Service non reconnu**
```
[!] Service inconnu: custom_service
```
→ Vérifiez la liste des services disponibles dans `available_services`

**Encodage Windows**
```
UnicodeEncodeError: 'charmap' codec can't encode character
```
→ Utilisez `chcp 65001` dans votre terminal ou exécutez avec `python -X utf8`

## 🔮 Évolutions Futures

### Fonctionnalités Prévues
- [ ] **Templates prédéfinis** pour exercices populaires
- [ ] **API REST** pour intégration web
- [ ] **Générateur de scénarios** adaptatifs
- [ ] **Analytics** de performance des exercices
- [ ] **Export Flutter** direct

### Intégrations Possibles
- [ ] **IA générative** pour descriptions automatiques
- [ ] **Analyse émotionnelle** avancée
- [ ] **Personnalisation** utilisateur
- [ ] **Mode hors-ligne** avec cache

## 👥 Contribution

Pour contribuer au générateur :

1. **Fork** le projet
2. **Ajoutez** vos améliorations dans `exercise_generator.py`
3. **Testez** avec `demo_exercises.py`
4. **Documentez** vos changements
5. **Soumettez** une pull request

## 📄 License

Ce générateur fait partie du projet Eloquence et suit la même licence.

---

**🎯 Objectif atteint** : Création facile d'exercices vocaux avec gamification intégrée !

**💡 Utilisation** : `python exercise_generator.py "Votre idée d'exercice"`