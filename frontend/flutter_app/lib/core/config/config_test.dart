/// Test de validation de la configuration réseau et d'environnement
/// 
/// Ce fichier permet de tester que toutes les configurations sont correctes
/// avant de lancer l'application
import 'environment_config.dart';
import 'network_config.dart';
import '../services/network_diagnostic_service.dart';
import '../services/livekit_config_service.dart';

class ConfigTest {
  /// Test complet de la configuration
  static Future<void> runFullConfigTest() async {
    print('🧪 === DÉMARRAGE DES TESTS DE CONFIGURATION ===');
    
    // Test 1: Validation de la configuration d'environnement
    print('\n📋 Test 1: Validation de la configuration d\'environnement');
    final envErrors = EnvironmentConfig.validateConfig();
    if (envErrors.isEmpty) {
      print('✅ Configuration d\'environnement valide');
    } else {
      print('❌ Erreurs dans la configuration d\'environnement:');
      envErrors.forEach((error) => print('   • $error'));
    }
    
    // Test 2: Affichage de la configuration
    print('\n📋 Test 2: Affichage de la configuration');
    EnvironmentConfig.debugConfig();
    
    // Test 3: Configuration réseau
    print('\n📋 Test 3: Configuration réseau');
    NetworkConfig.debugNetworkConfig();
    
    // Test 4: Configuration LiveKit
    print('\n📋 Test 4: Configuration LiveKit');
    LiveKitConfigService.debugLiveKitConfig();
    
    // Test 5: Diagnostic réseau (optionnel - peut prendre du temps)
    print('\n📋 Test 5: Diagnostic réseau des services');
    print('⏳ Test de connectivité en cours...');
    
    try {
      final results = await NetworkDiagnosticService.testAllServices();
      final report = NetworkDiagnosticService.generateDiagnosticReport(results);
      print(report);
    } catch (e) {
      print('❌ Erreur lors du diagnostic réseau: $e');
    }
    
    print('\n🧪 === FIN DES TESTS DE CONFIGURATION ===');
  }
  
  /// Test rapide de la configuration (sans diagnostic réseau)
  static void runQuickConfigTest() {
    print('🧪 === TEST RAPIDE DE CONFIGURATION ===');
    
    // Validation de base
    final envErrors = EnvironmentConfig.validateConfig();
    if (envErrors.isNotEmpty) {
      print('❌ Erreurs de configuration détectées:');
      envErrors.forEach((error) => print('   • $error'));
      return;
    }
    
    // Affichage des configurations
    EnvironmentConfig.debugConfig();
    NetworkConfig.debugNetworkConfig();
    LiveKitConfigService.debugLiveKitConfig();
    
    print('✅ Configuration de base valide');
    print('🧪 === FIN DU TEST RAPIDE ===');
  }
  
  /// Test spécifique à un service
  static Future<void> testSpecificService(String serviceName) async {
    print('🧪 === TEST DU SERVICE: $serviceName ===');
    
    try {
      final results = await NetworkDiagnosticService.testAllServices();
      final serviceResult = results[serviceName];
      
      if (serviceResult != null) {
        final statusIcon = _getStatusIcon(serviceResult.status);
        print('$statusIcon $serviceName: ${serviceResult.details}');
        print('   URL: ${serviceResult.url}');
        print('   Temps de réponse: ${serviceResult.responseTime.inMilliseconds}ms');
      } else {
        print('❌ Service $serviceName non trouvé dans les résultats');
      }
    } catch (e) {
      print('❌ Erreur lors du test: $e');
    }
    
    print('🧪 === FIN DU TEST ===');
  }
  
  static String _getStatusIcon(dynamic status) {
    switch (status) {
      case DiagnosticStatus.success:
        return '✅';
      case DiagnosticStatus.warning:
        return '⚠️';
      case DiagnosticStatus.error:
        return '❌';
      default:
        return '❓';
    }
  }
}

/// Point d'entrée pour les tests (à utiliser dans le code de développement)
void main() {
  // Test rapide par défaut
  ConfigTest.runQuickConfigTest();
  
  // Décommentez pour le test complet (peut prendre du temps)
  // ConfigTest.runFullConfigTest();
  
  // Test d'un service spécifique
  // ConfigTest.testSpecificService('livekitHttp');
}
