import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  print('🔍 TEST CHARGEMENT VARIABLES ENVIRONNEMENT');
  print('=' * 50);
  
  try {
    // Charger le fichier .env
    await dotenv.load(fileName: ".env");
    print('✅ Fichier .env chargé avec succès');
    
    // Afficher le nombre total de variables
    print('📊 Nombre total de variables: ${dotenv.env.length}');
    
    // Tester les variables critiques
    final criticalVars = [
      'LLM_SERVICE_URL',
      'STT_SERVICE_URL', 
      'WHISPER_STT_URL',
      'MOBILE_MODE',
      'ENVIRONMENT',
      'HYBRID_EVALUATION_URL'
    ];
    
    print('\n🎯 VARIABLES CRITIQUES:');
    for (final varName in criticalVars) {
      final value = dotenv.env[varName];
      final status = value != null ? '✅' : '❌';
      print('  $status $varName: ${value ?? "NON TROUVÉE"}');
    }
    
    // Vérifier les URLs réseau vs localhost
    print('\n🌐 ANALYSE URL RÉSEAU:');
    final networkVars = dotenv.env.entries
        .where((e) => e.value.contains('192.168.1.44'))
        .toList();
    
    final localhostVars = dotenv.env.entries
        .where((e) => e.value.contains('localhost') || e.value.contains('127.0.0.1'))
        .toList();
        
    print('  📍 URLs réseau (192.168.1.44): ${networkVars.length}');
    for (final entry in networkVars.take(5)) {
      print('    • ${entry.key}: ${entry.value}');
    }
    
    print('  🏠 URLs localhost: ${localhostVars.length}');
    for (final entry in localhostVars.take(3)) {
      print('    • ${entry.key}: ${entry.value}');
    }
    
    // État final
    final hasNetworkUrls = networkVars.isNotEmpty;
    final hasLlmServiceUrl = dotenv.env['LLM_SERVICE_URL'] != null;
    
    print('\n🎯 DIAGNOSTIC FINAL:');
    print('  ${hasNetworkUrls ? "✅" : "❌"} URLs réseau détectées');
    print('  ${hasLlmServiceUrl ? "✅" : "❌"} LLM_SERVICE_URL configurée');
    
    if (hasNetworkUrls && hasLlmServiceUrl) {
      print('\n🚀 RÉSULTAT: Configuration mobile ACTIVE et CORRECTE');
    } else {
      print('\n⚠️  RÉSULTAT: Problème de configuration détecté');
    }
    
  } catch (e) {
    print('❌ ERREUR: $e');
  }
}