import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service unifié pour l'analyse vocale utilisant exclusivement Whisper
class UnifiedSpeechAnalysisService {
  static const String _baseUrl = 'http://192.168.1.44:8000';
  static const Duration _defaultTimeout = Duration(seconds: 6);
  
  final Map<String, dynamic> _cache = {};
  
  Future<SpeechAnalysisResult> analyzeAudio(Uint8List audioData) async {
    try {
      final cacheKey = _generateCacheKey(audioData);
      if (_cache.containsKey(cacheKey)) {
        return SpeechAnalysisResult.fromJson(_cache[cacheKey]);
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/speech/analyze'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: audioData,
      ).timeout(_defaultTimeout);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _cache[cacheKey] = result;
        return SpeechAnalysisResult.fromJson(result);
      } else {
        throw SpeechAnalysisException('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      return _generateFallbackResult(audioData);
    }
  }
  
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  SpeechAnalysisResult _generateFallbackResult(Uint8List audioData) {
    final duration = _estimateAudioDuration(audioData);
    return SpeechAnalysisResult(
      transcription: 'Analyse en cours...',
      confidence: 0.7,
      duration: duration,
      wordsPerMinute: _estimateWPM(duration),
      feedback: 'Analyse simplifiée disponible.',
    );
  }
  
  String _generateCacheKey(Uint8List data) {
    return data.length.toString() + data.take(100).join();
  }
  
  double _estimateAudioDuration(Uint8List data) {
    return data.length / 16000.0;
  }
  
  double _estimateWPM(double duration) {
    return duration > 0 ? (150 * 60) / duration : 0;
  }
}

class SpeechAnalysisResult {
  final String transcription;
  final double confidence;
  final double duration;
  final double wordsPerMinute;
  final String feedback;
  
  SpeechAnalysisResult({
    required this.transcription,
    required this.confidence,
    required this.duration,
    required this.wordsPerMinute,
    required this.feedback,
  });
  
  factory SpeechAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpeechAnalysisResult(
      transcription: json['transcription'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 0.0).toDouble(),
      wordsPerMinute: (json['words_per_minute'] ?? 0.0).toDouble(),
      feedback: json['feedback'] ?? '',
    );
  }
}

class SpeechAnalysisException implements Exception {
  final String message;
  SpeechAnalysisException(this.message);
  
  @override
  String toString() => 'SpeechAnalysisException: $message';
}