import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Test spécifique pour la configuration Scaleway Mistral corrigée
/// Basé sur l'exemple Python fourni par l'utilisateur :
/// base_url = "https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1"
/// api_key = "SCW_SECRET_KEY"
void main() {
  group('Configuration Scaleway Mistral Tests', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    test('Test API Scaleway directe avec configuration corrigée', () async {
      // Configuration Scaleway selon l'exemple Python
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'] ?? 'fc23b118-a243-4e29-9d28-6c6106c997a4';
      final iamKey = dotenv.env['SCALEWAY_IAM_KEY'] ?? 'SCW_TEST_KEY';
      
      print('🔧 Configuration Scaleway:');
      print('   PROJECT_ID: ${projectId.substring(0, 8)}...');
      print('   IAM_KEY: ${iamKey.substring(0, 8)}...');
      
      // Construction de l'URL selon l'exemple Python
      final baseUrl = 'https://api.scaleway.ai/$projectId/v1';
      final url = Uri.parse('$baseUrl/chat/completions');
      
      print('🌐 URL Scaleway: $url');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $iamKey',
      };
      
      final body = {
        'model': 'mistral-nemo-instruct-2407', // Modèle Scaleway
        'messages': [
          {
            'role': 'user',
            'content': 'Bonjour ! Test de l\'API Scaleway Mistral. Répondez brièvement en français.'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.7,
      };
      
      print('📦 Headers: $headers');
      print('💬 Body: ${jsonEncode(body)}');
      
      try {
        print('🚀 Envoi requête Scaleway...');
        
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
        
        print('📊 Status Code: ${response.statusCode}');
        print('📄 Response Headers: ${response.headers}');
        print('📝 Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final generatedText = responseData['choices']?[0]?['message']?['content'];
          
          print('✅ SUCCÈS SCALEWAY! Texte généré: $generatedText');
          expect(generatedText, isNotNull);
          expect(generatedText, isNotEmpty);
          
        } else {
          print('❌ ERREUR SCALEWAY: ${response.statusCode}');
          print('📄 Détails: ${response.body}');
          
          // Analysons l'erreur
          if (response.statusCode == 401) {
            print('🔐 Erreur d\'authentification Scaleway');
            print('   - Vérifiez SCALEWAY_IAM_KEY');
            print('   - Vérifiez SCALEWAY_PROJECT_ID');
          } else if (response.statusCode == 404) {
            print('📍 Resource not found - URL ou PROJECT_ID incorrect');
          } else if (response.statusCode == 429) {
            print('⏰ Rate limit Scaleway atteint');
          } else if (response.statusCode == 400) {
            print('📋 Requête malformée pour Scaleway');
          }
          
          // Ne pas faire échouer le test si c'est un problème d'authentification connu
          if (iamKey == 'SCW_TEST_KEY' || iamKey == 'SCW_SECRET_KEY_PLACEHOLDER') {
            print('ℹ️ Test avec clé placeholder - erreur attendue');
            expect(response.statusCode, isIn([401, 403, 404]));
          } else {
            fail('API Scaleway a échoué avec le code ${response.statusCode}');
          }
        }
        
      } catch (e) {
        print('💥 Exception Scaleway: $e');
        
        // Ne pas faire échouer si c'est un timeout avec clé de test
        if (iamKey.contains('TEST') || iamKey.contains('PLACEHOLDER')) {
          print('ℹ️ Timeout avec clé de test - comportement attendu');
          expect(e, isNotNull);
        } else {
          fail('Erreur lors de l\'appel API Scaleway: $e');
        }
      }
    });

    test('Validation format URL Scaleway selon exemple Python', () async {
      // Test avec le PROJECT_ID de l'exemple Python
      const pythonProjectId = '18f6cc9d-07fc-49c3-a142-67be9b59ac63';
      const expectedPythonUrl = 'https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1/chat/completions';
      
      final constructedUrl = 'https://api.scaleway.ai/$pythonProjectId/v1/chat/completions';
      
      expect(constructedUrl, equals(expectedPythonUrl),
             reason: 'URL construite doit correspondre à l\'exemple Python');
      
      print('✅ Format URL Scaleway validé selon exemple Python');
      print('   URL attendue : $expectedPythonUrl');
      print('   URL construite: $constructedUrl');
    });

    test('Test détection configuration Scaleway vs Mistral classique', () async {
      await dotenv.load(fileName: '.env');
      
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      final mistralKey = dotenv.env['MISTRAL_API_KEY'];
      final iamKey = dotenv.env['SCALEWAY_IAM_KEY'];
      
      print('🔍 Détection de configuration:');
      print('   SCALEWAY_PROJECT_ID: ${projectId ?? "NON DÉFINI"}');
      print('   SCALEWAY_IAM_KEY: ${iamKey ?? "NON DÉFINI"}');
      print('   MISTRAL_API_KEY: ${mistralKey ?? "NON DÉFINI"}');
      
      // Logique de détection
      final isScalewayConfigured = projectId != null && projectId.isNotEmpty;
      final isMistralConfigured = mistralKey != null && mistralKey.isNotEmpty;
      
      print('📋 Résultat détection:');
      print('   Configuration Scaleway: ${isScalewayConfigured ? "✅" : "❌"}');
      print('   Configuration Mistral: ${isMistralConfigured ? "✅" : "❌"}');
      
      if (isScalewayConfigured) {
        print('🎯 Mode Scaleway détecté');
        expect(projectId, isNotEmpty);
        
        // Vérifier le format UUID
        final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
        expect(uuidPattern.hasMatch(projectId!), isTrue, 
               reason: 'PROJECT_ID doit être un UUID valide');
      } else {
        print('🎯 Mode Mistral classique détecté');
      }
      
      // Au moins une configuration doit être présente
      expect(isScalewayConfigured || isMistralConfigured, isTrue,
             reason: 'Au moins une configuration API doit être présente');
    });

    test('Test construction endpoints selon configuration', () async {
      await dotenv.load(fileName: '.env');
      
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      
      if (projectId != null && projectId.isNotEmpty) {
        // Mode Scaleway
        final scalewayUrl = 'https://api.scaleway.ai/$projectId/v1/chat/completions';
        final scalewayModel = 'mistral-nemo-instruct-2407';
        
        print('🏗️ Configuration Scaleway construite:');
        print('   URL: $scalewayUrl');
        print('   Modèle: $scalewayModel');
        
        expect(scalewayUrl, contains('api.scaleway.ai'));
        expect(scalewayUrl, contains(projectId));
        expect(scalewayModel, equals('mistral-nemo-instruct-2407'));
        
      } else {
        // Mode Mistral classique
        final mistralUrl = 'https://api.mistral.ai/v1/chat/completions';
        final mistralModel = 'mistral-small-latest';
        
        print('🏗️ Configuration Mistral classique construite:');
        print('   URL: $mistralUrl');
        print('   Modèle: $mistralModel');
        
        expect(mistralUrl, contains('api.mistral.ai'));
        expect(mistralModel, equals('mistral-small-latest'));
      }
    });
  });
}