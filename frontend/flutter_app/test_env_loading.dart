import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  debugPrint('🔍 TEST CHARGEMENT VARIABLES ENVIRONNEMENT');
  debugPrint('=' * 50);
  
  try {
    // Charger le fichier .env
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Fichier .env chargé avec succès');
    
    // Afficher le nombre total de variables
    debugPrint('📊 Nombre total de variables: ${dotenv.env.length}');
    
    // Tester les variables critiques
    final criticalVars = [
      'LLM_SERVICE_URL',
      'STT_SERVICE_URL',
      'WHISPER_STT_URL',
      'MOBILE_MODE',
      'ENVIRONMENT',
      'HYBRID_EVALUATION_URL'
    ];
    
    debugPrint('\n🎯 VARIABLES CRITIQUES:');
    for (final varName in criticalVars) {
      final value = dotenv.env[varName];
      final status = value != null ? '✅' : '❌';
      debugPrint('  $status $varName: ${value ?? "NON TROUVÉE"}');
    }
    
    // Vérifier les URLs réseau vs localhost
    debugPrint('\n🌐 ANALYSE URL RÉSEAU:');
    final networkVars = dotenv.env.entries
        .where((e) => e.value.contains('192.168.1.44'))
        .toList();
    
    final localhostVars = dotenv.env.entries
        .where((e) => e.value.contains('localhost') || e.value.contains('127.0.0.1'))
        .toList();
        
    debugPrint('  📍 URLs réseau (192.168.1.44): ${networkVars.length}');
    for (final entry in networkVars.take(5)) {
      debugPrint('    • ${entry.key}: ${entry.value}');
    }
    
    debugPrint('  🏠 URLs localhost: ${localhostVars.length}');
    for (final entry in localhostVars.take(3)) {
      debugPrint('    • ${entry.key}: ${entry.value}');
    }
    
    // État final
    final hasNetworkUrls = networkVars.isNotEmpty;
    final hasLlmServiceUrl = dotenv.env['LLM_SERVICE_URL'] != null;
    
    debugPrint('\n🎯 DIAGNOSTIC FINAL:');
    debugPrint('  ${hasNetworkUrls ? "✅" : "❌"} URLs réseau détectées');
    debugPrint('  ${hasLlmServiceUrl ? "✅" : "❌"} LLM_SERVICE_URL configurée');
    
    if (hasNetworkUrls && hasLlmServiceUrl) {
      debugPrint('\n🚀 RÉSULTAT: Configuration mobile ACTIVE et CORRECTE');
    } else {
      debugPrint('\n⚠️  RÉSULTAT: Problème de configuration détecté');
    }
    
  } catch (e) {
    debugPrint('❌ ERREUR: $e');
  }
}