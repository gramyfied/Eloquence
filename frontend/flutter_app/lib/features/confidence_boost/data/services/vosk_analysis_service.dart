import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/optimized_http_service.dart';

/// Service pour l'analyse vocale en temps réel avec VOSK
/// Remplace complètement Whisper pour la transcription et l'analyse prosodique
class VoskAnalysisService {
  final OptimizedHttpService _httpService = OptimizedHttpService();
  final String _baseUrl;
  
  // Configuration des timeouts optimisés pour mobile
  static const Duration _analysisTimeout = Duration(seconds: 6);
  
  VoskAnalysisService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://localhost:8003';

  /// Analyse l'audio et retourne la transcription avec les métriques prosodiques
  Future<VoskAnalysisResult> analyzeSpeech(Uint8List audioData) async {
    try {
      debugPrint('[VoskAnalysis] Starting speech analysis');
      debugPrint('[VoskAnalysis] Audio data size: ${audioData.length} bytes');
      
      // Créer la requête multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze_speech'),
      );
      
      // Ajouter le fichier audio
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio_file',
          audioData,
          filename: 'audio.wav',
        ),
      );
      
      // Envoyer la requête avec le service optimisé
      final streamedResponse = await _httpService.sendMultipartRequest(
        request,
        timeout: _analysisTimeout,
      );
      
      // Convertir en Response normale
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VoskAnalysisResult.fromJson(data);
      } else {
        throw Exception('VOSK analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[VoskAnalysis] Error: $e');
      rethrow;
    }
  }
  
  /// Convertit les résultats VOSK en AnalysisResult simple pour compatibilité
  AnalysisResult convertToAnalysisResult(VoskAnalysisResult voskResult) {
    return AnalysisResult(
      overallConfidenceScore: voskResult.confidence,
      otherMetrics: {
        'transcription': voskResult.transcription,
        'fluency': voskResult.fluency,
        'clarity': voskResult.clarity,
        'overallScore': voskResult.overallScore,
        'pitchMean': voskResult.pitchMean,
        'pitchVariation': voskResult.pitchVariation,
        'energyMean': voskResult.energyMean,
        'energyVariation': voskResult.energyVariation,
        'speakingRate': voskResult.speakingRate,
        'pauseDuration': voskResult.pauseDuration,
        'processingTime': voskResult.processingTime,
      },
    );
  }
  
  /// Vérifie la santé du service VOSK
  Future<bool> checkHealth() async {
    try {
      final response = await _httpService.get(
        '$_baseUrl/health',
        timeout: const Duration(seconds: 2),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[VoskAnalysis] Health check failed: $e');
      return false;
    }
  }
}

/// Résultat de l'analyse VOSK
class VoskAnalysisResult {
  final String transcription;
  final double confidence;
  final double fluency;
  final double clarity;
  final double overallScore;
  final double pitchMean;
  final double pitchVariation;
  final double energyMean;
  final double energyVariation;
  final double speakingRate;
  final double pauseDuration;
  final List<WordTiming> wordTimings;
  final double processingTime;
  
  const VoskAnalysisResult({
    required this.transcription,
    required this.confidence,
    required this.fluency,
    required this.clarity,
    required this.overallScore,
    required this.pitchMean,
    required this.pitchVariation,
    required this.energyMean,
    required this.energyVariation,
    required this.speakingRate,
    required this.pauseDuration,
    required this.wordTimings,
    required this.processingTime,
  });
  
  factory VoskAnalysisResult.fromJson(Map<String, dynamic> json) {
    final prosody = json['prosody'] ?? {};
    
    return VoskAnalysisResult(
      transcription: json['transcription'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      fluency: (json['fluency'] ?? 0.0).toDouble(),
      clarity: (json['clarity'] ?? 0.0).toDouble(),
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      pitchMean: (prosody['pitch_mean'] ?? 0.0).toDouble(),
      pitchVariation: (prosody['pitch_variation'] ?? 0.0).toDouble(),
      energyMean: (prosody['energy_mean'] ?? 0.0).toDouble(),
      energyVariation: (prosody['energy_variation'] ?? 0.0).toDouble(),
      speakingRate: (prosody['speaking_rate'] ?? 0.0).toDouble(),
      pauseDuration: (prosody['pause_duration'] ?? 0.0).toDouble(),
      wordTimings: (json['word_timings'] as List<dynamic>?)
          ?.map((w) => WordTiming.fromJson(w))
          .toList() ?? [],
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
    );
  }
}

/// Timing des mots pour l'analyse détaillée
class WordTiming {
  final String word;
  final double start;
  final double end;
  final double confidence;
  
  const WordTiming({
    required this.word,
    required this.start,
    required this.end,
    required this.confidence,
  });
  
  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] ?? '',
      start: (json['start'] ?? 0.0).toDouble(),
      end: (json['end'] ?? 0.0).toDouble(),
      confidence: (json['conf'] ?? 0.0).toDouble(),
    );
  }
}

/// Métriques prosodiques pour compatibilité avec le système existant
class ProsodyMetrics {
  final double pitchMean;
  final double pitchVariation;
  final double energyMean;
  final double energyVariation;
  final double speakingRate;
  final double pauseDuration;
  
  const ProsodyMetrics({
    required this.pitchMean,
    required this.pitchVariation,
    required this.energyMean,
    required this.energyVariation,
    required this.speakingRate,
    required this.pauseDuration,
  });
}

/// Classe temporaire AnalysisResult pour compatibilité
class AnalysisResult {
  final double overallConfidenceScore;
  final Map<String, dynamic> otherMetrics;

  AnalysisResult({
    required this.overallConfidenceScore,
    this.otherMetrics = const {},
  });
}

/// Provider pour le service VOSK
final voskAnalysisServiceProvider = Provider<VoskAnalysisService>((ref) {
  return VoskAnalysisService();
});