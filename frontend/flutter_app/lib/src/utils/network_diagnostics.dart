import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/config/app_config.dart';

class NetworkDiagnostics {
  static final Logger _logger = Logger();
  
  static Future<Map<String, dynamic>> runCompleteDiagnostics() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };
    
    _logger.i('🔍 === DÉBUT DIAGNOSTIC RÉSEAU COMPLET ===');
    
    // Test 1: Connectivité Internet de base
    results['tests']['internet_connectivity'] = await _testInternetConnectivity();
    
    // Test 2: Résolution DNS du serveur LiveKit
    results['tests']['dns_resolution'] = await _testDnsResolution();
    
    // Test 3: Accessibilité HTTP du serveur LiveKit
    results['tests']['livekit_http_access'] = await _testLiveKitHttpAccess();
    
    // Test 4: Test WebSocket direct
    results['tests']['websocket_connection'] = await _testWebSocketConnection();
    
    // Test 5: Vérification de la configuration
    results['tests']['configuration_check'] = _checkConfiguration();
    
    // Test 6: Vérification des permissions Android
    results['tests']['android_permissions'] = await _checkAndroidPermissions();
    
    _logger.i('🔍 === FIN DIAGNOSTIC RÉSEAU ===');
    _logDiagnosticSummary(results);
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testInternetConnectivity() async {
    _logger.i('📡 Test 1: Connectivité Internet...');
    final result = <String, dynamic>{
      'success': false,
      'details': <String, dynamic>{},
    };
    
    try {
      final googleResult = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (googleResult.isNotEmpty && googleResult[0].rawAddress.isNotEmpty) {
        result['success'] = true;
        result['details']['google_reachable'] = true;
        result['details']['resolved_ips'] = googleResult.map((e) => e.address).toList();
        _logger.i('✅ Connectivité Internet OK');
      }
    } catch (e) {
      result['error'] = e.toString();
      _logger.e('❌ Pas de connectivité Internet: $e');
    }
    
    return result;
  }
  
  static Future<Map<String, dynamic>> _testDnsResolution() async {
    _logger.i('🔍 Test 2: Résolution DNS du serveur LiveKit...');
    final result = <String, dynamic>{
      'success': false,
      'details': <String, dynamic>{},
    };
    
    try {
      final uri = Uri.parse(AppConfig.livekitUrl); // Correction: livekitWsUrl -> livekitUrl
      final host = uri.host;
      
      result['details']['host'] = host;
      result['details']['is_ip'] = _isIpAddress(host);
      
      if (_isIpAddress(host)) {
        result['success'] = true;
        result['details']['resolution_needed'] = false;
        _logger.i('✅ Utilisation directe de l\'IP: $host');
      } else {
        final addresses = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));
        
        if (addresses.isNotEmpty) {
          result['success'] = true;
          result['details']['resolved_ips'] = addresses.map((e) => e.address).toList();
          _logger.i('✅ DNS résolu: $host -> ${addresses.map((e) => e.address).join(", ")}');
        }
      }
    } catch (e) {
      result['error'] = e.toString();
      _logger.e('❌ Erreur résolution DNS: $e');
    }
    
    return result;
  }
  
  static Future<Map<String, dynamic>> _testLiveKitHttpAccess() async {
    _logger.i('🌐 Test 3: Accessibilité HTTP du serveur LiveKit...');
    final result = <String, dynamic>{
      'success': false,
      'details': <String, dynamic>{},
    };
    
    try {
      final wsUri = Uri.parse(AppConfig.livekitUrl); // Correction: livekitWsUrl -> livekitUrl
      final httpUri = wsUri.replace(
        scheme: wsUri.scheme == 'wss' ? 'https' : 'http',
      );
      
      result['details']['test_url'] = httpUri.toString();
      
      final response = await http.get(httpUri)
          .timeout(const Duration(seconds: 10));
      
      result['details']['status_code'] = response.statusCode;
      result['details']['headers'] = response.headers;
      
      // LiveKit répond généralement avec 404 ou 426 sur HTTP
      if ([200, 404, 426, 400].contains(response.statusCode)) {
        result['success'] = true;
        _logger.i('✅ Serveur LiveKit accessible (HTTP ${response.statusCode})');
      } else {
        _logger.w('⚠️ Réponse inhabituelle: HTTP ${response.statusCode}');
      }
    } catch (e) {
      result['error'] = e.toString();
      _logger.e('❌ Serveur LiveKit inaccessible: $e');
    }
    
    return result;
  }
  
  static Future<Map<String, dynamic>> _testWebSocketConnection() async {
    _logger.i('🔌 Test 4: Connexion WebSocket directe...');
    final result = <String, dynamic>{
      'success': false,
      'details': <String, dynamic>{},
    };
    
    try {
      final uri = Uri.parse(AppConfig.livekitUrl); // Correction: livekitWsUrl -> livekitUrl
      result['details']['ws_url'] = uri.toString();
      result['details']['is_secure'] = uri.scheme == 'wss';
      
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'User-Agent': 'Eloquence-Flutter-Diagnostic/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      result['success'] = true;
      result['details']['connection_established'] = true;
      _logger.i('✅ Connexion WebSocket établie');
      
      await socket.close();
    } catch (e) {
      result['error'] = e.toString();
      result['details']['error_type'] = e.runtimeType.toString();
      
      if (e.toString().contains('HandshakeException')) {
        result['details']['likely_cause'] = 'SSL/TLS handshake failed';
        _logger.e('❌ Échec handshake SSL/TLS: $e');
      } else if (e.toString().contains('SocketException')) {
        result['details']['likely_cause'] = 'Network unreachable or port blocked';
        _logger.e('❌ Erreur réseau/socket: $e');
      } else if (e.toString().contains('TimeoutException')) {
        result['details']['likely_cause'] = 'Connection timeout - server not responding';
        _logger.e('❌ Timeout connexion: $e');
      } else {
        _logger.e('❌ Erreur WebSocket: $e');
      }
    }
    
    return result;
  }
  
  static Map<String, dynamic> _checkConfiguration() {
    _logger.i('⚙️ Test 5: Vérification de la configuration...');
    final result = <String, dynamic>{
      'success': true,
      'issues': <String>[],
      'details': <String, dynamic>{},
    };
    
    final uri = Uri.parse(AppConfig.livekitUrl); // Correction: livekitWsUrl -> livekitUrl
    
    result['details']['livekit_url'] = AppConfig.livekitUrl; // Correction: livekitWsUrl -> livekitUrl
    result['details']['api_base_url'] = AppConfig.apiBaseUrl;
    result['details']['url_scheme'] = uri.scheme;
    result['details']['url_host'] = uri.host;
    result['details']['url_port'] = uri.port;
    
    // Vérifications
    if (uri.scheme == 'ws' && !_isLocalNetwork(uri.host)) {
      result['issues'].add('Using insecure WebSocket (ws://) for non-local connection');
      result['success'] = false;
    }
    
    if (uri.port == 0) {
      result['issues'].add('No port specified in LiveKit URL');
    }
    
    if (result['issues'].isEmpty) {
      _logger.i('✅ Configuration correcte');
    } else {
      _logger.w('⚠️ Problèmes de configuration: ${result['issues']}');
    }
    
    return result;
  }
  
  static Future<Map<String, dynamic>> _checkAndroidPermissions() async {
    _logger.i('🔐 Test 6: Vérification des permissions Android...');
    final result = <String, dynamic>{
      'success': true,
      'details': <String, dynamic>{},
    };
    
    try {
      // Vérifier si on est sur Android
      if (Platform.isAndroid) {
        result['details']['platform'] = 'Android';
        result['details']['android_version'] = Platform.operatingSystemVersion;
        
        // Note: Les permissions réelles sont vérifiées dans LiveKitService
        result['details']['required_permissions'] = [
          'INTERNET',
          'ACCESS_NETWORK_STATE',
          'RECORD_AUDIO',
          'MODIFY_AUDIO_SETTINGS',
        ];
        
        _logger.i('✅ Plateforme Android détectée');
      } else {
        result['details']['platform'] = Platform.operatingSystem;
        _logger.i('ℹ️ Plateforme non-Android: ${Platform.operatingSystem}');
      }
    } catch (e) {
      result['error'] = e.toString();
      _logger.e('❌ Erreur vérification plateforme: $e');
    }
    
    return result;
  }
  
  static bool _isIpAddress(String host) {
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final ipv6Regex = RegExp(r'^([\da-fA-F]{1,4}:){7}[\da-fA-F]{1,4}$');
    return ipv4Regex.hasMatch(host) || ipv6Regex.hasMatch(host);
  }
  
  static bool _isLocalNetwork(String host) {
    return host == 'localhost' ||
           host == '127.0.0.1' ||
           host.startsWith('192.168.') ||
           host.startsWith('10.') ||
           host.startsWith('172.');
  }
  
  static void _logDiagnosticSummary(Map<String, dynamic> results) {
    _logger.i('📊 === RÉSUMÉ DU DIAGNOSTIC ===');
    
    int passedTests = 0;
    int totalTests = 0;
    
    results['tests'].forEach((testName, testResult) {
      totalTests++;
      if (testResult['success'] == true) {
        passedTests++;
        _logger.i('✅ $testName: SUCCÈS');
      } else {
        _logger.e('❌ $testName: ÉCHEC');
        if (testResult['error'] != null) {
          _logger.e('   Erreur: ${testResult['error']}');
        }
        if (testResult['issues'] != null && (testResult['issues'] as List).isNotEmpty) {
          _logger.e('   Problèmes: ${testResult['issues']}');
        }
      }
    });
    
    _logger.i('📈 Score: $passedTests/$totalTests tests réussis');
    
    // Recommandations basées sur les résultats
    _logger.i('\n💡 === RECOMMANDATIONS ===');
    
    if (results['tests']['websocket_connection']['success'] == false) {
      final wsError = results['tests']['websocket_connection']['error']?.toString() ?? '';
      
      if (wsError.contains('HandshakeException')) {
        _logger.w('🔧 Problème SSL/TLS détecté. Solutions:');
        _logger.w('   1. Utiliser wss:// au lieu de ws:// pour une connexion sécurisée');
        _logger.w('   2. Vérifier les certificats SSL du serveur LiveKit');
        _logger.w('   3. Ajouter le domaine dans network_security_config.xml si nécessaire');
      } else if (wsError.contains('SocketException')) {
        _logger.w('🔧 Problème réseau détecté. Solutions:');
        _logger.w('   1. Vérifier que le port 7880 est ouvert sur le serveur');
        _logger.w('   2. Vérifier les règles de pare-feu');
        _logger.w('   3. Tester avec telnet: telnet 192.168.1.44 7880');
      }
    }
    
    if (results['tests']['configuration_check']['issues']?.isNotEmpty ?? false) {
      _logger.w('🔧 Problèmes de configuration détectés:');
      for (var issue in results['tests']['configuration_check']['issues']) {
        _logger.w('   - $issue');
      }
    }
  }
}