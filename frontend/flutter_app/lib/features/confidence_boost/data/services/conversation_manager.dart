import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/services/optimized_http_service.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// Gestionnaire de conversation pour l'exercice Confidence Boost
/// Utilise le backend eloquence-conversation (port 8003) pour l'échange avec l'IA en streaming
class ConversationManager {
  final OptimizedHttpService httpService;
  static const String _tag = 'ConversationManager';
  
  // Configuration du service backend
  late String _baseUrl;
  String? _currentSessionId;
  WebSocketChannel? _websocketChannel;
  StreamController<ConversationUpdate>? _conversationController;
  StreamController<ConfidenceAnalysis>? _analysisController;
  
  // État de la conversation
  bool _isSessionActive = false;
  List<ConversationMessage> _conversationHistory = [];
  ConfidenceScenario? _currentScenario;

  ConversationManager({
    required this.httpService,
    String? baseUrl,
  }) {
    _baseUrl = baseUrl ?? 'http://localhost:8003';
    logger.i(_tag, 'ConversationManager initialisé avec backend: $_baseUrl');
  }

  /// Configure l'URL du backend (pour mobile)
  void configureBackend(String hostIp, {int port = 8003}) {
    _baseUrl = 'http://$hostIp:$port';
    logger.i(_tag, 'Backend configuré: $_baseUrl');
  }

  /// Démarre une nouvelle session de conversation
  Future<ConversationSession?> startConversationSession({
    required ConfidenceScenario scenario,
    required String userContext,
    String? customInstructions,
    Map<String, dynamic>? additionalConfig,
  }) async {
    try {
      logger.i(_tag, 'Démarrage session conversation pour: ${scenario.title}');
      
      // Préparer la requête
      final requestData = {
        'exercise_type': 'confidence_boost',
        'scenario': scenario.toJson(),
        'user_context': userContext,
        if (customInstructions != null) 'custom_instructions': customInstructions,
        if (additionalConfig != null) ...additionalConfig,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Créer la session via l'API
      final response = await httpService.post(
        '$_baseUrl/api/sessions/create',
        body: jsonEncode(requestData),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final sessionData = response.jsonBody;
        _currentSessionId = sessionData['session_id'];
        _currentScenario = scenario;
        _isSessionActive = true;
        _conversationHistory.clear();

        // Initialiser les controllers de stream
        _conversationController = StreamController<ConversationUpdate>.broadcast();
        _analysisController = StreamController<ConfidenceAnalysis>.broadcast();

        logger.i(_tag, 'Session créée avec succès: $_currentSessionId');

        return ConversationSession(
          sessionId: _currentSessionId!,
          livekitUrl: sessionData['livekit_url'] ?? '',
          livekitToken: sessionData['livekit_token'] ?? '',
          exerciseType: sessionData['exercise'] ?? 'confidence_boost',
          characterName: sessionData['character'] ?? 'IA',
          status: sessionData['status'] ?? 'created',
        );
      } else {
        logger.e(_tag, 'Erreur création session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur démarrage session: $e');
      return null;
    }
  }

  /// Connecte le WebSocket pour le streaming en temps réel
  Future<bool> connectWebSocket() async {
    if (_currentSessionId == null) {
      logger.e(_tag, 'Pas de session active pour WebSocket');
      return false;
    }

    try {
      final wsUrl = _baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/api/sessions/$_currentSessionId/stream');
      
      logger.i(_tag, 'Connexion WebSocket: $uri');
      
      _websocketChannel = IOWebSocketChannel.connect(uri);
      
      // Écouter les messages
      _websocketChannel!.stream.listen(
        (data) => _handleWebSocketMessage(data),
        onError: (error) => logger.e(_tag, 'Erreur WebSocket: $error'),
        onDone: () => logger.i(_tag, 'WebSocket fermé'),
      );

      logger.i(_tag, 'WebSocket connecté avec succès');
      return true;
    } catch (e) {
      logger.e(_tag, 'Erreur connexion WebSocket: $e');
      return false;
    }
  }

  /// Traite les messages WebSocket reçus
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final messageType = message['type'];

      switch (messageType) {
        case 'welcome':
          logger.i(_tag, 'Message d\'accueil reçu: ${message['message']}');
          _conversationController?.add(ConversationUpdate(
            type: ConversationUpdateType.welcome,
            message: message['message'],
            characterName: message['character'],
            timestamp: DateTime.now(),
          ));
          break;

        case 'conversation_update':
          _handleConversationUpdate(message);
          break;

        case 'error':
          logger.e(_tag, 'Erreur WebSocket: ${message['message']}');
          _conversationController?.add(ConversationUpdate(
            type: ConversationUpdateType.error,
            message: message['message'],
            timestamp: DateTime.now(),
          ));
          break;

        default:
          logger.w(_tag, 'Type de message WebSocket inconnu: $messageType');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur traitement message WebSocket: $e');
    }
  }

  /// Traite les mises à jour de conversation
  void _handleConversationUpdate(Map<String, dynamic> message) {
    try {
      final transcription = message['transcription'] ?? '';
      final aiResponse = message['ai_response'] ?? '';
      final speechAnalysis = message['speech_analysis'] ?? {};
      final conversationTurn = message['conversation_turn'] ?? 0;

      // Ajouter à l'historique si on a du contenu
      if (transcription.isNotEmpty || aiResponse.isNotEmpty) {
        final conversationMessage = ConversationMessage(
          userMessage: transcription,
          aiResponse: aiResponse,
          timestamp: DateTime.now(),
          turn: conversationTurn,
          speechMetrics: speechAnalysis,
        );
        
        _conversationHistory.add(conversationMessage);
        
        logger.i(_tag, 'Conversation mise à jour - Tour: $conversationTurn');
      }

      // Envoyer la mise à jour
      _conversationController?.add(ConversationUpdate(
        type: ConversationUpdateType.conversationUpdate,
        transcription: transcription,
        aiResponse: aiResponse,
        speechAnalysis: speechAnalysis,
        conversationTurn: conversationTurn,
        timestamp: DateTime.now(),
      ));

      // Générer une analyse de confiance si on a des métriques
      if (speechAnalysis.isNotEmpty) {
        _generateConfidenceAnalysis(speechAnalysis, transcription);
      }
    } catch (e) {
      logger.e(_tag, 'Erreur traitement mise à jour conversation: $e');
    }
  }

  /// Génère une analyse de confiance à partir des métriques
  void _generateConfidenceAnalysis(Map<String, dynamic> speechMetrics, String transcription) {
    try {
      final confidenceLevel = speechMetrics['confidence_level']?.toDouble() ?? 0.7;
      final clarityScore = speechMetrics['clarity_score']?.toDouble() ?? 0.75;
      final paceRating = speechMetrics['pace_rating']?.toDouble() ?? 0.7;
      final hesitationCount = speechMetrics['hesitation_count']?.toInt() ?? 0;

      final analysis = ConfidenceAnalysis(
        overallScore: (confidenceLevel * 100).clamp(0.0, 100.0),
        confidenceScore: confidenceLevel,
        fluencyScore: paceRating,
        clarityScore: clarityScore,
        energyScore: (confidenceLevel + clarityScore) / 2,
        feedback: _generateFeedback(confidenceLevel, hesitationCount),
        wordCount: transcription.split(' ').length,
        speakingRate: _estimateSpeakingRate(transcription),
        keywordsUsed: _extractKeywords(transcription),
        transcription: transcription,
        strengths: _generateStrengths(confidenceLevel, clarityScore),
        improvements: _generateImprovements(confidenceLevel, hesitationCount),
      );

      _analysisController?.add(analysis);
      logger.i(_tag, 'Analyse de confiance générée: ${analysis.overallScore.toStringAsFixed(1)}%');
    } catch (e) {
      logger.e(_tag, 'Erreur génération analyse: $e');
    }
  }

  /// Envoie des données audio via WebSocket
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (_websocketChannel == null) {
      logger.w(_tag, 'WebSocket non connecté pour envoi audio');
      return;
    }

    try {
      final message = {
        'type': 'audio_chunk',
        'data': base64Encode(audioData),
        'timestamp': DateTime.now().toIso8601String(),
      };

      _websocketChannel!.sink.add(jsonEncode(message));
    } catch (e) {
      logger.e(_tag, 'Erreur envoi audio: $e');
    }
  }

  /// Demande une analyse de confiance via l'API REST
  Future<ConfidenceAnalysis?> requestConfidenceAnalysis({
    required String text,
    Uint8List? audioData,
  }) async {
    try {
      logger.i(_tag, 'Demande analyse de confiance');

      final requestData = {
        'text': text,
        'session_id': _currentSessionId,
        if (audioData != null) 'audio_data': base64Encode(audioData),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await httpService.post(
        '$_baseUrl/api/v1/confidence/analyze',
        body: jsonEncode(requestData),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = response.jsonBody;
        final confidenceScore = data['confidence_score']?.toDouble() ?? 0.0;
        final analysis = data['analysis'] ?? {};
        final recommendations = List<String>.from(data['recommendations'] ?? []);

        final result = ConfidenceAnalysis(
          overallScore: (confidenceScore * 100).clamp(0.0, 100.0),
          confidenceScore: confidenceScore,
          fluencyScore: analysis['speech_metrics']?['clarity_score']?.toDouble() ?? 0.75,
          clarityScore: confidenceScore,
          energyScore: confidenceScore,
          feedback: recommendations.isNotEmpty ? recommendations.first : 'Analyse terminée',
          wordCount: analysis['speech_metrics']?['word_count']?.toInt() ?? text.split(' ').length,
          speakingRate: _estimateSpeakingRate(text),
          keywordsUsed: _extractKeywords(text),
          transcription: text,
          strengths: recommendations.where((r) => r.contains('Excellent') || r.contains('Bonne')).toList(),
          improvements: recommendations.where((r) => r.contains('Pratiquez') || r.contains('Évitez')).toList(),
        );

        logger.i(_tag, 'Analyse reçue: ${result.overallScore.toStringAsFixed(1)}%');
        return result;
      } else {
        logger.e(_tag, 'Erreur API analyse: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur demande analyse: $e');
      return null;
    }
  }

  /// Termine la session de conversation
  Future<ConversationReport?> endConversationSession() async {
    if (_currentSessionId == null) {
      logger.w(_tag, 'Pas de session active à terminer');
      return null;
    }

    try {
      logger.i(_tag, 'Fin de session: $_currentSessionId');

      // Envoyer signal de fin via WebSocket
      if (_websocketChannel != null) {
        _websocketChannel!.sink.add(jsonEncode({
          'type': 'end_session',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }

      // Demander le rapport final via API
      final response = await httpService.post(
        '$_baseUrl/api/sessions/$_currentSessionId/end',
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final reportData = response.jsonBody['report'];
        
        final report = ConversationReport(
          sessionId: _currentSessionId!,
          exerciseType: reportData['exercise_type'] ?? 'confidence_boost',
          duration: Duration(seconds: (reportData['duration']?.toDouble() ?? 0.0).round()),
          totalInteractions: reportData['interactions']?.toInt() ?? _conversationHistory.length,
          finalConfidenceScore: reportData['final_confidence_score']?.toDouble() ?? 0.0,
          conversationSummary: reportData['conversation_summary'] ?? '',
          recommendations: List<String>.from(reportData['recommendations'] ?? []),
          conversationHistory: _conversationHistory,
        );

        logger.i(_tag, 'Rapport de session généré');
        return report;
      } else {
        logger.e(_tag, 'Erreur génération rapport: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur fin de session: $e');
      return null;
    } finally {
      _cleanup();
    }
  }

  /// Nettoie les ressources
  void _cleanup() {
    _websocketChannel?.sink.close();
    _websocketChannel = null;
    _conversationController?.close();
    _analysisController?.close();
    _conversationController = null;
    _analysisController = null;
    _currentSessionId = null;
    _isSessionActive = false;
    _conversationHistory.clear();
    _currentScenario = null;
    logger.i(_tag, 'Ressources nettoyées');
  }

  // Méthodes utilitaires
  String _generateFeedback(double confidenceLevel, int hesitationCount) {
    if (confidenceLevel >= 0.8 && hesitationCount <= 1) {
      return 'Excellente confiance ! Votre présentation est convaincante et fluide.';
    } else if (confidenceLevel >= 0.6) {
      return 'Bonne confiance générale. Quelques améliorations vous rendront encore plus percutant.';
    } else {
      return 'Continuez à pratiquer pour gagner en confiance et en fluidité.';
    }
  }

  List<String> _generateStrengths(double confidenceLevel, double clarityScore) {
    final strengths = <String>[];
    if (confidenceLevel >= 0.7) strengths.add('Ton confiant et assuré');
    if (clarityScore >= 0.75) strengths.add('Expression claire et articulée');
    if (strengths.isEmpty) strengths.add('Participation active à l\'exercice');
    return strengths;
  }

  List<String> _generateImprovements(double confidenceLevel, int hesitationCount) {
    final improvements = <String>[];
    if (confidenceLevel < 0.7) improvements.add('Travailler la confiance en soi');
    if (hesitationCount > 2) improvements.add('Réduire les hésitations');
    improvements.add('Intégrer plus d\'exemples concrets');
    return improvements;
  }

  double _estimateSpeakingRate(String text) {
    // Estimation: ~150 mots par minute en français
    return 150.0;
  }

  List<String> _extractKeywords(String text) {
    // Extraction simple de mots-clés
    final words = text.toLowerCase().split(' ');
    return words.where((word) => word.length > 4).take(3).toList();
  }

  // Getters
  bool get isSessionActive => _isSessionActive;
  String? get currentSessionId => _currentSessionId;
  List<ConversationMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  ConfidenceScenario? get currentScenario => _currentScenario;
  
  Stream<ConversationUpdate> get conversationStream => 
    _conversationController?.stream ?? const Stream.empty();
  
  Stream<ConfidenceAnalysis> get analysisStream => 
    _analysisController?.stream ?? const Stream.empty();

  /// Libère toutes les ressources
  void dispose() {
    _cleanup();
  }
}

// Classes de données pour la conversation
class ConversationSession {
  final String sessionId;
  final String livekitUrl;
  final String livekitToken;
  final String exerciseType;
  final String characterName;
  final String status;

  ConversationSession({
    required this.sessionId,
    required this.livekitUrl,
    required this.livekitToken,
    required this.exerciseType,
    required this.characterName,
    required this.status,
  });
}

class ConversationMessage {
  final String userMessage;
  final String aiResponse;
  final DateTime timestamp;
  final int turn;
  final Map<String, dynamic> speechMetrics;

  ConversationMessage({
    required this.userMessage,
    required this.aiResponse,
    required this.timestamp,
    required this.turn,
    required this.speechMetrics,
  });
}

class ConversationUpdate {
  final ConversationUpdateType type;
  final String? message;
  final String? characterName;
  final String? transcription;
  final String? aiResponse;
  final Map<String, dynamic>? speechAnalysis;
  final int? conversationTurn;
  final DateTime timestamp;

  ConversationUpdate({
    required this.type,
    this.message,
    this.characterName,
    this.transcription,
    this.aiResponse,
    this.speechAnalysis,
    this.conversationTurn,
    required this.timestamp,
  });
}

enum ConversationUpdateType {
  welcome,
  conversationUpdate,
  error,
}

class ConversationReport {
  final String sessionId;
  final String exerciseType;
  final Duration duration;
  final int totalInteractions;
  final double finalConfidenceScore;
  final String conversationSummary;
  final List<String> recommendations;
  final List<ConversationMessage> conversationHistory;

  ConversationReport({
    required this.sessionId,
    required this.exerciseType,
    required this.duration,
    required this.totalInteractions,
    required this.finalConfidenceScore,
    required this.conversationSummary,
    required this.recommendations,
    required this.conversationHistory,
  });
}
