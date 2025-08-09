import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// Service de test pour vérifier la connectivité LiveKit
class LiveKitTestService {
  static final Logger _logger = Logger();
  
  /// Test de connectivité au serveur LiveKit
  static Future<bool> testLiveKitServer() async {
    try {
      _logger.i('🧪 Test connectivité serveur LiveKit...');
      
      final response = await http.get(
        Uri.parse('${AppConfig.livekitUrl}/'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _logger.i('✅ Serveur LiveKit accessible');
        return true;
      } else {
        _logger.e('❌ Serveur LiveKit erreur HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Serveur LiveKit inaccessible: $e');
      return false;
    }
  }
  
  /// Test du service de tokens LiveKit
  static Future<bool> testTokenService() async {
    try {
      _logger.i('🧪 Test service de tokens LiveKit...');
      
      final response = await http.get(
        Uri.parse('${AppConfig.livekitTokenUrl}/health'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        
        if (status == 'healthy') {
          _logger.i('✅ Service de tokens LiveKit opérationnel');
          return true;
        } else {
          _logger.e('❌ Service de tokens LiveKit non sain: $status');
          return false;
        }
      } else {
        _logger.e('❌ Service de tokens LiveKit erreur HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Service de tokens LiveKit inaccessible: $e');
      return false;
    }
  }
  
  /// Test de génération de token
  static Future<bool> testTokenGeneration() async {
    try {
      _logger.i('🧪 Test génération de token LiveKit...');
      
      final response = await http.post(
        Uri.parse('${AppConfig.livekitTokenUrl}/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'room_name': 'test_room_${DateTime.now().millisecondsSinceEpoch}',
          'participant_name': 'test_user',
          'participant_identity': 'test_user_123',
          'grants': {
            'roomJoin': true,
            'canPublish': true,
            'canSubscribe': true,
            'canPublishData': true,
            'canUpdateOwnMetadata': true,
          },
          'metadata': {
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'validity_hours': 1,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        
        if (token != null && token.isNotEmpty) {
          _logger.i('✅ Token LiveKit généré avec succès');
          return true;
        } else {
          _logger.e('❌ Token LiveKit invalide dans la réponse');
          return false;
        }
      } else {
        final errorBody = response.body;
        _logger.e('❌ Erreur génération token HTTP ${response.statusCode}: $errorBody');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Erreur génération token: $e');
      return false;
    }
  }
  
  /// Test complet de l'infrastructure LiveKit
  static Future<Map<String, bool>> runFullTest() async {
    _logger.i('🚀 Démarrage test complet infrastructure LiveKit...');
    
    final results = <String, bool>{};
    
    // Test 1: Serveur LiveKit
    results['livekit_server'] = await testLiveKitServer();
    
    // Test 2: Service de tokens
    results['token_service'] = await testTokenService();
    
    // Test 3: Génération de token
    results['token_generation'] = await testTokenGeneration();
    
    // Résumé
    final successCount = results.values.where((result) => result).length;
    final totalCount = results.length;
    
    _logger.i('📊 Résultats tests LiveKit: $successCount/$totalCount réussis');
    
    for (final entry in results.entries) {
      final status = entry.value ? '✅' : '❌';
      _logger.i('  $status ${entry.key}');
    }
    
    return results;
  }
  
  /// Test de connectivité réseau
  static Future<bool> testNetworkConnectivity() async {
    try {
      _logger.i('🌐 Test connectivité réseau...');
      
      // Test DNS
      final livekitUri = Uri.parse(AppConfig.livekitUrl);
      final tokenUri = Uri.parse(AppConfig.livekitTokenUrl);
      
      _logger.d('  - LiveKit URL: ${livekitUri.host}:${livekitUri.port}');
      _logger.d('  - Token URL: ${tokenUri.host}:${tokenUri.port}');
      
      // Test de résolution DNS
      try {
        final livekitHost = await InternetAddress.lookup(livekitUri.host);
        _logger.d('  - DNS LiveKit: ${livekitHost.first.address}');
      } catch (e) {
        _logger.e('  - DNS LiveKit échec: $e');
        return false;
      }
      
      try {
        final tokenHost = await InternetAddress.lookup(tokenUri.host);
        _logger.d('  - DNS Token: ${tokenHost.first.address}');
      } catch (e) {
        _logger.e('  - DNS Token échec: $e');
        return false;
      }
      
      _logger.i('✅ Connectivité réseau OK');
      return true;
      
    } catch (e) {
      _logger.e('❌ Erreur test connectivité: $e');
      return false;
    }
  }
}
