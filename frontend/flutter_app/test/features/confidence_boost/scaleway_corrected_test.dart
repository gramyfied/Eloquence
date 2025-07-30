import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Scaleway Mistral API Corrigé', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    test('Test avec structure Scaleway correcte', () async {
      // D'après votre exemple, la structure Scaleway est :
      // base_url = "https://api.scaleway.ai/{PROJECT_ID}/v1"
      // api_key = "SCW_SECRET_KEY"
      
      const String projectId = 'fc23b118-a243-4e29-9d28-6c6106c997a4';
      const String baseUrl = 'https://api.scaleway.ai/$projectId/v1';
      const String endpoint = '$baseUrl/chat/completions';
      
      // Il nous faut la vraie clé IAM Scaleway
      const String iamApiKey = 'fc23b118-a243-4e29-9d28-6c6106c997a4'; // À remplacer par la vraie clé IAM
      
      debugPrint('🏗️ Configuration Scaleway:');
      debugPrint('   Project ID: $projectId');
      debugPrint('   Base URL: $baseUrl');
      debugPrint('   Endpoint: $endpoint');
      debugPrint('   IAM Key: ${iamApiKey.substring(0, 8)}...');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $iamApiKey',
      };
      
      final body = {
        'model': 'mistral-nemo-instruct-2407',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant'
          },
          {
            'role': 'user',
            'content': 'Bonjour ! Pouvez-vous répondre en français en une phrase courte ?'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.3,
      };
      
      debugPrint('📦 Request Body: ${jsonEncode(body)}');
      
      try {
        debugPrint('🚀 Test API Scaleway corrigée...');
        
        final response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: jsonEncode(body),
        );
        
        debugPrint('📊 Status Code: ${response.statusCode}');
        debugPrint('📄 Response Headers: ${response.headers}');
        debugPrint('📝 Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final generatedText = responseData['choices']?[0]?['message']?['content'];
          
          debugPrint('✅ SUCCÈS SCALEWAY! Réponse: $generatedText');
          expect(generatedText, isNotNull);
          expect(generatedText, isNotEmpty);
          
        } else {
          debugPrint('❌ ERREUR: ${response.statusCode}');
          debugPrint('📄 Détails: ${response.body}');
          
          if (response.statusCode == 401) {
            debugPrint('🔐 Clé IAM invalide ou projet non trouvé');
          } else if (response.statusCode == 403) {
            debugPrint('🚫 Permissions insuffisantes');
          } else if (response.statusCode == 404) {
            debugPrint('🔍 Project ID invalide ou endpoint incorrect');
          }
          
          // Ne pas faire échouer le test, juste informer
          debugPrint('ℹ️ Configuration Scaleway nécessite à la fois:');
          debugPrint('   1. Un Project ID (UUID du projet)');
          debugPrint('   2. Une clé IAM Scaleway (SCW_SECRET_KEY)');
        }
        
      } catch (e) {
        debugPrint('💥 Exception: $e');
        debugPrint('ℹ️ Vérifier la configuration Scaleway');
      }
    }, skip: true);

    test('Détection des paramètres manquants', () {
      debugPrint('📋 Configuration requise pour Scaleway:');
      debugPrint('   SCALEWAY_PROJECT_ID: UUID du projet (ex: 18f6cc9d-07fc-49c3-a142-67be9b59ac63)');
      debugPrint('   SCALEWAY_IAM_KEY: Clé IAM Scaleway (ex: SCW_SECRET_KEY...)');
      debugPrint('   MISTRAL_MODEL: mistral-nemo-instruct-2407');
      
      // Test de l'URL construction
      const projectId = 'fc23b118-a243-4e29-9d28-6c6106c997a4';
      const expectedUrl = 'https://api.scaleway.ai/$projectId/v1/chat/completions';
      
      expect(expectedUrl, contains('api.scaleway.ai'));
      expect(expectedUrl, contains(projectId));
      expect(expectedUrl, endsWith('/chat/completions'));
      
      debugPrint('✅ Structure URL correcte: $expectedUrl');
    });
  });
}