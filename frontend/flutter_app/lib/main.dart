import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'presentation/app.dart';

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
  } catch (e) {
    log.severe("Error loading .env file: $e");
  }

  runApp(const App());
}
