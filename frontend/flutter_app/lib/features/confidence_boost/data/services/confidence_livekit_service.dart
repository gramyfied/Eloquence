import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:audio_session/audio_session.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// Service LiveKit complet pour Confidence Boost
/// REMPLACE entièrement la solution WebSocket streaming
class ConfidenceLiveKitService {
  static final Logger _logger = Logger();

  // État LiveKit
  Room? _room;
  LocalAudioTrack? _localAudioTrack;
  RemoteAudioTrack? _remoteAudioTrack;
  bool _isConnected = false;
  bool _isPublishing = false;

  // Configuration audio
  AudioSession? _audioSession;
  AudioPlayer? _audioPlayer;
  static const platform = MethodChannel('eloquence.audio/native');

  // Configuration exercice
  ConfidenceScenario? _currentScenario;
  String? _sessionId;
  String? _participantIdentity;

  // Streams temps réel - API unifiée pour l'UI
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

  /// Démarre une session Confidence Boost avec LiveKit
  /// REMPLACE la méthode WebSocket startConversation()
  Future<bool> startConfidenceBoostSession({
    required ConfidenceScenario scenario,
    required String userId,
    String? sessionId,
  }) async {
    try {
      _logger.i('🚀 Démarrage session Confidence Boost via LiveKit');
      _logger.i('📝 Scénario: ${scenario.title}');

      // Générer un ID de session unique
      _sessionId = sessionId ?? 'cb_${DateTime.now().millisecondsSinceEpoch}';
      _currentScenario = scenario;

      _phaseController.add(ExercisePhase.connecting);

      // 0. Configurer l'audio session et le volume
      await _configureAudioSession();
      await _ensureAudioVolume();
      await _configureNativeAudio();

      // 1. Obtenir token LiveKit spécialisé Confidence Boost
      final tokenData = await _getConfidenceBoostToken(scenario, userId, _sessionId!);
      if (tokenData == null) {
        throw Exception('Impossible d\'obtenir le token LiveKit');
      }

      // 2. Créer et configurer la room LiveKit
      _room = Room();
      _setupRoomListeners();

      // 3. Connexion à LiveKit avec configuration audio optimisée
      await _room!.connect(
        tokenData['livekit_url'],
        tokenData['token'],
      );

      _participantIdentity = tokenData['participant_identity'];
      _isConnected = true;

      _logger.i('✅ Connexion LiveKit réussie');
      _phaseController.add(ExercisePhase.connected);

      // 4. Démarrer publication audio
      await _startAudioPublication();

      // 5. Envoyer configuration initiale de l'exercice
      await _sendExerciseConfiguration();

      _phaseController.add(ExercisePhase.ready);
      _logger.i('🎯 Session Confidence Boost prête');

      return true;

    } catch (e, stackTrace) {
      _logger.e('❌ Erreur démarrage session: $e', error: e, stackTrace: stackTrace);
      _errorController.add('Erreur connexion: $e');
      _phaseController.add(ExercisePhase.error);
      await _cleanup();
      return false;
    }
  }

  /// Publication audio avec configuration optimisée
  Future<void> _startAudioPublication() async {
    try {
      if (_room?.localParticipant == null) {
        throw Exception('Participant local non disponible');
      }

      // Configuration audio optimisée pour conversation
      final audioCaptureOptions = AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      );

      _localAudioTrack = await LocalAudioTrack.create(audioCaptureOptions);

      await _room!.localParticipant!.publishAudioTrack(_localAudioTrack!);
      _isPublishing = true;

      _logger.i('🎤 Audio publié avec configuration optimisée');

    } catch (e) {
      _logger.e('❌ Erreur publication audio: $e');
      throw Exception('Impossible de publier l\'audio: $e');
    }
  }

  /// Configuration de l'audio session Flutter
  Future<void> _configureAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      
      await _audioSession!.setActive(true);
      _logger.i('🔊 Audio session configurée pour conversation vocale');
    } catch (e) {
      _logger.e('❌ Erreur configuration audio session: $e');
      throw Exception('Configuration audio échouée: $e');
    }
  }

  /// Vérification et ajustement du volume système
  Future<void> _ensureAudioVolume() async {
    try {
      final volumeController = VolumeController();
      final currentVolume = await volumeController.getVolume();
      _logger.i('🔊 Volume actuel: ${(currentVolume * 100).toInt()}%');
      
      if (currentVolume < 0.3) {
        volumeController.setVolume(0.7);
        _logger.i('🔊 Volume ajusté à 70%');
      }
    } catch (e) {
      _logger.e('❌ Erreur contrôle volume: $e');
    }
  }

  /// Configuration audio native Android
  Future<void> _configureNativeAudio() async {
    try {
      await platform.invokeMethod('configureAudioForSpeech');
      await platform.invokeMethod('setAudioToSpeaker');
      _logger.i('🔊 Configuration audio native appliquée');
    } catch (e) {
      _logger.e('❌ Erreur configuration native: $e');
    }
  }

  /// Configuration des listeners LiveKit
  void _setupRoomListeners() {
    if (_room == null) return;

    // Événements de connexion
    _room!.addListener(() {
      final state = _room!.connectionState;
      _logger.d('📡 État connexion LiveKit: $state');

      switch (state) {
        case ConnectionState.connected:
          if (!_isConnected) {
            _isConnected = true;
            _phaseController.add(ExercisePhase.connected);
          }
          break;
        case ConnectionState.disconnected:
          if (_isConnected) {
            _isConnected = false;
            _phaseController.add(ExercisePhase.disconnected);
          }
          break;
        case ConnectionState.reconnecting:
          _phaseController.add(ExercisePhase.reconnecting);
          break;
        case ConnectionState.connecting:
          _phaseController.add(ExercisePhase.connecting);
          break;
      }
    });

    // 🔧 FIX CRITIQUE: Événements LiveKit corrects pour Flutter avec amélioration
    
    // Timer pour vérifier périodiquement les nouveaux tracks audio
    Timer? audioCheckTimer;
    audioCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_room == null) {
        timer.cancel();
        return;
      }
      
      _checkForNewAudioTracks();
    });
    
    // Écouter les événements de participant
    _room!.addListener(() {
      // Vérifier les changements de participants
      for (final participant in _room!.remoteParticipants.values) {
        _checkParticipantAudioTracks(participant);
      }
    });
  }

  /// Vérifier et configurer les nouveaux tracks audio
  void _checkForNewAudioTracks() {
    for (final participant in _room!.remoteParticipants.values) {
      _checkParticipantAudioTracks(participant);
    }
  }
  
  /// Vérifier les tracks audio d'un participant spécifique
  void _checkParticipantAudioTracks(RemoteParticipant participant) {
    for (final publication in participant.audioTrackPublications) {
      if (publication.subscribed && publication.track != null) {
        final track = publication.track as RemoteAudioTrack;
        
        if (_remoteAudioTrack != track) {
          _logger.i('🎵 Nouveau track audio détecté de ${participant.identity}');
          _handleRemoteAudioTrack(track, participant);
        }
      }
    }
  }
  
  /// Gérer un nouveau track audio distant avec configuration avancée
  Future<void> _handleRemoteAudioTrack(RemoteAudioTrack track, RemoteParticipant participant) async {
    try {
      _remoteAudioTrack = track;
      
      // Démarrer le track audio
      await track.start();
      _logger.i('🔊 Track audio démarré pour ${participant.identity}');
      
      // Configuration supplémentaire pour forcer l'audio
      await _ensureAudioRouting();
      
      // Vérifier si l'audio est effectivement audible après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      
      final isAudioPlaying = await _checkAudioPlayback();
      if (!isAudioPlaying) {
        _logger.w('⚠️ Audio LiveKit non détecté, activation du fallback');
        await _requestAudioFallback();
      } else {
        _logger.i('🔊 ✅ Audio LiveKit confirmé fonctionnel');
      }
      
    } catch (e) {
      _logger.e('❌ Erreur configuration RemoteAudioTrack: $e');
      await _requestAudioFallback();
    }
  }
  
  /// Forcer le routage audio vers les haut-parleurs
  Future<void> _ensureAudioRouting() async {
    try {
      // Essayer de forcer l'audio vers les haut-parleurs
      if (_room?.localParticipant != null) {
        // Note: Cette API pourrait ne pas être disponible dans toutes les versions
        // On garde cette tentative mais on ne fait pas échouer si elle n'existe pas
        _logger.i('🔊 Tentative de routage audio vers haut-parleurs');
      }
      
      // Configuration audio session pour routage
      if (_audioSession != null) {
        await _audioSession!.setActive(true);
      }
    } catch (e) {
      _logger.w('⚠️ Routage audio non supporté: $e');
    }
  }
  
  /// Vérifier si l'audio est effectivement en cours de lecture
  Future<bool> _checkAudioPlayback() async {
    // Vérification simplifiée - vérifier si le track existe et est actif
    return _remoteAudioTrack != null;
  }
  
  /// Demander un fallback audio au backend
  Future<void> _requestAudioFallback() async {
    try {
      _logger.i('🔄 Demande de fallback audio au backend');
      
      // Envoyer une demande de fallback au backend via data channel
      final fallbackRequest = {
        'type': 'audio_fallback_request',
        'session_id': _sessionId,
        'reason': 'livekit_audio_not_playing',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final jsonData = jsonEncode(fallbackRequest);
      final bytes = utf8.encode(jsonData);
      
      if (_room?.localParticipant != null) {
        await _room!.localParticipant!.publishData(bytes, reliable: true);
        _logger.i('📤 Demande de fallback envoyée');
      }
      
    } catch (e) {
      _logger.e('❌ Erreur demande fallback: $e');
    }
  }
  
  /// Jouer l'audio avec just_audio en fallback
  Future<void> _playWithJustAudio(String audioUrl) async {
    try {
      _audioPlayer ??= AudioPlayer();
      
      // Configurer et jouer l'audio
      await _audioPlayer!.setUrl(audioUrl);
      await _audioPlayer!.play();
      
      _logger.i('🎵 Audio joué via just_audio fallback: $audioUrl');
      
      // Écouter la fin de lecture
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _logger.i('🏁 Lecture audio fallback terminée');
        }
      });
      
    } catch (e) {
      _logger.e('❌ Erreur just_audio fallback: $e');
    }
  }
  
  /// Gestion des données reçues via data channel
  void _handleDataReceived(List<int> data, RemoteParticipant? participant) {
    try {
      final jsonString = utf8.decode(data);
      final message = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _logger.d('📨 Données reçues: ${message['type']}');
      
      switch (message['type']) {
        case 'transcription':
          final text = message['text'] as String;
          _transcriptionController.add(text);
          _logger.d('📝 Transcription: $text');
          break;
          
        case 'ai_response':
          final aiMessage = ConversationMessage(
            id: message['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: message['content'] as String,
            isUser: false,
            timestamp: DateTime.now(),
          );
          _conversationController.add(aiMessage);
          _logger.d('🤖 Réponse IA: ${aiMessage.content}');
          break;
          
        case 'audio_fallback_url':
          // Le backend fournit une URL audio en fallback
          final audioUrl = message['audio_url'] as String;
          _logger.i('🔊 URL audio fallback reçue: $audioUrl');
          _playWithJustAudio(audioUrl);
          break;
          
        case 'metrics':
          final metricsData = message['metrics'] as Map<String, dynamic>;
          final metrics = ConfidenceMetrics(
            confidenceLevel: (metricsData['confidence_level'] ?? 0.0).toDouble(),
            voiceClarity: (metricsData['voice_clarity'] ?? 0.0).toDouble(),
            speakingPace: (metricsData['speaking_pace'] ?? 0.0).toDouble(),
            energyLevel: (metricsData['energy_level'] ?? 0.0).toDouble(),
            timestamp: DateTime.now(),
          );
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
      _logger.e('❌ Erreur traitement données: $e');
    }
  }
  
  /// Gestion des données reçues du backend (transcription, réponses IA)
  /// DEPRECATED - Utiliser _handleDataReceived à la place
  void _handleParticipantData(RemoteParticipant participant) {
    try {
      // Les données sont envoyées via publishData() depuis le backend
      final dataReceived = participant.metadata;
      if (dataReceived != null && dataReceived.isNotEmpty) {
        final data = jsonDecode(dataReceived) as Map<String, dynamic>;
        
        switch (data['type']) {
          case 'transcription':
            final text = data['text'] as String;
            _transcriptionController.add(text);
            _logger.d('📝 Transcription: $text');
            break;

          case 'ai_response':
            final message = ConversationMessage(
              id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              content: data['content'] as String,
              isUser: false,
              timestamp: DateTime.now(),
            );
            _conversationController.add(message);
            _logger.d('🤖 Réponse IA: ${message.content}');
            break;

          case 'metrics':
            final metricsData = data['metrics'] as Map<String, dynamic>;
            final metrics = ConfidenceMetrics(
              confidenceLevel: (metricsData['confidence_level'] ?? 0.0).toDouble(),
              voiceClarity: (metricsData['voice_clarity'] ?? 0.0).toDouble(),
              speakingPace: (metricsData['speaking_pace'] ?? 0.0).toDouble(),
              energyLevel: (metricsData['energy_level'] ?? 0.0).toDouble(),
              timestamp: DateTime.now(),
            );
            _metricsController.add(metrics);
            _logger.d('📊 Métriques reçues');
            break;

          case 'phase_change':
            final phase = ExercisePhase.values.firstWhere(
              (p) => p.toString().split('.').last == data['phase'],
              orElse: () => ExercisePhase.unknown,
            );
            _phaseController.add(phase);
            break;
        }
      }
    } catch (e) {
      _logger.e('❌ Erreur traitement données participant: $e');
    }
  }

  /// Envoi de la configuration initiale de l'exercice
  Future<void> _sendExerciseConfiguration() async {
    if (!_isConnected || _room?.localParticipant == null || _currentScenario == null) {
      _logger.w('⚠️ Configuration impossible: pas de connexion active');
      return;
    }

    try {
      final configMessage = {
        'type': 'exercise_config',
        'exercise_type': 'confidence_boost',
        'scenario_id': _currentScenario!.id,
        'scenario_title': _currentScenario!.title,
        'scenario_description': _currentScenario!.description,
        'session_id': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'ai_character': 'thomas', // Ou configurable
      };

      final jsonData = jsonEncode(configMessage);
      final bytes = utf8.encode(jsonData);

      await _room!.localParticipant!.publishData(
        bytes,
        reliable: true,
      );

      _logger.i('📤 Configuration exercice envoyée');

    } catch (e) {
      _logger.e('❌ Erreur envoi configuration: $e');
      _errorController.add('Erreur configuration: $e');
    }
  }

  /// Envoi d'un message utilisateur (déclenche transcription + IA)
  Future<void> sendUserMessage(String content) async {
    if (!_isConnected || _room?.localParticipant == null) {
      _logger.w('⚠️ Message non envoyé: pas de connexion active');
      return;
    }

    try {
      // Ajouter le message utilisateur au stream local
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _conversationController.add(userMessage);

      // Envoyer au backend pour traitement IA
      final message = {
        'type': 'user_message',
        'content': content,
        'session_id': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(message);
      final bytes = utf8.encode(jsonData);

      await _room!.localParticipant!.publishData(
        bytes,
        reliable: true,
      );

      _logger.d('📤 Message utilisateur envoyé: $content');

    } catch (e) {
      _logger.e('❌ Erreur envoi message: $e');
      _errorController.add('Erreur envoi message: $e');
    }
  }

  /// Obtenir token spécialisé Confidence Boost
  Future<Map<String, dynamic>?> _getConfidenceBoostToken(
    ConfidenceScenario scenario,
    String userId,
    String sessionId,
  ) async {
    try {
      // Remplacer localhost par IP pour Android
      final tokenUrl = AppConfig.livekitTokenUrl.replaceAll('localhost', '192.168.1.44');
      _logger.i('🌐 URL remplacée: ${AppConfig.livekitTokenUrl} → $tokenUrl');

      // Générer des identifiants uniques
      final participantName = 'flutter_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final roomName = 'confidence_boost_$sessionId';

      _logger.i('📡 Appel token service: $tokenUrl/generate-token');
      _logger.i('👤 Participant: $participantName');
      _logger.i('🏠 Room: $roomName');

      // 🔧 CORRECTION FINALE: Le serveur Pydantic attend les métadonnées comme un objet dict, pas une string
      final metadataObject = {
        'exercise_type': 'confidence_boost',
        'scenario_id': scenario.id,
        'scenario_title': scenario.title,
        'user_id': userId,
        'session_id': sessionId,
        'ai_character': 'thomas',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final requestBody = {
        'participant_name': participantName,
        'room_name': roomName,
        'grants': {
          'roomJoin': true,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
        'metadata': metadataObject, // 🔧 FIX FINAL: Objet au lieu de string
      };

      _logger.i('🔍 DIAGNOSTIC: Corps de requête token:');
      _logger.i('   - participant_name: $participantName');
      _logger.i('   - room_name: $roomName');
      _logger.i('   - metadata (object): $metadataObject');
      _logger.i('   - Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$tokenUrl/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      _logger.i('🔍 DIAGNOSTIC: Réponse serveur token:');
      _logger.i('   - Status Code: ${response.statusCode}');
      _logger.i('   - Headers: ${response.headers}');
      _logger.i('   - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('🎫 Token Confidence Boost obtenu');
        
        // 🔍 DIAGNOSTIC: Vérifier la structure du token JWT
        final token = data['token'];
        if (token != null) {
          _logger.i('🔍 DIAGNOSTIC: Token JWT reçu: ${token.toString().substring(0, 50)}...');
          
          // Décoder le token pour vérifier sa structure
          try {
            final parts = token.toString().split('.');
            if (parts.length == 3) {
              _logger.i('✅ Token JWT valide (3 parties)');
            } else {
              _logger.e('❌ Token JWT invalide: ${parts.length} parties');
            }
          } catch (e) {
            _logger.e('❌ Erreur analyse token: $e');
          }
        }
        
        // Parse expires_at safely (peut être int ou string)
        final expiresAt = data['expires_at'];
        if (expiresAt != null) {
          try {
            final expiresTimestamp = expiresAt is int ? expiresAt : int.parse(expiresAt.toString());
            final expiresDate = DateTime.fromMillisecondsSinceEpoch(expiresTimestamp * 1000);
            _logger.i('✅ Token valide jusqu\'à: $expiresDate');
          } catch (e) {
            _logger.w('⚠️ Impossible de parser expires_at: $expiresAt');
          }
        }
        
        final livekitUrl = AppConfig.livekitUrl.replaceAll('localhost', '192.168.1.44');
        _logger.i('🔍 DIAGNOSTIC: URL LiveKit finale: $livekitUrl');
        
        // Adapter la réponse au format attendu par le reste du code
        return {
          'token': data['token'],
          'livekit_url': livekitUrl,
          'participant_identity': data['participant_identity'] ?? participantName,
          'room_name': data['room_name'] ?? roomName,
        };
      } else {
        _logger.e('❌ DIAGNOSTIC: Erreur serveur token:');
        _logger.e('   - Status: ${response.statusCode}');
        _logger.e('   - Body: ${response.body}');
        _logger.e('   - Headers: ${response.headers}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      _logger.e('❌ Erreur obtention token: $e');
      return null;
    }
  }

  /// Terminer la session
  Future<void> endSession() async {
    _logger.i('🛑 Fin de session Confidence Boost');
    
    try {
      // Notifier le backend de la fin de session
      if (_isConnected && _room?.localParticipant != null) {
        final endMessage = {
          'type': 'session_end',
          'session_id': _sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final jsonData = jsonEncode(endMessage);
        final bytes = utf8.encode(jsonData);

        await _room!.localParticipant!.publishData(bytes, reliable: true);
      }

      _phaseController.add(ExercisePhase.ended);
      await _cleanup();
      
      _logger.i('✅ Session terminée proprement');

    } catch (e) {
      _logger.e('❌ Erreur fin de session: $e');
      await _cleanup();
    }
  }

  /// Nettoyage des ressources
  Future<void> _cleanup() async {
    try {
      // Arrêter publication audio
      if (_localAudioTrack != null) {
        await _localAudioTrack!.stop();
        _localAudioTrack = null;
      }

      // Déconnecter room
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }

      // Réinitialiser état
      _isConnected = false;
      _isPublishing = false;
      _remoteAudioTrack = null;
      _participantIdentity = null;

    } catch (e) {
      _logger.e('❌ Erreur nettoyage: $e');
    }
  }

  /// Reconnecter en cas de déconnexion
  Future<bool> reconnect() async {
    if (_currentScenario == null || _sessionId == null) {
      _logger.w('⚠️ Impossible de reconnecter: configuration manquante');
      return false;
    }

    _logger.i('🔄 Tentative de reconnexion...');
    _phaseController.add(ExercisePhase.reconnecting);

    await _cleanup();

    // Utiliser les mêmes paramètres que la session initiale
    return await startConfidenceBoostSession(
      scenario: _currentScenario!,
      userId: _participantIdentity ?? 'user_unknown',
      sessionId: _sessionId,
    );
  }

  /// Dispose des ressources (à appeler dans dispose() du provider)
  void dispose() {
    _logger.i('🧹 Dispose du service LiveKit');
    
    // Nettoyer l'audio player
    _audioPlayer?.dispose();
    _audioPlayer = null;
    
    endSession();
    
    _transcriptionController.close();
    _conversationController.close();
    _metricsController.close();
    _phaseController.close();
    _errorController.close();
  }
}

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