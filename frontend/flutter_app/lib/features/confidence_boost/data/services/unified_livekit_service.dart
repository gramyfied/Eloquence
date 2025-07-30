import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// Service LiveKit unifié - REMPLACE tous les autres pipelines audio
class UnifiedLiveKitService {
  static String get livekitUrl {
    // Utiliser la configuration centralisée
    return AppConfig.livekitUrl;
  }
  
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
  
  /// Démarre une conversation unifiée avec configuration réseau correcte
  Future<bool> startConversation(ConfidenceScenario scenario) async {
    try {
      debugPrint('🔗 Connexion LiveKit vers: ${livekitUrl}');
      
      // 1. Obtenir un token valide depuis le service
      final token = await _getValidToken(scenario);
      if (token == null) {
        debugPrint('❌ Impossible d\'obtenir un token');
        return false;
      }
      
      // 2. Connexion LiveKit avec URL et token corrects
      _room = Room();
      await _room!.connect(livekitUrl, token);
      
      debugPrint('✅ Connexion LiveKit réussie');
      
      // 3. Configuration audio (à implémenter dans les prochains prompts)
      return true;
    } catch (e) {
      debugPrint('❌ Erreur connexion LiveKit: $e');
      return false;
    }
  }

  /// Obtient un token valide depuis le service backend
  Future<String?> _getValidToken(ConfidenceScenario scenario) async {
    try {
      final tokenServiceUrl = '${AppConfig.livekitTokenUrl}/generate-token';
      debugPrint('🎫 Demande token vers: $tokenServiceUrl');
      
      final response = await http.post(
        Uri.parse(tokenServiceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'room_name': 'confidence_boost_${scenario.id}_${DateTime.now().millisecondsSinceEpoch}',
          'participant_name': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'participant_identity': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'grants': {
            'roomJoin': true,
            'canPublish': true,
            'canSubscribe': true,
            'canPublishData': true,
            'canUpdateOwnMetadata': true,
          },
          'metadata': {
            'scenario_id': scenario.id,
            'scenario_title': scenario.title,
            'exercise_type': 'confidence_boost',
            'timestamp': DateTime.now().toIso8601String(),
          },
          'validity_hours': 2, // Token valide 2 heures
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final roomName = data['room_name'] as String?;
        final expiresAt = data['expires_at'] as String?;
        
        if (token != null) {
          debugPrint('✅ Token LiveKit obtenu pour room: $roomName (expire: $expiresAt)');
          return token;
        } else {
          throw Exception('Token manquant dans la réponse');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur obtention token: $e');
      return null;
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
