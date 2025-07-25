# 🌟 API Universelle d'Exercices Audio - Guide Développeur

## Vue d'ensemble

L'API universelle d'exercices audio permet d'ajouter facilement de nouveaux exercices de confidence boost sans développement complexe. Elle fournit une interface simple et flexible pour créer des exercices personnalisés.

## 🚀 Démarrage rapide

### 1. Utilisation d'un template prédéfini

```dart
// Le plus simple - utilise un exercice prêt à l'emploi
Widget myScreen = ConfidenceBoostEntry.universalExercise('job_interview');

Navigator.push(context, MaterialPageRoute(builder: (_) => myScreen));
```

### 2. Exercice personnalisé

```dart
// Configuration custom pour vos besoins spécifiques
const customConfig = AudioExerciseConfig(
  exerciseId: 'my_custom_exercise',
  title: 'Mon exercice personnalisé',
  description: 'Description de l\'exercice',
  scenario: 'mon_scenario_custom',
  maxDuration: Duration(minutes: 15),
  customSettings: {
    'difficulty': 'intermediate',
    'focus_areas': ['confidence', 'articulation'],
  },
);

Widget myCustomScreen = ConfidenceBoostEntry.customExercise(customConfig);
```

## 📚 Templates disponibles

| Template ID | Description | Durée | Difficulté |
|-------------|-------------|-------|------------|
| `job_interview` | Entretien d'embauche | 15 min | Intermédiaire |
| `public_speaking` | Prise de parole publique | 12 min | Avancé |
| `casual_conversation` | Conversation décontractée | 8 min | Débutant |
| `debate` | Débat argumenté | 20 min | Expert |

## 🛠️ Configuration d'exercice

### Champs obligatoires

```dart
AudioExerciseConfig(
  exerciseId: 'unique_exercise_id',        // Identifiant unique
  title: 'Titre de l\'exercice',          // Nom affiché
  description: 'Description détaillée',    // Description pour l'utilisateur
  scenario: 'scenario_backend',            // Scénario côté backend
)
```

### Champs optionnels

```dart
AudioExerciseConfig(
  // ... champs obligatoires
  language: 'fr',                          // Langue (défaut: 'fr')
  maxDuration: Duration(minutes: 10),      // Durée max (défaut: 10 min)
  enableRealTimeEvaluation: true,          // Évaluation temps réel
  enableTTS: true,                         // Text-to-Speech activé
  enableSTT: true,                         // Speech-to-Text activé
  customSettings: {                        // Paramètres personnalisés
    'difficulty': 'intermediate',
    'focus_areas': ['confidence', 'clarity'],
    'special_features': {...},
  },
)
```

## 🎯 Exemples d'utilisation

### Exercice simple avec template

```dart
class MyExerciseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mes exercices')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConfidenceBoostEntry.universalExercise('job_interview')
              ),
            ),
            child: Text('Entretien d\'embauche'),
          ),
        ],
      ),
    );
  }
}
```

### Exercice personnalisé avancé

```dart
Widget createNegotiationExercise() {
  const config = AudioExerciseConfig(
    exerciseId: 'business_negotiation',
    title: 'Négociation commerciale',
    description: 'Maîtrisez l\'art de la négociation',
    scenario: 'negociation_commerciale',
    maxDuration: Duration(minutes: 18),
    customSettings: {
      'difficulty': 'expert',
      'focus_areas': ['persuasion', 'objection_handling'],
      'role_context': {
        'user_role': 'Commercial expérimenté',
        'ai_role': 'Client exigeant',
        'scenario_goals': ['Conclure la vente', 'Maintenir la relation'],
      },
      'evaluation_criteria': {
        'confidence': 30,    // 30% du score
        'persuasion': 25,    // 25% du score
        'adaptability': 25,  // 25% du score
        'closing': 20,       // 20% du score
      },
    },
  );
  
  return ConfidenceBoostEntry.customExercise(config);
}
```

## 🔧 Builder Pattern (optionnel)

Pour une création encore plus simple :

```dart
Widget myExercise = QuickExerciseBuilder()
  .id('team_leadership')
  .title('Leadership d\'équipe')
  .description('Développez vos compétences de leader')
  .scenario('leadership_equipe')
  .duration(Duration(minutes: 20))
  .difficulty('advanced')
  .focusAreas(['motivation', 'communication'])
  .buildAndLaunch();
```

## 🏗️ Architecture interne

### Flux de données

```
[Configuration] → [ConfidenceBoostEntry] → [UniversalExerciseLauncher] 
                                       ↓
[UniversalExerciseProvider] ← [UniversalExerciseScreen]
                                       ↓
[UniversalAudioExerciseService] → [Backend API]
```

### Composants clés

1. **ConfidenceBoostEntry** : Point d'entrée de l'API
2. **AudioExerciseConfig** : Configuration d'exercice
3. **UniversalAudioExerciseService** : Communication backend
4. **UniversalExerciseProvider** : Gestion d'état
5. **UniversalExerciseScreen** : Interface utilisateur

## 📡 Intégration Backend

### Scénarios supportés

- `entretien_embauche` : Simulation d'entretien
- `presentation_publique` : Prise de parole publique
- `conversation_informelle` : Discussion casual
- `debat_argumente` : Débat structuré
- `negociation_commerciale` : Négociation business
- `coaching_vocal` : Amélioration vocale

### API Endpoints utilisés

- `POST /start-conversation` : Démarre un exercice
- `WebSocket /ws/conversation/{session_id}` : Communication temps réel
- `POST /analyze-audio` : Analyse audio complète
- `POST /complete-exercise` : Finalise l'exercice

## 🎨 Personnalisation UI

### Thème et couleurs

L'interface utilise le thème unifié d'Eloquence avec adaptation automatique selon le type d'exercice.

### Widgets réutilisables

- `AnimatedMicrophoneButton` : Bouton micro avec animation
- `AvatarWithHalo` : Avatar IA avec indicateur d'état
- `ConversationChatWidget` : Zone de conversation
- `RealTimeMetricsWidget` : Métriques en temps réel

## 🚦 Gestion d'état

### Phases d'exercice

```dart
enum ExercisePhase {
  setup,      // Configuration initiale
  ready,      // Prêt à commencer
  listening,  // Écoute en cours
  processing, // Traitement de la réponse
  feedback,   // Affichage du feedback
  completed,  // Exercice terminé
  error,      // Erreur
}
```

### Provider pattern

```dart
// Accès au provider
final exerciseState = ref.watch(universalExerciseProvider);
final exerciseNotifier = ref.read(universalExerciseProvider.notifier);

// Actions disponibles
await exerciseNotifier.startExercise(config);
await exerciseNotifier.startListening();
await exerciseNotifier.stopListening();
await exerciseNotifier.finishExercise();
```

## 🧪 Tests et validation

### Test rapide

```dart
// Test avec template prédéfini
ConfidenceBoostEntry.universalExercise('job_interview')

// Test avec configuration minimale
ConfidenceBoostEntry.customExercise(AudioExerciseConfig(
  exerciseId: 'test_exercise',
  title: 'Test',
  description: 'Exercice de test',
  scenario: 'test_scenario',
))
```

## 🔍 Debugging

### Logs utiles

```dart
// Activer les logs détaillés
debugPrint('🚀 Démarrage exercice: ${config.exerciseId}');
debugPrint('📊 Métriques: ${exerciseState.metrics}');
debugPrint('💬 Messages: ${exerciseState.messages.length}');
```

### Points de contrôle

1. Vérification de la configuration
2. Connexion au service backend
3. État du WebSocket
4. Réception des métriques
5. Finalisation de l'exercice

## 📋 Checklist d'intégration

- [ ] Importer les classes nécessaires
- [ ] Créer la configuration d'exercice
- [ ] Utiliser `ConfidenceBoostEntry.universalExercise()` ou `ConfidenceBoostEntry.customExercise()`
- [ ] Intégrer dans votre navigation
- [ ] Tester avec le backend Eloquence
- [ ] Vérifier les logs en cas de problème

## 💡 Bonnes pratiques

1. **IDs uniques** : Utilisez des exerciseId descriptifs et uniques
2. **Gestion d'erreur** : Toujours gérer les cas d'erreur
3. **Performance** : Évitez les configurations trop lourdes
4. **UX** : Prévoir des messages de statut clairs
5. **Tests** : Tester avec différents types d'exercices

## 🆘 Support

Pour toute question ou problème :
1. Consultez les exemples dans `universal_api_usage_examples.dart`
2. Vérifiez les logs de debug
3. Testez avec un template simple d'abord
4. Contactez l'équipe Eloquence pour support avancé

---

*Cette API universelle facilite grandement l'ajout de nouveaux exercices. Plus besoin de créer des écrans complets - juste une configuration et c'est parti ! 🚀*