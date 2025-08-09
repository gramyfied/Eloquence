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
      
      // 2. Créer la room avec configuration optimisée
      _room = Room();
      
      // 3. Configurer les listeners avec gestion d'erreurs robuste
      _setupRoomListeners();
      
      // 4. Se connecter à LiveKit avec URL configurée et options ICE
      await _room!.connect(
        AppConfig.livekitUrl,
        token,
        connectOptions: ConnectOptions(
          autoSubscribe: true,
        ),
      );
      
      // 5. Attendre que la connexion soit établie
      await _waitForConnection();
      
      // 6. Publier l'audio
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

  /// Attendre que la connexion soit établie
  Future<void> _waitForConnection() async {
    int attempts = 0;
    const maxAttempts = 30; // 30 secondes max
    
    while (_room?.connectionState != ConnectionState.connected && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
      _logger.d('⏳ Attente connexion... Tentative $attempts/$maxAttempts');
    }
    
    if (_room?.connectionState != ConnectionState.connected) {
      throw Exception('Timeout de connexion LiveKit après $maxAttempts secondes');
    }
  }

  /// Publication automatique de l'audio avec gestion d'erreurs améliorée
  Future<void> _publishAudio() async {
    try {
      if (_room?.localParticipant == null) {
        throw Exception('Participant local non disponible');
      }

      // Créer le track audio avec configuration optimisée
      _audioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );

      // Publier le track
      await _room!.localParticipant!.publishAudioTrack(_audioTrack!);
      
      _isPublishing = true;
      _logger.i('🎤 Audio publié avec succès');
      
    } catch (e) {
      _logger.e('❌ Erreur publication audio: $e');
      throw Exception('Impossible de publier l\'audio: $e');
    }
  }

  /// Configuration des listeners avec gestion robuste des événements
  void _setupRoomListeners() {
    if (_room == null) return;

    // Listener principal de la room avec gestion d'erreurs
    _room!.addListener(() {
      final state = _room!.connectionState;
      _logger.d('📡 Événement room: $state');
      
      switch (state) {
        case ConnectionState.connected:
          if (!_isConnected) {
            _isConnected = true;
            onConnected?.call();
          }
          break;
        case ConnectionState.disconnected:
          if (_isConnected) {
            _isConnected = false;
            onDisconnected?.call();
          }
          break;
        case ConnectionState.reconnecting:
          _logger.w('🔄 Reconnexion en cours...');
          break;
        case ConnectionState.disconnected:
          if (_isConnected) {
            _isConnected = false;
            onDisconnected?.call();
          }
          break;
        default:
          break;
      }
    });

    // Écouter les participants entrants
    _room!.addListener(() {
      for (final participant in _room!.remoteParticipants.values) {
        for (final publication in participant.audioTrackPublications) {
          if (publication.subscribed && publication.track != null) {
            final track = publication.track as RemoteAudioTrack;
            _setupAudioTrackListener(track);
          }
        }
      }
    });

    // Écouter les données reçues
    _room!.addListener(() {
      // Gérer les messages de données reçus
      // Cette fonctionnalité sera implémentée selon les besoins
    });
  }

  /// Configuration du listener pour un track audio distant
  void _setupAudioTrackListener(RemoteAudioTrack audioTrack) {
    audioTrack.addListener(() {
      // Ici on peut ajouter le monitoring du niveau audio
      // pour fournir un feedback visuel à l'utilisateur
      if (onAudioLevelChanged != null) {
        // Simuler un niveau audio (à adapter selon vos besoins)
        onAudioLevelChanged!(0.5);
      }
    });
  }

  /// Envoi de données à l'agent IA avec gestion d'erreurs améliorée
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
        topic: 'exercise_data',
      );

      _logger.d('📤 Données envoyées: $type');
      
    } catch (e) {
      _logger.e('❌ Erreur envoi données: $e');
      onErrorOccurred?.call('Erreur envoi données: $e');
    }
  }

  /// Déconnexion propre avec gestion d'erreurs
  Future<void> disconnect() async {
    _logger.i('🔌 Déconnexion LiveKit...');
    
    try {
      await _cleanup();
      _logger.i('✅ Déconnexion LiveKit terminée');
      
    } catch (e) {
      _logger.e('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Nettoyage des ressources avec gestion d'erreurs robuste
  Future<void> _cleanup() async {
    try {
      // Arrêter la publication audio
      if (_audioTrack != null) {
        await _audioTrack!.stop();
        _audioTrack = null;
      }

      // Déconnecter la room
      if (_room != null) {
        if (_room!.connectionState == ConnectionState.connected) {
          await _room!.disconnect();
        }
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

  /// Obtenir token LiveKit depuis le service de tokens avec gestion d'erreurs améliorée
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
          'room_name': 'exercise_${exerciseType}_${DateTime.now().millisecondsSinceEpoch}',
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
      ).timeout(const Duration(seconds: 15));

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
        final errorBody = response.body;
        _logger.e('❌ Erreur HTTP ${response.statusCode}: $errorBody');
        throw Exception('Erreur HTTP ${response.statusCode}: $errorBody');
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
