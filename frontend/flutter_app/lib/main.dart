import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'core/config/app_config.dart';
import 'core/utils/logger_service.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i('main', 'Chargement des variables d\'environnement...');
  
  try {
    await dotenv.load(fileName: ".env");
    logger.i('main', 'Variables d\'environnement chargees avec succes');
  } catch (e) {
    logger.w('main', 'Impossible de charger le fichier .env: $e');
    logger.i('main', 'Utilisation des valeurs par defaut');
  }

  // await AppConfig.initialize(); // Supprimé car AppConfig est maintenant statique
  logger.i('main', 'Configuration de l\'application initialisee');

  logger.i('main', 'Lancement de l\'application Eloquence 2.0 optimisee');
  logger.i('main', 'Thread principal non bloque - WebRTC initialise a la demande');

  // Test de connectivité au démarrage
  logger.i('main', '[DIAGNOSTIC] Test de connectivité backend...');
  logger.i('main', '[DIAGNOSTIC] IP configurée: ${AppConfig.devServerIP}');
  
  try {
    final testUrl = 'http://${AppConfig.devServerIP}:5002/health';
    logger.i('main', '[DIAGNOSTIC] Test de connexion à: $testUrl');
    
    final response = await http.get(
      Uri.parse(testUrl),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 5));
    
    logger.i('main', '[DIAGNOSTIC] ✓ Backend accessible! Status: ${response.statusCode}');
    logger.i('main', '[DIAGNOSTIC] Réponse: ${response.body}');
  } catch (e) {
    logger.e('main', '[DIAGNOSTIC] ✗ ERREUR: Backend inaccessible!');
    logger.e('main', '[DIAGNOSTIC] Type erreur: ${e.runtimeType}');
    logger.e('main', '[DIAGNOSTIC] Détails: $e');
    
    if (e.toString().contains('SocketException')) {
      logger.e('main', '[DIAGNOSTIC] → Erreur réseau: Vérifiez l\'IP (${AppConfig.devServerIP}) et le pare-feu');
    } else if (e.toString().contains('TimeoutException')) {
      logger.e('main', '[DIAGNOSTIC] → Timeout: Le service ne répond pas');
    }
  }
  
  // Test LiveKit WebSocket
  logger.i('main', '[DIAGNOSTIC] URL LiveKit configurée: ${AppConfig.livekitUrl}');

  runApp(const ProviderScope(child: EloquenceApp()));
}
