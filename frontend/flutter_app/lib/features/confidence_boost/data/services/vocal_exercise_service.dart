import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/config/app_config.dart';

/// Service d'exercices vocaux avec LiveKit
class VocalExerciseService {
  Room? _room;
  LocalAudioTrack? _localAudio;
  
  // Streams pour les différents types d'événements
  final StreamController<Map<String, dynamic>> _stateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _metricsController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream d'état de l'exercice
  Stream<Map<String, dynamic>> get stateStream => _stateController.stream;
  
  /// Stream des messages
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// Stream des métriques
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;

  /// URL de l'API des exercices
  String get _exercisesApiUrl => AppConfig.exercisesApiUrl ?? 'http://localhost:8005';

  /// Récupère la liste des exercices disponibles
  Future<List<Map<String, dynamic>>> getExercises() async {
    try {
      final response = await http.get(
        Uri.parse('$_exercisesApiUrl/api/exercises'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['exercises']);
      } else {
        throw Exception('Erreur récupération exercices: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération exercices: $e');
      rethrow;
    }
  }

  /// Récupère les templates d'exercices prédéfinis
  Future<List<Map<String, dynamic>>> getExerciseTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$_exercisesApiUrl/api/exercise-templates'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['templates']);
      } else {
        throw Exception('Erreur récupération templates: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération templates: $e');
      rethrow;
    }
  }

  /// Crée un nouvel exercice à partir d'un template
  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> config) async {
    try {
      final response = await http.post(
        Uri.parse('$_exercisesApiUrl/api/exercises'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(config),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur création exercice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur création exercice: $e');
      rethrow;
    }
  }

  /// Démarre une session d'exercice
  Future<Map<String, dynamic>> startExercise(String exerciseId, {String? participantName}) async {
    try {
      final sessionConfig = {
        'exercise_id': exerciseId,
        'language': 'fr',
        if (participantName != null) 'participant_name': participantName,
      };

      final response = await http.post(
        Uri.parse('$_exercisesApiUrl/api/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionConfig),
      );
      
      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
        
        // Connecter à LiveKit
        await _connectToLiveKit(
          sessionData['livekit_url'],
          sessionData['token'],
          sessionData['livekit_room']
        );
        
        debugPrint('✅ Session d\'exercice démarrée: ${sessionData['session_id']}');
        return sessionData;
      } else {
        throw Exception('Erreur démarrage exercice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage exercice: $e');
      rethrow;
    }
  }

  /// Connecte à la room LiveKit
  Future<void> _connectToLiveKit(String url, String token, String roomName) async {
    try {
      // Initialiser la room
      _room = Room();
      
      // Configurer les événements
      _room!.createListener().listen((event) {
        _handleRoomEvent(event);
      });
      
      // Se connecter à la room
      await _room!.connect(url, token);
      debugPrint('✅ Connecté à la room LiveKit: $roomName');
      
      // Publier l'audio local
      await _setupLocalAudio();
      
    } catch (e) {
      debugPrint('❌ Erreur connexion LiveKit: $e');
      rethrow;
    }
  }

  /// Configure l'audio local
  Future<void> _setupLocalAudio() async {
    try {
      // Créer track audio local
      _localAudio = await LocalAudioTrack.create(AudioCaptureOptions(
        deviceId: 'default',
        // Configuration pour une meilleure qualité audio
      ));
      
      // Publier l'audio
      await _room!.localParticipant?.publishAudioTrack(_localAudio!);
      debugPrint('✅ Audio local publié');
      
    } catch (e) {
      debugPrint('❌ Erreur configuration audio: $e');
      rethrow;
    }
  }

  /// Gère les événements LiveKit
  void _handleRoomEvent(RoomEvent event) {
    switch (event.runtimeType) {
      case RoomConnectedEvent:
        final connectedEvent = event as RoomConnectedEvent;
        debugPrint('✅ Room connectée: ${connectedEvent.room.name}');
        
        _stateController.add({
          'type': 'room_connected',
          'room_name': connectedEvent.room.name,
          'participants': connectedEvent.room.remoteParticipants.length,
        });
        break;

      case RoomDisconnectedEvent:
        final disconnectedEvent = event as RoomDisconnectedEvent;
        debugPrint('🛑 Room déconnectée: ${disconnectedEvent.reason}');
        
        _stateController.add({
          'type': 'room_disconnected',
          'reason': disconnectedEvent.reason?.toString(),
        });
        break;

      case ParticipantConnectedEvent:
        final participantEvent = event as ParticipantConnectedEvent;
        debugPrint('👤 Participant connecté: ${participantEvent.participant.identity}');
        
        _stateController.add({
          'type': 'participant_connected',
          'identity': participantEvent.participant.identity,
        });
        break;

      case ParticipantDisconnectedEvent:
        final participantEvent = event as ParticipantDisconnectedEvent;
        debugPrint('👤 Participant déconnecté: ${participantEvent.participant.identity}');
        
        _stateController.add({
          'type': 'participant_disconnected',
          'identity': participantEvent.participant.identity,
        });
        break;

      case TrackSubscribedEvent:
        final trackEvent = event as TrackSubscribedEvent;
        debugPrint('🎵 Track souscrit: ${trackEvent.track.sid}');
        
        if (trackEvent.track is RemoteAudioTrack) {
          // L'audio est automatiquement activé avec LiveKit
          _stateController.add({
            'type': 'audio_track_subscribed',
            'participant': trackEvent.participant.identity,
          });
        }
        break;

      case TrackUnsubscribedEvent:
        final trackEvent = event as TrackUnsubscribedEvent;
        debugPrint('🎵 Track désouscrit: ${trackEvent.track.sid}');
        break;

      case DataReceivedEvent:
        final dataEvent = event as DataReceivedEvent;
        _handleDataReceived(dataEvent);
        break;

      default:
        debugPrint('📡 Événement LiveKit non géré: ${event.runtimeType}');
    }
  }

  /// Gère les données reçues
  void _handleDataReceived(DataReceivedEvent event) {
    try {
      // Décoder les données
      final data = utf8.decode(event.data);
      final jsonData = jsonDecode(data);
      
      debugPrint('📊 Données reçues: ${jsonData['type']}');
      
      // Traiter selon le type
      switch (jsonData['type']) {
        case 'message':
          _messageController.add(jsonData);
          break;
        case 'metrics':
          _metricsController.add(jsonData);
          break;
        case 'coaching_feedback':
          _messageController.add({
            'type': 'coaching',
            'content': jsonData['content'],
            'timestamp': jsonData['timestamp'],
          });
          break;
        case 'exercise_progress':
          _stateController.add({
            'type': 'progress_update',
            'progress': jsonData['progress'],
            'stage': jsonData['stage'],
          });
          break;
        default:
          _stateController.add(jsonData);
      }
    } catch (e) {
      debugPrint('❌ Erreur décodage données: $e');
    }
  }

  /// Envoie un message texte
  Future<void> sendMessage(String text, {String? messageType}) async {
    if (_room?.localParticipant == null) {
      throw Exception('Non connecté à LiveKit');
    }
    
    final data = jsonEncode({
      'type': messageType ?? 'user_message',
      'content': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await _room!.localParticipant!.publishData(
      utf8.encode(data),
    );
    
    debugPrint('✅ Message envoyé: $text');
  }

  /// Envoie des métriques d'analyse
  Future<void> sendMetrics(Map<String, dynamic> metrics) async {
    if (_room?.localParticipant == null) {
      throw Exception('Non connecté à LiveKit');
    }
    
    final data = jsonEncode({
      'type': 'metrics',
      'data': metrics,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await _room!.localParticipant!.publishData(
      utf8.encode(data),
    );
    
    debugPrint('📊 Métriques envoyées');
  }

  /// Active/désactive le microphone
  Future<void> toggleMicrophone({bool? enabled}) async {
    if (_localAudio == null) return;
    
    final shouldEnable = enabled ?? !_localAudio!.muted;
    if (shouldEnable) {
      await _localAudio!.unmute();
    } else {
      await _localAudio!.mute();
    }
    
    debugPrint('🎤 Microphone ${shouldEnable ? "activé" : "désactivé"}');
    
    _stateController.add({
      'type': 'microphone_toggle',
      'enabled': shouldEnable,
    });
  }

  /// Vérifie si le microphone est activé
  bool get isMicrophoneEnabled => !(_localAudio?.muted ?? true);

  /// Vérifie si connecté à LiveKit
  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  /// Termine l'exercice et enregistre l'évaluation
  Future<Map<String, dynamic>> completeExercise(
    String sessionId,
    Map<String, dynamic> evaluation
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_exercisesApiUrl/api/sessions/$sessionId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(evaluation),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Déconnecter de LiveKit
        await disconnect();
        
        debugPrint('✅ Exercice terminé: $sessionId');
        return result;
      } else {
        throw Exception('Erreur complétion exercice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur complétion exercice: $e');
      rethrow;
    }
  }

  /// Récupère les détails d'une session
  Future<Map<String, dynamic>> getSessionDetails(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_exercisesApiUrl/api/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur récupération session: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération session: $e');
      rethrow;
    }
  }

  /// Récupère les statistiques générales
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_exercisesApiUrl/api/statistics'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur récupération statistiques: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques: $e');
      rethrow;
    }
  }

  /// Déconnecte de LiveKit
  Future<void> disconnect() async {
    try {
      // Arrêter l'audio local
      if (_localAudio != null) {
        await _localAudio!.disable();
        await _localAudio!.dispose();
        _localAudio = null;
      }
      
      // Déconnecter de la room
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }
      
      debugPrint('🛑 Déconnecté de LiveKit');
      
      _stateController.add({
        'type': 'disconnected',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
    }
  }

  /// Libère les ressources
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _metricsController.close();
  }
}