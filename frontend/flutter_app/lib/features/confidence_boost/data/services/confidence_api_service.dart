import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/api_models.dart';
import '../../domain/entities/confidence_scenario.dart';

/// Service API REST simple pour l'exercice Boost Confidence
/// Utilise les endpoints existants du backend Flask (port 8000)
class ConfidenceApiService {
  static const Duration _timeout = Duration(seconds: 30);
  
  /// Récupère la liste des scénarios disponibles depuis l'API backend
  Future<List<ApiScenario>> getScenarios({String language = 'fr'}) async {
    try {
      debugPrint('📡 Récupération scénarios depuis: ${AppConfig.apiBaseUrl}/api/scenarios');
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/scenarios?language=$language'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scenariosResponse = ScenariosResponse.fromJson(data);
        
        debugPrint('✅ ${scenariosResponse.scenarios.length} scénarios récupérés');
        return scenariosResponse.scenarios;
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération scénarios: $e');
      rethrow;
    }
  }
  
  /// Crée une nouvelle session d'exercice
  Future<ConfidenceSession> createSession({
    required String userId,
    required String scenarioId,
    String language = 'fr',
  }) async {
    try {
      debugPrint('📡 Création session pour scénario: $scenarioId');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'scenario_id': scenarioId,
          'language': language,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final session = ConfidenceSession.fromJson(data);
        
        debugPrint('✅ Session créée: ${session.sessionId}');
        return session;
      } else {
        throw Exception('Erreur création session ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur création session: $e');
      rethrow;
    }
  }
  
  /// Analyse un fichier audio et retourne la transcription + réponse IA
  Future<ConfidenceAnalysisResult> analyzeAudio({
    required String sessionId,
    required Uint8List audioData,
    String? audioFileName,
  }) async {
    try {
      debugPrint('📡 Analyse audio (${audioData.length} bytes) pour session: $sessionId');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/api/confidence-analysis'),
      );
      
      // Ajouter les headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'X-Session-ID': sessionId,
      });
      
      // Ajouter le fichier audio
      final fileName = audioFileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioData,
        filename: fileName,
      ));
      
      // Envoyer la requête
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = ConfidenceAnalysisResult.fromJson(data);
        
        debugPrint('✅ Analyse terminée - Transcription: "${result.transcription}"');
        debugPrint('✅ Réponse IA: "${result.aiResponse}"');
        
        return result;
      } else {
        throw Exception('Erreur analyse ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur analyse audio: $e');
      rethrow;
    }
  }
  
  /// Termine une session et récupère le rapport final
  /// Note: Cet endpoint devra être implémenté côté backend
  Future<ConfidenceReport> endSession(String sessionId) async {
    try {
      debugPrint('📡 Fin de session: $sessionId');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/sessions/$sessionId/end'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final report = ConfidenceReport.fromJson(data['report'] ?? data);
        
        debugPrint('✅ Session terminée - Score final: ${report.finalScore}');
        return report;
      } else {
        throw Exception('Erreur fin session ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur fin session: $e');
      
      // Fallback: créer un rapport basique si l'endpoint n'existe pas encore
      if (e.toString().contains('404')) {
        debugPrint('⚠️ Endpoint /end non implémenté, génération rapport fallback');
        return _generateFallbackReport(sessionId);
      }
      
      rethrow;
    }
  }
  
  /// Génère un rapport de fallback si l'endpoint backend n'est pas encore implémenté
  ConfidenceReport _generateFallbackReport(String sessionId) {
    return ConfidenceReport(
      sessionId: sessionId,
      finalScore: 75.0, // Score par défaut
      totalInteractions: 3,
      totalDuration: const Duration(minutes: 5),
      recommendations: [
        'Excellente participation à l\'exercice !',
        'Continuez à pratiquer régulièrement',
        'Travaillez votre confiance en public',
      ],
      detailedMetrics: {
        'average_confidence': 0.75,
        'speech_clarity': 0.80,
        'engagement_level': 0.70,
      },
      timestamp: DateTime.now(),
    );
  }
  
  /// Vérifie la santé de l'API backend
  Future<ApiHealthStatus> checkHealth() async {
    try {
      debugPrint('🔍 Vérification santé API: ${AppConfig.apiBaseUrl}/health');
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final healthStatus = ApiHealthStatus.fromJson(data);
        
        debugPrint('✅ API disponible: ${healthStatus.status}');
        return healthStatus;
      } else {
        throw Exception('API non disponible (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Erreur santé API: $e');
      return ApiHealthStatus(
        status: 'error',
        service: 'eloquence-api',
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Teste la connectivité réseau vers l'IP 192.168.1.44:8000
  Future<bool> testNetworkConnectivity() async {
    try {
      debugPrint('🌐 Test connectivité réseau vers ${AppConfig.apiBaseUrl}');
      
      // Test simple avec timeout court
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      final isConnected = response.statusCode == 200;
      debugPrint(isConnected ? '✅ Réseau OK' : '❌ Réseau KO');
      
      return isConnected;
    } catch (e) {
      debugPrint('❌ Connectivité réseau échouée: $e');
      return false;
    }
  }
  
  /// Convertit un ConfidenceScenario local en format API
  Map<String, dynamic> _scenarioToApiFormat(ConfidenceScenario scenario) {
    return {
      'scenario_id': scenario.id,
      'title': scenario.title,
      'description': scenario.description,
      'difficulty': scenario.difficulty,
      'duration_minutes': (scenario.durationSeconds / 60).round(),
      'category': scenario.type.name,
    };
  }
  
  /// Méthode utilitaire pour créer un userId unique
  static String generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Méthode utilitaire pour vérifier si une réponse JSON est valide
  bool _isValidJsonResponse(String responseBody) {
    try {
      jsonDecode(responseBody);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Gestion d'erreur standardisée
  Exception _handleApiError(http.Response response) {
    String errorMessage = 'Erreur API ${response.statusCode}';
    
    if (_isValidJsonResponse(response.body)) {
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error'] ?? errorMessage;
      } catch (e) {
        // Garder le message par défaut
      }
    }
    
    return Exception('$errorMessage: ${response.body}');
  }
}