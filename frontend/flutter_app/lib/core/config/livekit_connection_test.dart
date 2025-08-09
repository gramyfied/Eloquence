import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'environment_config.dart';

/// Test de connectivité et configuration LiveKit
class LiveKitConnectionTest {
  static const String _tag = '🔗 LiveKitConnectionTest';

  /// Test complet de la connectivité LiveKit
  static Future<void> runFullTest() async {
    print('$_tag: 🚀 Démarrage du test de connectivité complet...');
    print('');

    try {
      // Test 1: Configuration
      await _testConfiguration();
      print('');

      // Test 2: Connectivité au serveur LiveKit principal
      await _testLiveKitServerConnectivity();
      print('');

      // Test 3: Connectivité au service de tokens
      await _testTokenServiceConnectivity();
      print('');

      // Test 4: Test de génération de token
      await _testTokenGeneration();
      print('');

      // Test 5: Test de connexion WebSocket
      await _testWebSocketConnection();
      print('');

    } catch (e) {
      print('$_tag: ❌ Erreur lors du test: $e');
    }

    print('$_tag: ✅ Test de connectivité terminé');
  }

  /// Test de la configuration
  static Future<void> _testConfiguration() async {
    print('$_tag: 📋 Test de la configuration...');
    
    print('  API Key: ${EnvironmentConfig.livekitApiKey}');
    print('  API Secret: ${EnvironmentConfig.livekitApiSecret.substring(0, 10)}...');
    print('  LiveKit URL: ${EnvironmentConfig.livekitUrl}');
    print('  LiveKit HTTP URL: ${EnvironmentConfig.livekitHttpUrl}');
    print('  Token Service URL: ${EnvironmentConfig.livekitTokenUrl}');
    
    // Vérifier le format des clés
    final expectedFormat = '${EnvironmentConfig.livekitApiKey}: ${EnvironmentConfig.livekitApiSecret}';
    print('  Format attendu par LiveKit: $expectedFormat');
    
    print('  ✅ Configuration affichée');
  }

  /// Test de connectivité au serveur LiveKit principal
  static Future<void> _testLiveKitServerConnectivity() async {
    print('$_tag: 🌐 Test connectivité serveur LiveKit principal...');
    
    try {
      // Test HTTP (LiveKit expose un endpoint HTTP)
      final httpUrl = EnvironmentConfig.livekitHttpUrl;
      print('  Test HTTP vers: $httpUrl');
      
      final response = await http.get(
        Uri.parse(httpUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('  Status HTTP: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  ✅ Serveur LiveKit accessible via HTTP');
      } else {
        print('  ⚠️ Serveur LiveKit répond avec ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print('  Réponse: ${response.body}');
        }
      }
      
    } catch (e) {
      print('  ❌ Erreur connectivité serveur LiveKit: $e');
    }
  }

  /// Test de connectivité au service de tokens
  static Future<void> _testTokenServiceConnectivity() async {
    print('$_tag: 🎫 Test connectivité service de tokens...');
    
    try {
      final url = '${EnvironmentConfig.livekitTokenUrl}/health';
      print('  Test vers: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('  Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  ✅ Service de tokens accessible');
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            print('  Réponse: $data');
          } catch (e) {
            print('  Réponse brute: ${response.body}');
          }
        }
      } else {
        print('  ❌ Service de tokens inaccessible: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print('  Erreur: ${response.body}');
        }
      }
      
    } catch (e) {
      print('  ❌ Erreur connectivité service tokens: $e');
    }
  }

  /// Test de génération de token
  static Future<void> _testTokenGeneration() async {
    print('$_tag: 🔑 Test génération de token...');
    
    try {
      final url = '${EnvironmentConfig.livekitTokenUrl}/generate-token';
      print('  Test vers: $url');
      
      final requestBody = {
        'room_name': 'test_connection_${DateTime.now().millisecondsSinceEpoch}',
        'participant_name': 'test_user_connection',
        'grants': {
          'roomJoin': true,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
        'metadata': {
          'test_type': 'connection_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      
      print('  Corps de la requête: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      print('  Status: ${response.statusCode}');
      print('  Réponse: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final token = data['token'] as String?;
          
          if (token != null && token.isNotEmpty) {
            print('  ✅ Token généré avec succès');
            print('  Token (début): ${token.substring(0, 50)}...');
            
            // Vérifier la structure JWT
            final parts = token.split('.');
            if (parts.length == 3) {
              print('  ✅ Structure JWT valide (3 parties)');
            } else {
              print('  ⚠️ Structure JWT invalide (${parts.length} parties)');
            }
          } else {
            print('  ❌ Token manquant ou vide dans la réponse');
          }
        } catch (e) {
          print('  ⚠️ Erreur décodage réponse JSON: $e');
        }
      } else {
        print('  ❌ Échec génération token');
      }
      
    } catch (e) {
      print('  ❌ Erreur génération token: $e');
    }
  }

  /// Test de connexion WebSocket
  static Future<void> _testWebSocketConnection() async {
    print('$_tag: 🔌 Test connexion WebSocket...');
    
    try {
      final wsUrl = EnvironmentConfig.livekitUrl;
      print('  Test WebSocket vers: $wsUrl');
      
      // Note: En Flutter, on ne peut pas tester WebSocket directement sans package spécial
      // On va juste vérifier que l'URL est valide
      if (wsUrl.startsWith('ws://') || wsUrl.startsWith('wss://')) {
        print('  ✅ Format URL WebSocket valide');
        
        // Extraire l'hôte et le port
        final uri = Uri.parse(wsUrl.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://'));
        print('  Hôte: ${uri.host}');
        print('  Port: ${uri.port}');
        
        // Test de connectivité TCP basique
        try {
          final socket = await Socket.connect(uri.host, uri.port, timeout: const Duration(seconds: 5));
          await socket.close();
          print('  ✅ Port accessible via TCP');
        } catch (e) {
          print('  ⚠️ Port non accessible via TCP: $e');
        }
        
      } else {
        print('  ❌ Format URL WebSocket invalide');
      }
      
    } catch (e) {
      print('  ❌ Erreur test WebSocket: $e');
    }
  }

  /// Test rapide
  static Future<void> runQuickTest() async {
    print('$_tag: 🚀 Test rapide de connectivité...');
    
    try {
      // Test de connectivité au service de tokens
      final url = '${EnvironmentConfig.livekitTokenUrl}/health';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('$_tag: ✅ Service de tokens accessible');
        
        // Test rapide de génération
        await _testTokenGeneration();
      } else {
        print('$_tag: ❌ Service de tokens inaccessible: ${response.statusCode}');
      }
      
    } catch (e) {
      print('$_tag: ❌ Erreur test rapide: $e');
    }
  }
}

// Point d'entrée pour exécuter les tests
void main() {
  print('🔗 Test de connectivité LiveKit');
  print('===============================');
  print('');
  
  // Exécuter le test rapide par défaut
  LiveKitConnectionTest.runQuickTest();
  
  // Décommenter pour le test complet
  // LiveKitConnectionTest.runFullTest();
}
