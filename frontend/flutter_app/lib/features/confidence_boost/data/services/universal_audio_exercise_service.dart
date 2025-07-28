import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';

/// Configuration d'un exercice audio universel
class AudioExerciseConfig {
  final String exerciseId;
  final String title;
  final String description;
  final String scenario;
  final String language;
  final Duration maxDuration;
  final bool enableRealTimeEvaluation;
  final bool enableTTS;
  final bool enableSTT;
  final Map<String, dynamic> customSettings;

  const AudioExerciseConfig({
    required this.exerciseId,
    required this.title,
    required this.description,
    required this.scenario,
    this.language = 'fr',
    this.maxDuration = const Duration(minutes: 10),
    this.enableRealTimeEvaluation = true,
    this.enableTTS = true,
    this.enableSTT = true,
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'title': title,
      'description': description,
      'scenario': scenario,
      'language': language,
      'max_duration_seconds': maxDuration.inSeconds,
      'enable_real_time_evaluation': enableRealTimeEvaluation,
      'enable_tts': enableTTS,
      'enable_stt': enableSTT,
      'custom_settings': customSettings,
    };
  }
}

/// État d'un exercice audio en cours
class AudioExerciseState {
  final String sessionId;
  final String status; // 'starting', 'active', 'paused', 'completed', 'error'
  final Duration currentDuration;
  final List<AudioExchangeMessage> messages;
  final Map<String, dynamic> realTimeMetrics;
  final double currentScore;

  const AudioExerciseState({
    required this.sessionId,
    required this.status,
    required this.currentDuration,
    required this.messages,
    required this.realTimeMetrics,
    required this.currentScore,
  });

  factory AudioExerciseState.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => AudioExchangeMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return AudioExerciseState(
      sessionId: json['session_id'] as String,
      status: json['status'] as String,
      currentDuration: Duration(seconds: json['current_duration_seconds'] as int? ?? 0),
      messages: messages,
      realTimeMetrics: json['real_time_metrics'] as Map<String, dynamic>? ?? {},
      currentScore: (json['current_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Message d'échange audio bidirectionnel
class AudioExchangeMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String? text;
  final String? audioUrl;
  final DateTime timestamp;
  final Map<String, dynamic> analysisData;
  final double? confidenceScore;
  final Duration? audioDuration;

  const AudioExchangeMessage({
    required this.id,
    required this.role,
    this.text,
    this.audioUrl,
    required this.timestamp,
    this.analysisData = const {},
    this.confidenceScore,
    this.audioDuration,
  });

  factory AudioExchangeMessage.fromJson(Map<String, dynamic> json) {
    return AudioExchangeMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String?,
      audioUrl: json['audio_url'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      analysisData: json['analysis_data'] as Map<String, dynamic>? ?? {},
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      audioDuration: json['audio_duration_seconds'] != null 
          ? Duration(seconds: json['audio_duration_seconds'] as int)
          : null,
    );
  }
}

/// Résultat final d'évaluation d'exercice
class AudioExerciseEvaluation {
  final String sessionId;
  final double overallScore;
  final Map<String, double> detailedScores;
  final List<String> strengths;
  final List<String> improvements;
  final String feedback;
  final Duration totalDuration;
  final int totalExchanges;
  final Map<String, dynamic> prosodyAnalysis;
  final Map<String, dynamic> conversationQuality;

  const AudioExerciseEvaluation({
    required this.sessionId,
    required this.overallScore,
    required this.detailedScores,
    required this.strengths,
    required this.improvements,
    required this.feedback,
    required this.totalDuration,
    required this.totalExchanges,
    required this.prosodyAnalysis,
    required this.conversationQuality,
  });

  factory AudioExerciseEvaluation.fromJson(Map<String, dynamic> json) {
    return AudioExerciseEvaluation(
      sessionId: json['session_id'] as String,
      overallScore: (json['overall_score'] as num).toDouble(),
      detailedScores: Map<String, double>.from(
        (json['detailed_scores'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      strengths: List<String>.from(json['strengths'] as List<dynamic>),
      improvements: List<String>.from(json['improvements'] as List<dynamic>),
      feedback: json['feedback'] as String,
      totalDuration: Duration(seconds: json['total_duration_seconds'] as int),
      totalExchanges: json['total_exchanges'] as int,
      prosodyAnalysis: json['prosody_analysis'] as Map<String, dynamic>? ?? {},
      conversationQuality: json['conversation_quality'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Service universel pour exercices audio bidirectionnels avec évaluation
class UniversalAudioExerciseService {
  static const Duration _timeout = Duration(seconds: 45);
  static const Duration _virelangueTimeout = Duration(seconds: 60);
  WebSocketChannel? _wsChannel;
  
  // Streams pour les différents types d'événements
  final StreamController<AudioExerciseState> _stateController =
      StreamController<AudioExerciseState>.broadcast();
  final StreamController<AudioExchangeMessage> _messageController =
      StreamController<AudioExchangeMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _realTimeMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream d'état de l'exercice
  Stream<AudioExerciseState> get stateStream => _stateController.stream;
  
  /// Stream des messages d'échange
  Stream<AudioExchangeMessage> get messageStream => _messageController.stream;
  
  /// Stream des métriques en temps réel
  Stream<Map<String, dynamic>> get realTimeMetricsStream => _realTimeMetricsController.stream;

  /// Vérifie la santé du service
  Future<bool> checkHealth() async {
    try {
      debugPrint('🔍 Health check service universel: ${AppConfig.eloquenceStreamingApiUrl}/health');
      
      final response = await http.get(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Service universel disponible: ${data['status']}');
        return data['status'] == 'healthy';
      } else {
        debugPrint('❌ Service universel non disponible (${response.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur health check service universel: $e');
      return false;
    }
  }

  /// Démarre un nouvel exercice audio
  Future<String> startExercise(AudioExerciseConfig config) async {
    try {
      final apiUrl = AppConfig.eloquenceStreamingApiUrl;
      debugPrint('📡 Démarrage exercice audio: ${config.exerciseId}');
      debugPrint('🔗 URL utilisée: $apiUrl/start-conversation');
      
      final response = await http.post(
        Uri.parse('$apiUrl/start-conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'scenario': config.scenario,
          'language': config.language,
          'exercise_config': config.toJson(),
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'] as String;
        
        debugPrint('✅ Exercice audio démarré: $sessionId');
        return sessionId;
      } else {
        throw Exception('Erreur démarrage exercice ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage exercice: $e');
      rethrow;
    }
  }

  /// Connecte le WebSocket bidirectionnel pour l'exercice
  Future<void> connectExerciseWebSocket(String sessionId) async {
    try {
      final baseUri = Uri.parse(AppConfig.eloquenceStreamingApiUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final uri = Uri.parse('$wsScheme://${baseUri.host}:${baseUri.port}/ws/conversation/$sessionId');

      debugPrint('📡 Connexion WebSocket exercice: $uri');
      
      _wsChannel = WebSocketChannel.connect(uri);

      // Écouter les événements du serveur
      _wsChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data as String);
            final eventType = jsonData['type'] as String;
            
            switch (eventType) {
              case 'exercise_state':
                final state = AudioExerciseState.fromJson(jsonData['data']);
                _stateController.add(state);
                debugPrint('✅ État exercice mis à jour: ${state.status}');
                break;
                
              case 'message':
                final message = AudioExchangeMessage.fromJson(jsonData['data']);
                _messageController.add(message);
                debugPrint('✅ Nouveau message: ${message.role} - ${message.text}');
                break;
                
              case 'real_time_metrics':
                final metrics = jsonData['data'] as Map<String, dynamic>;
                _realTimeMetricsController.add(metrics);
                debugPrint('📊 Métriques temps réel: score=${metrics['current_score']}');
                break;
                
              case 'ai_response':
                // Réponse IA reçue - la traiter comme un message
                final text = jsonData['text'] as String?;
                final audioData = jsonData['audio_data'] as String?;
                final timestamp = jsonData['timestamp'] as double?;
                
                if (text != null) {
                  final message = AudioExchangeMessage(
                    id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
                    role: 'assistant',
                    text: text,
                    timestamp: timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).round())
                        : DateTime.now(),
                    analysisData: {
                      'has_audio': audioData != null,
                      'audio_format': jsonData['audio_format'],
                    },
                  );
                  
                  _messageController.add(message);
                  debugPrint('🤖 Réponse IA reçue: $text');
                  
                  if (audioData != null) {
                    debugPrint('🔊 Audio IA reçu (${audioData.length} chars base64)');
                  }
                }
                break;
                
              case 'connection_established':
                debugPrint('🔗 Connexion WebSocket établie avec succès');
                // Envoyer un message initial pour démarrer la conversation
                Future.microtask(() async {
                  await sendTextMessage("Bonjour ! Je suis prêt à commencer l'exercice de conversation.");
                });
                break;
                
              case 'audio_ready':
                debugPrint('🔊 Audio TTS prêt: ${jsonData['audio_url']}');
                break;
                
              case 'analysis_complete':
                debugPrint('🧠 Analyse audio terminée: ${jsonData['confidence_score']}');
                break;
                
              default:
                debugPrint('ℹ️ Événement non géré: $eventType');
            }
          } catch (e) {
            debugPrint('❌ Erreur parsing WebSocket exercice: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ Erreur WebSocket exercice: $error');
          _stateController.addError(error);
        },
        onDone: () {
          debugPrint('🛑 WebSocket exercice fermé');
          _wsChannel = null;
        },
      );
      
      debugPrint('✅ WebSocket exercice connecté');

    } catch (e) {
      debugPrint('❌ Échec connexion WebSocket exercice: $e');
      rethrow;
    }
  }

  /// Envoie un chunk audio pour analyse en temps réel
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (_wsChannel?.sink != null) {
      final audioBase64 = base64Encode(audioData);
      final message = {
        'type': 'audio_chunk',
        'data': audioBase64,
        'timestamp': DateTime.now().toIso8601String(),
        'format': 'wav', // Spécifier le format
        'sample_rate': 16000, // Spécifier le taux d'échantillonnage
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('📤 Chunk audio envoyé (${audioData.length} bytes)');
    } else {
      throw Exception('WebSocket exercice non connecté');
    }
  }

  /// Envoie un fichier audio complet pour analyse
  Future<Map<String, dynamic>> sendCompleteAudio({
    required String sessionId,
    required Uint8List audioData,
    String? fileName,
  }) async {
    try {
      debugPrint('📡 Envoi audio complet (${audioData.length} bytes) pour session: $sessionId');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/analyze-audio'),
      );
      
      // Headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'X-Session-ID': sessionId,
      });
      
      // Fichier audio
      final audioFileName = fileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioData,
        filename: audioFileName,
      ));
      
      // Envoyer la requête
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Analyse audio terminée');
        return data;
      } else {
        throw Exception('Erreur analyse audio ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi audio: $e');
      rethrow;
    }
  }

  /// Analyse spécifique pour virelangues avec évaluation détaillée
  Future<Map<String, dynamic>> analyzeVirelanguePronunciation({
    required String sessionId,
    required Uint8List audioData,
    required String virelangueText,
    required List<String> targetSounds,
    String? fileName,
  }) async {
    try {
      debugPrint('🎭 Analyse virelangue pour session: $sessionId');
      debugPrint('🎯 Texte cible: $virelangueText');
      debugPrint('🔊 Sons ciblés: ${targetSounds.join(', ')}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/analyze-virelangue'),
      );
      
      // Headers spécifiques aux virelangues
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'X-Session-ID': sessionId,
        'X-Analysis-Type': 'virelangue',
      });
      
      // Fichier audio
      final audioFileName = fileName ?? 'virelangue_${DateTime.now().millisecondsSinceEpoch}.wav';
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioData,
        filename: audioFileName,
      ));
      
      // Paramètres spécifiques aux virelangues
      request.fields.addAll({
        'target_text': virelangueText,
        'target_sounds': jsonEncode(targetSounds),
        'analysis_focus': 'pronunciation_accuracy',
        'enable_phoneme_analysis': 'true',
        'enable_fluency_metrics': 'true',
      });
      
      // Envoyer la requête avec timeout spécial pour virelangues
      final streamedResponse = await request.send().timeout(_virelangueTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Analyse virelangue terminée - Score: ${data['overall_score']}');
        return data;
      } else {
        throw Exception('Erreur analyse virelangue ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur analyse virelangue: $e');
      rethrow;
    }
  }

  /// Demande la génération d'un virelangue personnalisé
  Future<Map<String, dynamic>> generateCustomVirelangue({
    required String sessionId,
    required List<String> targetSounds,
    String difficulty = 'medium',
    String? theme,
  }) async {
    try {
      debugPrint('🤖 Génération virelangue personnalisé pour session: $sessionId');
      debugPrint('🎯 Sons ciblés: ${targetSounds.join(', ')}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/generate-virelangue'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
        },
        body: jsonEncode({
          'target_sounds': targetSounds,
          'difficulty': difficulty,
          'theme': theme,
          'language': 'fr',
          'max_length': 50, // Limite de caractères
          'style': 'ludique',
        }),
      ).timeout(_virelangueTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Virelangue généré: ${data['text']}');
        return data;
      } else {
        throw Exception('Erreur génération virelangue ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur génération virelangue: $e');
      rethrow;
    }
  }

  /// Calcule et envoie les récompenses de gemmes
  Future<Map<String, dynamic>> calculateGemRewards({
    required String sessionId,
    required double pronunciationScore,
    required int currentCombo,
    required String difficulty,
    bool isSpecialEvent = false,
  }) async {
    try {
      debugPrint('💎 Calcul récompenses gemmes pour session: $sessionId');
      debugPrint('📊 Score: $pronunciationScore, Combo: $currentCombo');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/calculate-gem-rewards'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
        },
        body: jsonEncode({
          'pronunciation_score': pronunciationScore,
          'current_combo': currentCombo,
          'difficulty': difficulty,
          'is_special_event': isSpecialEvent,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Récompenses calculées: ${data['gems_earned']} gemmes');
        return data;
      } else {
        throw Exception('Erreur calcul récompenses ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur calcul récompenses: $e');
      rethrow;
    }
  }

  /// Obtient la liste des virelangues disponibles
  Future<List<Map<String, dynamic>>> getAvailableVirelangues({
    String? difficulty,
    List<String>? targetSounds,
    int limit = 8,
  }) async {
    try {
      debugPrint('📋 Récupération virelangues disponibles');
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (difficulty != null) {
        queryParams['difficulty'] = difficulty;
      }
      
      if (targetSounds != null && targetSounds.isNotEmpty) {
        queryParams['target_sounds'] = targetSounds.join(',');
      }
      
      final uri = Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/virelangues')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final virelangues = List<Map<String, dynamic>>.from(data['virelangues']);
        debugPrint('✅ ${virelangues.length} virelangues récupérés');
        return virelangues;
      } else {
        throw Exception('Erreur récupération virelangues ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération virelangues: $e');
      rethrow;
    }
  }

  /// Envoie un message texte
  Future<void> sendTextMessage(String content) async {
    if (_wsChannel?.sink != null) {
      final message = {
        'type': 'user_message',
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('📤 Message texte envoyé: $content');
    } else {
      throw Exception('WebSocket exercice non connecté');
    }
  }

  /// Met en pause l'exercice
  Future<void> pauseExercise(String sessionId) async {
    if (_wsChannel?.sink != null) {
      final message = {
        'type': 'pause_exercise',
        'session_id': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('⏸️ Exercice mis en pause');
    }
  }

  /// Reprend l'exercice
  Future<void> resumeExercise(String sessionId) async {
    if (_wsChannel?.sink != null) {
      final message = {
        'type': 'resume_exercise',
        'session_id': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('▶️ Exercice repris');
    }
  }

  /// Termine l'exercice et récupère l'évaluation finale
  Future<AudioExerciseEvaluation> completeExercise(String sessionId) async {
    try {
      debugPrint('📡 Finalisation exercice: $sessionId');
      
      final response = await http.post(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/complete-exercise'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final evaluation = AudioExerciseEvaluation.fromJson(data);
        
        debugPrint('✅ Exercice terminé - Score final: ${evaluation.overallScore}');
        return evaluation;
      } else {
        throw Exception('Erreur finalisation exercice ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur finalisation exercice: $e');
      rethrow;
    }
  }

  /// Récupère l'état actuel de l'exercice
  Future<AudioExerciseState> getExerciseState(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.eloquenceStreamingApiUrl}/conversation/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final state = AudioExerciseState.fromJson(data);
        
        debugPrint('✅ État exercice récupéré: ${state.status}');
        return state;
      } else {
        throw Exception('Erreur récupération état ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération état exercice: $e');
      rethrow;
    }
  }

  /// Ferme la connexion WebSocket
  Future<void> disconnectWebSocket() async {
    debugPrint('⏳ Fermeture WebSocket exercice...');
    await _wsChannel?.sink.close();
    _wsChannel = null;
    debugPrint('🛑 WebSocket exercice fermé');
  }

  /// Libère toutes les ressources
  void dispose() {
    _wsChannel?.sink.close();
    _stateController.close();
    _messageController.close();
    _realTimeMetricsController.close();
    debugPrint('🗑️ UniversalAudioExerciseService disposé');
  }
}

/// Types d'exercices audio disponibles
enum AudioExerciseType {
  jobInterview,
  publicSpeaking,
  casualConversation,
  debate,
  virelangueRoulette, // Nouveau type pour les virelangues
}

/// Exemples de configurations d'exercices prédéfinis
class AudioExerciseTemplates {
  /// Exercice d'entretien d'embauche
  static AudioExerciseConfig get jobInterview => const AudioExerciseConfig(
    exerciseId: 'job_interview',
    title: 'Entretien d\'embauche',
    description: 'Simulez un entretien d\'embauche professionnel',
    scenario: 'entretien_embauche',
    maxDuration: Duration(minutes: 15),
    customSettings: {
      'difficulty': 'intermediate',
      'focus_areas': ['confidence', 'articulation', 'response_quality'],
      'exercise_type': 'job_interview',
    },
  );

  /// Exercice de présentation publique
  static AudioExerciseConfig get publicSpeaking => const AudioExerciseConfig(
    exerciseId: 'public_speaking',
    title: 'Prise de parole publique',
    description: 'Développez votre aisance en prise de parole publique',
    scenario: 'presentation_publique',
    maxDuration: Duration(minutes: 12),
    customSettings: {
      'difficulty': 'advanced',
      'focus_areas': ['voice_projection', 'engagement', 'clarity'],
      'exercise_type': 'public_speaking',
    },
  );

  /// Exercice de conversation informelle
  static AudioExerciseConfig get casualConversation => const AudioExerciseConfig(
    exerciseId: 'casual_conversation',
    title: 'Conversation décontractée',
    description: 'Pratiquez une conversation naturelle et fluide',
    scenario: 'conversation_informelle',
    maxDuration: Duration(minutes: 8),
    customSettings: {
      'difficulty': 'beginner',
      'focus_areas': ['fluency', 'naturalness', 'listening'],
      'exercise_type': 'casual_conversation',
    },
  );

  /// Exercice de débat
  static AudioExerciseConfig get debate => const AudioExerciseConfig(
    exerciseId: 'debate',
    title: 'Débat argumenté',
    description: 'Défendez vos idées dans un débat constructif',
    scenario: 'debat_argumente',
    maxDuration: Duration(minutes: 20),
    customSettings: {
      'difficulty': 'expert',
      'focus_areas': ['argumentation', 'persuasion', 'counter_arguments'],
      'exercise_type': 'debate',
    },
  );

  /// Exercice de virelangues magiques
  static AudioExerciseConfig get virelangueRoulette => const AudioExerciseConfig(
    exerciseId: 'virelangue_roulette',
    title: 'Roulette des Virelangues Magiques',
    description: 'Perfectionnez votre prononciation avec des virelangues ludiques et collectez des gemmes',
    scenario: 'virelangue_training',
    maxDuration: Duration(minutes: 10),
    enableRealTimeEvaluation: true,
    enableTTS: false, // Pas besoin de TTS pour les virelangues
    enableSTT: true,
    customSettings: {
      'difficulty': 'adaptive',
      'focus_areas': ['pronunciation', 'articulation', 'phoneme_accuracy'],
      'exercise_type': 'virelangue_roulette',
      'enable_gem_rewards': true,
      'enable_combo_system': true,
      'max_virelangues_per_session': 8,
      'target_accuracy': 0.75,
      'gem_multiplier': 1.0,
    },
  );

  /// Créer une configuration personnalisée pour les virelangues
  static AudioExerciseConfig createVirelangueConfig({
    List<String>? targetSounds,
    String difficulty = 'adaptive',
    bool enableCustomGeneration = true,
    double gemMultiplier = 1.0,
    int maxVirelangues = 8,
  }) {
    return AudioExerciseConfig(
      exerciseId: 'virelangue_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Virelangues Personnalisés',
      description: 'Entraînement ciblé sur vos difficultés spécifiques',
      scenario: 'virelangue_custom',
      maxDuration: Duration(minutes: maxVirelangues * 2), // 2 min par virelangue
      enableRealTimeEvaluation: true,
      enableTTS: false,
      enableSTT: true,
      customSettings: {
        'difficulty': difficulty,
        'focus_areas': ['pronunciation', 'articulation'],
        'exercise_type': 'virelangue_roulette',
        'target_sounds': targetSounds,
        'enable_custom_generation': enableCustomGeneration,
        'enable_gem_rewards': true,
        'gem_multiplier': gemMultiplier,
        'max_virelangues_per_session': maxVirelangues,
      },
    );
  }

  /// Liste de tous les templates
  static List<AudioExerciseConfig> get all => [
    jobInterview,
    publicSpeaking,
    casualConversation,
    debate,
    virelangueRoulette,
  ];

  /// Obtenir un template par type
  static AudioExerciseConfig getByType(AudioExerciseType type) {
    switch (type) {
      case AudioExerciseType.jobInterview:
        return jobInterview;
      case AudioExerciseType.publicSpeaking:
        return publicSpeaking;
      case AudioExerciseType.casualConversation:
        return casualConversation;
      case AudioExerciseType.debate:
        return debate;
      case AudioExerciseType.virelangueRoulette:
        return virelangueRoulette;
    }
  }
}