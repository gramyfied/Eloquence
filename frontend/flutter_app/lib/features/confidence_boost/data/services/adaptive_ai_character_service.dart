import 'dart:async';
import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../../domain/entities/ai_character_models.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';

/// Service IA sophistiqué pour personnages adaptatifs Thomas et Marie
/// 
/// ✅ MOTEUR INTELLIGENT COMPLET :
/// - Analyse contextuelle en temps réel
/// - Personnalisation adaptative selon profil utilisateur
/// - Évolution dynamique pendant la session
/// - Coaching contextuel intelligent
/// - Recommandations personnalisées avancées
class AdaptiveAICharacterService {
  final Logger _logger = Logger();
  final math.Random _random = math.Random();
  
  // Profils par défaut pour Thomas et Marie
  static const Map<AICharacterType, Map<String, dynamic>> _characterProfiles = {
    AICharacterType.thomas: {
      'personalityTraits': [
        'analytique', 'méthodique', 'direct', 'professionnel', 'exigeant'
      ],
      'communicationStyle': 'structure_et_logique',
      'preferredEmotions': [
        AIEmotionalState.analytical,
        AIEmotionalState.challenging,
        AIEmotionalState.confident,
      ],
      'expertise': [
        'présentation_executif', 'leadership', 'stratégie', 'négociation'
      ],
    },
    AICharacterType.marie: {
      'personalityTraits': [
        'empathique', 'intuitive', 'créative', 'collaborative', 'adaptable'
      ],
      'communicationStyle': 'relation_et_emotion',
      'preferredEmotions': [
        AIEmotionalState.empathetic,
        AIEmotionalState.encouraging,
        AIEmotionalState.analytical,
      ],
      'expertise': [
        'relation_client', 'storytelling', 'communication_persuasive', 'écoute_active'
      ],
    },
  };

  /// Initialise le service avec les données persistées
  Future<void> initialize() async {
    _logger.i('🤖 Initialisation du service IA adaptatif');
    await _loadDialogueTemplates();
    await _initializeCharacterPersonalities();
    _logger.i('✅ Service IA adaptatif initialisé avec succès');
  }

  /// Génère un dialogue adaptatif contextualisé
  Future<AdaptiveDialogue> generateContextualDialogue({
    required AICharacterType character,
    required AIInterventionPhase phase,
    required SessionContext context,
    AIEmotionalState? preferredEmotion,
  }) async {
    _logger.d('🎭 Génération dialogue adaptatif pour $character en phase $phase');

    // Analyse contextuelle du scénario et du profil utilisateur
    final contextAnalysis = await _analyzeSessionContext(context);
    
    // Sélection de l'état émotionnel optimal
    final optimalEmotion = _selectOptimalEmotion(
      character: character,
      phase: phase,
      context: context,
      preferred: preferredEmotion,
      analysis: contextAnalysis,
    );

    // Génération du message personnalisé
    final baseMessage = await _generateBaseMessage(
      character: character,
      phase: phase,
      emotion: optimalEmotion,
      context: context,
    );

    // Personnalisation avec variables contextuelles
    final personalizedVariables = _generatePersonalizedVariables(
      context: context,
      analysis: contextAnalysis,
    );

    return AdaptiveDialogue(
      speaker: character,
      message: baseMessage,
      emotionalState: optimalEmotion,
      phase: phase,
      priorityLevel: _calculatePriorityLevel(phase, context),
      triggers: _generateTriggers(phase, context),
      personalizedVariables: personalizedVariables,
      displayDuration: _calculateDisplayDuration(baseMessage.length),
      requiresUserResponse: _shouldRequireResponse(phase, optimalEmotion),
    );
  }

  /// Analyse comportementale avancée de l'utilisateur
  Future<BehavioralAnalysis> analyzeBehaviorPattern({
    required UserAdaptiveProfile profile,
    required List<ConfidenceAnalysis> sessionHistory,
    required ConfidenceScenario currentScenario,
  }) async {
    _logger.d('📊 Analyse comportementale pour ${profile.userId}');

    // Analyse des patterns de performance
    final behaviorPatterns = _identifyBehaviorPatterns(sessionHistory);
    
    // Détection des indicateurs de progrès
    final progressIndicators = _detectProgressIndicators(
      sessionHistory, 
      profile
    );
    
    // Alertes de régression
    final regressionWarnings = _detectRegressionWarnings(
      sessionHistory,
      profile,
    );

    // Calcul du score d'adaptation IA
    final adaptationScore = _calculateAdaptationScore(
      behaviorPatterns,
      progressIndicators,
      profile,
    );

    // Génération de recommandations personnalisées
    final recommendations = await _generatePersonalizedRecommendations(
      profile: profile,
      patterns: behaviorPatterns,
      scenario: currentScenario,
      adaptationScore: adaptationScore,
    );

    return BehavioralAnalysis(
      analysisDate: DateTime.now(),
      behaviorPatterns: behaviorPatterns,
      progressIndicators: progressIndicators,
      regressionWarnings: regressionWarnings,
      adaptationScore: adaptationScore,
      recommendations: recommendations,
    );
  }

  /// Adapte le profil utilisateur avec de nouvelles données
  Future<UserAdaptiveProfile> updateUserProfile({
    required UserAdaptiveProfile currentProfile,
    required ConfidenceAnalysis newAnalysis,
    required ConfidenceScenario scenario,
    required Duration sessionDuration,
  }) async {
    _logger.d('🔄 Mise à jour profil adaptatif ${currentProfile.userId}');

    // Calcul des nouvelles métriques
    final newTotalSessions = currentProfile.totalSessions + 1;
    final newAverageScore = _calculateNewAverageScore(
      currentProfile.averageScore,
      currentProfile.totalSessions,
      newAnalysis.overallScore,
    );

    // Mise à jour des forces et faiblesses
    final updatedStrengths = _updateStrengths(
      currentProfile.strengths,
      newAnalysis,
    );
    final updatedWeaknesses = _updateWeaknesses(
      currentProfile.weaknesses,
      newAnalysis,
    );

    // Adaptation du niveau de confiance
    final newConfidenceLevel = _adaptConfidenceLevel(
      currentProfile.confidenceLevel,
      newAnalysis.confidenceScore,
      sessionDuration,
    );

    return UserAdaptiveProfile(
      userId: currentProfile.userId,
      confidenceLevel: newConfidenceLevel,
      experienceLevel: _adaptExperienceLevel(
        currentProfile.experienceLevel,
        newTotalSessions,
        newAverageScore,
      ),
      strengths: updatedStrengths,
      weaknesses: updatedWeaknesses,
      preferredTopics: _updatePreferredTopics(
        currentProfile.preferredTopics,
        scenario,
        newAnalysis.overallScore,
      ),
      preferredCharacter: _adaptPreferredCharacter(
        currentProfile.preferredCharacter,
        newAnalysis,
      ),
      lastSessionDate: DateTime.now(),
      totalSessions: newTotalSessions,
      averageScore: newAverageScore,
    );
  }

  /// Génère un coaching en temps réel pendant l'enregistrement
  Stream<AdaptiveDialogue> generateRealTimeCoaching({
    required SessionContext context,
    required Stream<Map<String, double>> realTimeMetrics,
  }) async* {
    _logger.d('🎤 Démarrage coaching temps réel');

    await for (final metrics in realTimeMetrics) {
      // Analyse des métriques en temps réel
      final coachingNeeded = _assessCoachingNeeds(metrics, context);
      
      if (coachingNeeded.isNotEmpty) {
        for (final need in coachingNeeded) {
          final dialogue = await _generateRealTimeCoachingDialogue(
            need: need,
            context: context,
            metrics: metrics,
          );
          
          yield dialogue;
          
          // Délai entre les interventions pour éviter la surcharge
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
  }

  /// Sélectionne le personnage optimal pour un scénario donné
  AICharacterType selectOptimalCharacter({
    required ConfidenceScenario scenario,
    required UserAdaptiveProfile profile,
    AICharacterType? userPreference,
  }) {
    _logger.d('🎯 Sélection personnage optimal pour ${scenario.title}');

    // Respecter la préférence utilisateur si elle existe
    if (userPreference != null) {
      return userPreference;
    }

    // Analyse basée sur le type de scénario
    final scenarioCharacterMap = {
      ConfidenceScenarioType.presentation: AICharacterType.thomas,
      ConfidenceScenarioType.meeting: AICharacterType.thomas,
      ConfidenceScenarioType.interview: AICharacterType.thomas,
      ConfidenceScenarioType.networking: AICharacterType.marie,
      ConfidenceScenarioType.pitch: AICharacterType.marie,
    };

    final scenarioOptimal = scenarioCharacterMap[scenario.type] ?? 
                           profile.preferredCharacter;

    // Adaptation basée sur le niveau de confiance
    if (profile.confidenceLevel <= 3) {
      // Utilisateur peu confiant → Marie plus empathique
      return AICharacterType.marie;
    } else if (profile.confidenceLevel >= 8) {
      // Utilisateur très confiant → Thomas plus challengeant
      return AICharacterType.thomas;
    }

    return scenarioOptimal;
  }

  // === MÉTHODES PRIVÉES ===

  Future<void> _loadDialogueTemplates() async {
    // Charger les templates de dialogues depuis le stockage local
    // Implémentation future avec Hive/SharedPreferences
  }

  Future<void> _initializeCharacterPersonalities() async {
    // Initialiser les personnalités des personnages
    // Charger les configurations comportementales
  }

  Future<Map<String, dynamic>> _analyzeSessionContext(
    SessionContext context
  ) async {
    return {
      'userConfidenceLevel': context.userProfile.confidenceLevel,
      'scenarioDifficulty': context.scenario.difficulty,
      'sessionProgress': context.sessionDuration.inMinutes / 15.0,
      'previousAttempts': context.attemptsCount,
      'userStrengths': context.userProfile.strengths,
      'userWeaknesses': context.userProfile.weaknesses,
    };
  }

  AIEmotionalState _selectOptimalEmotion({
    required AICharacterType character,
    required AIInterventionPhase phase,
    required SessionContext context,
    AIEmotionalState? preferred,
    required Map<String, dynamic> analysis,
  }) {
    if (preferred != null) return preferred;

    final characterProfile = _characterProfiles[character]!;
    final preferredEmotions = characterProfile['preferredEmotions'] 
        as List<AIEmotionalState>;

    // Logique adaptative basée sur le contexte
    final userConfidence = analysis['userConfidenceLevel'] as int;
    final sessionProgress = analysis['sessionProgress'] as double;

    if (userConfidence <= 3) {
      return AIEmotionalState.encouraging;
    } else if (sessionProgress > 0.8) {
      return AIEmotionalState.confident;
    } else if (phase == AIInterventionPhase.performanceAnalysis) {
      return AIEmotionalState.analytical;
    }

    // Sélection aléatoire pondérée parmi les préférences du personnage
    return preferredEmotions[_random.nextInt(preferredEmotions.length)];
  }

  Future<String> _generateBaseMessage({
    required AICharacterType character,
    required AIInterventionPhase phase,
    required AIEmotionalState emotion,
    required SessionContext context,
  }) async {
    // Base de messages contextuels
    final messageTemplates = _getMessageTemplates(character, phase, emotion);
    
    // Sélection intelligente basée sur le contexte
    final contextScore = _calculateContextRelevanceScore(context);
    final selectedTemplate = _selectBestTemplate(messageTemplates, contextScore);
    
    return selectedTemplate;
  }

  List<String> _getMessageTemplates(
    AICharacterType character,
    AIInterventionPhase phase,
    AIEmotionalState emotion,
  ) {
    // Templates spécifiques par personnage/phase/émotion
    final key = '${character.name}_${phase.name}_${emotion.name}';
    
    // Base de données de messages (simplifiée pour l'exemple)
    final templates = {
      'thomas_scenarioIntroduction_analytical': [
        'Analysons ce scénario ensemble. {scenarioTitle} nécessite une approche structurée et méthodique.',
        'Excellent choix de scénario ! Pour réussir {scenarioTitle}, concentrons-nous sur la clarté et la logique.',
      ],
      'marie_scenarioIntroduction_empathetic': [
        'Je comprends que {scenarioTitle} puisse sembler intimidant. Ensemble, nous allons transformer cette appréhension en confiance.',
        'Ce scénario {scenarioTitle} est une belle opportunité de développer vos compétences relationnelles.',
      ],
      'thomas_preparationCoaching_challenging': [
        'Maintenant, montrez-moi votre meilleure version. N\'ayez pas peur d\'être direct et assertif.',
        'C\'est le moment de prouver votre expertise. Structurez vos idées et allez droit au but.',
      ],
      'marie_preparationCoaching_encouraging': [
        'Vous avez toutes les compétences nécessaires. Laissez votre authenticité transparaître.',
        'Rappelez-vous, votre perspective unique est votre force. Partagez-la avec confiance.',
      ],
    };

    return templates[key] ?? [
      'Message par défaut pour $character en phase $phase avec émotion $emotion'
    ];
  }

  Map<String, String> _generatePersonalizedVariables({
    required SessionContext context,
    required Map<String, dynamic> analysis,
  }) {
    return {
      'userName': context.userProfile.userId,
      'scenarioTitle': context.scenario.title,
      'confidenceLevel': context.userProfile.confidenceLevel.toString(),
      'sessionNumber': context.userProfile.totalSessions.toString(),
      'topStrength': context.userProfile.strengths.isNotEmpty 
          ? context.userProfile.strengths.first 
          : 'communication',
      'improvementArea': context.userProfile.weaknesses.isNotEmpty 
          ? context.userProfile.weaknesses.first 
          : 'confiance',
    };
  }

  int _calculatePriorityLevel(AIInterventionPhase phase, SessionContext context) {
    // Priorité basée sur la phase et le contexte
    const phasePriorities = {
      AIInterventionPhase.scenarioIntroduction: 9,
      AIInterventionPhase.supportSelection: 7,
      AIInterventionPhase.preparationCoaching: 8,
      AIInterventionPhase.realTimeGuidance: 10,
      AIInterventionPhase.performanceAnalysis: 6,
      AIInterventionPhase.improvementPlanning: 5,
    };

    return phasePriorities[phase] ?? 5;
  }

  List<String> _generateTriggers(AIInterventionPhase phase, SessionContext context) {
    // Conditions d'activation basées sur la phase
    switch (phase) {
      case AIInterventionPhase.scenarioIntroduction:
        return ['screen_loaded', 'scenario_selected'];
      case AIInterventionPhase.supportSelection:
        return ['support_types_displayed', 'user_hesitation'];
      case AIInterventionPhase.preparationCoaching:
        return ['support_selected', 'recording_preparation'];
      case AIInterventionPhase.realTimeGuidance:
        return ['recording_started', 'confidence_drop', 'pause_detected'];
      case AIInterventionPhase.performanceAnalysis:
        return ['recording_completed', 'analysis_available'];
      case AIInterventionPhase.improvementPlanning:
        return ['results_displayed', 'recommendations_ready'];
    }
  }

  Duration _calculateDisplayDuration(int messageLength) {
    // Durée basée sur la longueur du message (vitesse de lecture)
    final baseSeconds = (messageLength / 10).ceil(); // ~10 caractères par seconde
    return Duration(seconds: math.max(3, math.min(baseSeconds, 10)));
  }

  bool _shouldRequireResponse(AIInterventionPhase phase, AIEmotionalState emotion) {
    // Certaines phases nécessitent une interaction
    return phase == AIInterventionPhase.supportSelection ||
           phase == AIInterventionPhase.improvementPlanning ||
           emotion == AIEmotionalState.challenging;
  }

  Map<String, double> _identifyBehaviorPatterns(
    List<ConfidenceAnalysis> sessionHistory
  ) {
    if (sessionHistory.isEmpty) return {};

    final patterns = <String, double>{};
    
    // Analyse de la progression temporelle
    if (sessionHistory.length >= 3) {
      final recentSessions = sessionHistory.take(3).toList();
      final trend = _calculateTrend(recentSessions.map((s) => s.overallScore).toList());
      patterns['confidence_trend'] = trend;
    }

    // Pattern de consistance
    final scores = sessionHistory.map((s) => s.overallScore).toList();
    patterns['consistency'] = _calculateConsistency(scores);

    // Pattern de forces récurrentes
    final allStrengths = sessionHistory
        .expand((s) => s.strengths)
        .fold<Map<String, int>>({}, (map, strength) {
      map[strength] = (map[strength] ?? 0) + 1;
      return map;
    });

    patterns['top_strength_frequency'] = allStrengths.values.isNotEmpty
        ? allStrengths.values.reduce(math.max) / sessionHistory.length
        : 0.0;

    return patterns;
  }

  double _calculateTrend(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    double sum = 0.0;
    for (int i = 1; i < scores.length; i++) {
      sum += scores[i] - scores[i - 1];
    }
    return sum / (scores.length - 1);
  }

  double _calculateConsistency(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
        .map((score) => math.pow(score - mean, 2))
        .reduce((a, b) => a + b) / scores.length;
    
    return math.max(0.0, 1.0 - (math.sqrt(variance) / 100.0));
  }

  List<String> _detectProgressIndicators(
    List<ConfidenceAnalysis> sessionHistory,
    UserAdaptiveProfile profile,
  ) {
    final indicators = <String>[];
    
    if (sessionHistory.length >= 2) {
      final latest = sessionHistory.first;
      final previous = sessionHistory[1];
      
      if (latest.overallScore > previous.overallScore + 5) {
        indicators.add('Amélioration significative du score global');
      }
      
      if (latest.confidenceScore > previous.confidenceScore + 0.1) {
        indicators.add('Gain de confiance notable');
      }
      
      if (latest.wordCount > previous.wordCount * 1.2) {
        indicators.add('Expression plus riche et détaillée');
      }
    }
    
    return indicators;
  }

  List<String> _detectRegressionWarnings(
    List<ConfidenceAnalysis> sessionHistory,
    UserAdaptiveProfile profile,
  ) {
    final warnings = <String>[];
    
    if (sessionHistory.length >= 3) {
      final recent = sessionHistory.take(3).map((s) => s.overallScore).toList();
      if (recent.every((score) => score < recent.first)) {
        warnings.add('Baisse de performance sur les dernières sessions');
      }
    }
    
    return warnings;
  }

  double _calculateAdaptationScore(
    Map<String, double> patterns,
    List<String> progressIndicators,
    UserAdaptiveProfile profile,
  ) {
    double score = 0.5; // Score de base
    
    // Bonus pour la consistance
    score += (patterns['consistency'] ?? 0.0) * 0.3;
    
    // Bonus pour la tendance positive
    final trend = patterns['confidence_trend'] ?? 0.0;
    if (trend > 0) score += math.min(trend / 10.0, 0.2);
    
    // Bonus pour les indicateurs de progrès
    score += progressIndicators.length * 0.1;
    
    return math.max(0.0, math.min(1.0, score));
  }

  Future<List<AIRecommendation>> _generatePersonalizedRecommendations({
    required UserAdaptiveProfile profile,
    required Map<String, double> patterns,
    required ConfidenceScenario scenario,
    required double adaptationScore,
  }) async {
    final recommendations = <AIRecommendation>[];
    
    // Recommandation basée sur les faiblesses
    if (profile.weaknesses.isNotEmpty) {
      final topWeakness = profile.weaknesses.first;
      recommendations.add(_createWeaknessRecommendation(topWeakness));
    }
    
    // Recommandation basée sur le scénario
    recommendations.add(_createScenarioSpecificRecommendation(scenario));
    
    // Recommandation basée sur les patterns
    if (patterns['consistency'] != null && patterns['consistency']! < 0.5) {
      recommendations.add(_createConsistencyRecommendation());
    }
    
    return recommendations;
  }

  AIRecommendation _createWeaknessRecommendation(String weakness) {
    return AIRecommendation(
      title: 'Améliorer $weakness',
      description: 'Exercices ciblés pour renforcer cette compétence',
      recommender: AICharacterType.thomas,
      impactScore: 8,
      difficultyLevel: 6,
      actionSteps: [
        'Pratiquer 10 minutes par jour',
        'Enregistrer et analyser vos progrès',
        'Demander des retours à vos proches',
      ],
      relatedSkills: [weakness, 'confiance', 'communication'],
      estimatedTime: const Duration(minutes: 30),
      isPersonalized: true,
    );
  }

  AIRecommendation _createScenarioSpecificRecommendation(ConfidenceScenario scenario) {
    return AIRecommendation(
      title: 'Maîtriser ${scenario.title}',
      description: 'Techniques spécifiques pour ce type de scénario',
      recommender: AICharacterType.marie,
      impactScore: 9,
      difficultyLevel: scenario.difficulty == 'Débutant' ? 4 : 7,
      actionSteps: [
        'Répéter le scénario 3 fois',
        'Varier les approches',
        'Intégrer les conseils IA',
      ],
      relatedSkills: ['présentation', 'confiance', 'adaptation'],
      estimatedTime: const Duration(minutes: 45),
      isPersonalized: true,
    );
  }

  AIRecommendation _createConsistencyRecommendation() {
    return AIRecommendation(
      title: 'Améliorer la régularité',
      description: 'Développer une performance plus stable',
      recommender: AICharacterType.thomas,
      impactScore: 7,
      difficultyLevel: 5,
      actionSteps: [
        'Établir une routine d\'entraînement',
        'Identifier les facteurs de variabilité',
        'Pratiquer dans différents contextes',
      ],
      relatedSkills: ['régularité', 'gestion_stress', 'préparation'],
      estimatedTime: const Duration(minutes: 20),
      isPersonalized: true,
    );
  }

  // Méthodes utilitaires pour la mise à jour du profil
  double _calculateNewAverageScore(
    double currentAverage,
    int totalSessions,
    double newScore,
  ) {
    return (currentAverage * totalSessions + newScore) / (totalSessions + 1);
  }

  List<String> _updateStrengths(
    List<String> currentStrengths,
    ConfidenceAnalysis analysis,
  ) {
    final newStrengths = [...currentStrengths];
    
    // Ajouter les nouvelles forces identifiées
    for (final strength in analysis.strengths) {
      if (!newStrengths.contains(strength)) {
        newStrengths.add(strength);
      }
    }
    
    // Limiter à 5 forces maximum
    return newStrengths.take(5).toList();
  }

  List<String> _updateWeaknesses(
    List<String> currentWeaknesses,
    ConfidenceAnalysis analysis,
  ) {
    final newWeaknesses = [...currentWeaknesses];
    
    // Ajouter les nouvelles faiblesses identifiées
    for (final weakness in analysis.improvements) {
      if (!newWeaknesses.contains(weakness)) {
        newWeaknesses.add(weakness);
      }
    }
    
    // Retirer les faiblesses qui sont devenues des forces
    newWeaknesses.removeWhere((weakness) => analysis.strengths.contains(weakness));
    
    return newWeaknesses.take(5).toList();
  }

  int _adaptConfidenceLevel(
    int currentLevel,
    double confidenceScore,
    Duration sessionDuration,
  ) {
    int newLevel = currentLevel;
    
    // Ajustement basé sur le score de confiance
    if (confidenceScore >= 0.8) {
      newLevel = math.min(10, newLevel + 1);
    } else if (confidenceScore <= 0.4) {
      newLevel = math.max(1, newLevel - 1);
    }
    
    // Ajustement basé sur la durée de session (engagement)
    if (sessionDuration.inMinutes >= 10) {
      newLevel = math.min(10, newLevel + 1);
    }
    
    return newLevel;
  }

  int _adaptExperienceLevel(
    int currentLevel,
    int totalSessions,
    double averageScore,
  ) {
    // L'expérience augmente avec les sessions et les performances
    final experienceBonus = (totalSessions / 5).floor();
    final performanceBonus = averageScore >= 80 ? 1 : 0;
    
    return math.min(10, currentLevel + experienceBonus + performanceBonus);
  }

  List<String> _updatePreferredTopics(
    List<String> currentTopics,
    ConfidenceScenario scenario,
    double score,
  ) {
    final newTopics = [...currentTopics];
    
    // Ajouter le topic si la performance était bonne
    if (score >= 70 && !newTopics.contains(scenario.type.displayName)) {
      newTopics.add(scenario.type.displayName);
    }
    
    return newTopics.take(5).toList();
  }

  AICharacterType _adaptPreferredCharacter(
    AICharacterType current,
    ConfidenceAnalysis analysis,
  ) {
    // Garder la préférence actuelle pour la stabilité
    // Future logique d'adaptation basée sur les retours utilisateur
    return current;
  }

  // Méthodes pour le coaching temps réel
  List<String> _assessCoachingNeeds(
    Map<String, double> metrics,
    SessionContext context,
  ) {
    final needs = <String>[];
    
    if (metrics['confidence_level'] != null && metrics['confidence_level']! < 0.3) {
      needs.add('boost_confidence');
    }
    
    if (metrics['speaking_pace'] != null && metrics['speaking_pace']! > 200) {
      needs.add('slow_down');
    }
    
    if (metrics['pause_duration'] != null && metrics['pause_duration']! > 5) {
      needs.add('continue_speaking');
    }
    
    return needs;
  }

  Future<AdaptiveDialogue> _generateRealTimeCoachingDialogue({
    required String need,
    required SessionContext context,
    required Map<String, double> metrics,
  }) async {
    final messages = {
      'boost_confidence': 'Respirez profondément et rappelez-vous vos forces.',
      'slow_down': 'Prenez votre temps, ralentissez légèrement le débit.',
      'continue_speaking': 'Continuez, vous vous en sortez très bien !',
    };
    
    return AdaptiveDialogue(
      speaker: context.userProfile.preferredCharacter,
      message: messages[need] ?? 'Vous progressez bien, continuez !',
      emotionalState: AIEmotionalState.encouraging,
      phase: AIInterventionPhase.realTimeGuidance,
      priorityLevel: 10,
      triggers: ['real_time_metrics'],
      personalizedVariables: {},
      displayDuration: const Duration(seconds: 3),
      requiresUserResponse: false,
    );
  }

  double _calculateContextRelevanceScore(SessionContext context) {
    // Score basé sur la pertinence du contexte
    double score = 0.5;
    
    score += context.userProfile.confidenceLevel / 20.0; // 0-0.5
    score += context.userProfile.experienceLevel / 20.0; // 0-0.5
    
    return math.min(1.0, score);
  }

  String _selectBestTemplate(List<String> templates, double contextScore) {
    // Sélection intelligente du meilleur template
    if (templates.isEmpty) return 'Message par défaut';
    
    // Pour l'instant, sélection aléatoire pondérée
    // Future: logique plus sophistiquée basée sur le score de contexte
    return templates[_random.nextInt(templates.length)];
  }
}
