import 'dart:typed_data';
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
import '../../data/services/confidence_livekit_integration.dart';
import '../../data/services/text_support_generator.dart';
import '../../data/services/confidence_analysis_backend_service.dart';
import '../../data/services/prosody_analysis_interface.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_scenario.dart' as confidence_scenarios;
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

// Provider pour le service d'intégration LiveKit
final confidenceLiveKitIntegrationProvider = Provider<ConfidenceLiveKitIntegration>((ref) {
  final livekitService = ref.watch(livekitServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return ConfidenceLiveKitIntegration(
    livekitService: livekitService,
    apiService: apiService,
  );
});

// Provider pour le service d'analyse backend (Whisper + Mistral)
final confidenceAnalysisBackendServiceProvider = Provider<ConfidenceAnalysisBackendService>((ref) {
  return ConfidenceAnalysisBackendService();
});

// Provider pour l'interface d'analyse prosodique (Kaldi futur)
final prosodyAnalysisInterfaceProvider = Provider<ProsodyAnalysisInterface>((ref) {
  return FallbackProsodyAnalysis(); // Utilise le fallback en attendant Kaldi
});

// Provider pour récupérer les scénarios
final confidenceScenariosProvider = FutureProvider<List<confidence_scenarios.ConfidenceScenario>>((ref) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getScenarios();
});


final confidenceBoostProvider = ChangeNotifierProvider((ref) {
  return ConfidenceBoostProvider(
    livekitService: ref.watch(livekitServiceProvider),
    livekitIntegration: ref.watch(confidenceLiveKitIntegrationProvider),
    repository: ref.watch(confidenceRepositoryProvider),
    backendAnalysisService: ref.watch(confidenceAnalysisBackendServiceProvider),
    prosodyAnalysisInterface: ref.watch(prosodyAnalysisInterfaceProvider),
  );
});


class ConfidenceBoostProvider with ChangeNotifier {
  final CleanLiveKitService livekitService;
  final ConfidenceLiveKitIntegration livekitIntegration;
  final ConfidenceRepository repository;
  final ConfidenceAnalysisBackendService backendAnalysisService;
  final ProsodyAnalysisInterface prosodyAnalysisInterface;

  ConfidenceBoostProvider({
    required this.livekitService,
    required this.livekitIntegration,
    required this.repository,
    required this.backendAnalysisService,
    required this.prosodyAnalysisInterface,
  }) {
    logger.i("ConfidenceBoostProvider created!");
  }

  final logger = Logger();

  // NOUVEAUX états
  confidence_models.TextSupport? _currentTextSupport;
  confidence_models.SupportType _selectedSupportType = confidence_models.SupportType.fillInBlanks;
  bool _isGeneratingSupport = false;
  confidence_models.ConfidenceAnalysis? _lastAnalysis;

  // Getters
  confidence_models.TextSupport? get currentTextSupport => _currentTextSupport;
  confidence_models.SupportType get selectedSupportType => _selectedSupportType;
  bool get isGeneratingSupport => _isGeneratingSupport;
  confidence_models.ConfidenceAnalysis? get lastAnalysis => _lastAnalysis;

  // NOUVELLE méthode pour générer le support texte
  Future<void> generateTextSupport({
    required confidence_scenarios.ConfidenceScenario scenario,
    required confidence_models.SupportType type,
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

  // MÉTHODE PHASE 3 : Analyse backend avec Whisper + Mistral
  Future<void> analyzePerformance({
    required confidence_scenarios.ConfidenceScenario scenario,
    required confidence_models.TextSupport textSupport,
    required Duration recordingDuration,
    Uint8List? audioData, // Données audio de l'enregistrement
  }) async {
    logger.i("PHASE 3: Analysing performance via backend - Scenario: ${scenario.title}");
    
    try {
      // 1. Vérifier la disponibilité du service backend
      final isBackendAvailable = await backendAnalysisService.isServiceAvailable();
      logger.i("Backend service available: $isBackendAvailable");
      
      if (isBackendAvailable && audioData != null) {
        // 2. Analyser via le pipeline Whisper + Mistral
        final analysis = await backendAnalysisService.analyzeAudioRecording(
          audioData: audioData,
          scenario: scenario,
          userContext: 'Session d\'analyse de performance - Support: ${textSupport.type.name}',
          recordingDurationSeconds: recordingDuration.inSeconds,
        );
        
        if (analysis != null) {
          logger.i("Backend analysis completed successfully");
          _lastAnalysis = analysis;
          
          // 3. Enrichir avec l'analyse prosodique (Kaldi) si disponible
          try {
            final prosodyResult = await prosodyAnalysisInterface.analyzeProsody(
              audioData: audioData,
              scenario: scenario,
            );
            
            // Combiner les résultats si l'analyse prosodique a réussi
            if (prosodyResult != null) {
              logger.i("Prosody analysis completed - enhancing feedback");
              // Enrichir le feedback avec les données prosodiques
              final enrichedFeedback = "${analysis.feedback}\n\n"
                  "🎵 **Analyse Prosodique** :\n"
                  "• Débit de parole: ${prosodyResult.speechRate.wordsPerMinute.toStringAsFixed(0)} mots/min\n"
                  "• Variation intonation: ${(prosodyResult.intonation.f0Range).toStringAsFixed(0)} Hz\n"
                  "• Pauses détectées: ${prosodyResult.pauses.totalPauses} pauses";
              
              _lastAnalysis = confidence_models.ConfidenceAnalysis(
                overallScore: analysis.overallScore,
                confidenceScore: analysis.confidenceScore,
                fluencyScore: prosodyResult.speechRate.fluencyScore, // Utiliser le score prosodique
                clarityScore: analysis.clarityScore,
                energyScore: prosodyResult.energy.normalizedEnergyScore, // Utiliser l'énergie prosodique
                feedback: enrichedFeedback,
              );
            }
          } catch (e) {
            logger.w("Prosody analysis failed, continuing with backend-only results: $e");
          }
          
          notifyListeners();
          return;
        }
      }
      
      // 4. Fallback vers LiveKit si backend indisponible
      logger.w("Falling back to LiveKit integration");
      final success = await livekitIntegration.startSession(
        scenario: scenario,
        userContext: 'Session d\'analyse de performance (fallback)',
        preferredSupportType: textSupport.type,
      );

      if (success) {
        await livekitIntegration.startRecording();
        await Future.delayed(recordingDuration);
        await livekitIntegration.stopRecordingAndAnalyze();
        
        livekitIntegration.analysisStream.listen((analysis) {
          logger.i("LiveKit fallback analysis completed");
          _lastAnalysis = analysis;
          notifyListeners();
        });
      } else {
        // 5. Dernier fallback : CleanLiveKitService
        logger.w("Final fallback to CleanLiveKitService");
        final analysis = await livekitService.requestConfidenceAnalysis(
          scenario: scenario,
          recordingDurationSeconds: recordingDuration.inSeconds,
        );
        _lastAnalysis = analysis;
        notifyListeners();
      }
      
    } catch (e, stackTrace) {
      logger.e('Critical error in performance analysis: $e', error: e, stackTrace: stackTrace);
      
      // Fallback d'urgence avec analyse locale
      try {
        final fallbackAnalysis = confidence_models.ConfidenceAnalysis(
          overallScore: 70.0,
          confidenceScore: 0.70,
          fluencyScore: 0.65,
          clarityScore: 0.75,
          energyScore: 0.70,
          feedback: "⚠️ **Analyse Hors-ligne** : L'analyse complète n'est pas disponible.\n\n"
              "🎯 **Scénario** : ${scenario.title}\n"
              "⏱️ **Durée** : ${recordingDuration.inSeconds}s d'enregistrement\n\n"
              "💡 **Conseils** : ${scenario.tips.take(2).join(' • ')}"
        );
        
        _lastAnalysis = fallbackAnalysis;
        notifyListeners();
      } catch (fallbackError) {
        logger.e('Even fallback analysis failed: $fallbackError');
      }
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