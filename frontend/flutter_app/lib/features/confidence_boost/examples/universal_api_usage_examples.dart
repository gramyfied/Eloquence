/// 🌟 EXEMPLES D'UTILISATION DE L'API UNIVERSELLE D'EXERCICES
/// 
/// Ce fichier démontre comment utiliser l'API universelle pour ajouter
/// facilement de nouveaux exercices sans gros développement

import 'package:flutter/material.dart';
import '../presentation/screens/confidence_boost_entry.dart';
import '../data/services/universal_audio_exercise_service.dart';

/// 📚 GUIDE D'UTILISATION RAPIDE
/// 
/// L'API universelle permet d'ajouter de nouveaux exercices en 3 étapes :
/// 1. Créer une configuration AudioExerciseConfig
/// 2. Utiliser ConfidenceBoostEntry.universalExercise() ou ConfidenceBoostEntry.customExercise()
/// 3. Navigator.push vers l'écran généré
class UniversalApiExamples {

  /// 🎯 EXEMPLE 1: Utilisation d'un template prédéfini
  /// 
  /// Le plus simple - utilise un des templates existants
  static Widget launchJobInterviewExercise() {
    return ConfidenceBoostEntry.universalExercise('job_interview');
  }

  static Widget launchPublicSpeakingExercise() {
    return ConfidenceBoostEntry.universalExercise('public_speaking');
  }

  static Widget launchDebateExercise() {
    return ConfidenceBoostEntry.universalExercise('debate');
  }

  /// 🛠️ EXEMPLE 2: Création d'un exercice personnalisé
  /// 
  /// Pour des exercices spécifiques avec configuration custom
  static Widget createCustomNegotiationExercise() {
    const customConfig = AudioExerciseConfig(
      exerciseId: 'business_negotiation',
      title: 'Négociation commerciale',
      description: 'Maîtrisez l\'art de la négociation en contexte professionnel',
      scenario: 'negociation_commerciale',
      maxDuration: Duration(minutes: 18),
      language: 'fr',
      enableRealTimeEvaluation: true,
      enableTTS: true,
      enableSTT: true,
      customSettings: {
        'difficulty': 'expert',
        'focus_areas': ['persuasion', 'objection_handling', 'closing_techniques'],
        'evaluation_criteria': ['confidence', 'argumentation', 'adaptability'],
        'scenario_context': {
          'role': 'Vous êtes un commercial expérimenté',
          'situation': 'Négociation d\'un contrat important',
          'objectives': ['Maximiser la valeur', 'Maintenir la relation client'],
        },
      },
    );

    return ConfidenceBoostEntry.customExercise(customConfig);
  }

  /// 🚀 EXEMPLE 3: Exercice de coaching vocal
  static Widget createVoiceCoachingExercise() {
    const voiceConfig = AudioExerciseConfig(
      exerciseId: 'voice_coaching',
      title: 'Coaching vocal professionnel',
      description: 'Optimisez votre voix pour des présentations impactantes',
      scenario: 'coaching_vocal',
      maxDuration: Duration(minutes: 12),
      customSettings: {
        'difficulty': 'intermediate',
        'focus_areas': ['intonation', 'rythme', 'projection', 'articulation'],
        'voice_analysis': {
          'target_pitch_range': [120, 200], // Hz
          'target_pace': 150, // mots par minute
          'pause_detection': true,
          'emotion_analysis': true,
        },
        'feedback_type': 'real_time_vocal_coaching',
      },
    );

    return ConfidenceBoostEntry.customExercise(voiceConfig);
  }

  /// 🎭 EXEMPLE 4: Exercice de roleplay créatif
  static Widget createCreativeRoleplayExercise() {
    const roleplayConfig = AudioExerciseConfig(
      exerciseId: 'creative_roleplay',
      title: 'Roleplay créatif',
      description: 'Développez votre créativité et spontanéité orale',
      scenario: 'roleplay_creatif',
      maxDuration: Duration(minutes: 15),
      customSettings: {
        'difficulty': 'advanced',
        'roleplay_mode': true,
        'character_personas': [
          'entrepreneur_visionnaire',
          'journaliste_investigateur',
          'chef_de_projet_agile',
        ],
        'scenario_randomization': true,
        'creativity_metrics': {
          'vocabulary_diversity': true,
          'narrative_structure': true,
          'emotional_range': true,
        },
      },
    );

    return ConfidenceBoostEntry.customExercise(roleplayConfig);
  }

  /// 📱 EXEMPLE 5: Navigation complète dans une app
  /// 
  /// Comment intégrer l'API universelle dans votre navigation
  static void navigateToExercise(BuildContext context, String exerciseType) {
    Widget targetScreen;

    switch (exerciseType) {
      case 'quick_interview':
        targetScreen = ConfidenceBoostEntry.universalExercise('job_interview');
        break;
      case 'presentation_training':
        targetScreen = ConfidenceBoostEntry.universalExercise('public_speaking');
        break;
      case 'custom_negotiation':
        targetScreen = createCustomNegotiationExercise();
        break;
      case 'voice_coaching':
        targetScreen = createVoiceCoachingExercise();
        break;
      default:
        targetScreen = ConfidenceBoostEntry.universalExercise('casual_conversation');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  /// 🔧 EXEMPLE 6: API pour développeurs tiers
  /// 
  /// Structure simple pour que d'autres développeurs puissent ajouter facilement
  /// leurs propres exercices
  static Map<String, dynamic> getExerciseSchema() {
    return {
      'api_version': '1.0.0',
      'description': 'API universelle d\'exercices audio Eloquence',
      'quick_start': {
        'template_usage': 'ConfidenceBoostEntry.universalExercise("template_id")',
        'custom_usage': 'ConfidenceBoostEntry.customExercise(AudioExerciseConfig(...))',
      },
      'available_templates': [
        'job_interview',
        'public_speaking',
        'casual_conversation',
        'debate',
      ],
      'custom_config_fields': {
        'required': ['exerciseId', 'title', 'description', 'scenario'],
        'optional': ['maxDuration', 'language', 'customSettings'],
      },
      'supported_scenarios': [
        'entretien_embauche',
        'presentation_publique',
        'conversation_informelle',
        'debat_argumente',
        'negociation_commerciale',
        'coaching_vocal',
        'roleplay_creatif',
      ],
      'integration_examples': {
        'simple': 'Utiliser un template existant',
        'intermediate': 'Créer une configuration custom',
        'advanced': 'Intégrer dans votre propre navigation/architecture',
      },
    };
  }
}

/// 🎯 CLASSE HELPER POUR CRÉATION RAPIDE D'EXERCICES
/// 
/// Simplifie encore plus la création d'exercices personnalisés
class QuickExerciseBuilder {
  String _id = '';
  String _title = '';
  String _description = '';
  String _scenario = '';
  Duration _duration = const Duration(minutes: 10);
  Map<String, dynamic> _settings = {};

  QuickExerciseBuilder id(String exerciseId) {
    _id = exerciseId;
    return this;
  }

  QuickExerciseBuilder title(String exerciseTitle) {
    _title = exerciseTitle;
    return this;
  }

  QuickExerciseBuilder description(String exerciseDescription) {
    _description = exerciseDescription;
    return this;
  }

  QuickExerciseBuilder scenario(String exerciseScenario) {
    _scenario = exerciseScenario;
    return this;
  }

  QuickExerciseBuilder duration(Duration exerciseDuration) {
    _duration = exerciseDuration;
    return this;
  }

  QuickExerciseBuilder difficulty(String level) {
    _settings['difficulty'] = level;
    return this;
  }

  QuickExerciseBuilder focusAreas(List<String> areas) {
    _settings['focus_areas'] = areas;
    return this;
  }

  QuickExerciseBuilder customSetting(String key, dynamic value) {
    _settings[key] = value;
    return this;
  }

  /// Construit la configuration finale
  AudioExerciseConfig build() {
    assert(_id.isNotEmpty, 'Exercise ID is required');
    assert(_title.isNotEmpty, 'Exercise title is required');
    assert(_description.isNotEmpty, 'Exercise description is required');
    assert(_scenario.isNotEmpty, 'Exercise scenario is required');

    return AudioExerciseConfig(
      exerciseId: _id,
      title: _title,
      description: _description,
      scenario: _scenario,
      maxDuration: _duration,
      customSettings: _settings,
    );
  }

  /// Construit et lance directement l'exercice
  Widget buildAndLaunch() {
    final config = build();
    return ConfidenceBoostEntry.customExercise(config);
  }
}

/// 📖 EXEMPLE D'UTILISATION DU BUILDER
/// 
/// QuickExerciseBuilder()
///   .id('team_leadership')
///   .title('Leadership d\'équipe')
///   .description('Développez vos compétences de leader')
///   .scenario('leadership_equipe')
///   .duration(Duration(minutes: 20))
///   .difficulty('advanced')
///   .focusAreas(['motivation', 'communication', 'decision_making'])
///   .customSetting('team_size', 8)
///   .buildAndLaunch()