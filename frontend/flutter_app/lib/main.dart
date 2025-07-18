import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'core/config/supabase_config.dart'; // Import Supabase Config
import 'presentation/app.dart'; // Import App au lieu de AuthWrapper
// Imports des modèles Hive
import 'features/confidence_boost/domain/entities/gamification_models.dart';
import 'features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'features/confidence_boost/data/services/mistral_cache_service.dart'; // Import pour MistralCacheService

import 'features/confidence_boost/presentation/providers/confidence_boost_provider.dart'; // Import pour override

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL; // Set the root logger level
  Logger.root.onRecord.listen((record) {
    // For this refactoring, we remove direct prints to clean up the code.
    // The IDE's debug console will still show logs.
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('StackTrace: ${record.stackTrace}');
    }
  });

  final log = Logger('main');

  try {
    usePathUrlStrategy(); // Use path-based URLs for web
    await dotenv.load(fileName: ".env");
    log.info(".env file loaded successfully");
    
    // 🔍 DEBUG : Vérifier le chargement des variables critiques
    final llmServiceUrl = dotenv.env['LLM_SERVICE_URL'];
    final whisperUrl = dotenv.env['WHISPER_STT_URL'];
    final mobileMode = dotenv.env['MOBILE_MODE'];
    log.info("🔍 DEBUG Variables d'environnement:");
    log.info("  - LLM_SERVICE_URL: $llmServiceUrl");
    log.info("  - WHISPER_STT_URL: $whisperUrl");
    log.info("  - MOBILE_MODE: $mobileMode");
    log.info("  - Total variables chargées: ${dotenv.env.length}");
    
    // --- Gestion Hive ---
    await Hive.initFlutter();
    log.info("Hive initialized successfully");

    await _resetHiveBoxes(log); // Nettoyage des boîtes après init
    
    _registerHiveAdapters(log); // Enregistrement des TypeAdapters
    // --- Fin Gestion Hive ---

    // Initialiser Supabase
    await SupabaseConfig.initialize();
    log.info("Supabase initialized successfully");
    
    // Initialiser SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    log.info("SharedPreferences initialized successfully");

    // Initialiser le cache Mistral
    await MistralCacheService.init();
    log.info("MistralCacheService initialized successfully.");

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );
  } catch (e) {
    log.severe("Error during initialization: $e");
    // En cas d'erreur, lancer l'app quand même mais sans SharedPreferences
    runApp(
      const ProviderScope(
        child: App(),
      ),
    );
  }
}

/// Supprime les boîtes Hive existantes pour éviter les conflits de type ID.
/// Cela est crucial pour les changements de structure de données pendant le développement.
Future<void> _resetHiveBoxes(Logger log) async {
  try {
    log.info("Hive: Début du nettoyage des boîtes existantes...");
    await Hive.deleteBoxFromDisk('userGamificationProfileBox');
    await Hive.deleteBoxFromDisk('confidenceScenariosBox');
    await Hive.deleteBoxFromDisk('userPreferencesBox'); // Si cette boîte existe
    log.info("Hive: Nettoyage des boîtes terminé avec succès.");
  } catch (e) {
    log.warning("Hive: Erreur lors du nettoyage des boîtes (peut être ignorée si les boîtes n'existent pas encore): $e");
  }
}

/// Enregistre tous les TypeAdapters Hive nécessaires.
/// Vérifie qu'un adaptateur n'est pas déjà enregistré pour éviter les erreurs.
void _registerHiveAdapters(Logger log) {
  try {
    log.info("Hive: Enregistrement des TypeAdapters...");
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(UserGamificationProfileAdapter());
      log.info("✅ UserGamificationProfileAdapter registered (typeId: 20)");
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(ConfidenceScenarioAdapter());
      log.info("✅ ConfidenceScenarioAdapter registered (typeId: 21)");
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(BadgeRarityAdapter());
      log.info("✅ BadgeRarityAdapter registered (typeId: 22)");
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(BadgeCategoryAdapter());
      log.info("✅ BadgeCategoryAdapter registered (typeId: 23)");
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(BadgeAdapter());
      log.info("✅ BadgeAdapter registered (typeId: 24)");
    }
    log.info("🎯 Tous les TypeAdapters Hive enregistrés avec succès.");
  } catch (e) {
    log.severe("❌ [HIVE_REGISTER_ERROR] Erreur lors de l'enregistrement des TypeAdapters: $e");
    // Remonter l'erreur pour un crash explicite en développement si nécessaire
    rethrow;
  }
}
