import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  print('🔍 TEST CHARGEMENT VARIABLES FLUTTER');
  print('=' * 50);
  
  try {
    // Charger le fichier .env depuis la racine du projet
    final envFile = File('../../.env');
    if (!envFile.existsSync()) {
      print('❌ ERREUR: Fichier .env non trouvé à la racine');
      return;
    }
    
    // Charger dotenv comme le fait Flutter
    await dotenv.load(fileName: '../../.env');
    print('✅ Fichier .env chargé avec succès');
    
    // Tester les variables critiques
    final criticalVars = {
      'LLM_SERVICE_URL': 'Service Backend Principal',
      'WHISPER_STT_URL': 'Service Whisper STT',
      'HYBRID_EVALUATION_URL': 'Service Hybrid Evaluation',
      'MOBILE_MODE': 'Mode Mobile',
      'ENVIRONMENT': 'Environnement'
    };
    
    print('\n🎯 VARIABLES CRITIQUES:');
    bool allGood = true;
    
    for (final entry in criticalVars.entries) {
      final key = entry.key;
      final description = entry.value;
      final value = dotenv.env[key];
      
      if (value != null) {
        print('  ✅ $key: $value');
        
        // Vérification spéciale pour LLM_SERVICE_URL
        if (key == 'LLM_SERVICE_URL') {
          if (value.contains('192.168.1.44:8000')) {
            print('     🎯 URL réseau correcte (192.168.1.44:8000)');
          } else if (value.contains('localhost')) {
            print('     ⚠️  ATTENTION: Utilise encore localhost !');
            allGood = false;
          }
        }
      } else {
        print('  ❌ $key: NON DÉFINIE');
        allGood = false;
      }
    }
    
    print('\n📊 RÉSUMÉ FINAL:');
    if (allGood) {
      print('✅ SUCCÈS: Toutes les variables critiques sont correctement configurées');
      print('🎯 LLM_SERVICE_URL pointe vers le réseau (192.168.1.44:8000)');
      print('🚀 L\'application mobile devrait maintenant utiliser les URLs réseau');
    } else {
      print('❌ PROBLÈME: Certaines variables ne sont pas correctement configurées');
    }
    
  } catch (e) {
    print('❌ ERREUR lors du chargement: $e');
  }
}