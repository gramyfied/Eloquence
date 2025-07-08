# Confidence Boost Express

## Description
L'exercice "Confidence Boost Express" est une fonctionnalité permettant aux utilisateurs de pratiquer leur expression orale en 30 secondes sur différents scénarios. L'exercice utilise l'analyse vocale avec Whisper et Mistral pour fournir un feedback détaillé sur la performance.

## Architecture

### Structure des dossiers
```
confidence_boost/
├── domain/
│   ├── entities/
│   │   ├── confidence_scenario.dart
│   │   └── confidence_session.dart
│   └── repositories/
│       └── confidence_repository.dart
├── data/
│   ├── datasources/
│   │   ├── confidence_local_datasource.dart
│   │   └── confidence_remote_datasource.dart
│   ├── repositories/
│   │   └── confidence_repository_impl.dart
│   └── services/
│       └── confidence_analysis_service.dart
└── presentation/
    ├── providers/
    │   └── confidence_boost_provider.dart
    ├── screens/
    │   └── confidence_boost_screen.dart
    └── widgets/
        ├── confidence_scenario_card.dart
        ├── confidence_timer_widget.dart
        ├── confidence_tips_carousel.dart
        └── confidence_results_view.dart
```

## Fonctionnalités principales

### 1. Sélection de scénario
- 10 scénarios prédéfinis avec différents niveaux de difficulté
- Catégories : social, professionnel, leadership
- Tips contextuels pour chaque scénario

### 2. Enregistrement audio
- Durée fixe de 30 secondes
- Timer visuel avec progression circulaire
- Utilisation de flutter_sound pour l'enregistrement

### 3. Analyse vocale
- Transcription avec Whisper
- Analyse de confiance avec Mistral
- Scores détaillés :
  - Confiance (assurance, conviction)
  - Fluidité (débit, pauses)
  - Clarté (articulation, structure)
  - Énergie (enthousiasme, dynamisme)

### 4. Système de badges
- 8 badges à débloquer
- Progression basée sur les performances
- Animations de récompense

## Design System

### Couleurs
- Navy : #1A1F2E (fond principal)
- Cyan : #00D4FF (accent principal)
- Violet : #8B5CF6 (accent secondaire)

### Composants glassmorphism
- EloquenceGlassCard pour les cartes
- Effets de flou et transparence
- Bordures lumineuses animées

### Ergonomie thumb zone
- Microphone placé à 200px du bas minimum
- Boutons principaux dans la zone accessible
- Navigation intuitive

## Base de données

### Tables Supabase
1. **confidence_scenarios**
   - Stockage des scénarios d'exercice
   - Métadonnées (difficulté, catégorie, tips)

2. **confidence_sessions**
   - Historique des sessions utilisateur
   - Scores et analyses détaillées
   - Badges débloqués

## API Integration

### Endpoints utilisés
- `/api/transcribe` - Transcription audio avec Whisper
- `/api/generate` - Analyse avec Mistral

### Format des requêtes
```dart
// Transcription
POST /api/transcribe
Content-Type: multipart/form-data
Body: audio file

// Analyse
POST /api/generate
Content-Type: application/json
Body: {
  "prompt": "...",
  "model": "mistral",
  "temperature": 0.7,
  "max_tokens": 500
}
```

## État et gestion

### Providers Riverpod
- `confidenceSessionProvider` - État de la session en cours
- `confidenceScenariosProvider` - Liste des scénarios
- `confidenceStatsProvider` - Statistiques utilisateur
- `badgeCheckProvider` - Vérification des badges

## Tests recommandés

### Tests unitaires
- Services d'analyse
- Calcul des scores
- Logique de badges

### Tests widgets
- Timer et animations
- Cartes de scénario
- Vue des résultats

### Tests d'intégration
- Flow complet d'enregistrement
- Intégration API
- Persistance des données

## Améliorations futures

1. **Mode hors ligne**
   - Cache local des scénarios
   - Analyse basique sans API

2. **Personnalisation**
   - Scénarios personnalisés
   - Objectifs adaptés

3. **Social**
   - Partage de performances
   - Défis entre amis

4. **Analytics**
   - Graphiques de progression
   - Insights détaillés

## Utilisation

```dart
// Navigation vers l'exercice
context.go('/confidence-boost?userId=$userId');

// Démarrer une session
ref.read(confidenceSessionProvider(userId).notifier)
  .startSession(scenario);

// Analyser un enregistrement
ref.read(confidenceSessionProvider(userId).notifier)
  .stopRecordingAndAnalyze(audioPath);
```

## Maintenance

### Migration base de données
Exécuter le fichier SQL :
```
supabase/migrations/20250107_confidence_boost_tables.sql
```

### Configuration API
Vérifier les clés API dans :
- `ApiService` pour l'authentification
- Backend pour Whisper/Mistral

### Monitoring
- Logger les erreurs d'analyse
- Suivre les taux de complétion
- Analyser les performances moyennes