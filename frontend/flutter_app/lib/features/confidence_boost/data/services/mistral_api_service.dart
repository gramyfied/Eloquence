import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/logger_service.dart';

class MistralApiService {
  static const String _baseUrl = 'https://api.mistral.ai/v1';
  static const String _apiKey = '2b7e4e7e7c6e4e2e8e6e4e7e7c6e4e2e8e6e4e7e7c6e4e2e';
  static const String _tag = 'MistralApiService';

  Future<String> generateText({
    required String prompt,
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mistral/generate'),
        headers: {
          'Content-Type': 'application/json',
          'API_KEY': _apiKey,
        },
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generated_text'] ?? data['text'] ?? '';
      } else {
        logger.e(_tag, 'Erreur API Mistral: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur génération texte: ${response.statusCode}');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur communication Mistral: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analyzeContent({
    required String prompt,
    int maxTokens = 800,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mistral/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'API_KEY': _apiKey,
        },
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': maxTokens,
          'temperature': 0.3,
          'response_format': 'json',
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText = data['generated_text'] ?? data['text'] ?? '{}';
        
        // Tenter de parser le JSON de l'analyse
        try {
          return jsonDecode(analysisText);
        } catch (e) {
          // Si le parsing JSON échoue, créer une structure de base
          return {
            'content_score': 0.7,
            'feedback': analysisText,
            'strengths': ['Expression naturelle'],
            'improvements': ['Continuer la pratique'],
          };
        }
      } else {
        throw Exception('Erreur analyse Mistral: ${response.statusCode}');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur analyse Mistral: $e');
      rethrow;
    }
  }
}