import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_api_service.dart';

void main() {
  group('Test de Génération Mistral API', () {
    setUpAll(() async {
      // Charger le fichier .env pour les tests
      await dotenv.load(fileName: '.env');
    });

    test('devrait générer du texte avec l\'API Mistral réelle', () async {
      final service = MistralApiService();
      
      const prompt = '''
      Analysez cette présentation orale et donnez des conseils constructifs :
      "Bonjour tout le monde, je vais vous parler de l'importance de la communication dans le travail d'équipe."
      
      Donnez un feedback bref et encourageant en français.
      ''';

      try {
        final result = await service.generateText(prompt: prompt);
        
        debugPrint('=== RÉSULTAT GÉNÉRATION MISTRAL ===');
        debugPrint('Prompt: $prompt');
        debugPrint('Réponse: $result');
        debugPrint('=== FIN RÉSULTAT ===');
        
        // Vérifier que le résultat n'est pas vide
        expect(result, isNotEmpty);
        
        // Vérifier que c'est bien du français (contient des mots français typiques)
        final textLower = result.toLowerCase();
        final frenchWords = ['le', 'la', 'les', 'de', 'du', 'des', 'et', 'ou', 'bien', 'très', 'bon', 'bonne'];
        final containsFrench = frenchWords.any((word) => textLower.contains(word));
        
        expect(containsFrench, isTrue, reason: 'Le texte généré devrait contenir des mots français');
        
        // Vérifier une longueur raisonnable
        expect(result.length, greaterThan(20), reason: 'Le feedback devrait être substantiel');
        
      } catch (e) {
        debugPrint('Erreur lors de la génération: $e');
        // Si l'API échoue, vérifier que c'est bien un fallback
        fail('La génération de texte a échoué: $e');
      }
    });

    test('devrait analyser le contenu avec l\'API Mistral', () async {
      final service = MistralApiService();
      
      const prompt = '''
      Analysez cette performance orale et retournez un JSON avec:
      {
        "content_score": 0.8,
        "feedback": "Votre présentation était claire et bien structurée",
        "strengths": ["Clarté", "Structure"],
        "improvements": ["Gestuelle", "Contact visuel"]
      }
      ''';

      try {
        final result = await service.analyzeContent(prompt: prompt);
        
        debugPrint('=== RÉSULTAT ANALYSE MISTRAL ===');
        debugPrint('Prompt: $prompt');
        debugPrint('Réponse: $result');
        debugPrint('=== FIN RÉSULTAT ===');
        
        // Vérifier la structure du résultat
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('content_score'), isTrue);
        expect(result.containsKey('feedback'), isTrue);
        expect(result.containsKey('strengths'), isTrue);
        expect(result.containsKey('improvements'), isTrue);
        
        // Vérifier les types
        expect(result['content_score'], isA<num>());
        expect(result['feedback'], isA<String>());
        expect(result['strengths'], isA<List>());
        expect(result['improvements'], isA<List>());
        
        // Vérifier le contenu
        expect(result['feedback'], isNotEmpty);
        expect((result['strengths'] as List).isNotEmpty, isTrue);
        expect((result['improvements'] as List).isNotEmpty, isTrue);
        
      } catch (e) {
        debugPrint('Erreur lors de l\'analyse: $e');
        fail('L\'analyse de contenu a échoué: $e');
      }
    });

    test('devrait gérer le cas où Mistral est désactivé', () async {
      // Temporairement désactiver Mistral pour tester le fallback
      final originalValue = dotenv.env['MISTRAL_ENABLED'];
      dotenv.env['MISTRAL_ENABLED'] = 'false';
      
      final service = MistralApiService();
      
      final result = await service.generateText(
        prompt: 'Test avec Mistral désactivé'
      );
      
      // Vérifier que c'est bien un feedback simulé
      expect(result.contains('simulé'), isTrue);
      expect(result, isNotEmpty);
      
      // Restaurer la valeur originale
      if (originalValue != null) {
        dotenv.env['MISTRAL_ENABLED'] = originalValue;
      }
    });
  });
}