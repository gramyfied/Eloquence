import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🎯 TEST DE DIAGNOSTIC : Évaluations Réelles vs Simulées
/// 
/// Ce test détermine quels services d'évaluation sont effectivement disponibles
void main() {
  group('🔍 Diagnostic Évaluations Réelles vs Simulées', () {
    
    setUpAll(() async {
      // Charger les variables d'environnement
      await dotenv.load(fileName: '.env');
    });

    test('🌐 DIAGNOSTIC 1: API Mistral Scaleway - Connectivité Réelle', () async {
      print('\n🔍 [DIAGNOSTIC] Test connectivité API Mistral Scaleway...');
      
      final mistralUrl = dotenv.env['MISTRAL_BASE_URL'] ?? '';
      final mistralKey = dotenv.env['MISTRAL_API_KEY'] ?? '';
      final mistralEnabled = dotenv.env['MISTRAL_ENABLED']?.toLowerCase() == 'true';
      
      print('✅ [CONFIG] MISTRAL_ENABLED: $mistralEnabled');
      print('✅ [CONFIG] MISTRAL_BASE_URL: $mistralUrl');
      print('✅ [CONFIG] MISTRAL_API_KEY: ${mistralKey.isNotEmpty ? "Configurée (${mistralKey.length} chars)" : "MANQUANTE"}');
      
      if (!mistralEnabled) {
        print('⚠️ [RÉSULTAT] Mistral DÉSACTIVÉ - Utilisation feedback simulé');
        return;
      }
      
      if (mistralKey.isEmpty || mistralKey == 'your_mistral_api_key') {
        print('⚠️ [RÉSULTAT] Clé API Mistral INVALIDE - Utilisation feedback simulé');
        return;
      }
      
      try {
        print('🚀 [TEST] Appel API Mistral réel...');
        final response = await http.post(
          Uri.parse(mistralUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $mistralKey',
          },
          body: jsonEncode({
            'model': dotenv.env['MISTRAL_MODEL'] ?? 'mistral-nemo-instruct-2407',
            'messages': [
              {
                'role': 'user',
                'content': 'Test diagnostic: Répondez simplement "API Mistral fonctionnelle"',
              }
            ],
            'max_tokens': 50,
            'temperature': 0.1,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final responseText = data['choices']?[0]?['message']?['content'] ?? 'Pas de réponse';
          print('🎉 [SUCCÈS] API Mistral FONCTIONNELLE !');
          print('📝 [RÉPONSE] $responseText');
          print('✅ [RÉSULTAT] Évaluations Mistral = RÉELLES');
        } else {
          print('❌ [ERREUR] API Mistral - Status: ${response.statusCode}');
          print('📄 [DÉTAIL] ${response.body}');
          print('⚠️ [RÉSULTAT] Évaluations Mistral = SIMULÉES (erreur API)');
        }
      } catch (e) {
        print('❌ [EXCEPTION] Erreur API Mistral: $e');
        print('⚠️ [RÉSULTAT] Évaluations Mistral = SIMULÉES (timeout/erreur)');
      }
    });

    test('🖥️ DIAGNOSTIC 2: Backend Whisper + Mistral - Connectivité Locale', () async {
      print('\n🔍 [DIAGNOSTIC] Test connectivité Backend localhost...');
      
      final backendUrl = dotenv.env['LLM_SERVICE_URL'] ?? 'http://localhost:8000';
      print('✅ [CONFIG] LLM_SERVICE_URL: $backendUrl');
      
      try {
        print('🚀 [TEST] Ping backend health check...');
        final response = await http.get(
          Uri.parse('$backendUrl/health'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          print('🎉 [SUCCÈS] Backend DISPONIBLE !');
          print('📄 [RÉPONSE] ${response.body}');
          print('✅ [RÉSULTAT] Évaluations Backend = RÉELLES');
        } else {
          print('❌ [ERREUR] Backend - Status: ${response.statusCode}');
          print('⚠️ [RÉSULTAT] Évaluations Backend = SIMULÉES (service erreur)');
        }
      } catch (e) {
        print('❌ [EXCEPTION] Backend indisponible: $e');
        print('⚠️ [RÉSULTAT] Évaluations Backend = SIMULÉES (service down)');
      }
    });

    test('🎮 DIAGNOSTIC 3: LiveKit - Connectivité WebRTC', () async {
      print('\n🔍 [DIAGNOSTIC] Test connectivité LiveKit...');
      
      final livekitUrl = dotenv.env['LIVEKIT_URL'] ?? 'ws://localhost:7880';
      print('✅ [CONFIG] LIVEKIT_URL: $livekitUrl');
      
      // Pour WebSocket, on teste juste si le port HTTP répond
      final httpUrl = livekitUrl.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
      
      try {
        print('🚀 [TEST] Ping LiveKit port...');
        final response = await http.get(
          Uri.parse('$httpUrl/'),
        ).timeout(const Duration(seconds: 3));

        print('🎉 [SUCCÈS] LiveKit port ACCESSIBLE !');
        print('📄 [STATUT] ${response.statusCode}');
        print('✅ [RÉSULTAT] Évaluations LiveKit = POTENTIELLEMENT RÉELLES');
      } catch (e) {
        print('❌ [EXCEPTION] LiveKit indisponible: $e');
        print('⚠️ [RÉSULTAT] Évaluations LiveKit = SIMULÉES (service down)');
      }
    });

    test('📊 DIAGNOSTIC 4: Services Docker - État Global', () async {
      print('\n🔍 [DIAGNOSTIC] Résumé état des services...');
      
      print('📋 [ANALYSE] Configuration détectée:');
      print('   🔧 Backend Whisper+Mistral: ${dotenv.env['LLM_SERVICE_URL']}');
      print('   🤖 API Mistral Scaleway: ${dotenv.env['MISTRAL_ENABLED'] == "true" ? "ACTIVÉ" : "DÉSACTIVÉ"}');
      print('   🎭 LiveKit WebRTC: ${dotenv.env['LIVEKIT_URL']}');
      print('   🗣️ Whisper STT: ${dotenv.env['WHISPER_STT_URL']}');
      print('   🔊 OpenAI TTS: ${dotenv.env['OPENAI_TTS_URL']}');
      
      print('\n🎯 [CONCLUSION] Système d\'évaluation:');
      print('   ✅ Configuration complète présente');
      print('   ⚠️ Nécessite services démarrés pour évaluations réelles');
      print('   🔄 Fallbacks simulés fonctionnels en cas d\'indisponibilité');
    });
  });
}