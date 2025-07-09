import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Mistral API Real Test', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    test('Test API Mistral directe avec vraie clé', () async {
      // Force l'utilisation de l'API réelle
      const String apiKey = 'fc23b118-a243-4e29-9d28-6c6106c997a4';
      const String baseUrl = 'https://api.mistral.ai/v1';
      
      print('🔑 Clé API utilisée: ${apiKey.substring(0, 8)}...');
      
      final url = Uri.parse('$baseUrl/chat/completions');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      
      final body = {
        'model': 'mistral-small-latest',
        'messages': [
          {
            'role': 'user',
            'content': 'Bonjour ! Pouvez-vous répondre en français ? Juste un court message de test.'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.7,
      };
      
      print('🌐 URL: $url');
      print('📦 Headers: $headers');
      print('💬 Body: ${jsonEncode(body)}');
      
      try {
        print('🚀 Envoi de la requête...');
        
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        
        print('📊 Status Code: ${response.statusCode}');
        print('📄 Response Headers: ${response.headers}');
        print('📝 Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final generatedText = responseData['choices']?[0]?['message']?['content'];
          
          print('✅ SUCCÈS! Texte généré: $generatedText');
          expect(generatedText, isNotNull);
          expect(generatedText, isNotEmpty);
          
        } else {
          print('❌ ERREUR: ${response.statusCode}');
          print('📄 Détails: ${response.body}');
          
          // Analysons l'erreur
          if (response.statusCode == 401) {
            print('🔐 Erreur d\'authentification - clé API invalide ou expirée');
          } else if (response.statusCode == 429) {
            print('⏰ Rate limit atteint');
          } else if (response.statusCode == 400) {
            print('📋 Requête malformée');
          }
          
          fail('API Mistral a échoué avec le code ${response.statusCode}');
        }
        
      } catch (e) {
        print('💥 Exception: $e');
        fail('Erreur lors de l\'appel API: $e');
      }
    });

    test('Test avec modèle différent', () async {
      const String apiKey = 'fc23b118-a243-4e29-9d28-6c6106c997a4';
      const String baseUrl = 'https://api.mistral.ai/v1';
      
      final url = Uri.parse('$baseUrl/chat/completions');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      
      // Essayons avec un modèle différent
      final body = {
        'model': 'mistral-tiny',
        'messages': [
          {
            'role': 'user',
            'content': 'Test'
          }
        ],
        'max_tokens': 10,
      };
      
      print('🔄 Test avec modèle mistral-tiny...');
      
      try {
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        
        print('📊 Status Code (tiny): ${response.statusCode}');
        print('📝 Response Body (tiny): ${response.body}');
        
        if (response.statusCode != 200) {
          print('ℹ️ Modèle mistral-tiny non disponible ou erreur API');
        }
        
      } catch (e) {
        print('ℹ️ Test modèle alternatif échoué: $e');
      }
    });
  });
}