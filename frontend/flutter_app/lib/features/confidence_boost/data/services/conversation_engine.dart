import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
      '$systemPrompt\n\n$userPrompt'
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
  Future<String> generateResponse({
    required String userInput,
    required List<ConversationTurn> conversationHistory,
    required ConfidenceScenario scenario,
    required AICharacterType character,
    required UserAdaptiveProfile userProfile,
  }) async {
    _logger.i('🧠 [MISTRAL] Generating response for $character');
    
    try {
      // 1. CONSTRUCTION DU PROMPT CONTEXTUEL
      final prompt = _buildContextualPrompt(
        userInput: userInput,
        conversationHistory: conversationHistory,
        scenario: scenario,
        character: character,
        userProfile: userProfile,
      );
      
      // 2. APPEL À MISTRAL
      final response = await _callMistralAPI(prompt);
      
      // 3. POST-TRAITEMENT DE LA RÉPONSE
      final processedResponse = _postProcessResponse(response, character);
      
      _logger.i('✅ [MISTRAL] Generated response: ${processedResponse.substring(0, math.min(100, processedResponse.length))}...');
      
      return processedResponse;
      
    } catch (e) {
      _logger.e('❌ [MISTRAL] Failed to generate response: $e');
      return _generateFallbackResponse(character, userInput);
    }
  }

  String _buildContextualPrompt({
    required String userInput,
    required List<ConversationTurn> conversationHistory,
    required ConfidenceScenario scenario,
    required AICharacterType character,
    required UserAdaptiveProfile userProfile,
  }) {
    final systemPrompt = _characterSystemPrompts[character]!;
    final scenarioContext = _scenarioContextPrompts[scenario.type]!;
    
    // Historique de conversation formaté
    final historyText = conversationHistory
        .reversed
        .take(6)
        .toList()
        .reversed
        .map((turn) => '${turn.speaker.name}: ${turn.message}')
        .join('\n');
    
    // Adaptation selon le profil utilisateur
    final adaptationNote = _buildAdaptationNote(userProfile);
    
    return '''
$systemPrompt

$scenarioContext

$adaptationNote

Historique de la conversation:
$historyText

Utilisateur: $userInput

Réponds en tant que ${character.name} de manière naturelle et contextuelle. Ta réponse doit:
1. Être cohérente avec ta personnalité
2. S'adapter au niveau de l'utilisateur
3. Faire progresser la conversation
4. Rester dans le contexte du scénario
5. Être concise (2-3 phrases maximum)

Réponse:''';
  }

  Future<String> _callMistralAPI(String prompt) async {
    final response = await _httpService.post(
      '$_mistralBaseUrl/chat/completions',
      headers: {
        'Authorization': 'Bearer $_mistralApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _mistralModel,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 150,
        'temperature': 0.7,
        'top_p': 0.9,
      }),
      timeout: const Duration(seconds: 10),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Mistral API error: ${response.statusCode}');
    }
  }
  
  String _postProcessResponse(String response, AICharacterType character) {
    // Nettoie la réponse
    String cleaned = response.trim();
    
    // Supprime les préfixes indésirables
    cleaned = cleaned.replaceAll(RegExp(r'^(Thomas|Marie):\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^Réponse:\s*'), '');
    
    // Assure une ponctuation correcte
    if (!cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
      cleaned += '.';
    }
    
    return cleaned;
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

  String _buildAdaptationNote(UserAdaptiveProfile userProfile) {
    // Cette méthode peut être étendue pour des adaptations plus fines
    if (userProfile.confidenceLevel < 4) {
      return "Note: L'utilisateur est débutant et peu confiant. Sois particulièrement encourageant et simple dans tes explications.";
    } else if (userProfile.confidenceLevel > 7) {
      return "Note: L'utilisateur est avancé et confiant. Challenge-le avec des questions plus complexes et des feedbacks plus directs.";
    }
    return "Note: L'utilisateur a un niveau intermédiaire. Maintiens un équilibre entre soutien et challenge.";
  }

  /// Réponse de fallback en cas d'erreur Mistral
  String _generateFallbackResponse(AICharacterType character, String userInput) {
    _logger.w('Generating fallback response for $character');
    switch (character) {
      case AICharacterType.thomas:
        return "Je n'ai pas bien saisi votre point. Pouvez-vous reformuler votre idée plus clairement ?";
      case AICharacterType.marie:
        return "Excusez-moi, j'ai eu un petit problème technique. Pouvez-vous répéter ce que vous venez de dire ?";
    }
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