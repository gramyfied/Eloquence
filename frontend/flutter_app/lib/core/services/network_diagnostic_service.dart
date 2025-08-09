/// Service de diagnostic réseau pour tester la connectivité des services
/// 
/// Ce service permet de vérifier que tous les services sont accessibles
/// et de diagnostiquer les problèmes de connexion
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/environment_config.dart';

class NetworkDiagnosticService {
  static const Duration _timeout = Duration(seconds: 10);
  
  /// Test de connectivité pour tous les services
  static Future<Map<String, DiagnosticResult>> testAllServices() async {
    final results = <String, DiagnosticResult>{};
    
    // Test des services HTTP
    results['livekitHttp'] = await _testHttpService(
      EnvironmentConfig.livekitHttpUrl,
      'LiveKit HTTP',
    );
    
    results['tokenService'] = await _testHttpService(
      EnvironmentConfig.livekitTokenUrl,
      'Token Service',
    );
    
    results['exercisesApi'] = await _testHttpService(
      EnvironmentConfig.exercisesApiUrl,
      'Exercises API',
    );
    
    results['mistralService'] = await _testHttpService(
      EnvironmentConfig.llmServiceUrl,
      'Mistral Service',
    );
    
    results['voskService'] = await _testHttpService(
      EnvironmentConfig.voskServiceUrl,
      'Vosk Service',
    );
    
    results['haproxy'] = await _testHttpService(
      EnvironmentConfig.haproxyUrl,
      'HAProxy',
    );
    
    // Test WebSocket LiveKit
    results['livekitWebSocket'] = await _testWebSocketService(
      EnvironmentConfig.livekitUrl,
      'LiveKit WebSocket',
    );
    
    return results;
  }
  
  /// Test d'un service HTTP
  static Future<DiagnosticResult> _testHttpService(
    String url,
    String serviceName,
  ) async {
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Eloquence-Diagnostic/1.0'},
      ).timeout(_timeout);
      
      final duration = DateTime.now().difference(startTime);
      
      if (response.statusCode == 200) {
        return DiagnosticResult(
          service: serviceName,
          url: url,
          status: DiagnosticStatus.success,
          responseTime: duration,
          details: 'Status: ${response.statusCode}, Taille: ${response.body.length} bytes',
        );
      } else {
        return DiagnosticResult(
          service: serviceName,
          url: url,
          status: DiagnosticStatus.warning,
          responseTime: duration,
          details: 'Status: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      return DiagnosticResult(
        service: serviceName,
        url: url,
        status: DiagnosticStatus.error,
        responseTime: Duration.zero,
        details: 'Erreur de connexion: ${e.message}',
      );
    } on TimeoutException catch (e) {
      return DiagnosticResult(
        service: serviceName,
        url: url,
        status: DiagnosticStatus.error,
        responseTime: Duration.zero,
        details: 'Timeout: ${e.message}',
      );
    } catch (e) {
      return DiagnosticResult(
        service: serviceName,
        url: url,
        status: DiagnosticStatus.error,
        responseTime: Duration.zero,
        details: 'Erreur inattendue: $e',
      );
    }
  }
  
  /// Test d'un service WebSocket
  static Future<DiagnosticResult> _testWebSocketService(
    String url,
    String serviceName,
  ) async {
    try {
      final startTime = DateTime.now();
      
      final channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: {'User-Agent': 'Eloquence-Diagnostic/1.0'},
      );
      
      // Attendre un peu pour voir si la connexion s'établit
      await Future.delayed(const Duration(seconds: 2));
      
      final duration = DateTime.now().difference(startTime);
      
      if (channel.sink != null) {
        channel.sink.close();
        return DiagnosticResult(
          service: serviceName,
          url: url,
          status: DiagnosticStatus.success,
          responseTime: duration,
          details: 'Connexion WebSocket établie',
        );
      } else {
        return DiagnosticResult(
          service: serviceName,
          url: url,
          status: DiagnosticStatus.error,
          responseTime: duration,
          details: 'Impossible d\'établir la connexion WebSocket',
        );
      }
    } on SocketException catch (e) {
      return DiagnosticResult(
        service: serviceName,
        url: url,
        status: DiagnosticStatus.error,
        responseTime: Duration.zero,
        details: 'Erreur de connexion WebSocket: ${e.message}',
      );
    } catch (e) {
      return DiagnosticResult(
        service: serviceName,
        url: url,
        status: DiagnosticStatus.error,
        responseTime: Duration.zero,
        details: 'Erreur WebSocket inattendue: $e',
      );
    }
  }
  
  /// Génération d'un rapport de diagnostic
  static String generateDiagnosticReport(Map<String, DiagnosticResult> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔧 === RAPPORT DE DIAGNOSTIC RÉSEAU ===');
    buffer.writeln('📅 Date: ${DateTime.now()}');
    buffer.writeln('🌐 IP Hôte: ${EnvironmentConfig.devHostIP}');
    buffer.writeln('');
    
    // Résumé des résultats
    final successCount = results.values.where((r) => r.status == DiagnosticStatus.success).length;
    final warningCount = results.values.where((r) => r.status == DiagnosticStatus.warning).length;
    final errorCount = results.values.where((r) => r.status == DiagnosticStatus.error).length;
    
    buffer.writeln('📊 RÉSUMÉ:');
    buffer.writeln('   ✅ Succès: $successCount');
    buffer.writeln('   ⚠️ Avertissements: $warningCount');
    buffer.writeln('   ❌ Erreurs: $errorCount');
    buffer.writeln('');
    
    // Détails par service
    buffer.writeln('🔍 DÉTAILS PAR SERVICE:');
    results.forEach((key, result) {
      final statusIcon = _getStatusIcon(result.status);
      final statusText = _getStatusText(result.status);
      
      buffer.writeln('$statusIcon ${result.service}:');
      buffer.writeln('   URL: ${result.url}');
      buffer.writeln('   Statut: $statusText');
      buffer.writeln('   Temps de réponse: ${result.responseTime.inMilliseconds}ms');
      buffer.writeln('   Détails: ${result.details}');
      buffer.writeln('');
    });
    
    // Recommandations
    buffer.writeln('💡 RECOMMANDATIONS:');
    if (errorCount > 0) {
      buffer.writeln('   • Vérifiez que tous les services Docker sont démarrés');
      buffer.writeln('   • Vérifiez que l\'IP ${EnvironmentConfig.devHostIP} est correcte');
      buffer.writeln('   • Vérifiez que les ports ne sont pas bloqués par le pare-feu');
      buffer.writeln('   • Vérifiez la connectivité réseau entre l\'appareil et l\'hôte');
    } else if (warningCount > 0) {
      buffer.writeln('   • Certains services répondent mais avec des codes d\'état non-200');
      buffer.writeln('   • Vérifiez la configuration des services');
    } else {
      buffer.writeln('   • Tous les services sont accessibles ! 🎉');
    }
    
    buffer.writeln('🔧 === FIN RAPPORT ===');
    
    return buffer.toString();
  }
  
  static String _getStatusIcon(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.success:
        return '✅';
      case DiagnosticStatus.warning:
        return '⚠️';
      case DiagnosticStatus.error:
        return '❌';
    }
  }
  
  static String _getStatusText(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.success:
        return 'Succès';
      case DiagnosticStatus.warning:
        return 'Avertissement';
      case DiagnosticStatus.error:
        return 'Erreur';
    }
  }
}

/// Résultat d'un test de diagnostic
class DiagnosticResult {
  final String service;
  final String url;
  final DiagnosticStatus status;
  final Duration responseTime;
  final String details;
  
  DiagnosticResult({
    required this.service,
    required this.url,
    required this.status,
    required this.responseTime,
    required this.details,
  });
}

/// Statut d'un test de diagnostic
enum DiagnosticStatus {
  success,
  warning,
  error,
}
