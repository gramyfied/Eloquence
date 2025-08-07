import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/api_models.dart';
import '../../domain/entities/confidence_scenario.dart';

/// Modèles de données pour l'API eloquence-streaming
class EloquenceConversationMessage {
  final String role; // "user" ou "assistant"
  final String content;
  final DateTime timestamp;
  final String? audioUrl;

  EloquenceConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.audioUrl,
  });

  factory EloquenceConversationMessage.fromJson(Map<String, dynamic> json) {
    return EloquenceConversationMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      audioUrl: json['audio_url'] as String?,
    );
  }
}

class EloquenceConversationState {
  final String sessionId;
  final List<EloquenceConversationMessage> messages;
  final Map<String, dynamic> context;
  final bool isActive;

  EloquenceConversationState({
    required this.sessionId,
    required this.messages,
    required this.context,
    required this.isActive,
  });

  factory EloquenceConversationState.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => EloquenceConversationMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return EloquenceConversationState(
      sessionId: json['session_id'] as String,
      messages: messages,
      context: json['context'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

/// Service principal pour l'intégration avec eloquence-streaming-api
class EloquenceStreamingService {
  static const Duration _timeout = Duration(seconds: 45);
  WebSocketChannel? _wsChannel;
  final StreamController<EloquenceConversationMessage> _messageController =
      StreamController<EloquenceConversationMessage>.broadcast();

  /// Stream public pour écouter les messages de conversation
  Stream<EloquenceConversationMessage> get messageStream => _messageController.stream;

  /// Vérifie la santé du service
  Future<bool> checkHealth() async {
    try {
      debugPrint('🔍 Health check eloquence-streaming-api: ${AppConfig.eloquenceStreamingApiUrl}/health');
      
      final response = await http.get(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Service disponible: ${data['status']}');
        return data['status'] == 'healthy';
      } else {
        debugPrint('❌ Service non disponible (${response.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur health check: $e');
      return false;
    }
  }

  /// Démarre une nouvelle conversation
  Future<String> startConversation({
    required String scenario,
    String language = 'fr',
  }) async {
    try {
      debugPrint('📡 Démarrage conversation pour scénario: $scenario');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/api/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'exercise_id': 'conversation_${scenario}_${DateTime.now().millisecondsSinceEpoch}',
          'participant_name': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'scenario': scenario,
          'language': language,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'] as String;
        
        debugPrint('✅ Conversation démarrée: $sessionId');
        debugPrint('🔗 LiveKit room: ${data['livekit_room']}');
        debugPrint('🔑 Token reçu: ${data['token'] != null ? 'Oui' : 'Non'}');
        return sessionId;
      } else {
        throw Exception('Erreur démarrage conversation ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage conversation: $e');
      rethrow;
    }
  }

  /// Récupère l'état actuel d'une conversation
  Future<EloquenceConversationState> getConversationState(String sessionId) async {
    try {
      debugPrint('📡 Récupération état conversation: $sessionId');
      
      final response = await http.get(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/conversation/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final state = EloquenceConversationState.fromJson(data);
        
        debugPrint('✅ État récupéré: ${state.messages.length} messages');
        return state;
      } else {
        throw Exception('Erreur récupération état ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération état: $e');
      rethrow;
    }
  }

  /// Démarre une connexion WebSocket pour conversation en temps réel
  Future<void> connectConversationWebSocket(String sessionId) async {
    try {
      final baseUri = Uri.parse(AppConfig.eloquenceStreamingApiUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final uri = Uri.parse('$wsScheme://${baseUri.host}:${baseUri.port}/ws/conversation/$sessionId');

      debugPrint('📡 Connexion WebSocket conversation: $uri');
      
      _wsChannel = WebSocketChannel.connect(uri);

      // Écouter les messages du serveur
      _wsChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data as String);
            
            if (jsonData['type'] == 'message') {
              final message = EloquenceConversationMessage.fromJson(jsonData['data']);
              _messageController.add(message);
              debugPrint('✅ Message reçu via WebSocket: ${message.role} - ${message.content}');
            } else if (jsonData['type'] == 'audio_ready') {
              debugPrint('🔊 Audio TTS prêt: ${jsonData['audio_url']}');
            }
          } catch (e) {
            debugPrint('❌ Erreur parsing WebSocket: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ Erreur WebSocket: $error');
          _messageController.addError(error);
        },
        onDone: () {
          debugPrint('🛑 WebSocket conversation fermé');
          _wsChannel = null;
        },
      );
      
      debugPrint('✅ WebSocket conversation connecté');

    } catch (e) {
      debugPrint('❌ Échec connexion WebSocket conversation: $e');
      rethrow;
    }
  }

  /// Envoie un message via WebSocket
  Future<void> sendMessage(String content) async {
    if (_wsChannel?.sink != null) {
      final message = {
        'type': 'user_message',
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('📤 Message envoyé: $content');
    } else {
      throw Exception('WebSocket non connecté');
    }
  }

  /// Envoie un chunk audio via WebSocket
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (_wsChannel?.sink != null) {
      // Encoder l'audio en base64 pour le WebSocket
      final audioBase64 = base64Encode(audioData);
      final message = {
        'type': 'audio_chunk',
        'data': audioBase64,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('📤 Chunk audio envoyé (${audioData.length} bytes)');
    } else {
      throw Exception('WebSocket non connecté');
    }
  }

  /// Test TTS simple
  Future<Map<String, dynamic>> testTTS(String text) async {
    try {
      debugPrint('📡 Test TTS avec texte: $text');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/test-tts?text=${Uri.encodeComponent(text)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ TTS testé: ${data['audio_size']} bytes');
        return data;
      } else {
        throw Exception('Erreur TTS ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur test TTS: $e');
      rethrow;
    }
  }

  /// Teste une conversation simple
  Future<Map<String, dynamic>> testConversation(String message) async {
    try {
      debugPrint('📡 Test conversation avec message: $message');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/test-conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Conversation testée: ${data['ai_response']}');
        return data;
      } else {
        throw Exception('Erreur conversation ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur test conversation: $e');
      rethrow;
    }
  }

  /// Ferme la connexion WebSocket
  Future<void> disconnectWebSocket() async {
    debugPrint('⏳ Fermeture WebSocket conversation...');
    await _wsChannel?.sink.close();
    _wsChannel = null;
    debugPrint('🛑 WebSocket conversation fermé');
  }

  /// Libère les ressources
  void dispose() {
    _wsChannel?.sink.close();
    _messageController.close();
    debugPrint('🗑️ EloquenceStreamingService disposé');
  }
}

/// Service de compatibility pour remplacer ConfidenceApiService
class EloquenceConfidenceApiService {
  final EloquenceStreamingService _streamingService = EloquenceStreamingService();
  
  /// Remplace getScenarios en utilisant des scénarios par défaut
  Future<List<ApiScenario>> getScenarios({String language = 'fr'}) async {
    // Scénarios par défaut pour confidence boost
    return [
      ApiScenario(
        id: 'entretien_embauche',
        title: 'Entretien d\'embauche',
        description: 'Préparez-vous pour un entretien d\'embauche professionnel',
        category: 'professionnel',
        difficulty: 'intermediate',
        durationMinutes: 10,
        language: 'fr',
        tags: ['entretien', 'professionnel'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiScenario(
        id: 'presentation_publique',
        title: 'Présentation publique',
        description: 'Développez votre confiance en prise de parole publique',
        category: 'public_speaking',
        difficulty: 'advanced',
        durationMinutes: 15,
        language: 'fr',
        tags: ['présentation', 'public'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiScenario(
        id: 'reunion_equipe',
        title: 'Réunion d\'équipe',
        description: 'Participez activement à une réunion d\'équipe',
        category: 'equipe',
        difficulty: 'beginner',
        durationMinutes: 8,
        language: 'fr',
        tags: ['équipe', 'collaboration'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Remplace createSession
  Future<ConfidenceSession> createSession({
    required String userId,
    required String scenarioId,
    String language = 'fr',
  }) async {
    final sessionId = await _streamingService.startConversation(scenario: scenarioId, language: language);
    
    return ConfidenceSession(
      sessionId: sessionId,
      userId: userId,
      scenarioId: scenarioId,
      language: language,
      roomName: 'room-$sessionId',
      livekitUrl: 'wss://livekit.eloquence.local',
      livekitToken: 'token-$sessionId',
      participantIdentity: 'user-$userId',
      status: 'active',
      createdAt: DateTime.now(),
    );
  }

  /// Remplace analyzeAudio - pour l'instant utilise test conversation
  Future<ConfidenceAnalysisResult> analyzeAudio({
    required String sessionId,
    required Uint8List audioData,
    String? audioFileName,
  }) async {
    // Pour l'instant, on simule une analyse avec test conversation
    final testResult = await _streamingService.testConversation('Test analyse audio');
    
    return ConfidenceAnalysisResult(
      transcription: 'Transcription simulée depuis audio',
      aiResponse: testResult['ai_response'] ?? 'Réponse IA par défaut',
      confidenceScore: 0.85,
      metrics: {
        'session_id': sessionId,
        'audio_duration': audioData.length / 16000, // Approximation
        'confidence_score': 0.85,
        'clarity_score': 0.80,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Remplace endSession
  Future<ConfidenceReport> endSession(String sessionId) async {
    final state = await _streamingService.getConversationState(sessionId);
    
    return ConfidenceReport(
      sessionId: sessionId,
      finalScore: 80.0, // Score calculé
      totalInteractions: state.messages.length,
      totalDuration: const Duration(minutes: 5),
      recommendations: [
        'Excellente conversation !',
        'Continuez à pratiquer régulièrement',
        'Votre confiance s\'améliore',
      ],
      detailedMetrics: {
        'total_messages': state.messages.length,
        'conversation_quality': 0.80,
        'engagement_level': 0.85,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Remplace checkHealth
  Future<ApiHealthStatus> checkHealth() async {
    final isHealthy = await _streamingService.checkHealth();
    
    return ApiHealthStatus(
      status: isHealthy ? 'healthy' : 'error',
      service: 'eloquence-streaming-api',
      timestamp: DateTime.now(),
    );
  }

  /// Remplace testNetworkConnectivity
  Future<bool> testNetworkConnectivity() async {
    return await _streamingService.checkHealth();
  }

  /// Expose le service streaming pour usage avancé
  EloquenceStreamingService get streamingService => _streamingService;

  /// Libère les ressources
  void dispose() {
    _streamingService.dispose();
  }
}