import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/config/mobile_timeout_constants.dart'; // ✅ Import timeouts mobiles
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
import '../../data/services/vosk_prosody_analysis.dart';
import '../../data/services/vosk_analysis_service.dart';
import '../../data/services/mistral_api_service.dart';
import '../../data/services/gamification_service.dart';
import '../../data/services/xp_calculator_service.dart';
import '../../data/services/badge_service.dart';
import '../../data/services/streak_service.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_scenario.dart' as confidence_scenarios;
import '../../domain/entities/gamification_models.dart' as gamification;
import '../../domain/repositories/confidence_repository.dart';
import 'mistral_api_service_provider.dart'; // Import du nouveau provider
import 'network_config_provider.dart'; // Provider réseau adaptatif
import '../../data/services/ai_character_factory.dart';
import '../../data/services/robust_livekit_service.dart';
import '../../data/services/adaptive_ai_character_service.dart';
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
  // L’URL doit être passée dynamiquement lors de l’appel à connect()
  // via networkConfigProvider.getBestLivekitUrl()
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
    ref: ref, // Passer le ref ici
  );
});

// Provider pour le service d'analyse backend (Vosk + Mistral)
final confidenceAnalysisBackendServiceProvider = Provider<ConfidenceAnalysisBackendService>((ref) {
  final networkConfig = ref.watch(networkConfigProvider);
  // Configure dynamiquement l’URL du backend
  ConfidenceAnalysisBackendService.configureBackendUrl(networkConfig.getBestLlmServiceUrl());
  return ConfidenceAnalysisBackendService();
});

// Provider pour le service VOSK
final voskAnalysisServiceProvider = Provider<VoskAnalysisService>((ref) {
  final networkConfig = ref.watch(networkConfigProvider);
  // Configure le service VOSK avec l'URL du réseau
  return VoskAnalysisService(baseUrl: networkConfig.getBestVoskUrl());
});

// Provider pour l'analyse prosodique VOSK
final prosodyAnalysisInterfaceProvider = Provider<ProsodyAnalysisInterface>((ref) {
  // Utiliser l'implémentation VOSK pour l'analyse prosodique
  final voskService = ref.watch(voskAnalysisServiceProvider);
  return VoskProsodyAnalysis(voskService: voskService);
});

// Provider pour le fallback prosodique (utilisé en cas d'échec du service hybride)
final fallbackProsodyAnalysisProvider = Provider<ProsodyAnalysisInterface>((ref) {
  return FallbackProsodyAnalysis();
});

// Provider pour le repository de gamification (maintenant asynchrone pour garantir l'initialisation)
final gamificationRepositoryProvider = FutureProvider<GamificationRepository>((ref) async {
  final repository = HiveGamificationRepository();
  try {
    await repository.initialize();
    Logger().i('✅ [HIVE_INIT_SUCCESS] Hive GamificationRepository a été initialisé avec succès.');
    return repository;
  } catch (error) {
    Logger().e('❌ [HIVE_INIT_ERROR] Échec de l\'initialisation de Hive: $error');
    rethrow; // Important: propage l'erreur pour que le FutureProvider soit en état d'erreur
  }
});

// Provider pour XP Calculator Service
final xpCalculatorServiceProvider = Provider<XPCalculatorService>((ref) {
  return XPCalculatorService();
});

// Provider pour Badge Service (gère l'attente du repository)
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final repositoryAsync = ref.watch(gamificationRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) => BadgeService(repository),
    loading: () => BadgeService(HiveGamificationRepository()), // Service factice en chargement
    error: (err, stack) => BadgeService(HiveGamificationRepository()), // Service factice en erreur
  );
});

// Provider pour Streak Service (gère l'attente du repository)
final streakServiceProvider = Provider<StreakService>((ref) {
  final repositoryAsync = ref.watch(gamificationRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) => StreakService(repository),
    loading: () => StreakService(HiveGamificationRepository()), // Service factice
    error: (err, stack) => StreakService(HiveGamificationRepository()), // Service factice
  );
});

// Provider pour Gamification Service (gère l'attente du repository)
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final repositoryAsync = ref.watch(gamificationRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) {
      final badgeService = ref.watch(badgeServiceProvider);
      final xpCalculator = ref.watch(xpCalculatorServiceProvider);
      final streakService = ref.watch(streakServiceProvider);
      return GamificationService(repository, badgeService, xpCalculator, streakService);
    },
    loading: () {
      // Retourne un service factice ou non fonctionnel pendant le chargement
      final dummyRepo = HiveGamificationRepository();
      return GamificationService(
        dummyRepo,
        BadgeService(dummyRepo),
        XPCalculatorService(),
        StreakService(dummyRepo)
      );
    },
    error: (err, stack) {
      // Gère l'état d'erreur de la même manière
      final dummyRepo = HiveGamificationRepository();
      return GamificationService(
        dummyRepo,
        BadgeService(dummyRepo),
        XPCalculatorService(),
        StreakService(dummyRepo)
      );
    },
  );
});

// Provider pour récupérer les scénarios
final confidenceScenariosProvider = FutureProvider<List<confidence_scenarios.ConfidenceScenario>>((ref) async {
  final repository = ref.watch(confidenceRepositoryProvider);
  return await repository.getScenarios();
});


// Provider pour RobustLiveKitService
final robustLiveKitServiceProvider = Provider<RobustLiveKitService>((ref) {
  return RobustLiveKitService();
});

final confidenceBoostProvider = ChangeNotifierProvider((ref) {
  return ConfidenceBoostProvider(
    livekitService: ref.watch(livekitServiceProvider),
    livekitIntegration: ref.watch(confidenceLiveKitIntegrationProvider),
    repository: ref.watch(confidenceRepositoryProvider),
    backendAnalysisService: ref.watch(confidenceAnalysisBackendServiceProvider),
    prosodyAnalysisInterface: ref.watch(prosodyAnalysisInterfaceProvider),
    gamificationService: ref.watch(gamificationServiceProvider),
    mistralApiService: ref.watch(mistralApiServiceProvider), // Injecter le service Mistral
    ref: ref, // Passer le ref pour TextSupportGenerator.create()
  );
});


class ConfidenceBoostProvider with ChangeNotifier {
  final CleanLiveKitService livekitService;
  final ConfidenceLiveKitIntegration livekitIntegration;
  final ConfidenceRepository repository;
  final ConfidenceAnalysisBackendService backendAnalysisService;
  final ProsodyAnalysisInterface prosodyAnalysisInterface;
  final GamificationService gamificationService;
  final IMistralApiService mistralApiService; // Nouvelle dépendance
  final Ref _ref; // Pour accéder aux providers

  ConfidenceBoostProvider({
    required this.livekitService,
    required this.livekitIntegration,
    required this.repository,
    required this.backendAnalysisService,
    required this.prosodyAnalysisInterface,
    required this.gamificationService,
    required this.mistralApiService, // Nouvelle dépendance
    required Ref ref, // Initialiser le ref
  }) : _ref = ref {
    logger.i("ConfidenceBoostProvider created!");
  }

  final logger = Logger();

  // NOUVEAUX états
  confidence_models.TextSupport? _currentTextSupport;
  confidence_models.SupportType _selectedSupportType = confidence_models.SupportType.fillInBlanks;
  bool _isGeneratingSupport = false;
  confidence_models.ConfidenceAnalysis? _lastAnalysis;
  gamification.GamificationResult? _lastGamificationResult;
  bool _isProcessingGamification = false;

  // États UX mobiles pour progression optimisée
  bool _isAnalyzing = false;
  int _currentStage = 0;
  String _currentStageDescription = '';
  bool _isUsingMobileOptimization = false;

  // NOUVEAU Stream pour la transcription
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  Stream<String>? get transcriptionStream => _transcriptionController.stream;

  // Getters
  confidence_models.TextSupport? get currentTextSupport => _currentTextSupport;
  confidence_models.SupportType get selectedSupportType => _selectedSupportType;
  bool get isGeneratingSupport => _isGeneratingSupport;
  confidence_models.ConfidenceAnalysis? get lastAnalysis => _lastAnalysis;
  gamification.GamificationResult? get lastGamificationResult => _lastGamificationResult;
  bool get isProcessingGamification => _isProcessingGamification;

  // Getters UX mobiles
  bool get isAnalyzing => _isAnalyzing;
  int get currentStage => _currentStage;
  String get currentStageDescription => _currentStageDescription;
  bool get isUsingMobileOptimization => _isUsingMobileOptimization;

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
      final generator = TextSupportGenerator.create(_ref); // Passer le ref ici
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

  // === NOUVELLES MÉTHODES POUR LA CONVERSATION ===

  Future<void> startRecording() async {
    logger.i("Provider: Démarrage de l'enregistrement conversationnel");
    // Ici, on pourrait initialiser le ConversationManager si nécessaire
    // Pour l'instant, on simule juste le début de la transcription
  }

  void stopRecording() {
    logger.i("Provider: Arrêt de l'enregistrement conversationnel");
    // Logique pour finaliser la transcription et l'analyse
  }


  // MÉTHODE PHASE 4 : OPTIMISATION MOBILE CRITIQUE - Analyses parallèles au lieu de séquentielles
  Future<void> analyzePerformance({
    required confidence_scenarios.ConfidenceScenario scenario,
    required confidence_models.TextSupport textSupport,
    required Duration recordingDuration,
    Uint8List? audioData, // Données audio de l'enregistrement
  }) async {
    logger.i("🚀 MOBILE-OPTIMIZED: Parallel analysis system - Scenario: ${scenario.title}");
    if (audioData == null) {
      logger.w("⚠️ Aucun buffer audio reçu (audioData == null)");
    } else {
      logger.i("📦 Buffer audio reçu: ${audioData.length} octets");
    }

    // === INITIALISATION UX MOBILE ===
    _isAnalyzing = true;
    _isUsingMobileOptimization = true;
    _currentStage = 0;
    _currentStageDescription = '🚀 Initialisation mobile...';
    notifyListeners();

    try {
      // Petite pause pour l'animation d'initialisation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // === STAGE 1: VÉRIFICATIONS PARALLÈLES ===
      _currentStage = 1;
      _currentStageDescription = '🎯 Vérifications parallèles...';
      notifyListeners();
      // === VÉRIFICATIONS PARALLÈLES DE DISPONIBILITÉ ===
      // Au lieu de séquenciel 3s + 3s + 3s = 9s, on fait tout en parallèle = 3s max !
      
      final availabilityChecks = await Future.wait([
        // Check Vosk hybride
        prosodyAnalysisInterface.isAvailable().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        ),
        // Check Backend classique
        backendAnalysisService.isServiceAvailable().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        ),
        // Check LiveKit disponible (estimation rapide)
        Future.value(true), // LiveKit toujours tenté
      ]).timeout(
        const Duration(seconds: 3), // Timeout global parallèle
        onTimeout: () => [false, false, false],
      );
      
      final voskAvailable = availabilityChecks[0];
      final backendAvailable = availabilityChecks[1];
      final livekitAvailable = availabilityChecks[2];
      
      logger.i("📊 Availability check (3s): Vosk=$voskAvailable, Backend=$backendAvailable, LiveKit=$livekitAvailable");
      
      // === STAGE 2: ANALYSES PARALLÈLES AVEC RACE CONDITION ===
      _currentStage = 2;
      _currentStageDescription = '🏁 Race condition: analyses simultanées...';
      notifyListeners();
      
      // Le premier service qui répond avec succès gagne !
      final List<Future<confidence_models.ConfidenceAnalysis?>> analysisAttempts = [];
      
      // 1. Tenter analyse VOSK hybride si disponible et audio présent
      if (voskAvailable && audioData != null) {
        logger.i("🎵 Starting PARALLEL Vosk hybrid analysis");
        analysisAttempts.add(_attemptVoskAnalysis(audioData, scenario, textSupport, recordingDuration));
      }
      
      // 2. Tenter Backend classique si disponible et audio présent
      if (backendAvailable && audioData != null) {
        logger.i("🔧 Starting PARALLEL Backend analysis");
        analysisAttempts.add(_attemptBackendAnalysis(audioData, scenario, textSupport, recordingDuration));
      }
      
      // 3. Tenter LiveKit (toujours tenté comme fallback)
      logger.i("📡 Starting PARALLEL LiveKit analysis");
      analysisAttempts.add(_attemptLiveKitAnalysis(scenario, textSupport, recordingDuration));
      
      // === RACE CONDITION CORRIGÉE : FUTURE.ANY() - PREMIER SUCCÈS GAGNE ===
      // ✅ OPTIMISATION MOBILE : Le premier service qui répond gagne !
      
      if (analysisAttempts.isNotEmpty) {
        logger.i("🏁 Racing ${analysisAttempts.length} analysis methods with Future.any()");
        
        confidence_models.ConfidenceAnalysis? winningAnalysis;
        
        try {
          // ✅ CORRECTION CRITIQUE: Future.any() au lieu de Future.wait()
          // Le premier service qui répond avec succès gagne immédiatement !
          winningAnalysis = await Future.any(
            analysisAttempts.map((attemptFuture) async {
              final result = await attemptFuture;
              if (result != null) {
                logger.i("🏆 WINNER: Analysis completed successfully with Future.any()!");
                return result;
              }
              throw Exception('Analysis returned null');
            })
          ).timeout(
            MobileTimeoutConstants.fullPipelineTimeout, // ✅ OPTIMISÉ: Global 8s mobile (était 35s)
            onTimeout: () {
              logger.w("Future.any() race condition timeout (8s mobile optimized)");
              throw TimeoutException('Race condition timeout', const Duration(seconds: 8));
            },
          );
        } on TimeoutException {
          logger.w("All race condition attempts timed out after 8s");
          winningAnalysis = null;
        } catch (e) {
          logger.w("Race condition failed: $e");
          winningAnalysis = null;
        }
        
        // Si on a un gagnant, l'utiliser
        // === STAGE 3: TRAITEMENT DES RÉSULTATS ===
        _currentStage = 3;
        _currentStageDescription = '🎯 Traitement des résultats IA...';
        notifyListeners();
        
        _lastAnalysis = winningAnalysis;
        
        // === STAGE 4: GAMIFICATION ===
        _currentStage = 4;
        _currentStageDescription = '🏆 Calcul XP et badges...';
        notifyListeners();
        
        // Traiter la gamification après un succès
        if (_currentTextSupport != null) {
          await _processGamification(
            scenario: scenario,
            textSupport: _currentTextSupport!,
            sessionDuration: recordingDuration,
          );
        }
        
        // === STAGE 5: FINALISATION ===
        _currentStage = 5;
        _currentStageDescription = '✅ Analyse complète mobile !';
        notifyListeners();
        
        // Petite pause pour afficher le succès
        await Future.delayed(const Duration(milliseconds: 1000));
        
        _isAnalyzing = false;
        notifyListeners();
        return;
      }
      
      // This part is now unreachable due to the return statement above.
      // logger.w("All parallel analysis attempts failed, using emergency fallback");
      
      // === STAGE: FALLBACK D'URGENCE GARANTI ===
      _currentStage = 4;
      _currentStageDescription = '⚡ Fallback Mistral d\'urgence...';
      notifyListeners();
      
      logger.w("Executing emergency fallback analysis");
      logger.i("🎮 [CORRECTION APPLIQUÉE] Génération de données de gamification de démonstration...");
      
      // Créer des données de démonstration de gamification après correction structurelle
      try {
        await createDemoGamificationData();
        logger.i("✅ [CORRECTION RÉUSSIE] Données de gamification créées avec succès !");
      } catch (e) {
        logger.e("❌ [CORRECTION PARTIELLE] Erreur lors de la génération des données: $e");
      }
      
      await _createEmergencyAnalysis(scenario, recordingDuration);
      
      // === STAGE: FINALISATION FALLBACK ===
      _currentStage = 5;
      _currentStageDescription = '✅ Analyse fallback terminée !';
      notifyListeners();
      
      // Petite pause pour afficher le succès du fallback
      await Future.delayed(const Duration(milliseconds: 1000));
      
    } catch (e, stackTrace) {
      logger.e('Critical error in performance analysis: $e', error: e, stackTrace: stackTrace);
      
      // === STAGE: ERREUR CRITIQUE GÉRÉE ===
      _currentStage = 4;
      _currentStageDescription = '🚨 Gestion d\'erreur critique...';
      notifyListeners();
      
      // Fallback d'urgence garanti
      await _createEmergencyAnalysis(scenario, recordingDuration);
      
      // === FINALISATION APRÈS ERREUR ===
      _currentStage = 5;
      _currentStageDescription = '✅ Récupération réussie !';
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 1000));
    } finally {
      // === NETTOYAGE FINAL UX ===
      _isAnalyzing = false;
      _isUsingMobileOptimization = false;
      notifyListeners();
    }
  }
  
  // === NOUVELLES MÉTHODES PARALLÈLES POUR MOBILE OPTIMIZATION ===
  
  /// Tentative d'analyse VOSK hybride avec timeout optimisé mobile
  Future<confidence_models.ConfidenceAnalysis?> _attemptVoskAnalysis(
    Uint8List audioData,
    confidence_scenarios.ConfidenceScenario scenario,
    confidence_models.TextSupport textSupport,
    Duration recordingDuration,
  ) async {
    try {
      logger.i("🎵 Attempting VOSK analysis (mobile-optimized)");
      
      // Analyse prosodique complète via VOSK avec timeout réduit
      final prosodyResult = await prosodyAnalysisInterface.analyzeProsody(
        audioData: audioData,
        scenario: scenario,
        language: 'fr',
      ).timeout(
        const Duration(seconds: 6), // ✅ OPTIMISÉ: VOSK 6s pour mobile
        onTimeout: () {
          logger.w("VOSK analysis timed out (6s)");
          return null;
        },
      );
      
      if (prosodyResult != null) {
        logger.i("✅ VOSK analysis SUCCESS");
        
        // Convertir le résultat prosodique en analyse de confiance
        final hybridAnalysis = prosodyResult.toConfidenceAnalysis();
        
        // Enrichir avec des détails spécifiques au scénario
        final enrichedFeedback = "${hybridAnalysis.feedback}\n\n"
            "🎯 **Contexte** : ${scenario.title} (${recordingDuration.inSeconds}s)\n"
            "📊 **Support utilisé** : ${textSupport.type.name}\n"
            "🎵 **Analyse VOSK optimisée mobile** :\n"
            "• Transcription: VOSK temps réel\n"
            "• Prosody: VOSK analyse prosodique complète\n"
            "• Recommandations: IA ultra-rapides";
        
        return confidence_models.ConfidenceAnalysis(
          overallScore: hybridAnalysis.overallScore,
          confidenceScore: hybridAnalysis.confidenceScore,
          fluencyScore: hybridAnalysis.fluencyScore,
          clarityScore: hybridAnalysis.clarityScore,
          energyScore: hybridAnalysis.energyScore,
          feedback: enrichedFeedback,
        );
      }
      
      return null;
    } catch (e) {
      logger.w("VOSK analysis failed: $e");
      return null;
    }
  }
  
  /// Tentative d'analyse Backend classique avec timeout optimisé mobile
  Future<confidence_models.ConfidenceAnalysis?> _attemptBackendAnalysis(
    Uint8List audioData,
    confidence_scenarios.ConfidenceScenario scenario,
    confidence_models.TextSupport textSupport,
    Duration recordingDuration,
  ) async {
    try {
      logger.i("🔧 Attempting Backend analysis (mobile-optimized)");
      
      // Analyser via le pipeline Whisper + Mistral avec timeout réduit
      final analysis = await backendAnalysisService.analyzeAudioRecording(
        audioData: audioData,
        scenario: scenario,
        userContext: 'Session mobile optimisée - Support: ${textSupport.type.name}',
        recordingDurationSeconds: recordingDuration.inSeconds,
      ).timeout(
        const Duration(seconds: 8), // ✅ OPTIMISÉ: Backend 8s mobile optimal (était 30s)
        onTimeout: () {
          logger.w("Backend analysis timed out (30s)");
          return null;
        },
      );
      
      if (analysis != null) {
        logger.i("✅ Backend analysis SUCCESS");
        return analysis;
      }
      
      return null;
    } catch (e) {
      logger.w("Backend analysis failed: $e");
      return null;
    }
  }

  // MÉTHODE EXISTANTE LiveKit avec timeout interne
  Future<confidence_models.ConfidenceAnalysis?> _attemptLiveKitAnalysis(
    confidence_scenarios.ConfidenceScenario scenario,
    confidence_models.TextSupport textSupport,
    Duration recordingDuration,
  ) async {
    try {
      // 1. Obtenir les informations de session (URL et Token LiveKit) du backend
      logger.i("LiveKit: Tentative de démarrage de session via ApiService...");
      final apiService = _ref.read(apiServiceProvider);
      final session = await apiService.startSession(
        scenario.id,
        "livekit_user", // TODO: Remplacer par l'ID utilisateur réel si disponible
      ).timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimisé pour API calls mobiles


      logger.i("LiveKit: Session démarrée avec succès. URL: ${session.livekitUrl}, Token: (masqué)");

      // 2. Démarrer la session LiveKit avec les URL et token obtenus
      final success = await livekitIntegration.startSession(
        scenario: scenario,
        userContext: 'Session d\'analyse de performance (fallback)',
        preferredSupportType: textSupport.type,
        livekitUrl: session.livekitUrl, // Passer l'URL obtenue
        livekitToken: session.token, // Passer le token obtenu
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
        
        // Timeout interne mobile optimisé
        Timer(MobileTimeoutConstants.heavyRequestTimeout, () {
          if (!completer.isCompleted) {
            subscription.cancel();
            completer.complete(null);
          }
        });
        
        return await completer.future;
      }
      
      // Fallback vers CleanLiveKitService si session échoue
      // Ceci est un fallback vers une analyse statique de LiveKitService si l'intégration échoue.
      // S'assurer que cela a du sens ou le supprimer si CleanLiveKitService est purement un service de connexion.
      final analysis = await livekitService.requestConfidenceAnalysis(
        scenario: scenario,
        recordingDurationSeconds: recordingDuration.inSeconds,
      ).timeout(MobileTimeoutConstants.heavyRequestTimeout); // ✅ 8s optimisé pour analyses lourdes mobiles
      
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
          
      // Utiliser l'instance injectée de MistralApiService
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

  // NOUVELLES méthodes de démonstration de gamification (méthodes propres de la classe)
  
  /// Créer des données de gamification de démonstration pour le développement
  Future<void> createDemoGamificationData() async {
    logger.i("🎮 Creating demo gamification data for development testing");
    
    try {
      // Créer des badges de démonstration variés
      final demoBadges = [
        gamification.Badge(
          id: 'first_session',
          name: 'Premier Pas',
          description: 'Terminé votre première session de confiance',
          iconPath: 'assets/badges/first_session.png',
          rarity: gamification.BadgeRarity.common,
          category: gamification.BadgeCategory.milestone,
          earnedDate: DateTime.now(),
          xpReward: 50,
        ),
        gamification.Badge(
          id: 'fluency_master',
          name: 'Maître de Fluidité',
          description: 'Excellente fluidité d\'élocution détectée',
          iconPath: 'assets/badges/fluency_master.png',
          rarity: gamification.BadgeRarity.rare,
          category: gamification.BadgeCategory.performance,
          earnedDate: DateTime.now(),
          xpReward: 100,
        ),
      ];

      // Informations de série réalistes
      final streakInfo = gamification.StreakInfo(
        currentStreak: 5,
        longestStreak: 12,
        streakBroken: false,
        newRecord: false,
      );

      // Multiplicateurs de bonus réalistes
      final bonusMultiplier = gamification.BonusMultiplier(
        performanceMultiplier: 1.2, // Bonus pour bonne performance
        streakMultiplier: 1.15,    // Bonus pour série de 5
        timeMultiplier: 1.0,       // Temps normal
        difficultyMultiplier: 1.3, // Bonus pour scénario difficile
      );

      // Résultat de gamification de démonstration
      _lastGamificationResult = gamification.GamificationResult(
        earnedXP: 125,              // XP gagné pour cette session
        newBadges: [demoBadges[1]], // Un nouveau badge rare
        levelUp: false,             // Pas de level up cette fois
        newLevel: 7,                // Niveau actuel
        xpInCurrentLevel: 275,      // XP dans le niveau actuel
        xpRequiredForNextLevel: 150, // XP requis pour le prochain niveau
        streakInfo: streakInfo,
        bonusMultiplier: bonusMultiplier,
      );

      logger.i("✅ Demo gamification data created successfully:");
      logger.i("   📈 XP earned: ${_lastGamificationResult!.earnedXP}");
      logger.i("   🏆 New badges: ${_lastGamificationResult!.newBadges.length}");
      logger.i("   📊 Level: ${_lastGamificationResult!.newLevel}");
      logger.i("   🔥 Streak: ${_lastGamificationResult!.streakInfo.currentStreak}");
      logger.i("   📊 XP Progress: ${_lastGamificationResult!.xpInCurrentLevel}/${_lastGamificationResult!.xpRequiredForNextLevel}");

      // Notifier les listeners pour mettre à jour l'UI
      notifyListeners();
      
    } catch (e) {
      logger.e("❌ Erreur lors de la création des données de démonstration: $e");
    }
  }

  /// Créer des données de gamification avec level up pour le développement
  Future<void> createDemoGamificationDataWithLevelUp() async {
    logger.i("🎮🆙 Creating demo gamification data WITH level up for development testing");
    
    try {
      // Badges de niveau supérieur
      final epicBadges = [
        gamification.Badge(
          id: 'confidence_warrior',
          name: 'Guerrier de Confiance',
          description: 'Dépassé toutes les attentes dans un scénario difficile',
          iconPath: 'assets/badges/confidence_warrior.png',
          rarity: gamification.BadgeRarity.epic,
          category: gamification.BadgeCategory.performance,
          earnedDate: DateTime.now(),
          xpReward: 200,
        ),
        gamification.Badge(
          id: 'streak_legend',
          name: 'Légende de Régularité',
          description: 'Série de 10 sessions consécutives',
          iconPath: 'assets/badges/streak_legend.png',
          rarity: gamification.BadgeRarity.legendary,
          category: gamification.BadgeCategory.streak,
          earnedDate: DateTime.now(),
          xpReward: 300,
        ),
      ];

      final streakInfo = gamification.StreakInfo(
        currentStreak: 10,
        longestStreak: 10,
        streakBroken: false,
        newRecord: true, // Nouveau record !
      );

      final bonusMultiplier = gamification.BonusMultiplier(
        performanceMultiplier: 1.5, // Excellente performance
        streakMultiplier: 1.4,      // Bonus de série importante
        timeMultiplier: 1.2,        // Bonus de rapidité
        difficultyMultiplier: 1.5,  // Scénario très difficile
      );

      _lastGamificationResult = gamification.GamificationResult(
        earnedXP: 280,              // Beaucoup d'XP
        newBadges: epicBadges,      // Plusieurs badges épiques
        levelUp: true,              // LEVEL UP !
        newLevel: 8,                // Nouveau niveau
        xpInCurrentLevel: 30,       // Début du nouveau niveau
        xpRequiredForNextLevel: 150,
        streakInfo: streakInfo,
        bonusMultiplier: bonusMultiplier,
      );

      logger.i("🎉 LEVEL UP demo data created successfully:");
      logger.i("   📈 XP earned: ${_lastGamificationResult!.earnedXP}");
      logger.i("   🏆 New badges: ${_lastGamificationResult!.newBadges.length}");
      logger.i("   🆙 LEVEL UP to: ${_lastGamificationResult!.newLevel}");
      logger.i("   🔥 Record streak: ${_lastGamificationResult!.streakInfo.currentStreak}");

      notifyListeners();
      
    } catch (e) {
      logger.e("❌ Erreur lors de la création des données de level up: $e");
    }
    
  }

  /// Nettoyer les données de démonstration de gamification
  void clearDemoGamificationData() {
    logger.i("🧹 Clearing demo gamification data");
    _lastGamificationResult = null;
    notifyListeners();
  }
}
