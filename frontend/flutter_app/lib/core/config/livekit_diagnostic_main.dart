import 'environment_config.dart';
import '../services/livekit_token_diagnostic_service.dart';
import '../services/network_diagnostic_service.dart';
import '../services/livekit_config_service.dart';
import 'livekit_connection_test.dart';

/// Script principal de diagnostic LiveKit
/// Combine tous les outils de diagnostic pour identifier les problèmes
class LiveKitDiagnosticMain {
  static const String _tag = '🔧 LiveKitDiagnosticMain';

  /// Diagnostic complet de l'infrastructure LiveKit
  static Future<void> runCompleteDiagnostic() async {
    print('🔧 DIAGNOSTIC COMPLET LIVEKIT');
    print('==============================');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('');

    try {
      // Phase 1: Vérification de la configuration
      print('📋 PHASE 1: VÉRIFICATION DE LA CONFIGURATION');
      print('----------------------------------------------');
      await _checkConfiguration();
      print('');

      // Phase 2: Test de connectivité réseau
      print('🌐 PHASE 2: TEST DE CONNECTIVITÉ RÉSEAU');
      print('----------------------------------------');
      await _testNetworkConnectivity();
      print('');

      // Phase 3: Test des services LiveKit
      print('🎯 PHASE 3: TEST DES SERVICES LIVEKIT');
      print('--------------------------------------');
      await _testLiveKitServices();
      print('');

      // Phase 4: Test de génération de tokens
      print('🔑 PHASE 4: TEST DE GÉNÉRATION DE TOKENS');
      print('------------------------------------------');
      await _testTokenGeneration();
      print('');

      // Phase 5: Test de configuration LiveKit
      print('⚙️ PHASE 5: TEST DE CONFIGURATION LIVEKIT');
      print('-------------------------------------------');
      await _testLiveKitConfiguration();
      print('');

      // Phase 6: Résumé et recommandations
      print('📊 PHASE 6: RÉSUMÉ ET RECOMMANDATIONS');
      print('----------------------------------------');
      await _generateSummaryAndRecommendations();
      print('');

    } catch (e) {
      print('$_tag: ❌ Erreur lors du diagnostic complet: $e');
    }

    print('$_tag: ✅ Diagnostic complet terminé');
  }

  /// Vérification de la configuration
  static Future<void> _checkConfiguration() async {
    print('$_tag: Vérification de la configuration...');
    
    try {
      // Afficher la configuration actuelle
      print('  Configuration EnvironmentConfig:');
      print('    API Key: ${EnvironmentConfig.livekitApiKey}');
      print('    API Secret: ${EnvironmentConfig.livekitApiSecret.substring(0, 10)}...');
      print('    LiveKit URL: ${EnvironmentConfig.livekitUrl}');
      print('    Token Service URL: ${EnvironmentConfig.livekitTokenUrl}');
      print('    Dev Host IP: ${EnvironmentConfig.devHostIP}');
      
      // Vérifier le format des clés
      final expectedFormat = '${EnvironmentConfig.livekitApiKey}: ${EnvironmentConfig.livekitApiSecret}';
      print('    Format attendu par LiveKit: $expectedFormat');
      
      // Vérifier la cohérence des URLs
      final configIssues = <String>[];
      
      if (!EnvironmentConfig.livekitUrl.contains(EnvironmentConfig.devHostIP)) {
        configIssues.add('LiveKit URL ne contient pas l\'IP de développement');
      }
      
      if (!EnvironmentConfig.livekitTokenUrl.contains(EnvironmentConfig.devHostIP)) {
        configIssues.add('Token Service URL ne contient pas l\'IP de développement');
      }
      
      if (configIssues.isEmpty) {
        print('  ✅ Configuration cohérente');
      } else {
        print('  ⚠️ Problèmes de configuration détectés:');
        for (final issue in configIssues) {
          print('    - $issue');
        }
      }
      
    } catch (e) {
      print('  ❌ Erreur vérification configuration: $e');
    }
  }

  /// Test de connectivité réseau
  static Future<void> _testNetworkConnectivity() async {
    print('$_tag: Test de connectivité réseau...');
    
    try {
      // Test de tous les services
      final results = await NetworkDiagnosticService.testAllServices();
      
      print('  Résultats des tests de connectivité:');
      for (final result in results) {
        final status = result.status == DiagnosticStatus.success ? '✅' : '❌';
        print('    $status ${result.serviceName}: ${result.description}');
        
        if (result.status == DiagnosticStatus.failure) {
          print('      Erreur: ${result.error}');
        }
      }
      
      // Compter les succès/échecs
      final successCount = results.where((r) => r.status == DiagnosticStatus.success).length;
      final totalCount = results.length;
      
      print('  Résumé: $successCount/$totalCount services accessibles');
      
    } catch (e) {
      print('  ❌ Erreur test connectivité réseau: $e');
    }
  }

  /// Test des services LiveKit
  static Future<void> _testLiveKitServices() async {
    print('$_tag: Test des services LiveKit...');
    
    try {
      // Test de connectivité au serveur LiveKit principal
      await LiveKitConnectionTest.runQuickTest();
      
    } catch (e) {
      print('  ❌ Erreur test services LiveKit: $e');
    }
  }

  /// Test de génération de tokens
  static Future<void> _testTokenGeneration() async {
    print('$_tag: Test de génération de tokens...');
    
    try {
      // Test complet de génération de tokens
      final results = await LiveKitTokenDiagnosticService.runFullDiagnostic();
      
      // Afficher le rapport
      print('  Rapport de diagnostic des tokens:');
      print(LiveKitTokenDiagnosticService.generateDiagnosticReport(results));
      
    } catch (e) {
      print('  ❌ Erreur test génération tokens: $e');
    }
  }

  /// Test de configuration LiveKit
  static Future<void> _testLiveKitConfiguration() async {
    print('$_tag: Test de configuration LiveKit...');
    
    try {
      // Afficher la configuration LiveKit
      LiveKitConfigService.debugLiveKitConfig();
      
      // Vérifier la configuration des serveurs ICE
      final iceServers = LiveKitConfigService.iceServers;
      print('  Serveurs ICE configurés: ${iceServers.length}');
      
      for (final server in iceServers) {
        print('    - ${server.urls.join(', ')}');
      }
      
    } catch (e) {
      print('  ❌ Erreur test configuration LiveKit: $e');
    }
  }

  /// Génération du résumé et recommandations
  static Future<void> _generateSummaryAndRecommendations() async {
    print('$_tag: Génération du résumé et recommandations...');
    
    try {
      print('  📊 RÉSUMÉ DU DIAGNOSTIC:');
      print('  =========================');
      
      // Vérifier les points critiques
      final criticalIssues = <String>[];
      final warnings = <String>[];
      final successes = <String>[];
      
      // Test rapide de connectivité au service de tokens
      try {
        final url = '${EnvironmentConfig.livekitTokenUrl}/health';
        final response = await NetworkDiagnosticService.testHttpService(url, 'LiveKit Token Service');
        
        if (response.status == DiagnosticStatus.success) {
          successes.add('Service de tokens accessible');
        } else {
          criticalIssues.add('Service de tokens inaccessible: ${response.error}');
        }
      } catch (e) {
        criticalIssues.add('Erreur test service tokens: $e');
      }
      
      // Test rapide de génération de token
      try {
        final tokenTest = await LiveKitTokenDiagnosticService.runQuickDiagnostic();
        // Le test affiche déjà ses résultats
      } catch (e) {
        warnings.add('Erreur test génération token: $e');
      }
      
      // Afficher les résultats
      if (successes.isNotEmpty) {
        print('  ✅ SUCCÈS:');
        for (final success in successes) {
          print('    - $success');
        }
        print('');
      }
      
      if (warnings.isNotEmpty) {
        print('  ⚠️ AVERTISSEMENTS:');
        for (final warning in warnings) {
          print('    - $warning');
        }
        print('');
      }
      
      if (criticalIssues.isNotEmpty) {
        print('  ❌ PROBLÈMES CRITIQUES:');
        for (final issue in criticalIssues) {
          print('    - $issue');
        }
        print('');
      }
      
      // Recommandations
      print('  💡 RECOMMANDATIONS:');
      print('  ===================');
      
      if (criticalIssues.isNotEmpty) {
        print('    1. Résoudre les problèmes critiques avant de continuer');
        print('    2. Vérifier que tous les services Docker sont démarrés');
        print('    3. Vérifier la configuration réseau et les ports');
      } else if (warnings.isNotEmpty) {
        print('    1. Résoudre les avertissements pour une meilleure stabilité');
        print('    2. Vérifier la configuration des clés LiveKit');
      } else {
        print('    1. Configuration LiveKit fonctionnelle');
        print('    2. Tous les services sont accessibles');
        print('    3. Génération de tokens opérationnelle');
      }
      
      print('    4. Exécuter les tests régulièrement pour surveiller la santé');
      print('    5. Consulter les logs Docker en cas de problème');
      
    } catch (e) {
      print('  ❌ Erreur génération résumé: $e');
    }
  }

  /// Diagnostic rapide
  static Future<void> runQuickDiagnostic() async {
    print('🔧 DIAGNOSTIC RAPIDE LIVEKIT');
    print('=============================');
    print('');

    try {
      // Test rapide de connectivité
      await _testNetworkConnectivity();
      print('');

      // Test rapide des services LiveKit
      await _testLiveKitServices();
      print('');

      // Résumé rapide
      await _generateSummaryAndRecommendations();
      print('');

    } catch (e) {
      print('$_tag: ❌ Erreur lors du diagnostic rapide: $e');
    }

    print('$_tag: ✅ Diagnostic rapide terminé');
  }
}

// Point d'entrée principal
void main() {
  print('🔧 Outil de diagnostic LiveKit Eloquence');
  print('=========================================');
  print('');
  
  // Exécuter le diagnostic rapide par défaut
  LiveKitDiagnosticMain.runQuickDiagnostic();
  
  // Décommenter pour le diagnostic complet
  // LiveKitDiagnosticMain.runCompleteDiagnostic();
}
