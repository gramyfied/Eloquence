import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// Service audio universel basé sur LiveKit pour tous les exercices Eloquence
/// 
/// Utilisation simple :
/// ```dart
/// final service = UniversalLiveKitAudioService();
/// await service.connectToExercise(
///   exerciseType: 'confidence_boost',
///   userId: 'user123',
/// );
/// ```
class UniversalLiveKitAudioService {
  static final Logger _logger = Logger();
  
  // État de la connexion
  Room? _room;
  LocalAudioTrack? _audioTrack;
  bool _isConnected = false;
  bool _isPublishing = false;
  
  // Configuration
  String? _currentExerciseType;
  String? _currentUserId;
  Map<String, dynamic>? _exerciseConfig;
  
  // Callbacks pour les exercices
  Function(String)? onTranscriptionReceived;
  Function(String)? onAIResponseReceived;
  Function(Map<String, dynamic>)? onMetricsReceived;
  Function(String)? onErrorOccurred;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(double)? onAudioLevelChanged;

  // Getters publics
  bool get isConnected => _isConnected;
  bool get isPublishing => _isPublishing;
  String? get currentExerciseType => _currentExerciseType;
  Room? get room => _room;

  /// Connexion universelle à LiveKit pour un exercice
  /// 
  /// [exerciseType] : Type d'exercice (confidence_boost, presentation_skills, etc.)
  /// [userId] : Identifiant utilisateur
  /// [exerciseConfig] : Configuration spécifique à l'exercice
  Future<bool> connectToExercise({
    required String exerciseType,
    required String userId,
    Map<String, dynamic>? exerciseConfig,
  }) async {
    try {
      _logger.i('🔗 Connexion LiveKit pour exercice: $exerciseType');
      
      // Sauvegarder la configuration
      _currentExerciseType = exerciseType;
      _currentUserId = userId;
      _exerciseConfig = exerciseConfig;
      
      // 1. Obtenir token LiveKit
      final token = await _getLiveKitToken(exerciseType, userId, exerciseConfig);
      if (token == null) {
        throw Exception('Impossible d\'obtenir le token LiveKit');
      }
      
      // 2. Créer la room avec configuration simplifiée
      _room = Room();
      
      // 3. Configurer les listeners
      _setupRoomListeners();
      
      // 4. Se connecter à LiveKit avec URL configurée
      await _room!.connect(
        AppConfig.livekitUrl,
        token,
      );
      
      // 5. Publier l'audio
      await _publishAudio();
      
      _isConnected = true;
      _logger.i('✅ Connexion LiveKit réussie pour $exerciseType');
      onConnected?.call();
      
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur connexion LiveKit: $e', error: e, stackTrace: stackTrace);
      onErrorOccurred?.call('Erreur connexion LiveKit: $e');
      await _cleanup();
      return false;
    }
  }

  /// Publication automatique de l'audio
  Future<void> _publishAudio() async {
    try {
      if (_room?.localParticipant == null) {
        throw Exception('Participant local non disponible');
      }

      // Créer le track audio avec configuration basique
      _audioTrack = await LocalAudioTrack.create(AudioCaptureOptions());

      // Publier le track
      await _room!.localParticipant!.publishAudioTrack(_audioTrack!);
      
      _isPublishing = true;
      _logger.i('🎤 Audio publié avec succès');
      
    } catch (e) {
      _logger.e('❌ Erreur publication audio: $e');
      throw Exception('Impossible de publier l\'audio: $e');
    }
  }

  /// Configuration des listeners universels
  void _setupRoomListeners() {
    if (_room == null) return;

    // Listener principal de la room
    _room!.addListener(() {
      _logger.d('📡 Événement room: ${_room!.connectionState}');
    });

    // Événements de participants
    _room!.addListener(() {
      // Gestion basique des événements
      if (_room!.connectionState == ConnectionState.connected) {
        if (!_isConnected) {
          _isConnected = true;
          onConnected?.call();
        }
      } else if (_room!.connectionState == ConnectionState.disconnected) {
        if (_isConnected) {
          _isConnected = false;
          onDisconnected?.call();
        }
      }
    });
  }

  /// Configuration du monitoring audio
  void _setupAudioMonitoring(RemoteAudioTrack audioTrack) {
    // Ici on pourrait ajouter le monitoring du niveau audio
    // pour fournir un feedback visuel à l'utilisateur
  }

  /// Envoi de données à l'agent IA
  Future<void> sendData({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (!_isConnected || _room?.localParticipant == null) {
      _logger.w('⚠️ Tentative d\'envoi sans connexion active');
      return;
    }

    try {
      final message = {
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'exercise_type': _currentExerciseType,
        'user_id': _currentUserId,
        ...data,
      };

      final jsonData = jsonEncode(message);
      final bytes = utf8.encode(jsonData);

      await _room!.localParticipant!.publishData(
        bytes,
        reliable: true,
      );

      _logger.d('📤 Données envoyées: $type');
      
    } catch (e) {
      _logger.e('❌ Erreur envoi données: $e');
      onErrorOccurred?.call('Erreur envoi données: $e');
    }
  }

  /// Déconnexion propre
  Future<void> disconnect() async {
    _logger.i('🔌 Déconnexion LiveKit...');
    
    try {
      await _cleanup();
      _logger.i('✅ Déconnexion LiveKit terminée');
      
    } catch (e) {
      _logger.e('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Nettoyage des ressources
  Future<void> _cleanup() async {
    try {
      // Arrêter la publication audio
      if (_audioTrack != null) {
        await _audioTrack!.stop();
        _audioTrack = null;
      }

      // Déconnecter la room
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }

      // Réinitialiser l'état
      _isConnected = false;
      _isPublishing = false;
      _currentExerciseType = null;
      _currentUserId = null;
      _exerciseConfig = null;
      
    } catch (e) {
      _logger.e('❌ Erreur nettoyage: $e');
    }
  }

  /// Obtenir token LiveKit depuis le service de tokens
  Future<String?> _getLiveKitToken(
    String exerciseType,
    String userId,
    Map<String, dynamic>? config,
  ) async {
    try {
      // Utiliser l'URL correcte du service de tokens LiveKit
      final tokenServiceUrl = '${AppConfig.livekitTokenUrl}/generate-token';
      _logger.i('🎫 Demande token vers: $tokenServiceUrl');
      
      final response = await http.post(
        Uri.parse(tokenServiceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'room_name': 'confidence_boost_${exerciseType}_${DateTime.now().millisecondsSinceEpoch}',
          'participant_name': 'user_$userId',
          'participant_identity': userId,
          'grants': {
            'roomJoin': true,
            'canPublish': true,
            'canSubscribe': true,
            'canPublishData': true,
            'canUpdateOwnMetadata': true,
          },
          'metadata': {
            'exercise_type': exerciseType,
            'user_id': userId,
            'timestamp': DateTime.now().toIso8601String(),
            ...?config,
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
          _logger.i('✅ Token LiveKit obtenu pour room: $roomName (expire: $expiresAt)');
          return token;
        } else {
          throw Exception('Token manquant dans la réponse');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      _logger.e('❌ Erreur obtention token: $e');
      return null;
    }
  }

  /// Reconnecter automatiquement en cas de déconnexion
  Future<bool> reconnect() async {
    if (_currentExerciseType == null || _currentUserId == null) {
      _logger.w('⚠️ Impossible de reconnecter: configuration manquante');
      return false;
    }

    _logger.i('🔄 Tentative de reconnexion...');
    
    await _cleanup();
    
    return await connectToExercise(
      exerciseType: _currentExerciseType!,
      userId: _currentUserId!,
      exerciseConfig: _exerciseConfig,
    );
  }

  /// Dispose des ressources (à appeler dans dispose() du widget)
  void dispose() {
    disconnect();
  }
}
