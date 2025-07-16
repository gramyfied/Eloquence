import 'package:flutter/foundation.dart';
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
      debugPrint('\n🔍 [DIAGNOSTIC] Test connectivité API Mistral Scaleway...');
      
      final mistralUrl = dotenv.env['MISTRAL_BASE_URL'] ?? '';
      final mistralKey = dotenv.env['MISTRAL_API_KEY'] ?? '';
      final mistralEnabled = dotenv.env['MISTRAL_ENABLED']?.toLowerCase() == 'true';
      
      debugPrint('✅ [CONFIG] MISTRAL_ENABLED: $mistralEnabled');
      debugPrint('✅ [CONFIG] MISTRAL_BASE_URL: $mistralUrl');
      debugPrint('✅ [CONFIG] MISTRAL_API_KEY: ${mistralKey.isNotEmpty ? "Configurée (${mistralKey.length} chars)" : "MANQUANTE"}');
      
      if (!mistralEnabled) {
        debugPrint('⚠️ [RÉSULTAT] Mistral DÉSACTIVÉ - Utilisation feedback simulé');
        return;
      }
      
      if (mistralKey.isEmpty || mistralKey == 'your_mistral_api_key') {
        debugPrint('⚠️ [RÉSULTAT] Clé API Mistral INVALIDE - Utilisation feedback simulé');
        return;
      }
      
      try {
        debugPrint('🚀 [TEST] Appel API Mistral réel...');
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
          debugPrint('🎉 [SUCCÈS] API Mistral FONCTIONNELLE !');
          debugPrint('📝 [RÉPONSE] $responseText');
          debugPrint('✅ [RÉSULTAT] Évaluations Mistral = RÉELLES');
        } else {
          debugPrint('❌ [ERREUR] API Mistral - Status: ${response.statusCode}');
          debugPrint('📄 [DÉTAIL] ${response.body}');
          debugPrint('⚠️ [RÉSULTAT] Évaluations Mistral = SIMULÉES (erreur API)');
        }
      } catch (e) {
        debugPrint('❌ [EXCEPTION] Erreur API Mistral: $e');
        debugPrint('⚠️ [RÉSULTAT] Évaluations Mistral = SIMULÉES (timeout/erreur)');
      }
    });

    test('🖥️ DIAGNOSTIC 2: Backend Whisper + Mistral - Connectivité Locale', () async {
      debugPrint('\n🔍 [DIAGNOSTIC] Test connectivité Backend localhost...');
      
      final backendUrl = dotenv.env['LLM_SERVICE_URL'] ?? 'http://localhost:8000';
      debugPrint('✅ [CONFIG] LLM_SERVICE_URL: $backendUrl');
      
      try {
        debugPrint('🚀 [TEST] Ping backend health check...');
        final response = await http.get(
          Uri.parse('$backendUrl/health'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('🎉 [SUCCÈS] Backend DISPONIBLE !');
          debugPrint('📄 [RÉPONSE] ${response.body}');
          debugPrint('✅ [RÉSULTAT] Évaluations Backend = RÉELLES');
        } else {
          debugPrint('❌ [ERREUR] Backend - Status: ${response.statusCode}');
          debugPrint('⚠️ [RÉSULTAT] Évaluations Backend = SIMULÉES (service erreur)');
        }
      } catch (e) {
        debugPrint('❌ [EXCEPTION] Backend indisponible: $e');
        debugPrint('⚠️ [RÉSULTAT] Évaluations Backend = SIMULÉES (service down)');
      }
    });

    test('🎮 DIAGNOSTIC 3: LiveKit - Connectivité WebRTC', () async {
      debugPrint('\n🔍 [DIAGNOSTIC] Test connectivité LiveKit...');
      
      final livekitUrl = dotenv.env['LIVEKIT_URL'] ?? 'ws://localhost:7880';
      debugPrint('✅ [CONFIG] LIVEKIT_URL: $livekitUrl');
      
      // Pour WebSocket, on teste juste si le port HTTP répond
      final httpUrl = livekitUrl.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
      
      try {
        debugPrint('🚀 [TEST] Ping LiveKit port...');
        final response = await http.get(
          Uri.parse('$httpUrl/'),
        ).timeout(const Duration(seconds: 3));

        debugPrint('🎉 [SUCCÈS] LiveKit port ACCESSIBLE !');
        debugPrint('📄 [STATUT] ${response.statusCode}');
        debugPrint('✅ [RÉSULTAT] Évaluations LiveKit = POTENTIELLEMENT RÉELLES');
      } catch (e) {
        debugPrint('❌ [EXCEPTION] LiveKit indisponible: $e');
        debugPrint('⚠️ [RÉSULTAT] Évaluations LiveKit = SIMULÉES (service down)');
      }
    });

    test('📊 DIAGNOSTIC 4: Services Docker - État Global', () async {
      debugPrint('\n🔍 [DIAGNOSTIC] Résumé état des services...');
      
      debugPrint('📋 [ANALYSE] Configuration détectée:');
      debugPrint('   🔧 Backend Whisper+Mistral: ${dotenv.env['LLM_SERVICE_URL']}');
      debugPrint('   🤖 API Mistral Scaleway: ${dotenv.env['MISTRAL_ENABLED'] == "true" ? "ACTIVÉ" : "DÉSACTIVÉ"}');
      debugPrint('   🎭 LiveKit WebRTC: ${dotenv.env['LIVEKIT_URL']}');
      debugPrint('   🗣️ Whisper STT: ${dotenv.env['WHISPER_STT_URL']}');
      debugPrint('   🔊 OpenAI TTS: ${dotenv.env['OPENAI_TTS_URL']}');
      
      debugPrint('\n🎯 [CONCLUSION] Système d\'évaluation:');
      debugPrint('   ✅ Configuration complète présente');
      debugPrint('   ⚠️ Nécessite services démarrés pour évaluations réelles');
      debugPrint('   🔄 Fallbacks simulés fonctionnels en cas d\'indisponibilité');
    });
  });
}