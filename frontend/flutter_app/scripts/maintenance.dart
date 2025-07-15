// Script de maintenance pour l’application Flutter Eloquence
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/features/confidence_boost/data/services/mistral_cache_service.dart';

void main(List<String> args) async {
  print('=== Script de maintenance Eloquence Flutter ===\n');
  print('1. Nettoyer le cache Mistral');
  print('2. Réinitialiser les préférences utilisateur');
  print('3. Vérifier la connectivité backend');
  print('4. Relancer les tests automatisés');
  print('5. Quitter');
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
      print('Fin du script.');
  }
}

Future<void> _clearMistralCache() async {
  print('\nNettoyage du cache Mistral...');
  await dotenv.load(fileName: '.env');
  await MistralCacheService.clearCache();
  print('✅ Cache Mistral vidé.');
}

Future<void> _resetPreferences() async {
  print('\nRéinitialisation des préférences utilisateur...');
  final prefsFile = File('test_env_simple.dart');
  if (prefsFile.existsSync()) {
    prefsFile.deleteSync();
    print('✅ Fichier de préférences supprimé.');
  } else {
    print('Aucun fichier de préférences à supprimer.');
  }
}

Future<void> _checkBackend() async {
  print('\nVérification de la connectivité backend...');
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['LLM_SERVICE_URL'] ?? 'http://localhost:8000';
  try {
    final result = await Process.run('curl', ['-I', url]);
    print(result.stdout);
    print('✅ Connectivité backend testée.');
  } catch (e) {
    print('❌ Erreur de connexion au backend : $e');
  }
}

Future<void> _runTests() async {
  print('\nRelance des tests automatisés Flutter...');
  final result = await Process.run('flutter', ['test']);
  print(result.stdout);
  print(result.stderr);
  print('✅ Tests terminés.');
}