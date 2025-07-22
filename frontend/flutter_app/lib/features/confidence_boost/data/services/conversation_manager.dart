import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/ai_character_models.dart';
import 'conversation_engine.dart';
import 'ai_character_factory.dart';
import 'robust_livekit_service.dart';
import 'adaptive_ai_character_service.dart';
import 'vosk_analysis_service.dart';

/// Gestionnaire de conversation temps réel avec LiveKit
/// 
/// ✅ FONCTIONNALITÉS :
/// - Gestion des tours de parole entre utilisateur et IA
/// - Intégration VOSK pour la transcription temps réel
/// - Coordination avec ConversationEngine pour les réponses Mistral
/// - Gestion des états de conversation
/// - Support du streaming audio bidirectionnel
class ConversationManager {
  static const String _tag = 'ConversationManager';
  final Logger _logger = Logger();
  
  // Services
  final ConversationEngine _conversationEngine;
  final AICharacterFactory _characterFactory;
  final RobustLiveKitService _liveKitService;
  final AdaptiveAICharacterService _aiCharacterService;
  final VoskAnalysisService _voskAnalysisService;
  
  // État de la conversation
  ConversationState _state = ConversationState.idle;

  ConversationManager({
    ConversationEngine? conversationEngine,
    AICharacterFactory? characterFactory,
    RobustLiveKitService? liveKitService,
    AdaptiveAICharacterService? aiCharacterService,
    VoskAnalysisService? voskAnalysisService,
  })  : _conversationEngine = conversationEngine ?? ConversationEngine(),
        _characterFactory = characterFactory ?? AICharacterFactory(),
        _liveKitService = liveKitService ?? RobustLiveKitService(),
        _aiCharacterService = aiCharacterService ?? AdaptiveAICharacterService(),
        _voskAnalysisService = voskAnalysisService ?? VoskAnalysisService();
  ConfidenceScenario? _currentScenario;
  UserAdaptiveProfile? _userProfile;
  AICharacterInstance? _aiCharacter;
  
  // Streams et controllers
  final StreamController<ConversationEvent> _eventController = StreamController<ConversationEvent>.broadcast();
  final StreamController<TranscriptionSegment> _transcriptionController = StreamController<TranscriptionSegment>.broadcast();
  final StreamController<ConversationMetrics> _metricsController = StreamController<ConversationMetrics>.broadcast();
  
  // Buffers audio
  final List<Uint8List> _audioBuffer = [];
  Timer? _silenceDetectionTimer;
  static const Duration _silenceThreshold = Duration(seconds: 2);
  
  // Métriques temps réel
  DateTime? _conversationStartTime;
  DateTime? _lastUserSpeechTime;
  int _turnCount = 0;
  double _averageResponseTime = 0;

  /// Stream des événements de conversation
  Stream<ConversationEvent> get events => _eventController.stream;
  
  /// Stream des transcriptions en temps réel
  Stream<TranscriptionSegment> get transcriptions => _transcriptionController.stream;
  
  /// Stream des métriques de conversation
  Stream<ConversationMetrics> get metrics => _metricsController.stream;
  
  /// État actuel de la conversation
  ConversationState get state => _state;

  /// Initialise une nouvelle conversation
  Future<bool> initializeConversation({
    required ConfidenceScenario scenario,
    required UserAdaptiveProfile userProfile,
    required String livekitUrl,
    required String livekitToken,
    AICharacterType? preferredCharacter,
  }) async {
    try {
      _logger.i('🚀 [$_tag] Initialisation conversation pour ${scenario.title}');
      
      _currentScenario = scenario;
      _userProfile = userProfile;
      _conversationStartTime = DateTime.now();
      _turnCount = 0;
      
      // Créer le personnage IA
      _aiCharacter = _characterFactory.createCharacter(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: preferredCharacter,
      );
      
      // Initialiser les services
      await _aiCharacterService.initialize();
      await _conversationEngine.initialize(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: _aiCharacter!.type,
      );
      
      // Connecter à LiveKit
      final livekitConnected = await _liveKitService.initialize(
        livekitUrl: livekitUrl,
        livekitToken: livekitToken,
        isMobileOptimized: true,
      );
      
      if (!livekitConnected) {
        _logger.e('❌ [$_tag] Échec connexion LiveKit');
        _emitEvent(ConversationEventType.error, data: 'Échec connexion LiveKit');
        return false;
      }
      
      _setState(ConversationState.ready);
      _emitEvent(ConversationEventType.initialized);
      
      _logger.i('✅ [$_tag] Conversation initialisée avec succès');
      return true;
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur initialisation: $e');
      _emitEvent(ConversationEventType.error, data: e.toString());
      return false;
    }
  }

  /// Démarre la conversation
  Future<void> startConversation() async {
    if (_state != ConversationState.ready) {
      _logger.w('[$_tag] Impossible de démarrer, état: $_state');
      return;
    }
    
    try {
      _setState(ConversationState.aiSpeaking);
      _emitEvent(ConversationEventType.conversationStarted);
      
      // Générer l'introduction du personnage IA
      final introduction = await _conversationEngine.generateIntroduction();
      
      // Émettre le message IA
      _emitEvent(
        ConversationEventType.aiMessage,
        data: {
          'message': introduction.message,
          'character': introduction.character.name,
          'emotion': introduction.emotionalState.name,
          'suggestions': introduction.suggestedUserResponses,
        },
      );
      
      // TODO: Synthétiser et jouer l'audio via TTS
      await _playAIResponse(introduction.message);
      
      // Passer en mode écoute
      _setState(ConversationState.userSpeaking);
      _startListening();
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur démarrage conversation: $e');
      _emitEvent(ConversationEventType.error, data: e.toString());
    }
  }

  /// Démarre l'écoute de l'utilisateur avec LiveKit
  void _startListening() {
    _logger.d('🎤 [$_tag] Démarrage écoute utilisateur via LiveKit');
    
    _audioBuffer.clear();
    _lastUserSpeechTime = DateTime.now();
    
    // Activer la publication du microphone
    _liveKitService.publishMyAudio().catchError((e) {
      _logger.w('[$_tag] Erreur activation microphone: $e');
    });
    
    // Écouter le stream audio entrant
    _setupAudioStreamListener();
    
    // Démarrer la détection de silence
    _startSilenceDetection();
    
    _emitEvent(ConversationEventType.listeningStarted);
  }

  /// Configure l'écoute du stream audio LiveKit
  void _setupAudioStreamListener() {
    _liveKitService.onAudioReceivedStream.listen(
      (audioData) {
        if (_state == ConversationState.userSpeaking) {
          processUserAudio(audioData);
        }
      },
      onError: (error) {
        _logger.e('❌ [$_tag] Erreur stream audio: $error');
      },
    );
  }

  /// Traite l'audio reçu de l'utilisateur
  Future<void> processUserAudio(Uint8List audioData) async {
    if (_state != ConversationState.userSpeaking) return;
    
    _audioBuffer.add(audioData);
    _lastUserSpeechTime = DateTime.now();
    
    // TODO: Envoyer à VOSK pour transcription temps réel
    // Pour l'instant, simuler une transcription partielle
    _emitTranscription(
      text: '[Transcription en cours...]',
      isFinal: false,
      confidence: 0.0,
    );
  }

  /// Détection de silence pour fin de tour de parole
  void _startSilenceDetection() {
    _silenceDetectionTimer?.cancel();
    _silenceDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkSilence(),
    );
  }

  /// Vérifie si l'utilisateur a fini de parler
  void _checkSilence() {
    if (_lastUserSpeechTime == null) return;
    
    final silenceDuration = DateTime.now().difference(_lastUserSpeechTime!);
    
    if (silenceDuration >= _silenceThreshold) {
      _logger.d('🔇 [$_tag] Silence détecté, fin du tour utilisateur');
      _silenceDetectionTimer?.cancel();
      _processUserTurn();
    }
  }

  /// Traite le tour de parole de l'utilisateur
  Future<void> _processUserTurn() async {
    if (_audioBuffer.isEmpty) return;
    
    try {
      _setState(ConversationState.processing);
      _emitEvent(ConversationEventType.processingStarted);
      
      // Combiner les buffers audio
      final combinedAudio = _combineAudioBuffers(_audioBuffer);
      
      // Analyser avec VOSK direct
      final startTime = DateTime.now();
      final voskResult = await _voskAnalysisService.analyzeAudio(combinedAudio);
      
      final processingTime = DateTime.now().difference(startTime);
      _updateMetrics(processingTime);
      
      if (voskResult.errorMessage != null) {
        _logger.w('[$_tag] Analyse VOSK échouée: ${voskResult.errorMessage}');
        _emitTranscription(
          text: '[Erreur transcription]',
          isFinal: true,
          confidence: 0.0,
        );
        return;
      }
      
      // Émettre la transcription finale avec scores réalistes
      _emitTranscription(
        text: voskResult.transcription,
        isFinal: true,
        confidence: voskResult.confidence,
      );
      
      // Générer la réponse IA
      _setState(ConversationState.aiThinking);
      final aiResponse = await _conversationEngine.generateResponse(
        userInput: voskResult.transcription,
        conversationHistory: _conversationEngine.getConversationHistory(),
        scenario: _currentScenario!,
        character: _aiCharacter!.type,
        userProfile: _userProfile!,
      );
      
      // Émettre la réponse IA
      _setState(ConversationState.aiSpeaking);
      _emitEvent(
        ConversationEventType.aiMessage,
        data: {
          'message': aiResponse,
          'character': _aiCharacter!.type.displayName,
          'emotion': 'analytical', // TODO: Get emotion from a service
        },
      );
      
      // Jouer la réponse audio
      await _playAIResponse(aiResponse);
      
      // Incrémenter le nombre de tours
      _turnCount++;
      
      // Continuer l'écoute si nécessaire
      // Pour l'instant, on continue toujours
      _setState(ConversationState.userSpeaking);
      _startListening();
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur traitement tour utilisateur: $e');
      _emitEvent(ConversationEventType.error, data: e.toString());
      _setState(ConversationState.ready);
    }
  }

  /// Joue la réponse audio de l'IA via TTS OpenAI + LiveKit streaming
  Future<void> _playAIResponse(String text) async {
    try {
      _logger.d('🔊 [$_tag] Synthèse TTS + streaming LiveKit pour: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      // Appel au service TTS OpenAI
      final ttsUrl = AppConfig.azureTtsUrl;
      final response = await http.post(
        Uri.parse('$ttsUrl/synthesize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': text,
          'voice': 'nova', // Voix féminine pour Marie
          'format': 'wav',
          'speed': 1.0,
        }),
      );
      
      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        _logger.i('✅ [$_tag] Audio TTS généré (${audioBytes.length} bytes)');
        
        // Diffuser l'audio via LiveKit si connecté
        if (_liveKitService.healthCheck() != null) {
          await _streamAudioToLiveKit(audioBytes);
        } else {
          _logger.w('⚠️ [$_tag] LiveKit non connecté, lecture locale simulée');
          final estimatedDuration = Duration(
            milliseconds: (audioBytes.length / 16000 * 1000).round(),
          );
          await Future.delayed(estimatedDuration);
        }
        
        _logger.d('🔊 [$_tag] Réponse IA jouée via TTS + LiveKit');
      } else {
        _logger.w('⚠️ [$_tag] Échec TTS (${response.statusCode}), fallback simulation');
        await _fallbackSimulatedAudio(text);
      }
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur TTS + LiveKit: $e, fallback simulation');
      await _fallbackSimulatedAudio(text);
    }
  }

  /// Diffuse l'audio TTS via LiveKit
  Future<void> _streamAudioToLiveKit(Uint8List audioBytes) async {
    try {
      _logger.d('🎵 [$_tag] Streaming audio TTS vers LiveKit (${audioBytes.length} bytes)');
      
      // Utiliser les nouvelles méthodes publiques du RobustLiveKitService
      await _liveKitService.streamAudioData(audioBytes);
      
      _logger.i('✅ [$_tag] Audio TTS diffusé via LiveKit');
      
    } catch (e) {
      _logger.e('❌ [$_tag] Erreur diffusion LiveKit: $e');
      // Fallback local
      await Future.delayed(Duration(milliseconds: audioBytes.length ~/ 32));
    }
  }

  /// Fallback audio simulé
  Future<void> _fallbackSimulatedAudio(String text) async {
    final speakingDuration = Duration(
      milliseconds: text.length * 50, // ~50ms par caractère
    );
    await Future.delayed(speakingDuration);
  }

  /// Combine plusieurs buffers audio en un seul
  Uint8List _combineAudioBuffers(List<Uint8List> buffers) {
    final totalLength = buffers.fold<int>(0, (sum, buffer) => sum + buffer.length);
    final combined = Uint8List(totalLength);
    
    int offset = 0;
    for (final buffer in buffers) {
      combined.setRange(offset, offset + buffer.length, buffer);
      offset += buffer.length;
    }
    
    return combined;
  }

  /// Met à jour les métriques de conversation
  void _updateMetrics(Duration responseTime) {
    _averageResponseTime = (_averageResponseTime * (_turnCount - 1) + responseTime.inMilliseconds) / _turnCount;
    
    final metrics = ConversationMetrics(
      totalDuration: DateTime.now().difference(_conversationStartTime!),
      turnCount: _turnCount,
      averageResponseTime: Duration(milliseconds: _averageResponseTime.round()),
      currentState: _state,
    );
    
    _metricsController.add(metrics);
  }

  /// Change l'état de la conversation
  void _setState(ConversationState newState) {
    _logger.d('[$_tag] État: $_state → $newState');
    _state = newState;
    _emitEvent(ConversationEventType.stateChanged, data: newState.name);
  }

  /// Émet un événement de conversation
  void _emitEvent(ConversationEventType type, {dynamic data}) {
    final event = ConversationEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    _eventController.add(event);
  }

  /// Émet une transcription
  void _emitTranscription({
    required String text,
    required bool isFinal,
    required double confidence,
  }) {
    final segment = TranscriptionSegment(
      text: text,
      isFinal: isFinal,
      confidence: confidence,
      timestamp: DateTime.now(),
    );
    _transcriptionController.add(segment);
  }

  /// Met en pause la conversation
  void pauseConversation() {
    if (_state == ConversationState.userSpeaking || 
        _state == ConversationState.aiSpeaking) {
      _silenceDetectionTimer?.cancel();
      _setState(ConversationState.paused);
      _emitEvent(ConversationEventType.conversationPaused);
    }
  }

  /// Reprend la conversation
  void resumeConversation() {
    if (_state == ConversationState.paused) {
      _setState(ConversationState.userSpeaking);
      _startListening();
      _emitEvent(ConversationEventType.conversationResumed);
    }
  }

  /// Termine la conversation
  Future<ConversationSummary> endConversation() async {
    _logger.i('🏁 [$_tag] Fin de conversation');
    
    _silenceDetectionTimer?.cancel();
    _setState(ConversationState.ended);
    _emitEvent(ConversationEventType.conversationEnded);
    
    // Créer le résumé
    final summary = ConversationSummary(
      scenario: _currentScenario!,
      character: _aiCharacter!.type,
      totalDuration: DateTime.now().difference(_conversationStartTime!),
      turnCount: _turnCount,
      averageResponseTime: Duration(milliseconds: _averageResponseTime.round()),
      conversationHistory: _conversationEngine.getConversationHistory(),
    );
    
    // Nettoyer les ressources
    await dispose();
    
    return summary;
  }

  /// Libère les ressources
  Future<void> dispose() async {
    _logger.i('🧹 [$_tag] Nettoyage des ressources');
    
    _silenceDetectionTimer?.cancel();
    _audioBuffer.clear();
    
    await _eventController.close();
    await _transcriptionController.close();
    await _metricsController.close();
    
    await _liveKitService.dispose();
    _conversationEngine.reset();
  }
}

/// États de la conversation
enum ConversationState {
  idle,           // En attente d'initialisation
  ready,          // Prêt à démarrer
  aiSpeaking,     // L'IA parle
  userSpeaking,   // L'utilisateur parle
  processing,     // Traitement en cours
  aiThinking,     // L'IA génère une réponse
  paused,         // Conversation en pause
  ended,          // Conversation terminée
}

/// Types d'événements de conversation
enum ConversationEventType {
  initialized,
  conversationStarted,
  conversationEnded,
  conversationPaused,
  conversationResumed,
  listeningStarted,
  listeningEnded,
  processingStarted,
  processingCompleted,
  aiMessage,
  userMessage,
  stateChanged,
  error,
}

/// Événement de conversation
class ConversationEvent {
  final ConversationEventType type;
  final DateTime timestamp;
  final dynamic data;

  ConversationEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

/// Segment de transcription
class TranscriptionSegment {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;

  TranscriptionSegment({
    required this.text,
    required this.isFinal,
    required this.confidence,
    required this.timestamp,
  });
}

/// Métriques de conversation
class ConversationMetrics {
  final Duration totalDuration;
  final int turnCount;
  final Duration averageResponseTime;
  final ConversationState currentState;

  ConversationMetrics({
    required this.totalDuration,
    required this.turnCount,
    required this.averageResponseTime,
    required this.currentState,
  });
}

/// Résumé de conversation
class ConversationSummary {
  final ConfidenceScenario scenario;
  final AICharacterType character;
  final Duration totalDuration;
  final int turnCount;
  final Duration averageResponseTime;
  final List<ConversationTurn> conversationHistory;

  ConversationSummary({
    required this.scenario,
    required this.character,
    required this.totalDuration,
    required this.turnCount,
    required this.averageResponseTime,
    required this.conversationHistory,
  });
}
