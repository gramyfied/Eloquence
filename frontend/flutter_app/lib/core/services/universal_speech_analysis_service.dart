import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../../features/shared/analysis/domain/analysis_result.dart';
import '../../features/shared/analysis/domain/exercise_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class UniversalSpeechAnalysisService {
  static const String _tag = 'UniversalSpeechAnalysisService';
  static final Logger _logger = Logger();
  
  // Service Vosk backend optimisé
  static String get _baseUrl => AppConfig.voskAnalysisUrl;
  
  /// Analyse universelle pour tous types d'exercices
  Future<AnalysisResult> analyzeAudio({
    required Uint8List audioData,
    required String exerciseType,
    required ExerciseConfig config,
    String language = 'fr',
  }) async {
    
    _logger.i('$_tag: 🚀 Analyse $exerciseType démarrée');
    final stopwatch = Stopwatch()..start();
    
    try {
      // Requête multipart optimisée
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('$_baseUrl/api/analyze')
      );
      
      // Fichier audio
      request.files.add(http.MultipartFile.fromBytes(
        'audio_file',
        audioData,
        filename: 'recording.wav',
      ));
      
      // Paramètres
      request.fields['exercise_type'] = exerciseType;
      request.fields['exercise_config'] = jsonEncode(config.toJson());
      request.fields['language'] = language;
      
      // Headers
      request.headers['Accept'] = 'application/json';
      
      // Envoi avec timeout optimisé
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 10), // Timeout court car Vosk est rapide
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AnalysisResult.fromJson(data);
        
        _logger.i('$_tag: ✅ Analyse terminée en ${stopwatch.elapsedMilliseconds}ms');
        return result;
        
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      _logger.e('$_tag: ❌ Erreur analyse: $e');
      
      // Fallback local minimal (pas de backend complexe)
      return AnalysisResult.createFallback(
        exerciseType: exerciseType,
        error: e.toString(),
        processingTime: stopwatch.elapsedMilliseconds.toDouble(),
      );
    }
  }
  
  /// Vérification santé du service Vosk
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      
      return false;
    } catch (e) {
      _logger.w('$_tag: Health check failed: $e');
      return false;
    }
  }
  
  /// Obtenir les analyseurs disponibles
  Future<List<String>> getAvailableAnalyzers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['available_analyzers'] ?? []);
      }
      
      return ['confidence']; // Fallback
    } catch (e) {
      return ['confidence']; // Fallback
    }
  }
}

// Provider Riverpod
final universalSpeechAnalysisServiceProvider = Provider<UniversalSpeechAnalysisService>((ref) {
  return UniversalSpeechAnalysisService();
});