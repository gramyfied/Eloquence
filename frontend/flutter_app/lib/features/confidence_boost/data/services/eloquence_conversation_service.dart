import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:logger/logger.dart';

/// Service d'intégration avec le backend Eloquence Conversation (Port 8003)
/// Connecte Flutter à votre infrastructure backend existante
class EloquenceConversationService {
  // Configuration réseau adaptative pour mobile et émulateur
  static String get _baseUrl {
    if (kDebugMode && Platform.isAndroid) {
      // IP locale du PC de développement pour tests mobiles réels
      return 'http://192.168.1.44:8003';
    }
    // Localhost pour émulateur et web
    return 'http://localhost:8003';
  }
  
  static String get _wsBaseUrl {
    if (kDebugMode && Platform.isAndroid) {
      // WebSocket avec IP locale pour appareils Android réels
      return 'ws://192.168.1.44:8003';
    }
    // WebSocket localhost pour émulateur et web
    return 'ws://localhost:8003';
  }
  
  final Logger _logger = Logger();
  final http.Client _httpClient = http.Client();
  
  WebSocketChannel? _wsChannel;
  StreamController<ConversationEvent>? _eventController;
  String? _currentSessionId;
  
  /// Stream des événements de conversation
  Stream<ConversationEvent> get conversationEvents => 
      _eventController?.stream ?? const Stream.empty();

  /// Crée une nouvelle session de conversation
  Future<ConversationSession> createSession({
    required String exerciseType,
    Map<String, dynamic>? userConfig,
  }) async {
    try {
      final requestBody = {
        'exercise_type': exerciseType,
        'user_config': userConfig ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      _logger.i('🚀 Création session: $exerciseType');
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final session = ConversationSession(
          sessionId: data['session_id'],
          livekitToken: data['livekit_token'],
          livekitUrl: data['livekit_url'],
          exerciseType: data['exercise'],
          characterName: data['character'],
          status: data['status'],
        );
        
        _currentSessionId = session.sessionId;
        _logger.i('✅ Session créée: ${session.sessionId}');
        
        return session;
      } else {
        throw ConversationException(
          'Erreur création session: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      _logger.e('❌ Erreur création session: $e');
      throw ConversationException('Impossible de créer la session', e.toString());
    }
  }

  /// Démarre le streaming WebSocket pour une session
  Future<void> startConversationStream(String sessionId) async {
    try {
      _logger.i('🔌 Connexion WebSocket session: $sessionId');
      
      // Fermer connexion existante
      await _closeWebSocket();
      
      // Créer nouveau stream controller
      _eventController = StreamController<ConversationEvent>.broadcast();
      
      // Connexion WebSocket
      final wsUrl = '$_wsBaseUrl/api/sessions/$sessionId/stream';
      _wsChannel = IOWebSocketChannel.connect(wsUrl);
      
      // Écouter les messages
      _wsChannel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _handleWebSocketClosed(),
      );
      
      _logger.i('✅ WebSocket connecté pour session: $sessionId');
      
    } catch (e) {
      _logger.e('❌ Erreur connexion WebSocket: $e');
      throw ConversationException('Impossible de démarrer le streaming', e.toString());
    }
  }

  /// Envoie des données audio via WebSocket
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (_wsChannel == null) {
      throw ConversationException('WebSocket non connecté', 'Appelez startConversationStream d\'abord');
    }

    try {
      final message = {
        'type': 'audio_chunk',
        'data': base64Encode(audioData),
        'timestamp': DateTime.now().toIso8601String(),
      };

      _wsChannel!.sink.add(json.encode(message));
      _logger.d('🎤 Audio envoyé: ${audioData.length} octets');
      
    } catch (e) {
      _logger.e('❌ Erreur envoi audio: $e');
      throw ConversationException('Impossible d\'envoyer l\'audio', e.toString());
    }
  }

  /// Termine une session de conversation
  Future<ConversationReport> endSession(String sessionId) async {
    try {
      _logger.i('🏁 Fin de session: $sessionId');
      
      // Envoyer signal de fin via WebSocket
      if (_wsChannel != null) {
        final endMessage = {
          'type': 'end_session',
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _wsChannel!.sink.add(json.encode(endMessage));
      }
      
      // Appel API pour récupérer le rapport final
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/sessions/$sessionId/end'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final report = ConversationReport(
          sessionId: data['session_id'],
          exerciseType: data['report']['exercise_type'],
          duration: data['report']['duration']?.toDouble() ?? 0.0,
          interactions: data['report']['interactions'] ?? 0,
          finalConfidenceScore: data['report']['final_confidence_score']?.toDouble() ?? 0.0,
          conversationSummary: data['report']['conversation_summary'] ?? '',
          recommendations: List<String>.from(data['report']['recommendations'] ?? []),
        );
        
        // Fermer WebSocket
        await _closeWebSocket();
        _currentSessionId = null;
        
        _logger.i('✅ Session terminée avec rapport');
        return report;
        
      } else {
        throw ConversationException(
          'Erreur fin session: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      _logger.e('❌ Erreur fin session: $e');
      throw ConversationException('Impossible de terminer la session', e.toString());
    }
  }

  /// Analyse de confiance via API backend
  Future<ConfidenceAnalysis> analyzeConfidence({
    String? text,
    Uint8List? audioData,
    String? sessionId,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (text != null) requestBody['text'] = text;
      if (audioData != null) requestBody['audio_data'] = base64Encode(audioData);
      if (sessionId != null) requestBody['session_id'] = sessionId;
      
      _logger.d('🔍 Analyse confiance: ${text?.length ?? audioData?.length ?? 0}');
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/v1/confidence/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return ConfidenceAnalysis(
          confidenceScore: data['confidence_score']?.toDouble() ?? 0.0,
          overallConfidence: data['analysis']['overall_confidence'] ?? 'low',
          speechMetrics: Map<String, dynamic>.from(data['analysis']['speech_metrics'] ?? {}),
          recommendations: List<String>.from(data['recommendations'] ?? []),
          timestamp: DateTime.parse(data['timestamp']),
          sessionId: data['session_id'],
        );
        
      } else {
        throw ConversationException(
          'Erreur analyse: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      _logger.e('❌ Erreur analyse confiance: $e');
      throw ConversationException('Impossible d\'analyser la confiance', e.toString());
    }
  }

  /// Récupère l'analyse temps réel d'une session
  Future<SessionAnalysis> getSessionAnalysis(String sessionId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/sessions/$sessionId/analysis'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return SessionAnalysis(
          sessionId: data['session_id'],
          metrics: Map<String, dynamic>.from(data['metrics'] ?? {}),
          conversationLength: data['conversation_length'] ?? 0,
          status: data['status'] ?? 'unknown',
          timestamp: DateTime.parse(data['timestamp']),
        );
        
      } else {
        throw ConversationException(
          'Erreur récupération analyse: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      _logger.e('❌ Erreur analyse session: $e');
      throw ConversationException('Impossible de récupérer l\'analyse', e.toString());
    }
  }

  /// Gestion des messages WebSocket
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String?;
      
      switch (type) {
        case 'welcome':
          _eventController?.add(ConversationEvent.welcome(
            character: data['character'] ?? 'IA',
            message: data['message'] ?? '',
            sessionId: data['session_id'] ?? '',
          ));
          break;
          
        case 'conversation_update':
          _eventController?.add(ConversationEvent.conversationUpdate(
            transcription: data['transcription'] ?? '',
            aiResponse: data['ai_response'] ?? '',
            speechAnalysis: Map<String, dynamic>.from(data['speech_analysis'] ?? {}),
            conversationTurn: data['conversation_turn'] ?? 0,
            timestamp: DateTime.parse(data['timestamp']),
          ));
          break;
          
        case 'error':
          _eventController?.add(ConversationEvent.error(
            message: data['message'] ?? 'Erreur inconnue',
          ));
          break;
          
        default:
          _logger.w('⚠️ Type de message WebSocket inconnu: $type');
      }
    } catch (e) {
      _logger.e('❌ Erreur traitement message WebSocket: $e');
      _eventController?.add(ConversationEvent.error(
        message: 'Erreur traitement message: $e',
      ));
    }
  }

  void _handleWebSocketError(dynamic error) {
    _logger.e('❌ Erreur WebSocket: $error');
    _eventController?.add(ConversationEvent.error(
      message: 'Erreur connexion: $error',
    ));
  }

  void _handleWebSocketClosed() {
    _logger.i('🔌 WebSocket fermé');
    _eventController?.add(ConversationEvent.connectionClosed());
  }

  /// Ferme la connexion WebSocket
  Future<void> _closeWebSocket() async {
    await _wsChannel?.sink.close();
    _wsChannel = null;
    await _eventController?.close();
    _eventController = null;
  }

  /// Nettoyage des ressources
  void dispose() {
    _closeWebSocket();
    _httpClient.close();
    _currentSessionId = null;
  }
}

/// Modèles de données

class ConversationSession {
  final String sessionId;
  final String livekitToken;
  final String livekitUrl;
  final String exerciseType;
  final String characterName;
  final String status;

  ConversationSession({
    required this.sessionId,
    required this.livekitToken,
    required this.livekitUrl,
    required this.exerciseType,
    required this.characterName,
    required this.status,
  });
}

class ConversationReport {
  final String sessionId;
  final String exerciseType;
  final double duration;
  final int interactions;
  final double finalConfidenceScore;
  final String conversationSummary;
  final List<String> recommendations;

  ConversationReport({
    required this.sessionId,
    required this.exerciseType,
    required this.duration,
    required this.interactions,
    required this.finalConfidenceScore,
    required this.conversationSummary,
    required this.recommendations,
  });
}

class ConfidenceAnalysis {
  final double confidenceScore;
  final String overallConfidence;
  final Map<String, dynamic> speechMetrics;
  final List<String> recommendations;
  final DateTime timestamp;
  final String? sessionId;

  ConfidenceAnalysis({
    required this.confidenceScore,
    required this.overallConfidence,
    required this.speechMetrics,
    required this.recommendations,
    required this.timestamp,
    this.sessionId,
  });
}

class SessionAnalysis {
  final String sessionId;
  final Map<String, dynamic> metrics;
  final int conversationLength;
  final String status;
  final DateTime timestamp;

  SessionAnalysis({
    required this.sessionId,
    required this.metrics,
    required this.conversationLength,
    required this.status,
    required this.timestamp,
  });
}

/// Événements de conversation
abstract class ConversationEvent {
  const ConversationEvent();

  factory ConversationEvent.welcome({
    required String character,
    required String message,
    required String sessionId,
  }) = WelcomeEvent;

  factory ConversationEvent.conversationUpdate({
    required String transcription,
    required String aiResponse,
    required Map<String, dynamic> speechAnalysis,
    required int conversationTurn,
    required DateTime timestamp,
  }) = ConversationUpdateEvent;

  factory ConversationEvent.error({
    required String message,
  }) = ErrorEvent;

  factory ConversationEvent.connectionClosed() = ConnectionClosedEvent;
}

class WelcomeEvent extends ConversationEvent {
  final String character;
  final String message;
  final String sessionId;

  const WelcomeEvent({
    required this.character,
    required this.message,
    required this.sessionId,
  });
}

class ConversationUpdateEvent extends ConversationEvent {
  final String transcription;
  final String aiResponse;
  final Map<String, dynamic> speechAnalysis;
  final int conversationTurn;
  final DateTime timestamp;

  const ConversationUpdateEvent({
    required this.transcription,
    required this.aiResponse,
    required this.speechAnalysis,
    required this.conversationTurn,
    required this.timestamp,
  });
}

class ErrorEvent extends ConversationEvent {
  final String message;

  const ErrorEvent({required this.message});
}

class ConnectionClosedEvent extends ConversationEvent {
  const ConnectionClosedEvent();
}

/// Exception personnalisée
class ConversationException implements Exception {
  final String message;
  final String details;

  ConversationException(this.message, this.details);

  @override
  String toString() => 'ConversationException: $message ($details)';
}
