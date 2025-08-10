import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../../../core/config/network_config.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import 'ai_character_factory.dart';
import '../../domain/entities/ai_character_models.dart';

/// Extension pour les phases d'exercice
enum ExercisePhase {
  idle,
  connecting,
  connected,
  ready,
  listening,
  processing,
  responding,
  reconnecting,
  ended,
  error,
  disconnected,
  unknown,
}

/// Service LiveKit pour Confidence Boost, simplifié sur le modèle de StudioLiveKitService
class ConfidenceLiveKitService {
  static final Logger _logger = Logger();

  // État LiveKit
  Room? _room;
  LocalParticipant? get localParticipant => _room?.localParticipant;
  LocalAudioTrack? _localAudioTrack;

  bool _isConnected = false;
  bool _isPublishing = false;

  // Configuration exercice
  ConfidenceScenario? _currentScenario;
  String? _sessionId;

  // Streams temps réel
  final StreamController<String> _transcriptionController = StreamController.broadcast();
  final StreamController<ConversationMessage> _conversationController = StreamController.broadcast();
  final StreamController<ConfidenceMetrics> _metricsController = StreamController.broadcast();
  final StreamController<ExercisePhase> _phaseController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();

  // API publique pour l'UI
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<ConversationMessage> get conversationStream => _conversationController.stream;
  Stream<ConfidenceMetrics> get metricsStream => _metricsController.stream;
  Stream<ExercisePhase> get phaseStream => _phaseController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters d'état
  bool get isConnected => _isConnected;
  bool get isPublishing => _isPublishing;
  String? get sessionId => _sessionId;

  /// Démarre une session spécialisée pour le Tribunal des Idées Impossibles
  Future<bool> startTribunalIdeasSession({
    required String userId,
    String? sessionId,
    required String debateTopic, // NOUVEAU: Le sujet du débat
  }) async {
    _logger.i("⚖️ Démarrage session Tribunal via LiveKit (logique simplifiée)");
    _logger.d("   Sujet reçu: $debateTopic");

    if (_isConnected) {
      _logger.w("Une session est déjà en cours. Veuillez d'abord la fermer.");
      return false;
    }
    
    // Créer un scénario spécialisé pour le tribunal
    final tribunalScenario = ConfidenceScenario(
      id: 'tribunal_idees_impossibles',
      title: 'Tribunal des Idées Impossibles',
      description: 'Défendez des idées impossibles devant un tribunal bienveillant.',
      difficulty: 'Intermédiaire',
      prompt: 'Vous êtes avocat(e) dans le Tribunal des Idées Impossibles. Défendez votre cause farfelue avec conviction, créativité et éloquence. Le juge est bienveillant mais exigeant - développez longuement vos arguments !',
      type: ConfidenceScenarioType.presentation,
      durationSeconds: 1200, // 20 minutes au lieu de 15
      tips: [
        'Prenez votre temps pour développer vos arguments',
        'Soyez créatif et original dans votre plaidoirie',
        'Utilisez des exemples concrets et farfelus',
        'Le juge apprécie l\'humour et la conviction',
        'N\'hésitez pas à être théâtral et expressif',
      ],
      keywords: ['argumentation', 'créativité', 'éloquence', 'conviction'],
      icon: '⚖️',
    );

    _sessionId = sessionId ?? 'tribunal_${DateTime.now().millisecondsSinceEpoch}';
    _currentScenario = tribunalScenario;

    try {
      _phaseController.add(ExercisePhase.connecting);

      _room = Room();
      _setupRoomListeners();
      
      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      );
      
      final roomName = 'tribunal_idees_$_sessionId';
      final token = await _generateToken(roomName, userId, exerciceType: 'tribunal_idees_impossibles');

      await _room!.connect(NetworkConfig.livekitUrl, token, roomOptions: roomOptions);
      _isConnected = true;

      _logger.i('✅ Connexion LiveKit réussie pour le tribunal: $roomName');
      _phaseController.add(ExercisePhase.connected);

      await _publishAudio();

      // NOUVELLE LOGIQUE: Générer le prompt système dynamically
      final dummyProfile = UserAdaptiveProfile(
        userId: userId,
        confidenceLevel: 5,
        experienceLevel: 5,
        strengths: [],
        weaknesses: [],
        preferredTopics: [],
        preferredCharacter: AICharacterType.juge_magistrat,
        lastSessionDate: DateTime.now(),
        totalSessions: 0,
        averageScore: 0,
      );
      final factory = AICharacterFactory();
      final characterInstance = factory.createCharacter(
        scenario: tribunalScenario,
        userProfile: dummyProfile,
        preferredCharacter: AICharacterType.juge_magistrat,
      );
      final systemPrompt = characterInstance.getSystemPrompt(debateTopic: debateTopic);

      await _sendTribunalConfiguration(systemPrompt);

      _phaseController.add(ExercisePhase.ready);
      _logger.i('⚖️ Session Tribunal des Idées Impossibles prête.');

      return true;

    } catch (e, stackTrace) {
      _logger.e('❌ Erreur démarrage session tribunal: $e', error: e, stackTrace: stackTrace);
      _errorController.add('Erreur connexion tribunal: $e');
      _phaseController.add(ExercisePhase.error);
      await _cleanup();
      return false;
    }
  }

  /// Démarre une session Confidence Boost (logique identique au tribunal)
  Future<bool> startConfidenceBoostSession({
    required ConfidenceScenario scenario,
    required String userId,
    String? sessionId,
  }) async {
    _logger.i("🚀 Démarrage session Confidence Boost via LiveKit (logique simplifiée)");
    
    if (_isConnected) {
        _logger.w("Une session est déjà en cours. Veuillez d'abord la fermer.");
        return false;
    }
    
    _sessionId = sessionId ?? 'cb_${DateTime.now().millisecondsSinceEpoch}';
    _currentScenario = scenario;
    
    try {
         _phaseController.add(ExercisePhase.connecting);

        _room = Room();
        _setupRoomListeners();
        
        final roomOptions = RoomOptions(
            adaptiveStream: true,
            dynacast: true,
        );

        final roomName = 'confidence_boost_$_sessionId';
        final token = await _generateToken(roomName, userId, exerciceType: 'confidence_boost');

        await _room!.connect(NetworkConfig.livekitUrl, token, roomOptions: roomOptions);
        _isConnected = true;

        _logger.i('✅ Connexion LiveKit réussie pour Confidence Boost: $roomName');
        _phaseController.add(ExercisePhase.connected);

        await _publishAudio();
        
        await _sendExerciseConfiguration();

        _phaseController.add(ExercisePhase.ready);
        _logger.i('🎯 Session Confidence Boost prête.');
        
        return true;

    } catch (e, stackTrace) {
        _logger.e('❌ Erreur démarrage session Confidence Boost: $e', error: e, stackTrace: stackTrace);
        _errorController.add('Erreur connexion Confidence Boost: $e');
        _phaseController.add(ExercisePhase.error);
        await _cleanup();
        return false;
    }
  }

  /// Génère un token d'authentification via un appel HTTP simple
  Future<String> _generateToken(String roomName, String userId, {required String exerciceType}) async {
    _logger.i("🔑 Génération de token pour $roomName (User: $userId)");
    try {
      // Utilisation de l'URL centralisée qui gère l'IP locale pour Android
      final response = await http.post(
        Uri.parse(NetworkConfig.studioTokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room': roomName,
          'identity': userId,
          'metadata': json.encode({
            'exercise_type': exerciceType,
            'user_id': userId,
            'session_id': _sessionId,
          }),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i("✅ Token généré avec succès pour: $roomName");
        return data['token'];
      } else {
        _logger.e("Erreur génération token: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to generate token: ${response.statusCode}");
      }
    } catch (e) {
      _logger.e("Exception génération token: $e");
      throw Exception("Could not generate authentication token: $e");
    }
  }

  /// Publie la piste audio locale de manière simple
  Future<void> _publishAudio() async {
    if (_room == null || _room!.localParticipant == null) {
      _logger.w("Impossible de publier l'audio: room ou participant local non disponible.");
      return;
    }
    try {
      _localAudioTrack = await LocalAudioTrack.create(
        const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );
      await _room!.localParticipant!.publishAudioTrack(_localAudioTrack!);
      _isPublishing = true;
      _logger.i("🎤 Piste audio locale publiée.");
    } catch (e) {
      _logger.e("❌ Erreur publication audio: $e");
      _errorController.add("Erreur de publication audio: $e");
      throw Exception("Could not publish audio track: $e");
    }
  }


  /// Envoyer configuration spécialisée pour le tribunal
  Future<void> _sendTribunalConfiguration(String systemPrompt) async {
    if (!_isConnected || localParticipant == null) return;
    try {
      final configMessage = {
        'type': 'exercise_config',
        'exercise_type': 'tribunal_idees_impossibles',
        'scenario_id': _currentScenario!.id,
        'session_id': _sessionId,
        'ai_character': 'juge_magistrat',
        'system_prompt': systemPrompt,
      };
      final data = utf8.encode(jsonEncode(configMessage));
      await localParticipant!.publishData(data, reliable: true);
      _logger.i("⚖️ Configuration du tribunal avec prompt dynamique envoyée.");
      _logger.d("   Prompt envoyé: $systemPrompt");
    } catch(e) {
      _logger.e("Erreur envoi configuration tribunal: $e");
    }
  }
  
  /// Envoi de la configuration initiale de l'exercice
  Future<void> _sendExerciseConfiguration() async {
    if (!_isConnected || localParticipant == null || _currentScenario == null) return;
     try {
      final configMessage = {
        'type': 'exercise_config',
        'exercise_type': 'confidence_boost',
        'scenario_id': _currentScenario!.id,
        'session_id': _sessionId,
        'ai_character': 'thomas', // Ou configurable
      };
      final data = utf8.encode(jsonEncode(configMessage));
      await localParticipant!.publishData(data, reliable: true);
      _logger.i("📤 Configuration de l'exercice envoyée.");
    } catch(e) {
      _logger.e("Erreur envoi configuration exercice: $e");
    }
  }

  /// Configuration des listeners LiveKit
  void _setupRoomListeners() {
    _room?.addListener(() {
      final state = _room?.connectionState ?? ConnectionState.disconnected;
       if (state != _room?.connectionState) {
        _phaseController.add(state == ConnectionState.connected ? ExercisePhase.connected : ExercisePhase.disconnected);
       }
       _logger.d('📡 État connexion LiveKit: $state');
    });

    _room?.events.listen((event) {
      if (event is DataReceivedEvent) {
        _handleDataReceived(Uint8List.fromList(event.data), event.participant);
      }
    });
  }

  /// Gestion des données reçues via data channel
  void _handleDataReceived(Uint8List data, RemoteParticipant? participant) {
    try {
      final jsonString = utf8.decode(data);
      final message = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _logger.d("📨 Données reçues de ${participant?.identity}: ${message['type']}");
      
      switch (message['type']) {
        case 'transcription':
          _transcriptionController.add(message['text'] as String);
          break;
        case 'ai_response':
          final aiMessage = ConversationMessage(
            id: message['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: message['content'] as String,
            isUser: false,
            timestamp: DateTime.now(),
          );
          _conversationController.add(aiMessage);
          break;
        case 'metrics':
          final metricsData = message['metrics'] as Map<String, dynamic>;
          final metrics = ConfidenceMetrics.fromJson(metricsData);
          _metricsController.add(metrics);
          break;
        case 'phase_change':
           final phase = ExercisePhase.values.firstWhere(
            (p) => p.toString().split('.').last == message['phase'],
            orElse: () => ExercisePhase.unknown,
          );
          _phaseController.add(phase);
          break;
      }
    } catch (e) {
      _logger.e("❌ Erreur traitement données: $e");
    }
  }

  /// Envoi d'un message utilisateur (déclenche transcription + IA)
  Future<void> sendUserMessage(String content) async {
    if (!_isConnected || localParticipant == null) {
      _logger.w("⚠️ Message non envoyé: pas de connexion active");
      return;
    }

    try {
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _conversationController.add(userMessage);

      final message = {
        'type': 'user_message',
        'content': content,
        'session_id': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final data = utf8.encode(jsonEncode(message));
      await localParticipant!.publishData(data, reliable: true);

      _logger.d("📤 Message utilisateur envoyé: $content");

    } catch (e) {
      _logger.e("❌ Erreur envoi message: $e");
      _errorController.add("Erreur envoi message: $e");
    }
  }

  /// Nettoyage des ressources
  Future<void> _cleanup() async {
    _logger.i("🧹 Nettoyage des ressources LiveKit...");
    try {
      if (_localAudioTrack != null) {
        await _localAudioTrack!.stop();
        _isPublishing = false;
      }
      if (_room != null) {
        await _room!.disconnect();
      }
    } catch(e) {
        _logger.e("Erreur pendant le cleanup: $e");
    } finally {
        _room = null;
        _localAudioTrack = null;
        _isConnected = false;
        _isPublishing = false;
        _currentScenario = null;
        _sessionId = null;
        _logger.i("✅ Nettoyage terminé.");
    }
  }

  /// Terminer la session (méthode publique)
  Future<void> endSession() async {
    _logger.i("🔚 Fin de session demandée.");
    _phaseController.add(ExercisePhase.ended);
    await _cleanup();
  }

  /// Reconnecter en cas de problème
  Future<bool> reconnect() async {
    _logger.i("🔄 Tentative de reconnexion");
    await _cleanup();
    _phaseController.add(ExercisePhase.reconnecting);
      
    if (_currentScenario != null) {
      if (_currentScenario!.id == 'tribunal_idees_impossibles') {
        return await startTribunalIdeasSession(
          userId: 'reconnect_user',
          sessionId: _sessionId,
          debateTopic: 'Sujet non disponible après reconnexion', // Placeholder pour la reconnexion
        );
      } else {
        return await startConfidenceBoostSession(
          scenario: _currentScenario!,
          userId: 'reconnect_user_cb',
          sessionId: _sessionId,
        );
      }
    }
    _logger.w("Impossible de se reconnecter: aucun scénario actuel.");
    return false;
  }

  /// Libérer toutes les ressources (dispose)
  Future<void> dispose() async {
    _logger.i("🗑️ Dispose du service LiveKit");
    await _cleanup();
    _transcriptionController.close();
    _conversationController.close();
    _metricsController.close();
    _phaseController.close();
    _errorController.close();
  }
}
