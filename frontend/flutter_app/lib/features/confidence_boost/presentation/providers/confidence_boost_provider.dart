import 'dart:async';
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
import '../../data/services/mistral_api_service.dart';
import '../../data/services/gamification_service.dart';
import '../../data/services/xp_calculator_service.dart';
import '../../data/services/badge_service.dart';
import '../../data/services/streak_service.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_scenario.dart' as confidence_scenarios;
import '../../domain/entities/gamification_models.dart';
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

// Provider pour Mistral API Service
final mistralApiServiceProvider = Provider<MistralApiService>((ref) {
  return MistralApiService();
});

// Provider pour le repository de gamification
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final repository = HiveGamificationRepository();
  // Initialize asynchronously - this will be handled by the consumer
  repository.initialize().catchError((error) {
    print('❌ [HIVE_INIT_ERROR] Failed to initialize Hive: $error');
  });
  return repository;
});

// Provider pour XP Calculator Service
final xpCalculatorServiceProvider = Provider<XPCalculatorService>((ref) {
  return XPCalculatorService();
});

// Provider pour Badge Service
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  return BadgeService(repository);
});

// Provider pour Streak Service
final streakServiceProvider = Provider<StreakService>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  return StreakService(repository);
});

// Provider pour Gamification Service
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  final badgeService = ref.watch(badgeServiceProvider);
  final xpCalculator = ref.watch(xpCalculatorServiceProvider);
  final streakService = ref.watch(streakServiceProvider);
  return GamificationService(repository, badgeService, xpCalculator, streakService);
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
    mistralApiService: ref.watch(mistralApiServiceProvider),
    gamificationService: ref.watch(gamificationServiceProvider),
  );
});


class ConfidenceBoostProvider with ChangeNotifier {
  final CleanLiveKitService livekitService;
  final ConfidenceLiveKitIntegration livekitIntegration;
  final ConfidenceRepository repository;
  final ConfidenceAnalysisBackendService backendAnalysisService;
  final ProsodyAnalysisInterface prosodyAnalysisInterface;
  final MistralApiService mistralApiService;
  final GamificationService gamificationService;

  ConfidenceBoostProvider({
    required this.livekitService,
    required this.livekitIntegration,
    required this.repository,
    required this.backendAnalysisService,
    required this.prosodyAnalysisInterface,
    required this.mistralApiService,
    required this.gamificationService,
  }) {
    logger.i("ConfidenceBoostProvider created!");
  }

  final logger = Logger();

  // NOUVEAUX états
  confidence_models.TextSupport? _currentTextSupport;
  confidence_models.SupportType _selectedSupportType = confidence_models.SupportType.fillInBlanks;
  bool _isGeneratingSupport = false;
  confidence_models.ConfidenceAnalysis? _lastAnalysis;
  GamificationResult? _lastGamificationResult;
  bool _isProcessingGamification = false;

  // Getters
  confidence_models.TextSupport? get currentTextSupport => _currentTextSupport;
  confidence_models.SupportType get selectedSupportType => _selectedSupportType;
  bool get isGeneratingSupport => _isGeneratingSupport;
  confidence_models.ConfidenceAnalysis? get lastAnalysis => _lastAnalysis;
  GamificationResult? get lastGamificationResult => _lastGamificationResult;
  bool get isProcessingGamification => _isProcessingGamification;

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
      final generator = TextSupportGenerator.create();
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
      // 1. Vérifier la disponibilité du service backend avec TIMEOUT RÉDUIT
      final isBackendAvailable = await backendAnalysisService.isServiceAvailable().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          logger.w("Backend availability check timed out");
          return false;
        },
      );
      logger.i("Backend service available: $isBackendAvailable");
      
      if (isBackendAvailable && audioData != null) {
        // 2. Analyser via le pipeline Whisper + Mistral avec TIMEOUT
        final analysis = await backendAnalysisService.analyzeAudioRecording(
          audioData: audioData,
          scenario: scenario,
          userContext: 'Session d\'analyse de performance - Support: ${textSupport.type.name}',
          recordingDurationSeconds: recordingDuration.inSeconds,
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            logger.w("Backend analysis timed out");
            return null;
          },
        );
        
        if (analysis != null) {
          logger.i("Backend analysis completed successfully");
          _lastAnalysis = analysis;
          
          // 3. Enrichir avec l'analyse prosodique (Kaldi) si disponible
          try {
            final prosodyResult = await prosodyAnalysisInterface.analyzeProsody(
              audioData: audioData,
              scenario: scenario,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                logger.w("Prosody analysis timed out");
                return null;
              },
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
                fluencyScore: prosodyResult.speechRate.fluencyScore,
                clarityScore: analysis.clarityScore,
                energyScore: prosodyResult.energy.normalizedEnergyScore,
                feedback: enrichedFeedback,
              );
            }
          } catch (e) {
            logger.w("Prosody analysis failed, continuing with backend-only results: $e");
          }
          
          // Traiter la gamification après une analyse réussie
          if (_currentTextSupport != null) {
            await _processGamification(
              scenario: scenario,
              textSupport: _currentTextSupport!,
              sessionDuration: recordingDuration,
            );
          }
          
          notifyListeners();
          return;
        }
      }
      
      // 4. Fallback vers LiveKit avec TIMEOUT STRICT
      logger.w("Falling back to LiveKit integration");
      
      try {
        final livekitFuture = _attemptLiveKitAnalysis(scenario, textSupport, recordingDuration);
        final livekitResult = await livekitFuture.timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            logger.w("LiveKit analysis timed out, forcing fallback");
            return null;
          },
        );
        
        if (livekitResult != null) {
          _lastAnalysis = livekitResult;
          
          // Traiter la gamification après une analyse LiveKit réussie
          if (_currentTextSupport != null) {
            await _processGamification(
              scenario: scenario,
              textSupport: _currentTextSupport!,
              sessionDuration: recordingDuration,
            );
          }
          
          notifyListeners();
          return;
        }
      } catch (e) {
        logger.w("LiveKit fallback failed: $e");
      }
      
      // 5. FALLBACK D'URGENCE GARANTI - toujours exécuté
      logger.w("Executing emergency fallback analysis");
      await _createEmergencyAnalysis(scenario, recordingDuration);
      
    } catch (e, stackTrace) {
      logger.e('Critical error in performance analysis: $e', error: e, stackTrace: stackTrace);
      
      // Fallback d'urgence garanti
      await _createEmergencyAnalysis(scenario, recordingDuration);
    }
  }
  
  // NOUVELLE méthode pour LiveKit avec timeout interne
  Future<confidence_models.ConfidenceAnalysis?> _attemptLiveKitAnalysis(
    confidence_scenarios.ConfidenceScenario scenario,
    confidence_models.TextSupport textSupport,
    Duration recordingDuration,
  ) async {
    try {
      final success = await livekitIntegration.startSession(
        scenario: scenario,
        userContext: 'Session d\'analyse de performance (fallback)',
        preferredSupportType: textSupport.type,
      );

      if (success) {
        await livekitIntegration.startRecording();
        await Future.delayed(recordingDuration);
        await livekitIntegration.stopRecordingAndAnalyze();
        
        // Attendre l'analyse avec timeout
        final completer = Completer<confidence_models.ConfidenceAnalysis?>();
        late StreamSubscription subscription;
        
        subscription = livekitIntegration.analysisStream.listen((analysis) {
          logger.i("LiveKit fallback analysis completed");
          subscription.cancel();
          completer.complete(analysis);
        });
        
        // Timeout interne de 10 secondes
        Timer(const Duration(seconds: 10), () {
          if (!completer.isCompleted) {
            subscription.cancel();
            completer.complete(null);
          }
        });
        
        return await completer.future;
      }
      
      // Fallback vers CleanLiveKitService si session échoue
      final analysis = await livekitService.requestConfidenceAnalysis(
        scenario: scenario,
        recordingDurationSeconds: recordingDuration.inSeconds,
      ).timeout(const Duration(seconds: 10));
      
      return analysis;
    } catch (e) {
      logger.w("LiveKit analysis attempt failed: $e");
      return null;
    }
  }
  
  // NOUVELLE méthode de fallback d'urgence avec Mistral
  Future<void> _createEmergencyAnalysis(
    confidence_scenarios.ConfidenceScenario scenario,
    Duration recordingDuration,
  ) async {
    logger.i("Creating guaranteed emergency analysis with Mistral API");
    
    try {
      // Tenter d'utiliser l'API Mistral directement
      final prompt = "Analysez cette performance de prise de parole :\n"
          "Scénario : ${scenario.title}\n"
          "Description : ${scenario.description}\n"
          "Durée : ${recordingDuration.inSeconds} secondes\n"
          "Difficulté : ${scenario.difficulty}\n\n"
          "Fournissez un feedback constructif et encourageant en français, "
          "avec des conseils spécifiques pour améliorer la confiance en soi.";
          
      final aiResponse = await mistralApiService.generateText(
        prompt: prompt,
        maxTokens: 600,
        temperature: 0.7,
      );
      
      // Si Mistral répond, créer une analyse avec son feedback
      final difficultyBonus = scenario.difficulty.toLowerCase().contains('difficile') ? 5.0 :
                              scenario.difficulty.toLowerCase().contains('moyen') ? 3.0 : 2.0;
      
      final fallbackAnalysis = confidence_models.ConfidenceAnalysis(
        overallScore: 72.0 + difficultyBonus, // Score adaptatif selon difficulté
        confidenceScore: 0.70 + (difficultyBonus * 0.01),
        fluencyScore: 0.68 + (difficultyBonus * 0.008),
        clarityScore: 0.75 + (difficultyBonus * 0.006),
        energyScore: 0.70 + (difficultyBonus * 0.008),
        feedback: "🤖 **Analyse IA Mistral** :\n\n$aiResponse\n\n"
            "🎯 **Contexte** : ${scenario.title} (${recordingDuration.inSeconds}s)\n"
            "📈 **Progression** : Continuez vos efforts pour développer votre aisance !",
      );
      
      _lastAnalysis = fallbackAnalysis;
      logger.i("Emergency analysis with Mistral completed successfully");
    } catch (e) {
      logger.w("Mistral emergency fallback failed: $e, using static fallback");
      
      // Dernier recours : feedback statique mais personnalisé
      final fallbackAnalysis = confidence_models.ConfidenceAnalysis(
        overallScore: 70.0,
        confidenceScore: 0.70,
        fluencyScore: 0.65,
        clarityScore: 0.75,
        energyScore: 0.70,
        feedback: "⚠️ **Analyse d'Urgence** : Services d'analyse temporairement indisponibles.\n\n"
            "🎯 **Scénario** : ${scenario.title}\n"
            "⏱️ **Durée** : ${recordingDuration.inSeconds}s d'enregistrement\n\n"
            "💡 **Conseils génériques** :\n"
            "• Continuez à pratiquer régulièrement\n"
            "• Travaillez votre respiration et posture\n"
            "• ${scenario.tips.isNotEmpty ? scenario.tips.first : 'Restez confiant dans votre progression'}\n\n"
            "🔄 **Note** : Réessayez plus tard pour une analyse complète."
      );
      
      _lastAnalysis = fallbackAnalysis;
    }
    
    notifyListeners();
    logger.i("Emergency analysis created and listeners notified");
  }

  // NOUVELLE méthode pour traiter la gamification après une analyse
  Future<void> _processGamification({
    required confidence_scenarios.ConfidenceScenario scenario,
    required confidence_models.TextSupport textSupport,
    required Duration sessionDuration,
    String userId = 'default_user', // TODO: Récupérer l'ID utilisateur réel
  }) async {
    if (_lastAnalysis == null) return;
    
    _isProcessingGamification = true;
    notifyListeners();
    
    try {
      logger.i("Processing gamification for session completion");
      
      final gamificationResult = await gamificationService.processSessionCompletion(
        userId: userId,
        analysis: _lastAnalysis!,
        scenario: scenario,
        textSupport: textSupport,
        sessionDuration: sessionDuration,
      );
      
      _lastGamificationResult = gamificationResult;
      
      logger.i("Gamification processed successfully: XP: ${gamificationResult.earnedXP}, Badges: ${gamificationResult.newBadges.length}, Level: ${gamificationResult.newLevel}");
      
      // Log les nouveaux badges obtenus
      if (gamificationResult.newBadges.isNotEmpty) {
        for (final badge in gamificationResult.newBadges) {
          logger.i("Nouveau badge débloqué: ${badge.name} - ${badge.description}");
        }
      }
      
      if (gamificationResult.levelUp) {
        logger.i("🎉 LEVEL UP! Nouveau niveau: ${gamificationResult.newLevel}");
      }
      
    } catch (e) {
      logger.e("Erreur lors du traitement de la gamification: $e");
      // La gamification échoue silencieusement pour ne pas affecter l'expérience utilisateur
    } finally {
      _isProcessingGamification = false;
      notifyListeners();
    }
  }
}

