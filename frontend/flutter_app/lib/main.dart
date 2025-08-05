import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async'; // Import pour Completer

import 'core/config/supabase_config.dart';
import 'presentation/app.dart';
import 'features/confidence_boost/domain/entities/gamification_models.dart';
import 'features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'features/confidence_boost/domain/entities/virelangue_models.dart';
import 'features/confidence_boost/data/services/virelangue_reward_system.dart';
import 'features/confidence_boost/data/services/virelangue_leaderboard_service.dart';
import 'features/confidence_boost/data/services/mistral_cache_service.dart';
import 'features/confidence_boost/domain/entities/dragon_breath_models.dart';
import 'features/story_generator/domain/entities/story_models.dart';
import 'core/utils/hive_adapters.dart';

import 'features/confidence_boost/presentation/providers/confidence_boost_provider.dart';

// Création d'un Completer pour s'assurer que Hive est prêt.
final hiveInitializationCompleter = Completer<void>();

void main() async {
  final log = Logger('main');
  
  // Isoler l'initialisation dans un runZonedGuarded pour attraper toutes les erreurs.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Configuration du logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('[${record.level.name}] ${record.time}: ${record.message}');
      if (record.error != null) {
        debugPrint('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('StackTrace: ${record.stackTrace}');
      }
    });

    log.info("============== NOUVELLE SESSION DE DÉMARRAGE ==============");
    
    usePathUrlStrategy();
    await dotenv.load(fileName: ".env");
    log.info("✅ 1. .env file loaded.");

    // --- GESTION HIVE STRICTE ---
    log.info("▶️ 2. Initialisation de Hive...");
    await Hive.initFlutter();
    log.info("✅ 2.1. Hive.initFlutter() terminé.");

    _registerHiveAdapters(log);
    log.info("✅ 2.2. Tous les TypeAdapters sont enregistrés.");

    await _initializeHiveBoxes(log);
    log.info("✅ 2.3. Toutes les boîtes Hive sont initialisées.");
    
    // Indiquer que l'initialisation de Hive est terminée.
    hiveInitializationCompleter.complete();
    log.info("✅ 2.4. Hive est entièrement prêt (Completer terminé).");
    // --- FIN GESTION HIVE ---

    await SupabaseConfig.initialize();
    log.info("✅ 3. Supabase initialized.");

    final sharedPreferences = await SharedPreferences.getInstance();
    log.info("✅ 4. SharedPreferences initialized.");

    await MistralCacheService.init();
    log.info("✅ 5. MistralCacheService initialized.");

    log.info("🚀 Démarrage de l'application Flutter...");
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );
  }, (error, stack) {
    log.severe(" BUGSPLAT 💥: Erreur fatale non interceptée dans main.", error, stack);
  });
}

Future<void> _initializeHiveBoxes(Logger log) async {
  try {
    log.info("   -> Ouverture des boîtes Hive...");
    final shouldReset = dotenv.env['RESET_HIVE_BOXES'] == 'true';
    
    if (shouldReset) {
      log.warning("   -> NETTOYAGE FORCÉ des boîtes Hive activé.");
      await Hive.deleteBoxFromDisk('userGamificationProfileBox');
      await Hive.deleteBoxFromDisk('confidenceScenariosBox');
      await Hive.deleteBoxFromDisk('userPreferencesBox');
      await Hive.deleteBoxFromDisk('dragonProgressBox'); // Assurons-nous que celle-ci est aussi nettoyée
    }
    
    // ✅ CORRECTION CRITIQUE: Nettoyage des boîtes corrompues (TypeId 66/70)
    final shouldCleanCorrupted = dotenv.env['CLEAN_CORRUPTED_BOXES'] == 'true';
    if (shouldCleanCorrupted) {
      log.warning("   -> 🚨 NETTOYAGE des boîtes corrompues (TypeId 66/70) activé.");
      try {
        await Hive.deleteBoxFromDisk('virelanguePityTimerBox');
        await Hive.deleteBoxFromDisk('virelangueRewardHistoryBox');
        await Hive.deleteBoxFromDisk('virelangueLeaderboardBox');
        await Hive.deleteBoxFromDisk('virelangueUserRankHistoryBox');
        await Hive.deleteBoxFromDisk('virelangueSeasonStatsBox');
        await Hive.deleteBoxFromDisk('virelangueAchievementsBox');
        log.info("   -> ✅ Boîtes corrompues nettoyées avec succès");
      } catch (e) {
        log.warning("   -> ⚠️ Erreur lors du nettoyage: $e (non critique)");
      }
    }
    
    // On ouvre les boîtes essentielles ici avec gestion d'erreur robuste
    try {
      await Hive.openBox('userGamificationProfileBox');
      await Hive.openBox('confidenceScenariosBox');
      log.info("   -> Boîtes principales ouvertes.");
    } catch (e) {
      log.severe("   -> ❌ Erreur ouverture boîtes principales: $e");
      // En cas d'erreur, nettoyer et recréer
      log.warning("   -> 🔧 Tentative de réparation automatique...");
      try {
        await Hive.deleteBoxFromDisk('userGamificationProfileBox');
        await Hive.deleteBoxFromDisk('confidenceScenariosBox');
        await Hive.openBox('userGamificationProfileBox');
        await Hive.openBox('confidenceScenariosBox');
        log.info("   -> ✅ Boîtes principales recréées après réparation.");
      } catch (e2) {
        log.severe("   -> ❌ ÉCHEC de la réparation: $e2");
        rethrow;
      }
    }
  } catch (e, stack) {
    log.severe("   -> ERREUR CRITIQUE lors de l'initialisation des boîtes Hive.", e, stack);
    rethrow;
  }
}

void _registerHiveAdapters(Logger log) {
  void register<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
      log.info("   -> Adaptateur ${adapter.runtimeType} enregistré (typeId: $typeId)");
    } else {
      log.info("   -> Adaptateur ${adapter.runtimeType} (typeId: $typeId) était déjà enregistré.");
    }
  }

  try {
    log.info("   -> Enregistrement des TypeAdapters...");
    register(20, UserGamificationProfileAdapter());
    register(21, ConfidenceScenarioAdapter());
    register(22, BadgeRarityAdapter());
    register(23, BadgeCategoryAdapter());
    register(24, BadgeAdapter());
    
    // Virelangues
    register(30, GemTypeAdapter());
    register(31, VirelangueAdapter());
    register(32, GemCollectionAdapter());
    register(66, PityTimerStateAdapter());
    register(34, RewardHistoryAdapter());
    register(35, VirelangueDifficultyAdapter());
    register(36, VirelangueStatsAdapter());
    register(37, VirelangueUserProgressAdapter());

    // Dragon Breath
    register(40, DragonLevelAdapter());
    register(41, BreathingPhaseAdapter());
    register(42, BreathingExerciseAdapter());
    register(43, BreathingMetricsAdapter());
    register(44, DragonAchievementAdapter());
    register(45, BreathingSessionAdapter());
    register(46, DragonProgressAdapter());
    
    // Story Generator Models
    register(50, StoryElementTypeAdapter());
    register(51, StoryGenreAdapter());
    register(52, StoryElementAdapter());
    register(53, AIInterventionAdapter());
    register(54, StoryMetricsAdapter());
    register(55, StoryAdapter());
    register(71, StoryBadgeTypeAdapter());
    register(72, StoryUserStatsAdapter());
    register(73, InterventionTypeAdapter());
    register(74, AudioMetricsAdapter());
    register(75, StoryNarrativeAnalysisAdapter());
    
    // Leaderboard Models
    register(61, LeaderboardAchievementAdapter());
    register(67, UserRankHistoryAdapter());
    register(68, RankSnapshotAdapter());
    register(69, SeasonStatsAdapter());
    register(70, LeaderboardEntryAdapter());
    
    // Adaptateurs pour types complexes
    register(100, DurationAdapter());
    register(101, MapStringDynamicAdapter());
    register(102, ListDoubleAdapter());
    register(103, DateTimeAdapter());
    
    log.info("   -> Tous les adaptateurs ont été traités.");
  } catch (e, stack) {
    log.severe("   -> ERREUR CRITIQUE lors de l'enregistrement d'un adaptateur.", e, stack);
    rethrow;
  }
}
