import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:eloquence_2_0/core/utils/unified_logger_service.dart';
import 'package:eloquence_2_0/core/config/network_config.dart';
import 'package:flutter/services.dart'; // Added for MethodChannel

/// Service amélioré pour gérer la connexion LiveKit avec support multi-agents
class StudioLiveKitService {
  Room? _room;
  LocalParticipant? get localParticipant => _room?.localParticipant;
  
  final Ref _ref;
  
  // Streams pour la communication bidirectionnelle
  final StreamController<Map<String, dynamic>> _dataStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _messageStreamController = 
      StreamController<String>.broadcast();
  final StreamController<ConnectionState> _connectionStateController = 
      StreamController<ConnectionState>.broadcast();
  final StreamController<Map<String, dynamic>> _metricsStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Exposer les streams
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;
  Stream<String> get messageStream => _messageStreamController.stream;
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get metricsStream => _metricsStreamController.stream;
  
  // État de connexion
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  StudioLiveKitService(this._ref);

  /// Se connecte à une room LiveKit
  Future<void> connect(String roomName, {required String userId, String? userName, String? userSubject}) async {
    if (_room != null && _room?.connectionState == ConnectionState.connected) {
      UnifiedLoggerService.info('Already connected to room: ${_room?.name}');
      return;
    }

    try {
      UnifiedLoggerService.info('Connecting to LiveKit room: $roomName');
      _room = Room();
      
      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: const AudioPublishOptions(
          dtx: true,
        ),
        defaultVideoPublishOptions: const VideoPublishOptions(
          simulcast: true,
        ),
      );
      
      // Générer un token avec métadonnées attachées
      final token = await _generateToken(roomName, userId, userName: userName, userSubject: userSubject);

      await _room!.connect(NetworkConfig.livekitUrl, token, roomOptions: roomOptions);
      _isConnected = true;
      _connectionStateController.add(ConnectionState.connected);
      
      UnifiedLoggerService.info('Successfully connected to LiveKit room: ${_room?.name}');
      
      // Attacher les métadonnées à la room après connexion (non-bloquant)
      await _attachRoomMetadata(userName: userName, userSubject: userSubject);
      
      _setupListeners();
      
      // Start capturing audio
      await _publishAudio();

    } catch (e) {
      UnifiedLoggerService.error('Could not connect to LiveKit: $e');
      _isConnected = false;
      _connectionStateController.add(ConnectionState.disconnected);
      rethrow;
    }
  }

  /// Attache les métadonnées à la room pour que les agents puissent les récupérer
  Future<void> _attachRoomMetadata({String? userName, String? userSubject}) async {
    try {
      if (_room?.localParticipant == null) {
        UnifiedLoggerService.warning('Local participant not available for metadata attachment');
        return;
      }

      // Créer les métadonnées de la room
      final roomMetadata = {
        'exercise_type': 'studio_debate_tv',
        'user_name': userName ?? 'Participant',
        'user_subject': userSubject ?? 'Sujet non défini',
        'topic': userSubject ?? 'Sujet non défini',
        'timestamp': DateTime.now().toIso8601String(),
        'room_type': 'multi_agent_simulation',
      };

      // Attacher les métadonnées au participant local (non-bloquant)
      try {
        _room!.localParticipant!.setMetadata(json.encode(roomMetadata));
        UnifiedLoggerService.info('✅ Métadonnées attachées au participant: ${json.encode(roomMetadata)}');
        
        // Envoyer également les métadonnées via un message de données pour s'assurer qu'elles sont reçues
        await sendMessage(json.encode({
          'type': 'room_metadata',
          'metadata': roomMetadata,
        }));
        UnifiedLoggerService.info('✅ Métadonnées envoyées via message de données');
        
      } catch (e) {
        UnifiedLoggerService.error('❌ Erreur lors de l\'attachement des métadonnées: $e');
      }
      
    } catch (e) {
      UnifiedLoggerService.error('❌ Erreur lors de l\'attachement des métadonnées: $e');
    }
  }

  /// Génère un token d'authentification via le backend
  Future<String> _generateToken(String roomName, String userId, {String? userName, String? userSubject}) async {
    try {
      // Appeler le backend pour générer un token réel
      final response = await http.post(
        Uri.parse(NetworkConfig.studioTokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room': roomName,
          'identity': userId,
          'metadata': json.encode({
            'exercise_type': 'studio_debate_tv',
            'user_role': 'participant',
            // Propager la configuration utilisateur dès le token
            'user_name': userName ?? 'Participant',
            'user_subject': userSubject ?? 'Sujet non défini',
            'topic': userSubject ?? 'Sujet non défini',
          }),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        UnifiedLoggerService.info('Token generated successfully for room: $roomName');
        return data['token'];
      } else {
        throw Exception('Failed to generate token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      UnifiedLoggerService.error('Token generation failed: $e');
      throw Exception('Could not generate authentication token: $e');
    }
  }

  /// Publie la piste audio locale
  Future<void> _publishAudio() async {
    try {
      final audioTrack = await LocalAudioTrack.create(
        const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: false, // Désactivé pour éviter l'amplification automatique
        ),
      );
      
      // Configuration supplémentaire pour réduire la sensibilité
      await _configureAudioSensitivity(audioTrack);
      
      await localParticipant!.publishAudioTrack(audioTrack);
      UnifiedLoggerService.info('Local audio track published with reduced sensitivity.');
    } catch (e) {
      UnifiedLoggerService.error('Could not publish audio track: $e');
    }
  }
  
  /// Configure la sensibilité audio pour réduire les captures de bruit
  Future<void> _configureAudioSensitivity(LocalAudioTrack audioTrack) async {
    try {
      // Configuration via MethodChannel pour ajuster la sensibilité hardware
      const platform = MethodChannel('eloquence/audio');
      
      await platform.invokeMethod('configureMicrophoneSensitivity', {
        'reducedSensitivity': true,
        'noiseGateThreshold': 0.3, // Seuil de bruit élevé (0.0-1.0)
        'gainReduction': 0.5, // Réduction du gain de 50%
        'voiceActivityThreshold': 0.4, // Seuil d'activité vocale plus strict
      });
      
      UnifiedLoggerService.info('Microphone sensitivity configured for reduced noise capture.');
    } catch (e) {
      UnifiedLoggerService.warning('Could not configure microphone sensitivity via platform: $e');
      // Fallback: configuration via LiveKit uniquement
    }
  }
  
  /// Configure les listeners pour les événements LiveKit
  void _setupListeners() {
    _room?.addListener(() {
      final state = _room?.connectionState ?? ConnectionState.disconnected;
      _connectionStateController.add(state);
      
      if (state == ConnectionState.connected) {
        UnifiedLoggerService.info('Room connected: ${_room!.name}');
        _isConnected = true;
        
        // Simuler l'arrivée des agents après connexion
        _simulateAgentJoining();
      } else if (state == ConnectionState.disconnected) {
        UnifiedLoggerService.info('Room disconnected');
        _isConnected = false;
      }
    });
    
    // Écouter les participants et leurs pistes audio
    _room?.addListener(() {
      final participants = _room!.remoteParticipants.values.toList();
      for (final participant in participants) {
        participant.addListener(() {
          // Écouter les changements de l'état du participant
          if (participant.isSpeaking) {
            _dataStreamController.add({
              'type': 'active_speaker',
              'speaker_id': participant.identity,
              'speaker_type': 'agent',
            });
          }
        });
        
        // CRITIQUE : Écouter les pistes audio distantes
        participant.trackPublications.forEach((trackSid, publication) {
          if (publication.track is RemoteAudioTrack) {
            final audioTrack = publication.track as RemoteAudioTrack;
            UnifiedLoggerService.info('Audio track detected from ${participant.identity}: ${audioTrack.sid}');
            
            // Assurer que la piste audio est activée pour la lecture
            audioTrack.start();
            UnifiedLoggerService.info('Remote audio track started for ${participant.identity}');
          }
        });
      }
    });
    
    // Écouter les événements via room events
    _room?.events.listen((event) {
      if (event is DataReceivedEvent) {
        final pid = event.participant?.identity ?? 'unknown';
        UnifiedLoggerService.debug('Data received from $pid: ${String.fromCharCodes(event.data)}');
        _handleAgentData(Uint8List.fromList(event.data));
      } else if (event is ParticipantConnectedEvent) {
        UnifiedLoggerService.info('Participant connected: ${event.participant.identity}');
        _handleParticipantJoined(event.participant);
      } else if (event is ParticipantDisconnectedEvent) {
        UnifiedLoggerService.info('Participant disconnected: ${event.participant.identity}');
        _handleParticipantLeft(event.participant);
      } else if (event is TrackSubscribedEvent) {
        UnifiedLoggerService.info('Track subscribed: ${event.track.sid} from ${event.participant?.identity}');
        _handleTrackSubscribed(event);
      } else if (event is TrackPublishedEvent) {
        UnifiedLoggerService.info('Track published: ${event.publication.sid} from ${event.participant?.identity}');
        _handleTrackPublished(event);
      }
    });
  }
  
  /// Simule l'arrivée des agents pour le développement
  void _simulateAgentJoining() {
    if (!kDebugMode) return;
    
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (timer.tick <= 3) { // Simuler 3 agents
        final agentData = {
          'type': 'agent_joined',
          'agent_id': 'agent_${timer.tick}',
          'agent_name': 'Agent ${timer.tick}',
          'role': 'interviewer',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _dataStreamController.add(agentData);
      } else {
        timer.cancel();
        
        // Simuler le premier message après 5 secondes
        Timer(const Duration(seconds: 5), () {
          _simulateAgentMessage();
        });
      }
    });
  }

  void _simulateAgentMessage() {
    if (!kDebugMode) return;
    
    final messages = [
      "Bonjour ! Je suis ravi de participer à cette simulation avec vous.",
      "Excellente initiative ! Commençons par définir le cadre de notre échange.",
      "Je suis là pour vous challenger de manière constructive. Prêt ?",
    ];
    
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (timer.tick <= messages.length) {
        final messageData = {
          'type': 'agent_message',
          'agent_id': 'agent_${(timer.tick % 3) + 1}',
          'agent_name': 'Agent ${(timer.tick % 3) + 1}',
          'message': messages[timer.tick - 1],
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _handleAgentMessage(messageData);
      } else {
        timer.cancel();
      }
    });
  }
  
  void _handleParticipantJoined(RemoteParticipant participant) {
    _dataStreamController.add({
      'type': 'participant_joined',
      'participant_id': participant.identity,
      'participant_name': participant.name ?? participant.identity,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void _handleParticipantLeft(RemoteParticipant participant) {
    _dataStreamController.add({
      'type': 'participant_left',
      'participant_id': participant.identity,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Gère l'événement de souscription à une piste (quand on reçoit de l'audio/vidéo)
  void _handleTrackSubscribed(TrackSubscribedEvent event) {
    final track = event.track;
    final participant = event.participant;
    
    UnifiedLoggerService.info('Track subscribed: ${track.sid} from ${participant?.identity}');
    
    if (track is RemoteAudioTrack) {
      UnifiedLoggerService.info('AUDIO TRACK SUBSCRIBED from ${participant?.identity}');
      
      // CRITIQUE : Connecter l'audio distant aux haut-parleurs
      _connectRemoteAudioToSpeakers(track, participant?.identity ?? 'unknown');
      
      _dataStreamController.add({
        'type': 'audio_track_subscribed',
        'participant_id': participant?.identity,
        'track_sid': track.sid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Connecte une piste audio distante aux haut-parleurs pour l'entendre
  void _connectRemoteAudioToSpeakers(RemoteAudioTrack audioTrack, String participantId) {
    try {
      UnifiedLoggerService.info('🔊 CONNEXION AUDIO HAUT-PARLEURS pour $participantId');
      
      // Activer explicitement la lecture audio
      audioTrack.start();
      
      // Marquer comme activé pour lecture
      audioTrack.enable();
      
      UnifiedLoggerService.info('✅ Audio $participantId - start() et enable() appelés');
      UnifiedLoggerService.info('   Track SID: ${audioTrack.sid}');
      UnifiedLoggerService.info('   Track Source: ${audioTrack.source}');
      
    } catch (e) {
      UnifiedLoggerService.error('❌ Erreur connexion audio $participantId: $e');
    }
  }
  
  /// Gère l'événement de publication de piste (quand un agent commence à parler)
  void _handleTrackPublished(TrackPublishedEvent event) {
    final publication = event.publication;
    final participant = event.participant;
    
    UnifiedLoggerService.info('Track published: ${publication.sid} from ${participant?.identity}');
    
    if (publication.kind == TrackType.AUDIO) {
      UnifiedLoggerService.info('AUDIO TRACK PUBLISHED by ${participant?.identity}');
      
      _dataStreamController.add({
        'type': 'audio_track_published',
        'participant_id': participant?.identity,
        'track_sid': publication.sid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Traite les données reçues des agents
  void _handleAgentData(Uint8List data) {
    try {
      final jsonString = String.fromCharCodes(data);
      final jsonData = json.decode(jsonString);
      
      // Router les différents types de messages
      if (jsonData['type'] == 'agent_message') {
        _handleAgentMessage(jsonData);
      } else if (jsonData['type'] == 'agent_reaction') {
        _handleAgentReaction(jsonData);
      } else if (jsonData['type'] == 'metrics') {
        _handleMetrics(jsonData);
      } else {
        // Transmettre les données brutes
        _dataStreamController.add(jsonData);
      }
    } catch (e) {
      UnifiedLoggerService.error('Error parsing agent data: $e');
    }
  }
  
  /// Traite un message d'agent
  void _handleAgentMessage(Map<String, dynamic> data) {
    final agentName = data['agent_name'] ?? 'Agent';
    final message = data['message'] ?? '';
    
    UnifiedLoggerService.info('Agent message from $agentName: $message');
    
    // Transmettre via le stream de messages
    _messageStreamController.add('$agentName: $message');
    
    // Transmettre également via le stream de données
    _dataStreamController.add(data);
  }
  
  /// Traite une réaction d'agent
  void _handleAgentReaction(Map<String, dynamic> data) {
    final agentName = data['agent_name'] ?? 'Agent';
    final reaction = data['reaction'] ?? '';
    
    UnifiedLoggerService.debug('Agent reaction from $agentName: $reaction');
    
    // Transmettre via le stream de données
    _dataStreamController.add(data);
  }
  
  /// Traite les métriques reçues
  void _handleMetrics(Map<String, dynamic> data) {
    UnifiedLoggerService.debug('Metrics received: $data');
    
    // Transmettre via le stream de métriques
    _metricsStreamController.add(data);
    
    // Transmettre également via le stream de données principal
    _dataStreamController.add({
      'type': 'metrics_update',
      'metrics': data,
    });
  }
  
  /// Envoie un message texte via LiveKit
  Future<void> sendMessage(String message) async {
    if (!_isConnected || _room == null) {
      UnifiedLoggerService.warning('Cannot send message: not connected');
      return;
    }
    
    try {
      final data = utf8.encode(message);
      await _room!.localParticipant!.publishData(
        Uint8List.fromList(data),
        reliable: true,
      );
      
      UnifiedLoggerService.info('Message sent: $message');
    } catch (e) {
      UnifiedLoggerService.error('Error sending message: $e');
    }
  }
  
  /// Active/désactive le microphone
  Future<void> muteAudio(bool mute) async {
    try {
      final trackPublications = localParticipant?.trackPublications.values ?? [];
      
      for (final publication in trackPublications) {
        if (publication.track is LocalAudioTrack) {
          final audioTrack = publication.track as LocalAudioTrack;
          if (mute) {
            await audioTrack.mute();
          } else {
            await audioTrack.unmute();
          }
        }
      }
      
      UnifiedLoggerService.info('Audio ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      UnifiedLoggerService.error('Error toggling audio mute: $e');
    }
  }
  
  /// Se déconnecte de la room LiveKit
  Future<void> disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      _room = null;
      _isConnected = false;
      _connectionStateController.add(ConnectionState.disconnected);
      UnifiedLoggerService.info('Disconnected from LiveKit.');
    }
  }
  
  /// Libère les ressources
  void dispose() {
    disconnect();
    _dataStreamController.close();
    _messageStreamController.close();
    _connectionStateController.close();
    _metricsStreamController.close();
  }
}

/// Provider pour le service LiveKit
final studioLiveKitServiceProvider = Provider<StudioLiveKitService>((ref) {
  final service = StudioLiveKitService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});