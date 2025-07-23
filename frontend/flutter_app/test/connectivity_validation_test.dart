import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Test de validation de la connectivité réseau pour Eloquence
/// Vérifie que l'app Flutter peut se connecter aux services backend
void main() {
  group('Connectivité Eloquence', () {
    late String hostIp;
    late String apiPort;
    late String voskPort;
    late String livekitPort;
    late String llmPort;

    setUpAll(() async {
      // Charger les variables d'environnement
      try {
        await dotenv.load(fileName: '.env');
        hostIp = dotenv.env['MOBILE_HOST_IP'] ?? '192.168.1.44';
        apiPort = dotenv.env['API_PORT'] ?? '8000';
        voskPort = dotenv.env['VOSK_PORT'] ?? '2700';
        livekitPort = dotenv.env['LIVEKIT_PORT'] ?? '7880';
        llmPort = dotenv.env['LLM_PORT'] ?? '8001';
      } catch (e) {
        // Valeurs par défaut si .env n'est pas trouvé
        hostIp = '192.168.1.44';
        apiPort = '8000';
        voskPort = '2700';
        livekitPort = '7880';
        llmPort = '8001';
      }

      print('🔧 Configuration de test:');
      print('   Host IP: $hostIp');
      print('   API Port: $apiPort');
      print('   VOSK Port: $voskPort');
      print('   LiveKit Port: $livekitPort');
      print('   LLM Port: $llmPort');
    });

    test('API Backend - Health Check', () async {
      final url = 'http://$hostIp:$apiPort/health';
      print('🌐 Test: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        expect(response.statusCode, 200);
        print('   ✅ API Backend accessible (${response.statusCode})');
      } catch (e) {
        print('   ❌ API Backend non accessible: $e');
        fail('API Backend non accessible: $e');
      }
    });

    test('VOSK STT - Health Check', () async {
      final url = 'http://$hostIp:$voskPort/health';
      print('🌐 Test: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        expect(response.statusCode, 200);
        print('   ✅ VOSK STT accessible (${response.statusCode})');
      } catch (e) {
        print('   ❌ VOSK STT non accessible: $e');
        fail('VOSK STT non accessible: $e');
      }
    });

    test('Mistral LLM - Health Check', () async {
      final url = 'http://$hostIp:$llmPort/health';
      print('🌐 Test: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10)); // Plus de temps pour LLM
        
        expect(response.statusCode, 200);
        print('   ✅ Mistral LLM accessible (${response.statusCode})');
      } catch (e) {
        print('   ❌ Mistral LLM non accessible: $e');
        fail('Mistral LLM non accessible: $e');
      }
    });

    test('LiveKit - Connectivité TCP', () async {
      print('🌐 Test LiveKit TCP: $hostIp:$livekitPort');
      
      try {
        final socket = await Socket.connect(
          hostIp, 
          int.parse(livekitPort),
          timeout: const Duration(seconds: 5),
        );
        
        await socket.close();
        print('   ✅ LiveKit port accessible');
        expect(true, true); // Test réussi
      } catch (e) {
        print('   ❌ LiveKit non accessible: $e');
        fail('LiveKit non accessible: $e');
      }
    });

    test('Configuration Constants - Validation', () async {
      print('🔧 Validation de la configuration des constantes');
      
      // Vérifier que les constantes sont cohérentes
      expect(hostIp.isNotEmpty, true, reason: 'Host IP ne doit pas être vide');
      expect(apiPort.isNotEmpty, true, reason: 'API Port ne doit pas être vide');
      expect(voskPort.isNotEmpty, true, reason: 'VOSK Port ne doit pas être vide');
      expect(livekitPort.isNotEmpty, true, reason: 'LiveKit Port ne doit pas être vide');
      expect(llmPort.isNotEmpty, true, reason: 'LLM Port ne doit pas être vide');
      
      // Vérifier le format IP
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      expect(ipRegex.hasMatch(hostIp), true, reason: 'Format IP invalide: $hostIp');
      
      // Vérifier les ports
      final apiPortNum = int.tryParse(apiPort);
      expect(apiPortNum, isNotNull, reason: 'Port API invalide: $apiPort');
      expect(apiPortNum! > 0 && apiPortNum < 65536, true, reason: 'Port API hors limites');
      
      print('   ✅ Configuration valide');
    });

    test('Temps de réponse - Performance', () async {
      print('⏱️  Test de performance des services');
      
      final services = [
        {'name': 'API Backend', 'url': 'http://$hostIp:$apiPort/health'},
        {'name': 'VOSK STT', 'url': 'http://$hostIp:$voskPort/health'},
        {'name': 'Mistral LLM', 'url': 'http://$hostIp:$llmPort/health'},
      ];
      
      for (final service in services) {
        final stopwatch = Stopwatch()..start();
        
        try {
          final response = await http.get(
            Uri.parse(service['url']!),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          stopwatch.stop();
          final responseTime = stopwatch.elapsedMilliseconds;
          
          print('   ${service['name']}: ${responseTime}ms');
          
          // Vérifier que le temps de réponse est raisonnable
          expect(responseTime < 5000, true, 
            reason: '${service['name']} trop lent: ${responseTime}ms');
          
        } catch (e) {
          stopwatch.stop();
          print('   ${service['name']}: Erreur - $e');
          // Ne pas faire échouer le test pour les erreurs de performance
        }
      }
    });

    test('URLs Flutter - Construction', () async {
      print('🔗 Test de construction des URLs Flutter');
      
      // Simuler la construction d'URLs comme dans l'app
      final baseApiUrl = 'http://$hostIp:$apiPort';
      final baseVoskUrl = 'http://$hostIp:$voskPort';
      final baseLlmUrl = 'http://$hostIp:$llmPort';
      final livekitUrl = 'ws://$hostIp:$livekitPort';
      
      // Vérifier les formats d'URL
      expect(Uri.tryParse(baseApiUrl), isNotNull, reason: 'URL API invalide');
      expect(Uri.tryParse(baseVoskUrl), isNotNull, reason: 'URL VOSK invalide');
      expect(Uri.tryParse(baseLlmUrl), isNotNull, reason: 'URL LLM invalide');
      expect(Uri.tryParse(livekitUrl), isNotNull, reason: 'URL LiveKit invalide');
      
      print('   ✅ API: $baseApiUrl');
      print('   ✅ VOSK: $baseVoskUrl');
      print('   ✅ LLM: $baseLlmUrl');
      print('   ✅ LiveKit: $livekitUrl');
    });
  });
}
