// Script de maintenance pour l’application Flutter Eloquence
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_cache_service.dart';

void main(List<String> args) async {
  debugPrint('=== Script de maintenance Eloquence Flutter ===\n');
  debugPrint('1. Nettoyer le cache Mistral');
  debugPrint('2. Réinitialiser les préférences utilisateur');
  debugPrint('3. Vérifier la connectivité backend');
  debugPrint('4. Relancer les tests automatisés');
  debugPrint('5. Quitter');
  stdout.write('\nChoisissez une option (1-5) : ');
  final choice = stdin.readLineSync();

  switch (choice) {
    case '1':
      await _clearMistralCache();
      break;
    case '2':
      await _resetPreferences();
      break;
    case '3':
      await _checkBackend();
      break;
    case '4':
      await _runTests();
      break;
    default:
      debugPrint('Fin du script.');
  }
}

Future<void> _clearMistralCache() async {
  debugPrint('\nNettoyage du cache Mistral...');
  await dotenv.load(fileName: '.env');
  await MistralCacheService.clearCache();
  debugPrint('✅ Cache Mistral vidé.');
}

Future<void> _resetPreferences() async {
  debugPrint('\nRéinitialisation des préférences utilisateur...');
  final prefsFile = File('test_env_simple.dart');
  if (prefsFile.existsSync()) {
    prefsFile.deleteSync();
    debugPrint('✅ Fichier de préférences supprimé.');
  } else {
    debugPrint('Aucun fichier de préférences à supprimer.');
  }
}

Future<void> _checkBackend() async {
  debugPrint('\nVérification de la connectivité backend...');
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['LLM_SERVICE_URL'] ?? 'http://localhost:8000';
  try {
    final result = await Process.run('curl', ['-I', url]);
    debugPrint(result.stdout);
    debugPrint('✅ Connectivité backend testée.');
  } catch (e) {
    debugPrint('❌ Erreur de connexion au backend : $e');
  }
}

Future<void> _runTests() async {
  debugPrint('\nRelance des tests automatisés Flutter...');
  final result = await Process.run('flutter', ['test']);
  debugPrint(result.stdout);
  debugPrint(result.stderr);
  debugPrint('✅ Tests terminés.');
}