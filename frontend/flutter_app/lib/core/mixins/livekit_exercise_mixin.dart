import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/universal_livekit_audio_service.dart';

/// Mixin pour faciliter l'intégration LiveKit dans les exercices
/// 
/// Utilisation :
/// ```dart
/// class MonExerciceScreen extends ConsumerStatefulWidget
///     with LiveKitExerciseMixin {
///   
///   @override
///   void initState() {
///     super.initState();
///     initializeAudio(exerciseType: 'mon_exercice');
///   }
///   
///   @override
///   void onTranscriptionReceived(String text) {
///     // Traiter la transcription
///   }
/// }
/// ```
mixin LiveKitExerciseMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  UniversalLiveKitAudioService? _audioService;
  bool _isAudioActive = false;
  bool _isInitializing = false;

  /// Initialisation audio pour l'exercice
  /// 
  /// [exerciseType] : Type d'exercice (confidence_boost, presentation_skills, etc.)
  /// [config] : Configuration optionnelle spécifique à l'exercice
  Future<void> initializeAudio({
    required String exerciseType,
    Map<String, dynamic>? config,
  }) async {
    if (_isInitializing || _isAudioActive) {
      return; // Éviter les initialisations multiples
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      // Créer le service audio
      _audioService = UniversalLiveKitAudioService();
      
      // Configuration des callbacks
      _audioService!.onTranscriptionReceived = onTranscriptionReceived;
      _audioService!.onAIResponseReceived = onAIResponseReceived;
      _audioService!.onMetricsReceived = onMetricsReceived;
      _audioService!.onErrorOccurred = onAudioError;
      _audioService!.onConnected = onAudioConnected;
      _audioService!.onDisconnected = onAudioDisconnected;
      
      // Connexion à LiveKit
      final success = await _audioService!.connectToExercise(
        exerciseType: exerciseType,
        userId: _getUserId(), // À implémenter selon votre système d'auth
        exerciseConfig: config,
      );
      
      if (success) {
        setState(() {
          _isAudioActive = true;
          _isInitializing = false;
        });
        onAudioInitialized();
      } else {
        setState(() {
          _isInitializing = false;
        });
        onAudioError('Échec de l\'initialisation audio');
      }
      
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      onAudioError('Erreur initialisation: $e');
    }
  }

  /// Nettoyage audio (à appeler dans dispose())
  Future<void> cleanupAudio() async {
    try {
      await _audioService?.disconnect();
      setState(() {
        _isAudioActive = false;
        _isInitializing = false;
      });
      _audioService = null;
    } catch (e) {
      debugPrint('Erreur nettoyage audio: $e');
    }
  }

  /// Envoyer des données à l'agent IA
  Future<void> sendToAI({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _audioService?.sendData(type: type, data: data);
  }

  /// Reconnecter en cas de problème
  Future<void> reconnectAudio() async {
    if (_audioService != null) {
      final success = await _audioService!.reconnect();
      setState(() {
        _isAudioActive = success;
      });
    }
  }

  // ========================================
  // MÉTHODES À IMPLÉMENTER DANS L'EXERCICE
  // ========================================

  /// Appelée quand une transcription est reçue
  void onTranscriptionReceived(String text);

  /// Appelée quand une réponse IA est reçue
  void onAIResponseReceived(String response);

  /// Appelée quand des métriques sont reçues
  void onMetricsReceived(Map<String, dynamic> metrics);

  /// Appelée en cas d'erreur audio
  void onAudioError(String error);

  // ========================================
  // MÉTHODES OPTIONNELLES (avec implémentation par défaut)
  // ========================================

  /// Appelée quand l'audio est connecté
  void onAudioConnected() {
    debugPrint('🎤 Audio connecté');
  }

  /// Appelée quand l'audio est déconnecté
  void onAudioDisconnected() {
    debugPrint('🔌 Audio déconnecté');
    setState(() {
      _isAudioActive = false;
    });
  }

  /// Appelée quand l'initialisation audio est terminée
  void onAudioInitialized() {
    debugPrint('✅ Audio initialisé');
  }

  /// Obtenir l'ID utilisateur (à personnaliser selon votre système)
  String _getUserId() {
    // TODO: Récupérer l'ID utilisateur depuis votre système d'authentification
    // Par exemple : ref.read(authProvider).currentUser?.id ?? 'anonymous'
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ========================================
  // GETTERS UTILES
  // ========================================

  /// L'audio est-il actif ?
  bool get isAudioActive => _isAudioActive;

  /// L'audio est-il en cours d'initialisation ?
  bool get isAudioInitializing => _isInitializing;

  /// Le service audio (pour usage avancé)
  UniversalLiveKitAudioService? get audioService => _audioService;

  /// État de connexion détaillé
  String get audioStatus {
    if (_isInitializing) return 'Initialisation...';
    if (_isAudioActive) return 'Connecté';
    return 'Déconnecté';
  }

  // ========================================
  // WIDGETS UTILES
  // ========================================

  /// Widget indicateur d'état audio
  Widget buildAudioStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            audioStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur selon l'état
  Color _getStatusColor() {
    if (_isInitializing) return Colors.orange;
    if (_isAudioActive) return Colors.green;
    return Colors.red;
  }

  /// Icône selon l'état
  IconData _getStatusIcon() {
    if (_isInitializing) return Icons.sync;
    if (_isAudioActive) return Icons.mic;
    return Icons.mic_off;
  }

  /// Widget bouton de reconnexion
  Widget buildReconnectButton() {
    if (_isAudioActive || _isInitializing) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: reconnectAudio,
      icon: const Icon(Icons.refresh),
      label: const Text('Reconnecter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Provider pour le service audio universel (optionnel)
final universalLiveKitServiceProvider = Provider<UniversalLiveKitAudioService>(
  (ref) => UniversalLiveKitAudioService(),
);
