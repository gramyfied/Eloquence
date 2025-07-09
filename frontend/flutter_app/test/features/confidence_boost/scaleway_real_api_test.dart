import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  group('🔑 Test API Scaleway Réelle', () {
    setUpAll(() async {
      // Charger les variables d'environnement
      await dotenv.load(fileName: '.env');
    });

    test('✅ Valider configuration Scaleway avec vraies clés', () async {
      print('\n🔧 TEST CONFIGURATION SCALEWAY RÉELLE');
      
      // Vérifier configuration
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      final iamKey = dotenv.env['SCALEWAY_IAM_KEY'];
      
      print('📋 PROJECT_ID: $projectId');
      print('🔑 IAM_KEY: ${iamKey?.substring(0, 8)}...');
      
      expect(projectId, isNotNull);
      expect(projectId, isNotEmpty);
      expect(iamKey, isNotNull);
      expect(iamKey, isNotEmpty);
      expect(iamKey, isNot('SCW_SECRET_KEY_PLACEHOLDER'));
      
      // Construire URL selon structure Scaleway
      final baseUrl = 'https://api.scaleway.ai/$projectId/v1';
      final endpoint = '$baseUrl/chat/completions';
      
      print('🌐 URL Endpoint: $endpoint');
      
      expect(endpoint, equals('https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1/chat/completions'));
    });

    test('🚀 Test API Scaleway Mistral réelle', () async {
      print('\n🚀 TEST API SCALEWAY MISTRAL RÉELLE');
      
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      final iamKey = dotenv.env['SCALEWAY_IAM_KEY'];
      
      final endpoint = 'https://api.scaleway.ai/$projectId/v1/chat/completions';
      
      // Préparer requête Scaleway
      final requestBody = {
        'model': 'mistral-nemo-instruct-2407',
        'messages': [
          {
            'role': 'user',
            'content': 'Dis bonjour en français dans 5 mots maximum.'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.7
      };
      
      print('📤 Envoi requête à: $endpoint');
      print('🤖 Modèle: mistral-nemo-instruct-2407');
      print('💬 Message: ${requestBody['messages']}');
      
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $iamKey',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 30));
        
        print('📬 Status Code: ${response.statusCode}');
        print('📄 Response Headers: ${response.headers}');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('✅ SUCCÈS SCALEWAY API!');
          print('📝 Response: $responseData');
          
          // Vérifier structure réponse
          expect(responseData, contains('choices'));
          expect(responseData['choices'], isA<List>());
          expect(responseData['choices'][0], contains('message'));
          expect(responseData['choices'][0]['message'], contains('content'));
          
          final content = responseData['choices'][0]['message']['content'];
          print('🗨️ Contenu généré: "$content"');
          
          expect(content, isNotNull);
          expect(content, isNotEmpty);
          
        } else {
          print('❌ ERREUR SCALEWAY: ${response.statusCode}');
          print('📄 Response Body: ${response.body}');
          
          // Analyser l'erreur pour diagnostic
          if (response.statusCode == 401) {
            print('🔑 Erreur d\'authentification - Vérifier clé IAM');
          } else if (response.statusCode == 403) {
            print('🚫 Erreur de permissions - Vérifier accès Scaleway');
          } else if (response.statusCode == 404) {
            print('🔍 Endpoint non trouvé - Vérifier PROJECT_ID');
          }
          
          fail('API Scaleway a retourné ${response.statusCode}: ${response.body}');
        }
        
      } catch (e) {
        print('💥 EXCEPTION lors du test API: $e');
        if (e is SocketException) {
          print('🌐 Problème de connexion réseau');
        }
        rethrow;
      }
    });

    test('🔄 Test fallback vers Mistral classique', () async {
      print('\n🔄 TEST FALLBACK MISTRAL CLASSIQUE');
      
      // Temporairement vider SCALEWAY_PROJECT_ID pour tester fallback
      final originalProjectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      dotenv.env['SCALEWAY_PROJECT_ID'] = '';
      
      // Vérifier que détection bascule vers Mistral
      final projectId = dotenv.env['SCALEWAY_PROJECT_ID'];
      final isScaleway = projectId != null && projectId.isNotEmpty;
      
      print('📋 PROJECT_ID (temporaire): "$projectId"');
      print('🔍 Détection Scaleway: $isScaleway');
      
      expect(isScaleway, isFalse);
      
      final baseUrl = isScaleway 
          ? 'https://api.scaleway.ai/$projectId/v1'
          : 'https://api.mistral.ai/v1';
          
      print('🌐 URL de fallback: $baseUrl');
      expect(baseUrl, equals('https://api.mistral.ai/v1'));
      
      // Restaurer configuration originale
      dotenv.env['SCALEWAY_PROJECT_ID'] = originalProjectId ?? '';
      
      print('✅ Configuration restaurée');
    });
  });
}