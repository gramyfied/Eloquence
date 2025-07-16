import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  debugPrint('🔍 TEST CHARGEMENT VARIABLES FLUTTER');
  debugPrint('=' * 50);
  
  try {
    // Charger le fichier .env depuis la racine du projet
    final envFile = File('../../.env');
    if (!envFile.existsSync()) {
      debugPrint('❌ ERREUR: Fichier .env non trouvé à la racine');
      return;
    }
    
    // Charger dotenv comme le fait Flutter
    await dotenv.load(fileName: '../../.env');
    debugPrint('✅ Fichier .env chargé avec succès');
    
    // Tester les variables critiques
    final criticalVars = {
      'LLM_SERVICE_URL': 'Service Backend Principal',
      'WHISPER_STT_URL': 'Service Whisper STT',
      'HYBRID_EVALUATION_URL': 'Service Hybrid Evaluation',
      'MOBILE_MODE': 'Mode Mobile',
      'ENVIRONMENT': 'Environnement'
    };
    
    debugPrint('\n🎯 VARIABLES CRITIQUES:');
    bool allGood = true;
    
    for (final entry in criticalVars.entries) {
      final key = entry.key;
      final value = dotenv.env[key];
      
      if (value != null) {
        debugPrint('  ✅ $key: $value');
        
        // Vérification spéciale pour LLM_SERVICE_URL
        if (key == 'LLM_SERVICE_URL') {
          if (value.contains('192.168.1.44:8000')) {
            debugPrint('     🎯 URL réseau correcte (192.168.1.44:8000)');
          } else if (value.contains('localhost')) {
            debugPrint('     ⚠️  ATTENTION: Utilise encore localhost !');
            allGood = false;
          }
        }
      } else {
        debugPrint('  ❌ $key: NON DÉFINIE');
        allGood = false;
      }
    }
    
    debugPrint('\n📊 RÉSUMÉ FINAL:');
    if (allGood) {
      debugPrint('✅ SUCCÈS: Toutes les variables critiques sont correctement configurées');
      debugPrint('🎯 LLM_SERVICE_URL pointe vers le réseau (192.168.1.44:8000)');
      debugPrint('🚀 L\'application mobile devrait maintenant utiliser les URLs réseau');
    } else {
      debugPrint('❌ PROBLÈME: Certaines variables ne sont pas correctement configurées');
    }
    
  } catch (e) {
    debugPrint('❌ ERREUR lors du chargement: $e');
  }
}