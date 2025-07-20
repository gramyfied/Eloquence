import 'package:logger/logger.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/ai_character_models.dart';

/// Factory pour créer et configurer les personnages IA selon le scénario
/// 
/// ✅ FONCTIONNALITÉS :
/// - Sélection intelligente du personnage selon le scénario
/// - Configuration des traits de personnalité
/// - Adaptation selon le profil utilisateur
/// - Gestion des préférences utilisateur
class AICharacterFactory {
  static const String _tag = 'AICharacterFactory';
  final Logger _logger = Logger();

  // Mapping des scénarios vers les personnages recommandés
  static const Map<ConfidenceScenarioType, AICharacterType> _defaultCharacterMapping = {
    ConfidenceScenarioType.interview: AICharacterType.thomas, // Manager pour entretiens
    ConfidenceScenarioType.presentation: AICharacterType.thomas, // Structure et logique
    ConfidenceScenarioType.meeting: AICharacterType.thomas, // Professionnel et direct
    ConfidenceScenarioType.networking: AICharacterType.marie, // Empathique et relationnelle
    ConfidenceScenarioType.pitch: AICharacterType.marie, // Persuasive et créative
  };

  // Configuration des personnalités par scénario
  static const Map<String, AICharacterConfig> _characterConfigurations = {
    'thomas_interview': AICharacterConfig(
      character: AICharacterType.thomas,
      scenarioType: ConfidenceScenarioType.interview,
      personalityTraits: [
        'Recruteur expérimenté',
        'Questions précises et pertinentes',
        'Évaluation des compétences techniques',
        'Focus sur l\'expérience et les résultats',
      ],
      conversationStyle: ConversationStyle.professional,
      challengeLevel: ChallengeLevel.high,
      feedbackStyle: FeedbackStyle.constructive,
    ),
    'thomas_presentation': AICharacterConfig(
      character: AICharacterType.thomas,
      scenarioType: ConfidenceScenarioType.presentation,
      personalityTraits: [
        'Audience exigeante',
        'Attention aux détails',
        'Valorise la structure claire',
        'Questions sur les données et preuves',
      ],
      conversationStyle: ConversationStyle.analytical,
      challengeLevel: ChallengeLevel.medium,
      feedbackStyle: FeedbackStyle.detailed,
    ),
    'marie_networking': AICharacterConfig(
      character: AICharacterType.marie,
      scenarioType: ConfidenceScenarioType.networking,
      personalityTraits: [
        'Contact professionnel ouvert',
        'Intérêt pour les synergies',
        'Questions sur les projets',
        'Recherche de collaboration',
      ],
      conversationStyle: ConversationStyle.friendly,
      challengeLevel: ChallengeLevel.low,
      feedbackStyle: FeedbackStyle.encouraging,
    ),
    'marie_pitch': AICharacterConfig(
      character: AICharacterType.marie,
      scenarioType: ConfidenceScenarioType.pitch,
      personalityTraits: [
        'Investisseur potentiel',
        'Focus sur la vision',
        'Questions sur l\'impact',
        'Intérêt pour l\'innovation',
      ],
      conversationStyle: ConversationStyle.engaging,
      challengeLevel: ChallengeLevel.medium,
      feedbackStyle: FeedbackStyle.supportive,
    ),
  };

  /// Crée un personnage IA configuré pour le scénario
  AICharacterInstance createCharacter({
    required ConfidenceScenario scenario,
    required UserAdaptiveProfile userProfile,
    AICharacterType? preferredCharacter,
  }) {
    _logger.i('🎭 [$_tag] Création personnage pour ${scenario.title}');

    // Sélectionner le personnage
    final character = preferredCharacter ?? 
                     _selectOptimalCharacter(scenario, userProfile);

    // Obtenir la configuration
    final config = _getCharacterConfig(character, scenario.type) ??
                  _createDefaultConfig(character, scenario.type);

    // Adapter selon le profil utilisateur
    final adaptedConfig = _adaptConfigToUser(config, userProfile);

    // Créer l'instance
    final instance = AICharacterInstance(
      type: character,
      config: adaptedConfig,
      scenario: scenario,
      userProfile: userProfile,
      createdAt: DateTime.now(),
    );

    _logger.i('✅ [$_tag] Personnage créé: ${character.displayName} avec style ${adaptedConfig.conversationStyle}');
    
    return instance;
  }

  /// Sélectionne le personnage optimal selon le contexte
  AICharacterType _selectOptimalCharacter(
    ConfidenceScenario scenario,
    UserAdaptiveProfile userProfile,
  ) {
    // Vérifier la préférence utilisateur
    if (userProfile.preferredCharacter != null) {
      _logger.d('[$_tag] Utilisation préférence utilisateur: ${userProfile.preferredCharacter}');
      return userProfile.preferredCharacter;
    }

    // Adapter selon le niveau de confiance
    if (userProfile.confidenceLevel <= 3) {
      // Utilisateur peu confiant → Marie plus empathique
      _logger.d('[$_tag] Niveau confiance faible → Marie sélectionnée');
      return AICharacterType.marie;
    } else if (userProfile.confidenceLevel >= 8 && 
               scenario.difficulty != 'Débutant') {
      // Utilisateur très confiant + scénario non-débutant → Thomas challengeant
      _logger.d('[$_tag] Niveau confiance élevé → Thomas sélectionné');
      return AICharacterType.thomas;
    }

    // Utiliser le mapping par défaut
    final defaultCharacter = _defaultCharacterMapping[scenario.type] ?? 
                           AICharacterType.marie;
    _logger.d('[$_tag] Mapping par défaut → ${defaultCharacter.displayName}');
    
    return defaultCharacter;
  }

  /// Obtient la configuration pour un personnage et scénario
  AICharacterConfig? _getCharacterConfig(
    AICharacterType character,
    ConfidenceScenarioType scenarioType,
  ) {
    final key = '${character.name}_${scenarioType.name}';
    return _characterConfigurations[key];
  }

  /// Crée une configuration par défaut
  AICharacterConfig _createDefaultConfig(
    AICharacterType character,
    ConfidenceScenarioType scenarioType,
  ) {
    return AICharacterConfig(
      character: character,
      scenarioType: scenarioType,
      personalityTraits: _getDefaultTraits(character),
      conversationStyle: character == AICharacterType.thomas 
          ? ConversationStyle.professional 
          : ConversationStyle.friendly,
      challengeLevel: ChallengeLevel.medium,
      feedbackStyle: character == AICharacterType.thomas
          ? FeedbackStyle.constructive
          : FeedbackStyle.encouraging,
    );
  }

  /// Traits par défaut selon le personnage
  List<String> _getDefaultTraits(AICharacterType character) {
    switch (character) {
      case AICharacterType.thomas:
        return [
          'Professionnel et structuré',
          'Focus sur les résultats',
          'Questions précises',
          'Feedback constructif',
        ];
      case AICharacterType.marie:
        return [
          'Empathique et bienveillante',
          'Focus sur la relation',
          'Questions ouvertes',
          'Encouragements positifs',
        ];
    }
  }

  /// Adapte la configuration selon le profil utilisateur
  AICharacterConfig _adaptConfigToUser(
    AICharacterConfig baseConfig,
    UserAdaptiveProfile userProfile,
  ) {
    // Adapter le niveau de challenge
    ChallengeLevel adaptedChallenge = baseConfig.challengeLevel;
    
    if (userProfile.confidenceLevel <= 3) {
      // Réduire le challenge pour les utilisateurs peu confiants
      adaptedChallenge = ChallengeLevel.low;
    } else if (userProfile.confidenceLevel >= 8 && 
               userProfile.experienceLevel >= 7) {
      // Augmenter le challenge pour les utilisateurs expérimentés
      adaptedChallenge = ChallengeLevel.high;
    }

    // Adapter le style de feedback
    FeedbackStyle adaptedFeedback = baseConfig.feedbackStyle;
    
    if (userProfile.weaknesses.contains('confiance')) {
      adaptedFeedback = FeedbackStyle.encouraging;
    } else if (userProfile.strengths.contains('leadership')) {
      adaptedFeedback = FeedbackStyle.challenging;
    }

    // Créer la configuration adaptée
    return AICharacterConfig(
      character: baseConfig.character,
      scenarioType: baseConfig.scenarioType,
      personalityTraits: _adaptTraits(baseConfig.personalityTraits, userProfile),
      conversationStyle: baseConfig.conversationStyle,
      challengeLevel: adaptedChallenge,
      feedbackStyle: adaptedFeedback,
    );
  }

  /// Adapte les traits de personnalité
  List<String> _adaptTraits(
    List<String> baseTraits,
    UserAdaptiveProfile userProfile,
  ) {
    final adaptedTraits = [...baseTraits];

    // Ajouter des traits basés sur les faiblesses de l'utilisateur
    if (userProfile.weaknesses.contains('structure')) {
      adaptedTraits.add('Guide sur la structuration');
    }
    if (userProfile.weaknesses.contains('clarté')) {
      adaptedTraits.add('Aide à clarifier les idées');
    }

    // Ajouter des traits basés sur les forces
    if (userProfile.strengths.contains('créativité')) {
      adaptedTraits.add('Valorise l\'originalité');
    }

    return adaptedTraits;
  }
}

/// Configuration d'un personnage IA
class AICharacterConfig {
  final AICharacterType character;
  final ConfidenceScenarioType scenarioType;
  final List<String> personalityTraits;
  final ConversationStyle conversationStyle;
  final ChallengeLevel challengeLevel;
  final FeedbackStyle feedbackStyle;

  const AICharacterConfig({
    required this.character,
    required this.scenarioType,
    required this.personalityTraits,
    required this.conversationStyle,
    required this.challengeLevel,
    required this.feedbackStyle,
  });
}

/// Instance d'un personnage IA
class AICharacterInstance {
  final AICharacterType type;
  final AICharacterConfig config;
  final ConfidenceScenario scenario;
  final UserAdaptiveProfile userProfile;
  final DateTime createdAt;

  AICharacterInstance({
    required this.type,
    required this.config,
    required this.scenario,
    required this.userProfile,
    required this.createdAt,
  });

  /// Obtient le prompt système pour ce personnage
  String getSystemPrompt() {
    final traits = config.personalityTraits.join('\n- ');
    final style = _getStyleDescription();
    final challenge = _getChallengeDescription();

    return '''Tu es ${type.displayName}, ${type.description}.

Traits de personnalité:
- $traits

Style de conversation: $style
Niveau de challenge: $challenge

Contexte: ${scenario.title}
Description: ${scenario.description}

Instructions:
1. Reste toujours dans ton rôle
2. Adapte ton niveau selon l'utilisateur (confiance: ${userProfile.confidenceLevel}/10)
3. Utilise le style de feedback ${config.feedbackStyle.name}
4. Pose des questions pertinentes pour le scénario
5. Guide l'utilisateur vers l'amélioration

Réponds toujours en français.''';
  }

  String _getStyleDescription() {
    switch (config.conversationStyle) {
      case ConversationStyle.professional:
        return 'Professionnel, direct et structuré';
      case ConversationStyle.analytical:
        return 'Analytique, précis et factuel';
      case ConversationStyle.friendly:
        return 'Amical, ouvert et accessible';
      case ConversationStyle.engaging:
        return 'Engageant, dynamique et inspirant';
    }
  }

  String _getChallengeDescription() {
    switch (config.challengeLevel) {
      case ChallengeLevel.low:
        return 'Doux - Questions simples et encouragements fréquents';
      case ChallengeLevel.medium:
        return 'Modéré - Équilibre entre challenge et soutien';
      case ChallengeLevel.high:
        return 'Élevé - Questions pointues et attentes élevées';
    }
  }
}

/// Styles de conversation
enum ConversationStyle {
  professional,
  analytical,
  friendly,
  engaging,
}

/// Niveaux de challenge
enum ChallengeLevel {
  low,
  medium,
  high,
}

/// Styles de feedback
enum FeedbackStyle {
  encouraging,
  constructive,
  detailed,
  supportive,
  challenging,
}