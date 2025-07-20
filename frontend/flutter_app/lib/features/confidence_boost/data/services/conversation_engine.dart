import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/services/optimized_http_service.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/ai_character_models.dart';
import 'adaptive_ai_character_service.dart';

/// Moteur de conversation avec Mistral pour la génération de réponses IA adaptatives
/// 
/// ✅ FONCTIONNALITÉS :
/// - Génération de réponses contextuelles avec Mistral
/// - Personnages IA différents selon le scénario
/// - Gestion de l'historique de conversation
/// - Adaptation dynamique selon les performances
/// - Support multi-tours de conversation
class ConversationEngine {
  static const String _tag = 'ConversationEngine';
  final Logger _logger = Logger();
  
  // Services
  final OptimizedHttpService _httpService;
  final AdaptiveAICharacterService _aiCharacterService;
  
  // Constructeur avec injection de dépendances pour les tests
  ConversationEngine({
    OptimizedHttpService? httpService,
    AdaptiveAICharacterService? aiCharacterService,
  }) : _httpService = httpService ?? OptimizedHttpService(),
        _aiCharacterService = aiCharacterService ?? AdaptiveAICharacterService();
  
  // Configuration Mistral
  static String get _mistralBaseUrl => AppConfig.mistralBaseUrl;
  static String get _mistralApiKey => dotenv.env['MISTRAL_API_KEY'] ?? '';
  static const String _mistralModel = 'mistral-medium-latest'; // Modèle optimisé pour la conversation
  
  // État de la conversation
  final List<ConversationTurn> _conversationHistory = [];
  AICharacterType? _currentCharacter;
  ConfidenceScenario? _currentScenario;
  UserAdaptiveProfile? _userProfile;
  
  // Prompts système par personnage
  static const Map<AICharacterType, String> _characterSystemPrompts = {
    AICharacterType.thomas: '''Tu es Thomas, un manager expérimenté et exigeant. Tu es professionnel, direct et analytique.
Tu coaches l'utilisateur pour améliorer sa communication professionnelle.
Caractéristiques:
- Ton direct et professionnel
- Focus sur la structure et la logique
- Exigeant mais constructif
- Donne des conseils pratiques et actionnables
Réponds toujours en français et adapte ton niveau d'exigence selon la performance de l'utilisateur.''',
    
    AICharacterType.marie: '''Tu es Marie, une experte en relation client empathique et encourageante. Tu es intuitive et collaborative.
Tu aides l'utilisateur à développer sa confiance en communication.
Caractéristiques:
- Ton empathique et bienveillant
- Focus sur l'émotion et la relation
- Encourageante et positive
- Valorise les progrès même petits
Réponds toujours en français et adapte ton soutien selon le niveau de confiance de l'utilisateur.''',
  };

  // Prompts par type de scénario
  static const Map<ConfidenceScenarioType, String> _scenarioContextPrompts = {
    ConfidenceScenarioType.interview: '''Context: L'utilisateur s'entraîne pour un entretien d'embauche.
Focus sur: clarté des réponses, structure STAR, exemples concrets, gestion du stress.''',
    
    ConfidenceScenarioType.presentation: '''Context: L'utilisateur prépare une présentation professionnelle.
Focus sur: structure du discours, captation de l'attention, gestion du trac, contact visuel.''',
    
    ConfidenceScenarioType.meeting: '''Context: L'utilisateur participe à une réunion d'équipe.
Focus sur: prise de parole opportune, argumentation, écoute active, synthèse.''',
    
    ConfidenceScenarioType.networking: '''Context: L'utilisateur fait du networking professionnel.
Focus sur: pitch personnel, questions ouvertes, écoute, création de lien.''',
    
    ConfidenceScenarioType.pitch: '''Context: L'utilisateur présente un pitch commercial.
Focus sur: accroche, proposition de valeur, storytelling, call-to-action.''',
  };

  /// Initialise le moteur de conversation
  Future<void> initialize({
    required ConfidenceScenario scenario,
    required UserAdaptiveProfile userProfile,
    AICharacterType? preferredCharacter,
  }) async {
    _logger.i('🚀 [$_tag] Initialisation pour ${scenario.title}');
    
    _currentScenario = scenario;
    _userProfile = userProfile;
    _conversationHistory.clear();
    
    // Sélection du personnage optimal
    _currentCharacter = preferredCharacter ?? 
                       _aiCharacterService.selectOptimalCharacter(
                         scenario: scenario,
                         profile: userProfile,
                         userPreference: preferredCharacter,
                       );
    
    await _aiCharacterService.initialize();
    
    _logger.i('✅ [$_tag] Initialisé avec ${_currentCharacter?.displayName}');
  }

  /// Génère la première réponse d'introduction du personnage IA
  Future<ConversationResponse> generateIntroduction() async {
    if (_currentScenario == null || _currentCharacter == null || _userProfile == null) {
      throw StateError('ConversationEngine non initialisé');
    }
    
    _logger.d('🎭 [$_tag] Génération introduction ${_currentCharacter!.displayName}');
    
    // Générer un dialogue d'introduction adaptatif
    final adaptiveDialogue = await _aiCharacterService.generateContextualDialogue(
      character: _currentCharacter!,
      phase: AIInterventionPhase.scenarioIntroduction,
      context: SessionContext(
        scenario: _currentScenario!,
        userProfile: _userProfile!,
        currentPhase: AIInterventionPhase.scenarioIntroduction,
        sessionDuration: Duration.zero,
        attemptsCount: 0,
        previousFeedback: [],
        currentMetrics: {},
      ),
    );
    
    // Créer le contexte pour Mistral
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildIntroductionPrompt();
    
    // Appeler Mistral pour une réponse plus naturelle
    final mistralResponse = await _callMistralAPI(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.8, // Plus créatif pour l'introduction
    );
    
    // Créer le tour de conversation
    final turn = ConversationTurn(
      speaker: ConversationSpeaker.ai,
      character: _currentCharacter!,
      message: mistralResponse,
      emotionalState: adaptiveDialogue.emotionalState,
      timestamp: DateTime.now(),
      metadata: {
        'phase': AIInterventionPhase.scenarioIntroduction.name,
        'scenario': _currentScenario!.id,
      },
    );
    
    _conversationHistory.add(turn);
    
    return ConversationResponse(
      message: mistralResponse,
      character: _currentCharacter!,
      emotionalState: adaptiveDialogue.emotionalState,
      suggestedUserResponses: _generateSuggestedResponses(turn),
      requiresUserResponse: true,
    );
  }

  /// Génère une réponse IA basée sur l'entrée utilisateur
  Future<ConversationResponse> generateAIResponse({
    required String userMessage,
    Map<String, double>? performanceMetrics,
    AIInterventionPhase? currentPhase,
  }) async {
    if (_currentScenario == null || _currentCharacter == null || _userProfile == null) {
      throw StateError('ConversationEngine non initialisé');
    }
    
    _logger.d('💬 [$_tag] Traitement message utilisateur: ${userMessage.length > 50 ? userMessage.substring(0, 50) + '...' : userMessage}');
    
    // Ajouter le message utilisateur à l'historique
    _conversationHistory.add(ConversationTurn(
      speaker: ConversationSpeaker.user,
      character: null,
      message: userMessage,
      emotionalState: null,
      timestamp: DateTime.now(),
      metadata: performanceMetrics ?? {},
    ));
    
    // Déterminer la phase actuelle
    final phase = currentPhase ?? _determineCurrentPhase();
    
    // Analyser le contexte pour adapter la réponse
    final context = SessionContext(
      scenario: _currentScenario!,
      userProfile: _userProfile!,
      currentPhase: phase,
      sessionDuration: _calculateSessionDuration(),
      attemptsCount: _conversationHistory.where((t) => t.speaker == ConversationSpeaker.user).length,
      previousFeedback: _extractPreviousFeedback(),
      currentMetrics: performanceMetrics ?? {},
    );
    
    // Générer le dialogue adaptatif
    final adaptiveDialogue = await _aiCharacterService.generateContextualDialogue(
      character: _currentCharacter!,
      phase: phase,
      context: context,
    );
    
    // Construire le prompt pour Mistral avec l'historique
    final systemPrompt = _buildSystemPrompt();
    final conversationPrompt = _buildConversationPrompt(userMessage, performanceMetrics);
    
    // Appeler Mistral
    final mistralResponse = await _callMistralAPI(
      systemPrompt: systemPrompt,
      userPrompt: conversationPrompt,
      temperature: _getTemperatureForPhase(phase),
    );
    
    // Créer le tour de conversation IA
    final aiTurn = ConversationTurn(
      speaker: ConversationSpeaker.ai,
      character: _currentCharacter!,
      message: mistralResponse,
      emotionalState: adaptiveDialogue.emotionalState,
      timestamp: DateTime.now(),
      metadata: {
        'phase': phase.name,
        'adaptiveScore': performanceMetrics?['confidence_level'] ?? 0.0,
      },
    );
    
    _conversationHistory.add(aiTurn);
    
    return ConversationResponse(
      message: mistralResponse,
      character: _currentCharacter!,
      emotionalState: adaptiveDialogue.emotionalState,
      suggestedUserResponses: _generateSuggestedResponses(aiTurn),
      requiresUserResponse: adaptiveDialogue.requiresUserResponse,
    );
  }

  /// Appel API Mistral
  Future<String> _callMistralAPI({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    try {
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ];
      
      final requestBody = {
        'model': _mistralModel,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': 300, // Réponses concises
        'top_p': 0.95,
        'stream': false,
      };
      
      _logger.d('🤖 [$_tag] Appel Mistral API...');
      
      final response = await _httpService.post(
        '$_mistralBaseUrl/v1/chat/completions',
        headers: {
          'Authorization': 'Bearer $_mistralApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
        timeout: OptimizedHttpService.mediumTimeout,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        _logger.d('✅ [$_tag] Réponse Mistral reçue');
        return content.trim();
      } else {
        _logger.e('❌ [$_tag] Erreur Mistral: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur Mistral API: ${response.statusCode}');
      }
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur appel Mistral: $e');
      return _generateFallbackResponse();
    }
  }

  /// Construit le prompt système complet
  String _buildSystemPrompt() {
    final characterPrompt = _characterSystemPrompts[_currentCharacter!] ?? '';
    final scenarioPrompt = _scenarioContextPrompts[_currentScenario!.type] ?? '';
    
    return '''$characterPrompt

$scenarioPrompt

Instructions supplémentaires:
- Reste dans ton rôle de ${_currentCharacter!.displayName} en permanence
- Adapte ton niveau selon la confiance de l'utilisateur (niveau ${_userProfile!.confidenceLevel}/10)
- Sois concis mais pertinent (max 3-4 phrases par réponse)
- Pose des questions pour faire progresser la conversation
- Donne des conseils pratiques et actionnables''';
  }

  /// Construit le prompt d'introduction
  String _buildIntroductionPrompt() {
    return '''L'utilisateur vient de sélectionner le scénario "${_currentScenario!.title}".
Description du scénario: ${_currentScenario!.description}

Présente-toi brièvement et explique comment tu vas l'aider dans cet exercice.
Mets l'utilisateur à l'aise tout en montrant ton expertise.''';
  }

  /// Construit le prompt de conversation avec historique
  String _buildConversationPrompt(String userMessage, Map<String, double>? metrics) {
    final buffer = StringBuffer();
    
    // Ajouter l'historique récent (max 5 derniers échanges)
    final recentHistory = _conversationHistory.length > 10 
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;
    
    buffer.writeln('Historique de conversation:');
    for (final turn in recentHistory) {
      final speaker = turn.speaker == ConversationSpeaker.user ? 'Utilisateur' : turn.character!.displayName;
      buffer.writeln('$speaker: ${turn.message}');
    }
    
    // Ajouter les métriques si disponibles
    if (metrics != null && metrics.isNotEmpty) {
      buffer.writeln('\nMétriques de performance actuelles:');
      if (metrics['confidence_level'] != null) {
        buffer.writeln('- Niveau de confiance: ${(metrics['confidence_level']! * 100).toStringAsFixed(0)}%');
      }
      if (metrics['fluency_score'] != null) {
        buffer.writeln('- Fluidité: ${(metrics['fluency_score']! * 100).toStringAsFixed(0)}%');
      }
    }
    
    buffer.writeln('\nRéponds à ce message de l\'utilisateur de manière adaptée à son niveau et au contexte.');
    
    return buffer.toString();
  }

  /// Détermine la phase actuelle de la conversation
  AIInterventionPhase _determineCurrentPhase() {
    final userTurns = _conversationHistory.where((t) => t.speaker == ConversationSpeaker.user).length;
    
    if (userTurns == 0) return AIInterventionPhase.scenarioIntroduction;
    if (userTurns <= 2) return AIInterventionPhase.preparationCoaching;
    if (userTurns <= 5) return AIInterventionPhase.realTimeGuidance;
    return AIInterventionPhase.performanceAnalysis;
  }

  /// Calcule la durée de session
  Duration _calculateSessionDuration() {
    if (_conversationHistory.isEmpty) return Duration.zero;
    
    final firstTurn = _conversationHistory.first;
    final lastTurn = _conversationHistory.last;
    return lastTurn.timestamp.difference(firstTurn.timestamp);
  }

  /// Extrait les feedbacks précédents
  List<String> _extractPreviousFeedback() {
    return _conversationHistory
        .where((t) => t.speaker == ConversationSpeaker.ai)
        .map((t) => t.message)
        .take(3)
        .toList();
  }

  /// Température adaptée selon la phase
  double _getTemperatureForPhase(AIInterventionPhase phase) {
    switch (phase) {
      case AIInterventionPhase.scenarioIntroduction:
        return 0.8; // Plus créatif
      case AIInterventionPhase.preparationCoaching:
        return 0.7; // Équilibré
      case AIInterventionPhase.realTimeGuidance:
        return 0.6; // Plus focalisé
      case AIInterventionPhase.performanceAnalysis:
        return 0.5; // Plus analytique
      default:
        return 0.7;
    }
  }

  /// Génère des suggestions de réponses pour l'utilisateur
  List<String> _generateSuggestedResponses(ConversationTurn aiTurn) {
    // Basé sur la phase et le contexte
    final phase = AIInterventionPhase.values.firstWhere(
      (p) => p.name == aiTurn.metadata['phase'],
      orElse: () => AIInterventionPhase.preparationCoaching,
    );
    
    switch (phase) {
      case AIInterventionPhase.scenarioIntroduction:
        return [
          "Je suis prêt(e) à commencer",
          "J'ai quelques questions sur le scénario",
          "Je me sens un peu stressé(e)",
        ];
      case AIInterventionPhase.preparationCoaching:
        return [
          "Peux-tu me donner un exemple ?",
          "Comment puis-je m'améliorer ?",
          "Je vais essayer cette approche",
        ];
      case AIInterventionPhase.realTimeGuidance:
        return [
          "J'ai compris, je continue",
          "C'est difficile pour moi",
          "Merci pour le conseil",
        ];
      default:
        return [
          "Que penses-tu de ma performance ?",
          "Sur quoi dois-je me concentrer ?",
          "J'aimerais réessayer",
        ];
    }
  }

  /// Réponse de fallback en cas d'erreur Mistral
  String _generateFallbackResponse() {
    final responses = {
      AICharacterType.thomas: [
        "Concentrez-vous sur la structure de votre message. Soyez clair et direct.",
        "Votre approche manque de précision. Reformulez avec des exemples concrets.",
        "Bien. Maintenant, travaillons sur l'impact de votre communication.",
      ],
      AICharacterType.marie: [
        "Je sens que vous progressez ! Continuez avec cette énergie positive.",
        "N'hésitez pas à prendre votre temps. L'important est d'être authentique.",
        "C'est très bien ! Essayons d'ajouter un peu plus d'émotion dans votre message.",
      ],
    };
    
    final characterResponses = responses[_currentCharacter!] ?? ["Continuez, vous êtes sur la bonne voie."];
    return characterResponses[DateTime.now().millisecond % characterResponses.length];
  }

  /// Obtient l'historique de conversation
  List<ConversationTurn> getConversationHistory() => List.unmodifiable(_conversationHistory);

  /// Réinitialise la conversation
  void reset() {
    _conversationHistory.clear();
    _currentCharacter = null;
    _currentScenario = null;
    _userProfile = null;
    _logger.i('🔄 [$_tag] Conversation réinitialisée');
  }
}

/// Modèle pour un tour de conversation
class ConversationTurn {
  final ConversationSpeaker speaker;
  final AICharacterType? character; // Null pour l'utilisateur
  final String message;
  final AIEmotionalState? emotionalState; // Null pour l'utilisateur
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ConversationTurn({
    required this.speaker,
    required this.character,
    required this.message,
    required this.emotionalState,
    required this.timestamp,
    required this.metadata,
  });
}

/// Type de locuteur
enum ConversationSpeaker { user, ai }

/// Modèle de réponse de conversation
class ConversationResponse {
  final String message;
  final AICharacterType character;
  final AIEmotionalState emotionalState;
  final List<String> suggestedUserResponses;
  final bool requiresUserResponse;

  ConversationResponse({
    required this.message,
    required this.character,
    required this.emotionalState,
    required this.suggestedUserResponses,
    required this.requiresUserResponse,
  });
}