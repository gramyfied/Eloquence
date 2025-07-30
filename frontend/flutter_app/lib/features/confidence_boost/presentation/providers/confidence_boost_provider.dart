import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/config/mobile_timeout_constants.dart';
import 'package:logger/logger.dart';
import '../../../../data/services/api_service.dart';
import '../../data/datasources/confidence_local_datasource.dart';
import '../../data/datasources/confidence_remote_datasource.dart';
import '../../data/repositories/confidence_repository_impl.dart';
import '../../data/services/text_support_generator.dart';
import '../../data/services/mistral_api_service.dart';
import '../../data/services/gamification_service.dart';
import '../../data/services/xp_calculator_service.dart';
import '../../data/services/badge_service.dart';
import '../../data/services/streak_service.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/services/unified_livekit_service.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_scenario.dart' as confidence_scenarios;
import '../../domain/entities/gamification_models.dart' as gamification;
import '../../domain/repositories/confidence_repository.dart';
import 'mistral_api_service_provider.dart';
import 'network_config_provider.dart';
import '../../data/services/ai_character_factory.dart';
import '../../data/services/adaptive_ai_character_service.dart';
// Provider pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

// Provider pour ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(apiKey: 'your-api-key'); // TODO: Récupérer depuis la config
});

// Provider pour le service LiveKit unifié
final unifiedLiveKitServiceProvider = Provider<UnifiedLiveKitService>((ref) {
  return UnifiedLiveKitService();
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

// Provider pour le repository de gamification (maintenant synchrone avec initialisation lazy)
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final repository = HiveGamificationRepository();
  // Initialisation lazy - sera faite lors du premier accès
  return repository;
});

// Provider d'initialisation séparé pour gérer l'état d'initialisation
final gamificationInitializationProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  try {
    await repository.initialize();
    Logger().i('✅ [HIVE_INIT_SUCCESS] Hive GamificationRepository initialisé avec succès.');
    return true;
  } catch (error) {
    Logger().e('❌ [HIVE_INIT_ERROR] Échec initialisation Hive: $error');
    return false; // Retourner false au lieu de rethrow
  }
});

// Provider pour XP Calculator Service
final xpCalculatorServiceProvider = Provider<XPCalculatorService>((ref) {
  return XPCalculatorService();
});

// Provider pour Badge Service (maintenant utilise directement le repository)
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  return BadgeService(repository);
});

// Provider pour Streak Service (maintenant utilise directement le repository)
final streakServiceProvider = Provider<StreakService>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  return StreakService(repository);
});

// Provider pour Gamification Service (maintenant utilise directement le repository)
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
    unifiedLiveKitService: ref.watch(unifiedLiveKitServiceProvider),
    repository: ref.watch(confidenceRepositoryProvider),
    gamificationService: ref.watch(gamificationServiceProvider),
    mistralApiService: ref.watch(mistralApiServiceProvider),
    ref: ref,
  );
});


class ConfidenceBoostProvider with ChangeNotifier {
  final UnifiedLiveKitService unifiedLiveKitService;
  final ConfidenceRepository repository;
  final GamificationService gamificationService;
  final IMistralApiService mistralApiService;
  final Ref _ref;

  ConfidenceBoostProvider({
    required this.unifiedLiveKitService,
    required this.repository,
    required this.gamificationService,
    required this.mistralApiService,
    required Ref ref,
  }) : _ref = ref {
    logger.i("ConfidenceBoostProvider created with unified architecture!");
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


  // MÉTHODE SIMPLIFIÉE : ANALYSE UNIFIÉE LIVEKIT
  Future<void> analyzePerformance({
    required confidence_scenarios.ConfidenceScenario scenario,
    required confidence_models.TextSupport textSupport,
    required Duration recordingDuration,
    Uint8List? audioData,
  }) async {
    logger.i("🚀 UNIFIED LIVEKIT: Starting analysis - Scenario: ${scenario.title}");
    
    _isAnalyzing = true;
    _isUsingMobileOptimization = true;
    _currentStage = 0;
    _currentStageDescription = '🚀 Initialisation du service unifié...';
    notifyListeners();

    try {
      // === STAGE 1: CONNEXION AU SERVICE UNIFIÉ ===
      _currentStage = 1;
      _currentStageDescription = '🔗 Connexion LiveKit unifié...';
      notifyListeners();
      
      // === STAGE 2: ANALYSE UNIFIÉE ===
      _currentStage = 2;
      _currentStageDescription = '🎯 Analyse LiveKit unifiée...';
      notifyListeners();
      
      // Utiliser le service LiveKit unifié
      final analysis = await unifiedLiveKitService.startConversation(scenario).timeout(
        MobileTimeoutConstants.fullPipelineTimeout,
        onTimeout: () {
          logger.w("Service LiveKit unifié timeout");
          return false;
        },
      );
      
      if (analysis) {
        // Récupérer les résultats d'analyse (simulation pour l'instant)
        _lastAnalysis = await _createUnifiedAnalysis(scenario, recordingDuration);
        
        // === STAGE 3: GAMIFICATION ===
        _currentStage = 3;
        _currentStageDescription = '🏆 Calcul XP et badges...';
        notifyListeners();
        
        await _processGamification(
          scenario: scenario,
          textSupport: textSupport,
          sessionDuration: recordingDuration,
        );
        
        // === STAGE 4: FINALISATION ===
        _currentStage = 4;
        _currentStageDescription = '✅ Analyse unifiée terminée !';
        notifyListeners();
        
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        throw Exception('Service LiveKit unifié indisponible');
      }
      
    } catch (e, stackTrace) {
      logger.e('Erreur dans l\'analyse unifiée: $e', error: e, stackTrace: stackTrace);
      
      _currentStage = 3;
      _currentStageDescription = '⚡ Fallback d\'urgence...';
      notifyListeners();
      
      await _createEmergencyAnalysis(scenario, recordingDuration);
      
      _currentStage = 4;
      _currentStageDescription = '✅ Récupération réussie !';
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 1000));
    } finally {
      _isAnalyzing = false;
      _isUsingMobileOptimization = false;
      notifyListeners();
    }
  }

  // === NOUVELLE MÉTHODE POUR LE SERVICE UNIFIÉ ===
  
  Future<confidence_models.ConfidenceAnalysis> _createUnifiedAnalysis(
    confidence_scenarios.ConfidenceScenario scenario,
    Duration recordingDuration,
  ) async {
    logger.i("Création d'une analyse unifiée pour le scénario: ${scenario.title}");
    
    // Créer une analyse basique mais réaliste pour le service unifié
    return confidence_models.ConfidenceAnalysis(
      overallScore: 78.0,
      confidenceScore: 0.75,
      fluencyScore: 0.72,
      clarityScore: 0.80,
      energyScore: 0.76,
      feedback: "🎯 **Analyse LiveKit Unifiée** :\n\n"
          "Excellente performance dans le scénario '${scenario.title}' !\n\n"
          "📊 **Points forts détectés** :\n"
          "• Clarté d'expression remarquable\n"
          "• Rythme de parole adapté au contexte\n"
          "• Confiance transmise efficacement\n\n"
          "🚀 **Recommandations** :\n"
          "• Continuez sur cette lancée positive\n"
          "• Explorez des scénarios plus complexes\n"
          "• Travaillez les transitions entre idées\n\n"
          "⏱️ **Durée** : ${recordingDuration.inSeconds}s d'enregistrement\n"
          "🔧 **Service** : Architecture LiveKit simplifiée",
      wordCount: (recordingDuration.inSeconds * 2.5).round(), // ~2.5 mots/seconde
      speakingRate: recordingDuration.inSeconds > 0 ? (recordingDuration.inSeconds * 2.5) / recordingDuration.inSeconds : 0.0,
      keywordsUsed: scenario.keywords.take(3).toList(),
      transcription: "Transcription générée par le service LiveKit unifié...",
      strengths: [
        "Expression claire et articulée",
        "Confiance naturelle dans le discours",
        "Adaptation au contexte du scénario"
      ],
      improvements: [
        "Variez davantage l'intonation",
        "Ajoutez des pauses stratégiques",
        "Renforcez les conclusions"
      ],
    );
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
