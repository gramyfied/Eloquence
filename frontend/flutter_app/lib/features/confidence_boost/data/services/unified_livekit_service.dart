import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// Service LiveKit unifié - REMPLACE tous les autres pipelines audio
class UnifiedLiveKitService {
  // Configuration
  static const String defaultLiveKitUrl = 'ws://localhost:7880';
  
  // État LiveKit
  Room? _room;
  LocalAudioTrack? _localAudio;
  RemoteAudioTrack? _remoteAudio;
  
  // Streams unifiés
  final StreamController<String> _transcriptionController = StreamController.broadcast();
  final StreamController<ConfidenceMetrics> _metricsController = StreamController.broadcast();
  final StreamController<ConversationMessage> _conversationController = StreamController.broadcast();
  
  // API publique
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<ConfidenceMetrics> get metricsStream => _metricsController.stream;
  Stream<ConversationMessage> get conversationStream => _conversationController.stream;
  
  /// Démarre une conversation unifiée
  Future<bool> startConversation(ConfidenceScenario scenario) async {
    try {
      // 1. Connexion LiveKit
      _room = Room();
      await _room!.connect(defaultLiveKitUrl, 'token-placeholder');
      
      // 2. Configuration audio
      _localAudio = await LocalAudioTrack.create();
      await _room!.localParticipant?.publishAudioTrack(_localAudio!);
      
      // 3. Écoute des tracks distants
      _room!.events.listen((event) {
        if (event is TrackSubscribedEvent) {
          if (event.track is RemoteAudioTrack) {
            _remoteAudio = event.track as RemoteAudioTrack;
          }
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('Erreur connexion LiveKit: $e');
      return false;
    }
  }
  
  /// Termine la conversation
  Future<void> endConversation() async {
    await _localAudio?.stop();
    await _room?.disconnect();
    _room = null;
    _localAudio = null;
    _remoteAudio = null;
  }
  
  /// Nettoyage
  void dispose() {
    _transcriptionController.close();
    _metricsController.close();
    _conversationController.close();
  }
}
