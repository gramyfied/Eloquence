// test_backend_connection.dart
import 'dart:io';
import 'lib/config/environment_config.dart';
import 'lib/services/eloquence_conversation_service.dart';

void main() async {
  print('🔍 Test de connexion au backend Eloquence');
  print('==========================================');
  
  // Configuration pour différents environnements
  await testEnvironment('Development (Local)', () {
    EnvironmentConfig.configureForLocalDevelopment();
  });
  
  await testEnvironment('Production (Scaleway)', () {
    // Configuration avec l'IP Scaleway réelle sur le bon port
    EnvironmentConfig.initialize(
      environment: 'production',
      apiUrl: 'http://51.159.110.4:8005',
    );
  });
  
  // Test avec l'IP directe Scaleway
  await testEnvironment('Scaleway Direct IP', () {
    EnvironmentConfig.initialize(
      environment: 'production',
      apiUrl: 'http://51.159.110.4:8005',
    );
  });
  
  // Test avec HTTPS (si configuré)
  await testEnvironment('Scaleway HTTPS', () {
    EnvironmentConfig.initialize(
      environment: 'production',
      apiUrl: 'https://51.159.110.4:8005',
    );
  });
  
  print('\n✅ Tests terminés');
}

Future<void> testEnvironment(String name, Function configure) async {
  print('\n📡 Test: $name');
  print('${'-' * 40}');
  
  try {
    // Configurer l'environnement
    configure();
    EnvironmentConfig.printConfig();
    
    // Créer le service
    final service = EloquenceConversationService();
    
    print('\n🔄 Test de connexion...');
    
    // Test 1: Health Check
    print('1. Health Check...');
    final isHealthy = await service.healthCheck().timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('   ❌ Timeout - Le serveur ne répond pas');
        return false;
      },
    );
    
    if (isHealthy) {
      print('   ✅ Health Check réussi');
    } else {
      print('   ❌ Health Check échoué');
      return;
    }
    
    // Test 2: Récupération des exercices
    print('2. Récupération des exercices...');
    final exercises = await service.getExercises().timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('   ❌ Timeout - Récupération des exercices échouée');
        return <Map<String, dynamic>>[];
      },
    );
    
    if (exercises.isNotEmpty) {
      print('   ✅ ${exercises.length} exercices récupérés');
      for (var exercise in exercises.take(3)) {
        print('      - ${exercise['name'] ?? exercise['type'] ?? 'Exercice'}');
      }
    } else {
      print('   ⚠️  Aucun exercice trouvé (peut être normal)');
    }
    
    // Test 3: Test de création de session
    print('3. Test de création de session...');
    final session = await service.createSession(
      exerciseType: 'confidence_boost',
      userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('   ❌ Timeout - Création de session échouée');
        return null;
      },
    );
    
    if (session != null) {
      print('   ✅ Session créée: ${session['session_id'] ?? 'ID non disponible'}');
    } else {
      print('   ❌ Échec de création de session');
    }
    
    print('\n🎉 Test $name terminé avec succès');
    
  } catch (e) {
    print('\n❌ Erreur lors du test $name:');
    print('   $e');
    
    if (e is SocketException) {
      print('   💡 Suggestion: Vérifiez que le serveur est accessible');
      print('   💡 Vérifiez l\'URL et le port');
    } else if (e.toString().contains('certificate')) {
      print('   💡 Suggestion: Problème de certificat SSL');
      print('   💡 Vérifiez la configuration HTTPS');
    }
  }
}
