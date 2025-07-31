import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scenario_models.dart';
import '../../domain/entities/feedback_models.dart';

/// Provider pour gérer l'état des scénarios IA
final scenarioProvider = StateNotifierProvider<ScenarioNotifier, ScenarioState>((ref) {
  return ScenarioNotifier();
});

/// État global des scénarios
class ScenarioState {
  final ScenarioConfiguration? currentConfiguration;
  final ExerciseSession? currentSession;
  final SessionResults? lastResults;
  final List<SessionResults> history;
  final bool isLoading;
  final String? error;

  const ScenarioState({
    this.currentConfiguration,
    this.currentSession,
    this.lastResults,
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  ScenarioState copyWith({
    ScenarioConfiguration? currentConfiguration,
    ExerciseSession? currentSession,
    SessionResults? lastResults,
    List<SessionResults>? history,
    bool? isLoading,
    String? error,
  }) {
    return ScenarioState(
      currentConfiguration: currentConfiguration ?? this.currentConfiguration,
      currentSession: currentSession ?? this.currentSession,
      lastResults: lastResults ?? this.lastResults,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier pour gérer les actions des scénarios
class ScenarioNotifier extends StateNotifier<ScenarioState> {
  ScenarioNotifier() : super(const ScenarioState());

  /// Définir la configuration du scénario
  void setConfiguration(ScenarioConfiguration configuration) {
    state = state.copyWith(
      currentConfiguration: configuration,
      error: null,
    );
  }

  /// Démarrer une nouvelle session d'exercice
  void startSession(ScenarioConfiguration configuration) {
    final session = ExerciseSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      configuration: configuration,
      startTime: DateTime.now(),
      state: ExerciseState.notStarted,
      metrics: ExerciseMetrics.empty(),
      aiMessages: [],
      userTranscripts: [],
      helpUsedCount: 0,
    );

    state = state.copyWith(
      currentSession: session,
      currentConfiguration: configuration,
      error: null,
    );
  }

  /// Mettre à jour l'état de la session
  void updateSessionState(ExerciseState exerciseState) {
    if (state.currentSession == null) return;

    state = state.copyWith(
      currentSession: state.currentSession!.copyWith(
        state: exerciseState,
      ),
    );
  }

  /// Mettre à jour les métriques en temps réel
  void updateMetrics(ExerciseMetrics metrics) {
    if (state.currentSession == null) return;

    state = state.copyWith(
      currentSession: state.currentSession!.copyWith(
        metrics: metrics,
      ),
    );
  }

  /// Ajouter un message de l'IA
  void addAIMessage(String message) {
    if (state.currentSession == null) return;

    final updatedMessages = [...state.currentSession!.aiMessages, message];
    
    state = state.copyWith(
      currentSession: state.currentSession!.copyWith(
        aiMessages: updatedMessages,
      ),
    );
  }

  /// Ajouter une transcription utilisateur
  void addUserTranscript(String transcript) {
    if (state.currentSession == null) return;

    final updatedTranscripts = [...state.currentSession!.userTranscripts, transcript];
    
    state = state.copyWith(
      currentSession: state.currentSession!.copyWith(
        userTranscripts: updatedTranscripts,
      ),
    );
  }

  /// Incrémenter le compteur d'aide utilisée
  void incrementHelpUsed() {
    if (state.currentSession == null) return;

    state = state.copyWith(
      currentSession: state.currentSession!.copyWith(
        helpUsedCount: state.currentSession!.helpUsedCount + 1,
      ),
    );
  }

  /// Terminer la session et générer les résultats
  void completeSession() {
    if (state.currentSession == null) return;

    final completedSession = state.currentSession!.copyWith(
      state: ExerciseState.completed,
      endTime: DateTime.now(),
    );

    // Générer les résultats
    final results = SessionResults.generateFromSession(completedSession);

    // Ajouter aux historiques
    final updatedHistory = [...state.history, results];

    state = state.copyWith(
      currentSession: completedSession,
      lastResults: results,
      history: updatedHistory,
    );
  }

  /// Mettre en pause la session
  void pauseSession() {
    updateSessionState(ExerciseState.paused);
  }

  /// Reprendre la session
  void resumeSession() {
    updateSessionState(ExerciseState.recording);
  }

  /// Arrêter la session en cours
  void stopSession() {
    if (state.currentSession == null) return;

    state = state.copyWith(
      currentSession: null,
    );
  }

  /// Définir un état de chargement
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Définir une erreur
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Obtenir les statistiques globales
  Map<String, dynamic> getGlobalStats() {
    if (state.history.isEmpty) {
      return {
        'totalSessions': 0,
        'averageScore': 0.0,
        'totalTime': Duration.zero,
        'favoriteScenario': null,
        'improvementTrend': 0.0,
      };
    }

    final totalSessions = state.history.length;
    final averageScore = state.history
        .map((r) => r.analysis.overallScore)
        .reduce((a, b) => a + b) / totalSessions;

    final totalTime = state.history
        .map((r) => r.session.totalDuration)
        .reduce((a, b) => a + b);

    // Scénario le plus pratiqué
    final scenarioCounts = <ScenarioType, int>{};
    for (final result in state.history) {
      final type = result.session.configuration.type;
      scenarioCounts[type] = (scenarioCounts[type] ?? 0) + 1;
    }
    
    final favoriteScenario = scenarioCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Tendance d'amélioration (comparaison des 3 dernières vs 3 premières)
    double improvementTrend = 0.0;
    if (totalSessions >= 6) {
      final firstThree = state.history.take(3)
          .map((r) => r.analysis.overallScore)
          .reduce((a, b) => a + b) / 3;
      final lastThree = state.history.skip(totalSessions - 3)
          .map((r) => r.analysis.overallScore)
          .reduce((a, b) => a + b) / 3;
      improvementTrend = lastThree - firstThree;
    }

    return {
      'totalSessions': totalSessions,
      'averageScore': averageScore,
      'totalTime': totalTime,
      'favoriteScenario': favoriteScenario,
      'improvementTrend': improvementTrend,
    };
  }

  /// Obtenir les résultats par type de scénario
  Map<ScenarioType, List<SessionResults>> getResultsByScenario() {
    final resultsByScenario = <ScenarioType, List<SessionResults>>{};
    
    for (final result in state.history) {
      final type = result.session.configuration.type;
      resultsByScenario[type] = [...(resultsByScenario[type] ?? []), result];
    }
    
    return resultsByScenario;
  }

  /// Obtenir la progression dans le temps
  List<ChartDataPoint> getProgressOverTime() {
    return state.history.map((result) {
      return ChartDataPoint(
        date: result.completedAt,
        value: result.analysis.overallScore.toDouble(),
        label: result.session.configuration.type.displayName,
      );
    }).toList();
  }
}

/// Provider pour les statistiques globales
final globalStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final scenarioState = ref.watch(scenarioProvider);
  return ref.read(scenarioProvider.notifier).getGlobalStats();
});

/// Provider pour les résultats par scénario
final resultsByScenarioProvider = Provider<Map<ScenarioType, List<SessionResults>>>((ref) {
  final scenarioState = ref.watch(scenarioProvider);
  return ref.read(scenarioProvider.notifier).getResultsByScenario();
});

/// Provider pour la progression dans le temps
final progressOverTimeProvider = Provider<List<ChartDataPoint>>((ref) {
  final scenarioState = ref.watch(scenarioProvider);
  return ref.read(scenarioProvider.notifier).getProgressOverTime();
});
