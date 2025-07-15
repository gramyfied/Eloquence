import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../lib/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
import '../../fakes/fake_mistral_api_service.dart';

void main() {
  group('Test refactorisé de Génération Mistral API avec injection', () {
    late FakeMistralApiService fakeService;

    setUpAll(() async {
      // Charger le fichier .env pour les tests
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      fakeService = FakeMistralApiService();
    });

    test('devrait générer du texte avec FakeMistralApiService injecté via Riverpod', () async {
      const prompt = '''
      Analysez cette présentation orale et donnez des conseils constructifs :
      "Bonjour tout le monde, je vais vous parler de l\'importance de la communication dans le travail d\'équipe."

      Donnez un feedback bref et encourageant en français.
      ''';

      final container = ProviderContainer(
        overrides: [
          mistralApiServiceProvider.overrideWithValue(fakeService),
        ],
      );

      final service = container.read(mistralApiServiceProvider);

      final result = await service.generateText(prompt: prompt);

      print('=== RÉSULTAT GÉNÉRATION MISTRAL (Fake) ===');
      print('Prompt: \$prompt');
      print('Réponse: \$result');
      print('=== FIN RÉSULTAT ===');

      // Vérifier que le résultat n'est pas vide
      expect(result, isNotEmpty);

      // Vérifier que c'est bien du français (contient des mots français typiques)
      final textLower = result.toLowerCase();
      final frenchWords = ['le', 'la', 'les', 'de', 'du', 'des', 'et', 'ou', 'bien', 'très', 'bon', 'bonne'];
      final containsFrench = frenchWords.any((word) => textLower.contains(word));

      expect(containsFrench, isTrue, reason: 'Le texte généré devrait contenir des mots français');

      // Vérifier une longueur raisonnable
      expect(result.length, greaterThan(20), reason: 'Le feedback devrait être substantiel');

      container.dispose();
    });
  });
}