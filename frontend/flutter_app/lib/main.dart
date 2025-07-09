import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'core/config/supabase_config.dart'; // Import Supabase Config
import 'presentation/app.dart'; // Import App au lieu de AuthWrapper
import 'features/confidence_boost/presentation/providers/confidence_boost_provider.dart'; // Import pour override

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL; // Set the root logger level
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('StackTrace: ${record.stackTrace}');
    }
  });

  final log = Logger('main');

  try {
    usePathUrlStrategy(); // Use path-based URLs for web
    await dotenv.load(fileName: ".env");
    log.info(".env file loaded successfully");
    
    // Initialiser Supabase
    await SupabaseConfig.initialize();
    log.info("Supabase initialized successfully");
    
    // Initialiser SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    log.info("SharedPreferences initialized successfully");

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
