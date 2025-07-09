import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';
import '../../../../data/services/api_service.dart';
import '../../../../src/services/clean_livekit_service.dart';
import '../../data/datasources/confidence_local_datasource.dart';
import '../../data/datasources/confidence_remote_datasource.dart';
import '../../data/repositories/confidence_repository_impl.dart';
import '../../data/services/confidence_analysis_service.dart';
import '../../data/services/text_support_generator.dart';
import '../../domain/entities/confidence_models.dart' as ConfidenceModels;
import '../../domain/entities/confidence_scenario.dart' as ConfidenceScenarios;
import '../../domain/entities/confidence_session.dart';
import '../../domain/repositories/confidence_repository.dart';

// ... (providers existants inchangés) ...

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
final confidenceScenariosProvider = FutureProvider<List<ConfidenceScenarios.ConfidenceScenario>>((ref) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getScenarios();
});


final confidenceBoostProvider = ChangeNotifierProvider((ref) {
  // Ici, vous pouvez passer les dépendances nécessaires au provider
  // Par exemple, le service LiveKit, le service d'analyse, etc.
  return ConfidenceBoostProvider(
    livekitIntegration: ref.watch(livekitServiceProvider),
    // Assurez-vous que les autres dépendances sont fournies
    analysisService: ref.watch(confidenceAnalysisServiceProvider),
    repository: ref.watch(confidenceRepositoryProvider),
  );
});


class ConfidenceBoostProvider with ChangeNotifier {
  final CleanLiveKitService livekitIntegration;
  final ConfidenceAnalysisService analysisService;
  final ConfidenceRepository repository;

  ConfidenceBoostProvider({
    required this.livekitIntegration,
    required this.analysisService,
    required this.repository,
  }) {
    logger.i("ConfidenceBoostProvider created!");
  }

  final logger = Logger();

  // NOUVEAUX états
  ConfidenceModels.TextSupport? _currentTextSupport;
  ConfidenceModels.SupportType _selectedSupportType = ConfidenceModels.SupportType.fillInBlanks;
  bool _isGeneratingSupport = false;
  ConfidenceModels.ConfidenceAnalysis? _lastAnalysis;

  // Getters
  ConfidenceModels.TextSupport? get currentTextSupport => _currentTextSupport;
  ConfidenceModels.SupportType get selectedSupportType => _selectedSupportType;
  bool get isGeneratingSupport => _isGeneratingSupport;
  ConfidenceModels.ConfidenceAnalysis? get lastAnalysis => _lastAnalysis;

  // NOUVELLE méthode pour générer le support texte
  Future<void> generateTextSupport({
    required ConfidenceScenarios.ConfidenceScenario scenario,
    required ConfidenceModels.SupportType type,
  }) async {
    logger.i("Generating text support for scenario: ${scenario.title}, type: $type");
    _isGeneratingSupport = true;
    notifyListeners();

    try {
      // Utiliser Mistral via votre pipeline LiveKit existant
      final generator = TextSupportGenerator();
      final support = await generator.generateSupport(
        scenario: scenario,
        type: type,
        difficulty: scenario.difficulty,
      );

      _currentTextSupport = support;
      _selectedSupportType = type;
    } catch (e) {
      logger.e('Erreur génération support: $e');
    } finally {
      _isGeneratingSupport = false;
      notifyListeners();
    }
  }

  // NOUVELLE méthode pour analyser la performance
  Future<void> analyzePerformance({
    required ConfidenceScenarios.ConfidenceScenario scenario,
    required ConfidenceModels.TextSupport textSupport,
    required Duration recordingDuration,
  }) async {
    logger.i("Analyzing performance for scenario: ${scenario.title}");
    logger.d("DEBUG: scenario type = ${scenario.runtimeType}");
    try {
      // Utiliser votre ConfidenceLiveKitIntegration existant
      final analysis = await livekitIntegration.requestConfidenceAnalysis(
        scenario: scenario,
        recordingDurationSeconds: recordingDuration.inSeconds,
      );

      logger.d("DEBUG: analysis type = ${analysis.runtimeType}");
      logger.d("DEBUG: _lastAnalysis type = ${_lastAnalysis.runtimeType}");
      _lastAnalysis = analysis;
      notifyListeners();
    } catch (e) {
      logger.e('Erreur analyse: $e');
    }
  }
}

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