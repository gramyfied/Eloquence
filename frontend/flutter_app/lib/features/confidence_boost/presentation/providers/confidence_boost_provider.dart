import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../data/services/api_service.dart';
import '../../../../src/services/clean_livekit_service.dart';
import '../../data/datasources/confidence_local_datasource.dart';
import '../../data/datasources/confidence_remote_datasource.dart';
import '../../data/repositories/confidence_repository_impl.dart';
import '../../data/services/confidence_analysis_service.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';
import '../../domain/repositories/confidence_repository.dart';

// Provider pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

// Provider pour ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(apiKey: 'your-api-key'); // TODO: Récupérer depuis la config
});

// Provider pour CleanLiveKitService
final livekitServiceProvider = Provider<CleanLiveKitService>((ref) {
  return CleanLiveKitService();
});

// Provider pour le datasource local
final confidenceLocalDataSourceProvider = Provider<ConfidenceLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return ConfidenceLocalDataSourceImpl(sharedPreferences: sharedPreferences);
});

// Provider pour le datasource remote
final confidenceRemoteDataSourceProvider = Provider<ConfidenceRemoteDataSource>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConfidenceRemoteDataSourceImpl(
    apiService: apiService,
    supabaseClient: SupabaseConfig.client,
  );
});

// Provider pour le repository
final confidenceRepositoryProvider = Provider<ConfidenceRepository>((ref) {
  final localDataSource = ref.watch(confidenceLocalDataSourceProvider);
  final remoteDataSource = ref.watch(confidenceRemoteDataSourceProvider);
  return ConfidenceRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// Provider pour le service d'analyse
final confidenceAnalysisServiceProvider = Provider<ConfidenceAnalysisService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final livekitService = ref.watch(livekitServiceProvider);
  return ConfidenceAnalysisService(
    apiService: apiService,
    livekitService: livekitService,
  );
});

// Provider pour récupérer les scénarios
final confidenceScenariosProvider = FutureProvider<List<ConfidenceScenario>>((ref) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getScenarios();
});

// Provider pour récupérer un scénario aléatoire
final randomConfidenceScenarioProvider = FutureProvider<ConfidenceScenario>((ref) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getRandomScenario();
});

// Provider pour les statistiques utilisateur
final confidenceStatsProvider = FutureProvider.family<ConfidenceStats, String>((ref, userId) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getUserStats(userId);
});

// Provider pour l'historique des sessions
final userConfidenceSessionsProvider = FutureProvider.family<List<ConfidenceSession>, String>((ref, userId) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getUserSessions(userId);
});

// État de la session en cours
class ConfidenceSessionState {
  final ConfidenceSession? currentSession;
  final bool isRecording;
  final int recordingSeconds;
  final bool isAnalyzing;
  final String? error;

  const ConfidenceSessionState({
    this.currentSession,
    this.isRecording = false,
    this.recordingSeconds = 0,
    this.isAnalyzing = false,
    this.error,
  });

  ConfidenceSessionState copyWith({
    ConfidenceSession? currentSession,
    bool? isRecording,
    int? recordingSeconds,
    bool? isAnalyzing,
    String? error,
  }) {
    return ConfidenceSessionState(
      currentSession: currentSession ?? this.currentSession,
      isRecording: isRecording ?? this.isRecording,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

// Provider pour gérer l'état de la session en cours
class ConfidenceSessionNotifier extends StateNotifier<ConfidenceSessionState> {
  final ConfidenceRepository repository;
  final ConfidenceAnalysisService analysisService;
  final String userId;

  ConfidenceSessionNotifier({
    required this.repository,
    required this.analysisService,
    required this.userId,
  }) : super(const ConfidenceSessionState());

  // Démarrer une nouvelle session
  Future<void> startSession(ConfidenceScenario scenario) async {
    try {
      state = state.copyWith(error: null);
      
      final session = await repository.startSession(
        userId: userId,
        scenario: scenario,
      );
      
      state = state.copyWith(currentSession: session);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Démarrer l'enregistrement
  void startRecording() {
    if (state.currentSession == null) return;
    state = state.copyWith(isRecording: true, recordingSeconds: 0);
  }

  // Mettre à jour le temps d'enregistrement
  void updateRecordingTime(int seconds) {
    if (!state.isRecording) return;
    state = state.copyWith(recordingSeconds: seconds);
  }

  // Arrêter l'enregistrement et analyser
  Future<void> stopRecordingAndAnalyze(String audioFilePath) async {
    if (state.currentSession == null || !state.isRecording) return;

    try {
      state = state.copyWith(isRecording: false, isAnalyzing: true, error: null);

      // Analyser l'audio
      final analysis = await analysisService.analyzeRecording(
        audioFilePath: audioFilePath,
        scenario: state.currentSession!.scenario,
        recordingDurationSeconds: state.recordingSeconds,
      );

      // Compléter la session
      final completedSession = await repository.completeSession(
        sessionId: state.currentSession!.id,
        audioFilePath: audioFilePath,
        recordingDurationSeconds: state.recordingSeconds,
        analysis: analysis,
      );

      state = state.copyWith(
        currentSession: completedSession,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  // Réinitialiser la session
  void resetSession() {
    state = const ConfidenceSessionState();
  }

  // Alias pour la compatibilité
  void reset() => resetSession();
}

// Provider pour la session en cours
final confidenceSessionProvider = StateNotifierProvider.family<ConfidenceSessionNotifier, ConfidenceSessionState, String>((ref, userId) {
  final repository = ref.watch(confidenceRepositoryProvider);
  final analysisService = ref.watch(confidenceAnalysisServiceProvider);
  
  return ConfidenceSessionNotifier(
    repository: repository,
    analysisService: analysisService,
    userId: userId,
  );
});

// Provider pour vérifier si l'utilisateur peut débloquer un badge
final badgeCheckProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final stats = await ref.watch(confidenceStatsProvider(userId).future);
  final availableBadges = <String>[];

  // Vérifier les badges débloquables
  if (stats.totalSessions == 0) {
    availableBadges.add('first_victory');
  }
  if (stats.consecutiveDays >= 7 && !stats.unlockedBadges.contains('regular_speaker')) {
    availableBadges.add('regular_speaker');
  }
  if (stats.totalSessions >= 30 && !stats.unlockedBadges.contains('marathon_speaker')) {
    availableBadges.add('marathon_speaker');
  }
  if (stats.averageConfidenceScore >= 0.9 && !stats.unlockedBadges.contains('confidence_master')) {
    availableBadges.add('confidence_master');
  }

  return availableBadges;
});

// Définition des badges
class ConfidenceBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String requirement;

  const ConfidenceBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
  });
}

// Provider pour la liste des badges
final confidenceBadgesProvider = Provider<List<ConfidenceBadge>>((ref) {
  return [
    const ConfidenceBadge(
      id: 'first_victory',
      name: 'Première Victoire',
      description: 'Complétez votre première session',
      icon: '🏆',
      requirement: '1 session complétée',
    ),
    const ConfidenceBadge(
      id: 'regular_speaker',
      name: 'Orateur Régulier',
      description: 'Pratiquez pendant 7 jours consécutifs',
      icon: '📅',
      requirement: '7 jours consécutifs',
    ),
    const ConfidenceBadge(
      id: 'confidence_master',
      name: 'Maître de la Confiance',
      description: 'Obtenez un score de confiance supérieur à 90%',
      icon: '👑',
      requirement: 'Score > 90%',
    ),
    const ConfidenceBadge(
      id: 'clear_voice',
      name: 'Voix Claire',
      description: 'Obtenez un score de clarté supérieur à 85%',
      icon: '🎤',
      requirement: 'Clarté > 85%',
    ),
    const ConfidenceBadge(
      id: 'contagious_energy',
      name: 'Énergie Contagieuse',
      description: 'Obtenez un score d\'énergie supérieur à 85%',
      icon: '⚡',
      requirement: 'Énergie > 85%',
    ),
    const ConfidenceBadge(
      id: 'marathon_speaker',
      name: 'Marathonien',
      description: 'Complétez 30 sessions',
      icon: '🏃',
      requirement: '30 sessions',
    ),
    const ConfidenceBadge(
      id: 'versatile_speaker',
      name: 'Polyvalent',
      description: 'Essayez tous les types de scénarios',
      icon: '🎭',
      requirement: 'Tous les scénarios',
    ),
    const ConfidenceBadge(
      id: 'perfectionist',
      name: 'Perfectionniste',
      description: 'Obtenez un score global supérieur à 95%',
      icon: '💎',
      requirement: 'Score global > 95%',
    ),
  ];
});