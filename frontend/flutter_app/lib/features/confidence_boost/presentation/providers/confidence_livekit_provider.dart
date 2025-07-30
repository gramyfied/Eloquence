import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/confidence_livekit_service.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// Provider d'état pour Confidence Boost avec LiveKit
/// REMPLACE complètement universal_exercise_provider.dart
class ConfidenceLiveKitNotifier extends StateNotifier<ConfidenceLiveKitState> {
  final ConfidenceLiveKitService _livekitService;

  ConfidenceLiveKitNotifier(this._livekitService) : super(ConfidenceLiveKitState.initial()) {
    _initializeListeners();
  }

  /// Configuration des listeners du service LiveKit
  void _initializeListeners() {
    // Écouter les phases de l'exercice
    _livekitService.phaseStream.listen((phase) {
      state = state.copyWith(currentPhase: phase);
    });

    // Écouter les messages de conversation
    _livekitService.conversationStream.listen((message) {
      final updatedMessages = [...state.conversationMessages, message];
      state = state.copyWith(conversationMessages: updatedMessages);
    });

    // Écouter les transcriptions temps réel
    _livekitService.transcriptionStream.listen((transcription) {
      state = state.copyWith(currentTranscription: transcription);
    });

    // Écouter les métriques de confiance
    _livekitService.metricsStream.listen((metrics) {
      final updatedMetrics = [...state.confidenceMetrics, metrics];
      state = state.copyWith(confidenceMetrics: updatedMetrics);
    });

    // Écouter les erreurs
    _livekitService.errorStream.listen((error) {
      state = state.copyWith(
        currentPhase: ExercisePhase.error,
        errorMessage: error,
      );
    });
  }

  /// Démarre une session Confidence Boost
  Future<bool> startSession({
    required ConfidenceScenario scenario,
    required String userId,
  }) async {
    debugPrint('🚀 Démarrage session Confidence Boost LiveKit');
    
    state = state.copyWith(
      currentPhase: ExercisePhase.connecting,
      currentScenario: scenario,
      conversationMessages: [],
      confidenceMetrics: [],
      errorMessage: null,
    );

    final success = await _livekitService.startConfidenceBoostSession(
      scenario: scenario,
      userId: userId,
    );

    if (!success) {
      state = state.copyWith(
        currentPhase: ExercisePhase.error,
        errorMessage: 'Impossible de démarrer la session LiveKit',
      );
    }

    return success;
  }

  /// Envoie un message utilisateur
  Future<void> sendMessage(String content) async {
    debugPrint('📤 Envoi message: $content');
    
    if (state.currentPhase != ExercisePhase.ready && 
        state.currentPhase != ExercisePhase.listening) {
      debugPrint('⚠️ Session non prête pour envoi message');
      return;
    }

    await _livekitService.sendUserMessage(content);
  }

  /// Termine la session
  Future<void> endSession() async {
    debugPrint('🛑 Fin session Confidence Boost');
    
    await _livekitService.endSession();
    
    state = state.copyWith(
      currentPhase: ExercisePhase.ended,
    );
  }

  /// Reconnecte en cas de problème
  Future<bool> reconnect() async {
    debugPrint('🔄 Reconnexion LiveKit...');
    
    state = state.copyWith(currentPhase: ExercisePhase.reconnecting);
    
    final success = await _livekitService.reconnect();
    
    if (!success) {
      state = state.copyWith(
        currentPhase: ExercisePhase.error,
        errorMessage: 'Impossible de reconnecter',
      );
    }

    return success;
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    debugPrint('🧹 Dispose du provider LiveKit');
    _livekitService.dispose();
    super.dispose();
  }
}

/// État de l'exercice Confidence Boost avec LiveKit
class ConfidenceLiveKitState {
  final ExercisePhase currentPhase;
  final ConfidenceScenario? currentScenario;
  final List<ConversationMessage> conversationMessages;
  final List<ConfidenceMetrics> confidenceMetrics;
  final String? currentTranscription;
  final String? errorMessage;
  final bool isConnected;

  const ConfidenceLiveKitState({
    required this.currentPhase,
    this.currentScenario,
    required this.conversationMessages,
    required this.confidenceMetrics,
    this.currentTranscription,
    this.errorMessage,
    required this.isConnected,
  });

  factory ConfidenceLiveKitState.initial() {
    return const ConfidenceLiveKitState(
      currentPhase: ExercisePhase.idle,
      conversationMessages: [],
      confidenceMetrics: [],
      isConnected: false,
    );
  }

  ConfidenceLiveKitState copyWith({
    ExercisePhase? currentPhase,
    ConfidenceScenario? currentScenario,
    List<ConversationMessage>? conversationMessages,
    List<ConfidenceMetrics>? confidenceMetrics,
    String? currentTranscription,
    String? errorMessage,
    bool? isConnected,
  }) {
    return ConfidenceLiveKitState(
      currentPhase: currentPhase ?? this.currentPhase,
      currentScenario: currentScenario ?? this.currentScenario,
      conversationMessages: conversationMessages ?? this.conversationMessages,
      confidenceMetrics: confidenceMetrics ?? this.confidenceMetrics,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      errorMessage: errorMessage ?? this.errorMessage,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Getters utilitaires
  bool get isReady => currentPhase == ExercisePhase.ready;
  bool get isConnecting => currentPhase == ExercisePhase.connecting;
  bool get hasError => currentPhase == ExercisePhase.error;
  bool get isListening => currentPhase == ExercisePhase.listening;
  bool get isProcessing => currentPhase == ExercisePhase.processing;
  
  ConfidenceMetrics? get latestMetrics => 
      confidenceMetrics.isNotEmpty ? confidenceMetrics.last : null;
      
  ConversationMessage? get latestMessage => 
      conversationMessages.isNotEmpty ? conversationMessages.last : null;
}

/// Provider d'instance du service LiveKit
final confidenceLiveKitServiceProvider = Provider<ConfidenceLiveKitService>((ref) {
  return ConfidenceLiveKitService();
});

/// Provider principal pour l'état LiveKit de Confidence Boost
final confidenceLiveKitProvider = StateNotifierProvider<ConfidenceLiveKitNotifier, ConfidenceLiveKitState>((ref) {
  final service = ref.watch(confidenceLiveKitServiceProvider);
  return ConfidenceLiveKitNotifier(service);
});

/// Provider de l'état de connexion LiveKit
final livekitConnectionStateProvider = Provider<bool>((ref) {
  final service = ref.watch(confidenceLiveKitServiceProvider);
  return service.isConnected;
});

/// Provider des métriques temps réel
final realtimeMetricsProvider = Provider<ConfidenceMetrics?>((ref) {
  final state = ref.watch(confidenceLiveKitProvider);
  return state.latestMetrics;
});

/// Provider des messages de conversation
final conversationMessagesProvider = Provider<List<ConversationMessage>>((ref) {
  final state = ref.watch(confidenceLiveKitProvider);
  return state.conversationMessages;
});

/// Provider de la phase actuelle
final exercisePhaseProvider = Provider<ExercisePhase>((ref) {
  final state = ref.watch(confidenceLiveKitProvider);
  return state.currentPhase;
});