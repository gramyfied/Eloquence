import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../lib/features/confidence_boost/data/services/mistral_api_service.dart';

void main() {
  group('Configuration Backend Simplifiée Tests', () {
    setUpAll(() async {
      // Charger le fichier .env
      await dotenv.load(fileName: '.env');
      print('📋 Variables chargées depuis .env');
    });

    test('✅ Configuration identique au backend Python', () {
      // Vérifier que toutes les variables nécessaires sont présentes
      final mistralBaseUrl = dotenv.env['MISTRAL_BASE_URL'];
      final mistralApiKey = dotenv.env['MISTRAL_API_KEY'];
      final mistralModel = dotenv.env['MISTRAL_MODEL'];

      print('🔧 MISTRAL_BASE_URL: $mistralBaseUrl');
      print('🔑 MISTRAL_API_KEY: ${mistralApiKey?.substring(0, 8)}...');
      print('🤖 MISTRAL_MODEL: $mistralModel');

      expect(mistralBaseUrl, isNotNull);
      expect(mistralBaseUrl, contains('scaleway.ai'));
      expect(mistralBaseUrl, contains('chat/completions'));
      expect(mistralApiKey, isNotNull);
      expect(mistralApiKey, isNotEmpty);
      expect(mistralModel, equals('mistral-nemo-instruct-2407'));
    });

    test('🌐 Test API Scaleway avec configuration simplifiée', () async {
      final mistralService = MistralApiService();
      
      try {
        print('🚀 Test génération de texte avec configuration backend...');
        final result = await mistralService.generateText(
          prompt: 'Hello, test simple configuration',
          maxTokens: 50,
        );
        
        print('✅ Résultat: $result');
        expect(result, isNotEmpty);
        expect(result, isNot(contains('Feedback simulé')));
        
      } catch (e) {
        print('❌ Erreur lors du test: $e');
        fail('Test échoué avec erreur: $e');
      }
    });

    test('🔍 Test direct HTTP avec même configuration que backend', () async {
      final mistralBaseUrl = dotenv.env['MISTRAL_BASE_URL'];
      final mistralApiKey = dotenv.env['MISTRAL_API_KEY'];
      final mistralModel = dotenv.env['MISTRAL_MODEL'];

      final headers = {
        'Authorization': 'Bearer $mistralApiKey',
        'Content-Type': 'application/json',
      };

      final data = {
        'model': mistralModel,
        'messages': [
          {
            'role': 'user',
            'content': 'Hello test direct',
          }
        ],
        'max_tokens': 30,
      };

      print('🌐 Appel direct API: $mistralBaseUrl');
      print('📦 Headers: Authorization Bearer ${mistralApiKey?.substring(0, 8)}...');
      
      try {
        final response = await http.post(
          Uri.parse(mistralBaseUrl!),
          headers: headers,
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 30));

        print('📊 Status Code: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          expect(responseData['choices'], isNotNull);
          print('✅ Succès! API Scaleway fonctionne avec configuration simplifiée');
        } else {
          print('❌ Erreur ${response.statusCode}: ${response.body}');
          fail('API call failed with status ${response.statusCode}');
        }
        
      } catch (e) {
        print('❌ Exception lors de l\'appel API: $e');
        fail('Test échoué avec exception: $e');
      }
    });
  });
}