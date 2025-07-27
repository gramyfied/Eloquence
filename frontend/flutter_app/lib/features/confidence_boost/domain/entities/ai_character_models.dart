import 'confidence_scenario.dart';

/// Moteur IA sophistiqué pour personnages adaptatifs Thomas et Marie
/// 
/// ✅ FONCTIONNALITÉS AVANCÉES :
/// - Analyse contextuelle dynamique du scénario
/// - Personnalisation selon profil utilisateur
/// - Évolution pendant la session d'entraînement
/// - Coaching contextuel en temps réel
/// - Recommandations adaptatives intelligentes

// Enum pour les types de personnages IA
enum AICharacterType {
  thomas, // Manager expérimenté, coaching professionnel
  marie,  // Cliente experte, perspective utilisateur
}

// Enum pour les états émotionnels des personnages
enum AIEmotionalState {
  encouraging,    // Encourageant, supportif
  analytical,     // Analytique, détaillé
  challenging,    // Défiant, pousse à l'excellence
  empathetic,     // Empathique, compréhensif
  confident,      // Confiant, assuré
}

// Enum pour les phases d'intervention IA
enum AIInterventionPhase {
  scenarioIntroduction,  // Introduction du scénario
  supportSelection,      // Aide à la sélection du support
  preparationCoaching,   // Coaching de préparation
  realTimeGuidance,      // Guidage en temps réel
  performanceAnalysis,   // Analyse de performance
  improvementPlanning,   // Planification d'améliorations
}

// Modèle pour le profil utilisateur adaptatif
class UserAdaptiveProfile {
  final String userId;
  final int confidenceLevel;        // 1-10
  final int experienceLevel;        // 1-10
  final List<String> strengths;     // Points forts identifiés
  final List<String> weaknesses;    // Points à améliorer
  final List<String> preferredTopics; // Sujets préférés
  final AICharacterType preferredCharacter; // Personnage préféré
  final DateTime lastSessionDate;
  final int totalSessions;
  final double averageScore;

  UserAdaptiveProfile({
    required this.userId,
    required this.confidenceLevel,
    required this.experienceLevel,
    required this.strengths,
    required this.weaknesses,
    required this.preferredTopics,
    required this.preferredCharacter,
    required this.lastSessionDate,
    required this.totalSessions,
    required this.averageScore,
  });
}

// Modèle pour le contexte de session
class SessionContext {
  final ConfidenceScenario scenario;
  final UserAdaptiveProfile userProfile;
  final AIInterventionPhase currentPhase;
  final Duration sessionDuration;
  final int attemptsCount;
  final List<String> previousFeedback;
  final Map<String, double> currentMetrics; // Métriques temps réel

  SessionContext({
    required this.scenario,
    required this.userProfile,
    required this.currentPhase,
    required this.sessionDuration,
    required this.attemptsCount,
    required this.previousFeedback,
    required this.currentMetrics,
  });
}

// Modèle pour les dialogues adaptatifs
class AdaptiveDialogue {
  final AICharacterType speaker;
  final String message;
  final AIEmotionalState emotionalState;
  final AIInterventionPhase phase;
  final int priorityLevel;          // 1-10, pour l'ordre d'affichage
  final List<String> triggers;      // Conditions d'activation
  final Map<String, String> personalizedVariables; // Variables personnalisées
  final Duration displayDuration;
  final bool requiresUserResponse;

  AdaptiveDialogue({
    required this.speaker,
    required this.message,
    required this.emotionalState,
    required this.phase,
    required this.priorityLevel,
    required this.triggers,
    required this.personalizedVariables,
    required this.displayDuration,
    required this.requiresUserResponse,
  });

  /// Personnalise le message avec les variables contextuelles
  String getPersonalizedMessage(SessionContext context) {
    String personalizedMessage = message;
    
    // Remplacer les variables dynamiques
    personalizedVariables.forEach((key, value) {
      personalizedMessage = personalizedMessage.replaceAll('{$key}', value);
    });
    
    // Variables contextuelles automatiques
    personalizedMessage = personalizedMessage.replaceAll(
      '{userName}', context.userProfile.userId
    );
    personalizedMessage = personalizedMessage.replaceAll(
      '{scenarioTitle}', context.scenario.title
    );
    personalizedMessage = personalizedMessage.replaceAll(
      '{confidenceLevel}', context.userProfile.confidenceLevel.toString()
    );
    
    return personalizedMessage;
  }
}

/// Modèle pour la réponse de l'IA
class AIResponse {
  final String text;
  final double confidenceScore;
  final String feedback;
  final String? audioUrl;

  AIResponse({
    required this.text,
    required this.confidenceScore,
    required this.feedback,
    this.audioUrl,
  });
}

// Modèle pour les recommandations IA
class AIRecommendation {
  final String title;
  final String description;
  final AICharacterType recommender;
  final int impactScore;           // 1-10, impact estimé
  final int difficultyLevel;       // 1-10, difficulté
  final List<String> actionSteps;  // Étapes concrètes
  final List<String> relatedSkills; // Compétences associées
  final Duration estimatedTime;    // Temps estimé pour appliquer
  final bool isPersonalized;       // Recommandation personnalisée

  AIRecommendation({
    required this.title,
    required this.description,
    required this.recommender,
    required this.impactScore,
    required this.difficultyLevel,
    required this.actionSteps,
    required this.relatedSkills,
    required this.estimatedTime,
    required this.isPersonalized,
  });
}

// Modèle pour l'analyse comportementale IA
class BehavioralAnalysis {
  final DateTime analysisDate;
  final Map<String, double> behaviorPatterns; // Patterns identifiés
  final List<String> progressIndicators;      // Indicateurs de progrès
  final List<String> regressionWarnings;      // Alertes de régression
  final double adaptationScore;               // Score d'adaptation IA
  final List<AIRecommendation> recommendations; // Recommandations personnalisées

  BehavioralAnalysis({
    required this.analysisDate,
    required this.behaviorPatterns,
    required this.progressIndicators,
    required this.regressionWarnings,
    required this.adaptationScore,
    required this.recommendations,
  });
}

// Extensions pour les énumérations
extension AICharacterTypeExtension on AICharacterType {
  String get displayName {
    switch (this) {
      case AICharacterType.thomas:
        return 'Thomas';
      case AICharacterType.marie:
        return 'Marie';
    }
  }

  String get description {
    switch (this) {
      case AICharacterType.thomas:
        return 'Manager expérimenté, expert en coaching professionnel';
      case AICharacterType.marie:
        return 'Cliente experte, apporte la perspective utilisateur';
    }
  }

  String get expertise {
    switch (this) {
      case AICharacterType.thomas:
        return 'Leadership, présentation, management d\'équipe';
      case AICharacterType.marie:
        return 'Communication client, négociation, relation commerciale';
    }
  }

  List<String> get specialties {
    switch (this) {
      case AICharacterType.thomas:
        return [
          'Structuration du discours',
          'Gestion du stress',
          'Présence et autorité',
          'Argumentation logique',
        ];
      case AICharacterType.marie:
        return [
          'Empathie et écoute',
          'Adaptation au public',
          'Storytelling',
          'Gestion des objections',
        ];
    }
  }
}

extension AIEmotionalStateExtension on AIEmotionalState {
  String get displayName {
    switch (this) {
      case AIEmotionalState.encouraging:
        return 'Encourageant';
      case AIEmotionalState.analytical:
        return 'Analytique';
      case AIEmotionalState.challenging:
        return 'Défiant';
      case AIEmotionalState.empathetic:
        return 'Empathique';
      case AIEmotionalState.confident:
        return 'Confiant';
    }
  }

  String get emoji {
    switch (this) {
      case AIEmotionalState.encouraging:
        return '😊';
      case AIEmotionalState.analytical:
        return '🤔';
      case AIEmotionalState.challenging:
        return '💪';
      case AIEmotionalState.empathetic:
        return '🤗';
      case AIEmotionalState.confident:
        return '😎';
    }
  }
}

extension AIInterventionPhaseExtension on AIInterventionPhase {
  String get displayName {
    switch (this) {
      case AIInterventionPhase.scenarioIntroduction:
        return 'Introduction du scénario';
      case AIInterventionPhase.supportSelection:
        return 'Sélection du support';
      case AIInterventionPhase.preparationCoaching:
        return 'Coaching de préparation';
      case AIInterventionPhase.realTimeGuidance:
        return 'Guidage temps réel';
      case AIInterventionPhase.performanceAnalysis:
        return 'Analyse de performance';
      case AIInterventionPhase.improvementPlanning:
        return 'Planification d\'améliorations';
    }
  }
}
