import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import '../../../confidence_boost/data/services/streaming_confidence_service.dart';
import '../../../confidence_boost/data/services/mistral_api_service.dart';
import '../../domain/entities/scenario_models.dart';
import '../../../../core/config/app_config.dart';

// Modèles pour la conversation
class ConversationMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ConversationMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

enum MessageSender { ai, user }

/// Service unifié pour les conversations IA de scénarios
/// Combine LiveKit + Vosk + Mistral pour une expérience complète
class AIScenarioConversationService {
  // Services sous-jacents
  late final StreamingConfidenceService _voskService;
  late final MistralApiService _mistralService;
  
  // État de la conversation
  String? _currentSessionId;
  ScenarioConfiguration? _currentConfiguration;
  List<ConversationMessage> _conversationHistory = [];
  
  // Streams publics
  final StreamController<ConversationMessage> _messageController = StreamController.broadcast();
  final StreamController<String> _transcriptionController = StreamController.broadcast();
  final StreamController<List<String>> _suggestionsController = StreamController.broadcast();
  final StreamController<bool> _isListeningController = StreamController.broadcast();
  
  // API publique
  Stream<ConversationMessage> get messageStream => _messageController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<List<String>> get suggestionsStream => _suggestionsController.stream;
  Stream<bool> get isListeningStream => _isListeningController.stream;
  
  // État audio
  bool _isRecording = false;
  Room? _room;
  LocalAudioTrack? _localAudio;
  
  AIScenarioConversationService() {
    _voskService = StreamingConfidenceService();
    _mistralService = MistralApiService();
    
    _setupVoskListener();
  }
  
  /// Démarre une nouvelle conversation de scénario
  Future<bool> startConversation(ScenarioConfiguration configuration) async {
    try {
      debugPrint('🚀 Démarrage conversation scénario: ${configuration.type}');
      
      _currentConfiguration = configuration;
      _currentSessionId = 'scenario_${DateTime.now().millisecondsSinceEpoch}';
      _conversationHistory.clear();
      
      // Test de connectivité et initialisation avec fallbacks
      final connectivityResults = await _testServiceConnectivity();
      debugPrint('📊 Résultats connectivité: $connectivityResults');
      
      // 1. Initialiser LiveKit pour l'audio bidirectionnel (avec fallback)
      try {
        await _initializeLiveKit();
        debugPrint('✅ LiveKit initialisé avec succès');
      } catch (e) {
        debugPrint('⚠️ LiveKit indisponible, mode conversation textuelle: $e');
        // Continuer sans LiveKit
      }
      
      // 2. Démarrer le service Vosk pour la transcription (avec fallback)
      try {
        await _voskService.startStreaming(_currentSessionId!);
        debugPrint('✅ Vosk initialisé avec succès');
      } catch (e) {
        debugPrint('⚠️ Vosk indisponible, mode manuel: $e');
        // Continuer sans Vosk
      }
      
      // 3. Générer et envoyer le message d'accueil IA (toujours disponible)
      await _sendInitialAIMessage();
      
      debugPrint('✅ Conversation scénario démarrée (mode dégradé si nécessaire)');
      return true;
      
    } catch (e) {
      debugPrint('❌ Erreur démarrage conversation: $e');
      
      // Fallback : Mode conversation basique
      await _startFallbackMode();
      return true; // Retourner true car on a un mode de fallback
    }
  }
  
  /// Teste la connectivité des services
  Future<Map<String, bool>> _testServiceConnectivity() async {
    final results = <String, bool>{};
    
    // Test LiveKit Token Service
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.livekitTokenUrl}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      results['livekit'] = response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ LiveKit indisponible: $e');
      results['livekit'] = false;
    }
    
    // Test Vosk Service
    try {
      final voskUri = Uri.parse(AppConfig.apiBaseUrl);
      final response = await http.get(
        Uri.parse('${voskUri.scheme}://${voskUri.host}:${voskUri.port}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      results['vosk'] = response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Vosk indisponible: $e');
      results['vosk'] = false;
    }
    
    // Test Mistral (toujours disponible via fallbacks)
    results['mistral'] = true;
    
    return results;
  }
  
  /// Démarre le mode de fallback basique
  Future<void> _startFallbackMode() async {
    debugPrint('🆘 Démarrage mode de fallback basique');
    
    _currentConfiguration ??= ScenarioConfiguration(
      type: ScenarioType.presentation,
      difficulty: 0.5,
      durationMinutes: 10,
      personality: AIPersonalityType.professional,
    );
    
    _currentSessionId ??= 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    
    // Message d'accueil en mode dégradé
    final fallbackMessage = ConversationMessage(
      text: "Bonjour ! Nous sommes en mode de conversation basique. "
            "Vous pouvez taper vos réponses et je vous donnerai des conseils. "
            "Commençons par votre présentation !",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );
    
    _conversationHistory.add(fallbackMessage);
    _messageController.add(fallbackMessage);
    
    // Suggestions de fallback
    final fallbackSuggestions = [
      "Bonjour, je m'appelle...",
      "Je suis ravi de vous présenter...",
      "Mon objectif aujourd'hui est de...",
    ];
    
    _suggestionsController.add(fallbackSuggestions);
  }
  
  /// Initialise LiveKit pour l'audio bidirectionnel
  Future<void> _initializeLiveKit() async {
    try {
      // Générer un token pour la room
      final token = await _generateLiveKitToken();
      if (token == null) throw Exception('Impossible d\'obtenir un token LiveKit');
      
      // Connecter à la room
      _room = Room();
      await _room!.connect(AppConfig.livekitUrl, token);
      
      // Configurer l'audio local
      await _setupLocalAudio();
      
      debugPrint('✅ LiveKit initialisé');
      
    } catch (e) {
      debugPrint('❌ Erreur initialisation LiveKit: $e');
      rethrow;
    }
  }
  
  /// Configure l'audio local pour l'enregistrement
  Future<void> _setupLocalAudio() async {
    try {
      // Créer une piste audio locale
      _localAudio = await LocalAudioTrack.create(AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ));
      
      // Publier dans la room
      await _room!.localParticipant!.publishAudioTrack(_localAudio!);
      
      debugPrint('✅ Audio local configuré');
      
    } catch (e) {
      debugPrint('❌ Erreur configuration audio: $e');
      rethrow;
    }
  }
  
  /// Génère un token LiveKit pour la session
  Future<String?> _generateLiveKitToken() async {
    try {
      final tokenServiceUrl = '${AppConfig.livekitTokenUrl}/generate-token';
      debugPrint('🎫 Demande token vers: $tokenServiceUrl');
      
      final response = await http.post(
        Uri.parse(tokenServiceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'room_name': 'ai_scenario_${_currentSessionId}',
          'participant_name': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'participant_identity': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'grants': {
            'roomJoin': true,
            'canPublish': true,
            'canSubscribe': true,
            'canPublishData': true,
            'canUpdateOwnMetadata': true,
          },
          'metadata': {
            'session_id': _currentSessionId,
            'scenario_type': _currentConfiguration?.type.toString(),
            'exercise_type': 'ai_scenario',
            'timestamp': DateTime.now().toIso8601String(),
          },
          'validity_hours': 2,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        
        if (token != null) {
          debugPrint('✅ Token LiveKit obtenu');
          return token;
        } else {
          throw Exception('Token manquant dans la réponse');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur génération token: $e');
      return null;
    }
  }
  
  /// Configure l'écoute des transcriptions Vosk
  void _setupVoskListener() {
    _voskService.results.listen((result) {
      if (result.type == 'partial_transcription' && result.text != null) {
        // Transcription en cours
        _transcriptionController.add(result.text!);
        
      } else if (result.type == 'final_result' && result.transcription != null) {
        // Transcription finale - traiter comme message utilisateur
        _handleUserMessage(result.transcription!);
      }
    });
  }
  
  /// Envoie le message d'accueil IA initial
  Future<void> _sendInitialAIMessage() async {
    final welcomeMessage = _generateWelcomeMessage();
    final aiMessage = ConversationMessage(
      text: welcomeMessage,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );
    
    _conversationHistory.add(aiMessage);
    _messageController.add(aiMessage);
    
    // Générer les premières suggestions d'aide
    await _generateContextualSuggestions();
  }
  
  /// Génère le message d'accueil selon le type de scénario
  String _generateWelcomeMessage() {
    if (_currentConfiguration == null) return "Bonjour ! Commençons cet exercice.";
    
    switch (_currentConfiguration!.type) {
      case ScenarioType.jobInterview:
        return "Bonjour ! Je suis ravi de vous rencontrer. Pouvez-vous commencer par vous présenter et me parler de votre parcours ?";
      case ScenarioType.salesPitch:
        return "Bonjour ! J'aimerais en savoir plus sur votre produit ou service. Pouvez-vous me faire une présentation convaincante ?";
      case ScenarioType.presentation:
        return "Bonjour ! Je suis impatient d'écouter votre présentation. Prenez votre temps et commencez quand vous êtes prêt.";
      case ScenarioType.networking:
        return "Bonjour ! Ravi de vous rencontrer lors de cet événement. Pouvez-vous me parler de vous et de votre activité ?";
    }
  }
  
  /// Traite un message utilisateur (transcription finale)
  Future<void> _handleUserMessage(String userText) async {
    try {
      // Ajouter le message utilisateur à l'historique
      final userMessage = ConversationMessage(
        text: userText,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );
      
      _conversationHistory.add(userMessage);
      _messageController.add(userMessage);
      
      // Générer une réponse IA contextuelle
      await _generateAIResponse(userText);
      
    } catch (e) {
      debugPrint('❌ Erreur traitement message utilisateur: $e');
    }
  }
  
  /// Génère une réponse IA contextuelle via Mistral
  Future<void> _generateAIResponse(String userText) async {
    try {
      final prompt = _buildConversationPrompt(userText);
      final aiResponse = await _mistralService.generateText(
        prompt: prompt,
        maxTokens: 150,
        temperature: 0.8,
      );
      
      // Ajouter la réponse IA
      final aiMessage = ConversationMessage(
        text: aiResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      
      _conversationHistory.add(aiMessage);
      _messageController.add(aiMessage);
      
      // Générer de nouvelles suggestions
      await _generateContextualSuggestions();
      
    } catch (e) {
      debugPrint('❌ Erreur génération réponse IA: $e');
      
      // Fallback avec réponse générique
      final fallbackResponse = _generateFallbackResponse();
      final aiMessage = ConversationMessage(
        text: fallbackResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      
      _conversationHistory.add(aiMessage);
      _messageController.add(aiMessage);
    }
  }
  
  /// Construit le prompt de conversation pour Mistral
  String _buildConversationPrompt(String userText) {
    final scenarioContext = _getScenarioContext();
    final historyContext = _buildHistoryContext();
    
    return '''
Tu es un expert en communication qui joue le rôle d'un interlocuteur dans un $scenarioContext.

Contexte de la conversation:
$historyContext

L'utilisateur vient de dire: "$userText"

Instructions:
- Réponds de manière naturelle et professionnelle
- Pose une question de suivi pertinente pour continuer la conversation
- Reste dans le rôle et le contexte du scénario
- Garde ta réponse courte (2-3 phrases maximum)
- Encourage l'utilisateur à développer ses idées

Réponds uniquement avec ta réponse directe, sans préfixe ni explication.
''';
  }
  
  /// Obtient le contexte du scénario pour les prompts
  String _getScenarioContext() {
    if (_currentConfiguration == null) return "exercice de communication";
    
    switch (_currentConfiguration!.type) {
      case ScenarioType.jobInterview:
        return "entretien d'embauche où tu es le recruteur";
      case ScenarioType.salesPitch:
        return "rendez-vous commercial où tu es le client potentiel";
      case ScenarioType.presentation:
        return "présentation professionnelle où tu es l'audience";
      case ScenarioType.networking:
        return "événement de networking où tu es un participant";
    }
  }
  
  /// Construit le contexte d'historique pour les prompts
  String _buildHistoryContext() {
    if (_conversationHistory.length <= 2) return "Début de conversation";
    
    final recentMessages = _conversationHistory.length > 4 
        ? _conversationHistory.sublist(_conversationHistory.length - 4)
        : _conversationHistory;
        
    return recentMessages.map((msg) {
      final sender = msg.sender == MessageSender.ai ? "Toi" : "Utilisateur";
      return "$sender: ${msg.text}";
    }).join("\n");
  }
  
  /// Génère une réponse de fallback
  String _generateFallbackResponse() {
    final responses = [
      "C'est très intéressant. Pouvez-vous me donner un exemple concret ?",
      "Excellent ! Comment avez-vous développé cette approche ?",
      "Je vois. Qu'est-ce qui vous motive le plus dans ce domaine ?",
      "Parfait ! Pouvez-vous élaborer davantage sur ce point ?",
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }
  
  /// Ajoute manuellement un message utilisateur (pour mode fallback/textuel)
  Future<void> addUserMessage(String userText) async {
    if (userText.trim().isEmpty) return;
    
    try {
      debugPrint('📝 Message utilisateur manuel: $userText');
      await _handleUserMessage(userText.trim());
    } catch (e) {
      debugPrint('❌ Erreur ajout message utilisateur: $e');
    }
  }
  
  /// Diagnostique l'état actuel du service
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'session_id': _currentSessionId,
      'conversation_started': _currentConfiguration != null,
      'message_count': _conversationHistory.length,
      'livekit_connected': _room?.connectionState == ConnectionState.connected,
      'vosk_connected': _voskService != null,
      'recording_active': _isRecording,
      'configuration': _currentConfiguration?.toJson(),
      'last_error': null, // Sera utilisé pour stocker la dernière erreur
    };
  }
  
  /// Force une régénération des suggestions
  Future<void> regenerateSuggestions() async {
    try {
      await _generateContextualSuggestions();
      debugPrint('✅ Suggestions régénérées');
    } catch (e) {
      debugPrint('❌ Erreur régénération suggestions: $e');
      final fallback = _generateFallbackSuggestions();
      _suggestionsController.add(fallback);
    }
  }
  
  /// Réinitialise la conversation en conservant la configuration
  Future<void> resetConversation() async {
    try {
      debugPrint('🔄 Réinitialisation de la conversation');
      
      // Conserver la configuration actuelle
      final currentConfig = _currentConfiguration;
      
      // Nettoyer l'historique
      _conversationHistory.clear();
      
      // Régénérer le message d'accueil
      if (currentConfig != null) {
        _currentConfiguration = currentConfig;
        await _sendInitialAIMessage();
      }
      
      debugPrint('✅ Conversation réinitialisée');
    } catch (e) {
      debugPrint('❌ Erreur réinitialisation: $e');
    }
  }
  
  /// Génère des suggestions d'aide contextuelles
  Future<void> _generateContextualSuggestions() async {
    try {
      final prompt = _buildSuggestionsPrompt();
      final suggestionsText = await _mistralService.generateText(
        prompt: prompt,
        maxTokens: 100,
        temperature: 0.7,
      );
      
      // Parser les suggestions (une par ligne)
      final suggestions = suggestionsText
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim().replaceAll(RegExp(r'^[-*•]\s*'), ''))
          .where((suggestion) => suggestion.isNotEmpty)
          .take(3)
          .toList();
      
      if (suggestions.isNotEmpty) {
        _suggestionsController.add(suggestions);
      }
      
    } catch (e) {
      debugPrint('❌ Erreur génération suggestions: $e');
      
      // Suggestions de fallback
      final fallbackSuggestions = _generateFallbackSuggestions();
      _suggestionsController.add(fallbackSuggestions);
    }
  }
  
  /// Construit le prompt pour générer des suggestions
  String _buildSuggestionsPrompt() {
    final scenarioContext = _getScenarioContext();
    final lastAIMessage = _conversationHistory
        .where((msg) => msg.sender == MessageSender.ai)
        .toList()
        .isEmpty ? "" : _conversationHistory
        .where((msg) => msg.sender == MessageSender.ai)
        .toList()
        .last
        .text;
    
    return '''
Dans un contexte de $scenarioContext, l'interlocuteur vient de dire: "$lastAIMessage"

Génère 3 suggestions courtes et naturelles pour aider l'utilisateur à répondre.
Chaque suggestion doit:
- Être une phrase de début naturelle (10-15 mots max)
- Être adaptée au contexte professionnel
- Être en français
- Commencer différemment

Format: Une suggestion par ligne, sans numérotation ni tirets.

Exemples:
Mon expérience dans ce domaine m'a appris que...
Ce qui me distingue particulièrement, c'est...
Dans mon parcours, j'ai pu développer...
''';
  }
  
  /// Génère des suggestions de fallback selon le type de scénario
  List<String> _generateFallbackSuggestions() {
    if (_currentConfiguration == null) {
      return [
        "Mon expérience m'a appris que...",
        "Ce qui me distingue, c'est...",
        "Dans ma pratique, je privilégie...",
      ];
    }
    
    switch (_currentConfiguration!.type) {
      case ScenarioType.jobInterview:
        return [
          "Mon point fort principal est...",
          "Dans mon précédent poste, j'ai...",
          "Ce qui me motive, c'est...",
        ];
      case ScenarioType.salesPitch:
        return [
          "Notre solution apporte...",
          "Le bénéfice clé pour vous serait...",
          "Ce qui nous différencie, c'est...",
        ];
      case ScenarioType.presentation:
        return [
          "L'objectif de cette présentation est...",
          "Permettez-moi de vous expliquer...",
          "Les points clés à retenir sont...",
        ];
      case ScenarioType.networking:
        return [
          "Je travaille dans le domaine de...",
          "Mon activité consiste à...",
          "Ce qui me passionne, c'est...",
        ];
    }
  }
  
  /// Démarre l'enregistrement audio
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    try {
      _isRecording = true;
      _isListeningController.add(true);
      
      // Activer l'audio local
      if (_localAudio != null) {
        await _localAudio!.unmute();
      }
      
      debugPrint('🎤 Enregistrement démarré');
      
    } catch (e) {
      debugPrint('❌ Erreur démarrage enregistrement: $e');
      _isRecording = false;
      _isListeningController.add(false);
    }
  }
  
  /// Arrête l'enregistrement audio
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _isRecording = false;
      _isListeningController.add(false);
      
      // Couper l'audio local
      if (_localAudio != null) {
        await _localAudio!.mute();
      }
      
      debugPrint('🛑 Enregistrement arrêté');
      
    } catch (e) {
      debugPrint('❌ Erreur arrêt enregistrement: $e');
    }
  }
  
  /// Termine la conversation
  Future<void> endConversation() async {
    try {
      // Arrêter l'enregistrement
      if (_isRecording) {
        await stopRecording();
      }
      
      // Fermer les services
      await _voskService.stopStreaming();
      await _room?.disconnect();
      _room = null;
      _localAudio = null;
      
      // Nettoyer l'état
      _currentSessionId = null;
      _currentConfiguration = null;
      _conversationHistory.clear();
      
      debugPrint('✅ Conversation terminée');
      
    } catch (e) {
      debugPrint('❌ Erreur fin de conversation: $e');
    }
  }
  
  /// Obtient l'historique de la conversation
  List<ConversationMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  /// Vérifie si l'enregistrement est actif
  bool get isRecording => _isRecording;
  
  /// Nettoie les ressources
  void dispose() {
    _messageController.close();
    _transcriptionController.close();
    _suggestionsController.close();
    _isListeningController.close();
    
    _voskService.dispose();
    _mistralService.dispose();
  }
}