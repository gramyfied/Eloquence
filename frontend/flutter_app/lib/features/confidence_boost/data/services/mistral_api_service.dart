import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/logger_service.dart';

class MistralApiService {
  // Configuration simple - Même approche que le backend Python
  static String get _endpoint {
    // MISTRAL_BASE_URL contient déjà l'URL complète avec /chat/completions
    return dotenv.env['MISTRAL_BASE_URL'] ?? 'https://api.mistral.ai/v1/chat/completions';
  }
  
  static String get _model {
    return dotenv.env['MISTRAL_MODEL'] ?? 'mistral-nemo-instruct-2407';
  }
  
  static String get _apiKey {
    return dotenv.env['MISTRAL_API_KEY'] ?? '';
  }
  static bool get _isEnabled => dotenv.env['MISTRAL_ENABLED']?.toLowerCase() == 'true';
  static const String _tag = 'MistralApiService';

  Future<String> generateText({
    required String prompt,
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    // Vérifier si Mistral est activé
    if (!_isEnabled) {
      logger.i(_tag, 'Mistral désactivé, utilisation du feedback simulé');
      return 'Feedback simulé: Excellente performance ! Continuez ainsi pour développer votre confiance en prise de parole.';
    }
    
    // Vérifier si la clé API est présente
    if (_apiKey.isEmpty || _apiKey == 'your_mistral_api_key') {
      logger.w(_tag, 'Clé API Mistral invalide, utilisation du feedback simulé');
      return 'Feedback simulé: Très bonne performance ! Votre élocution était claire et votre message était bien structuré.';
    }
    
    try {
      logger.i(_tag, 'Appel API Mistral: $_endpoint');
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] ?? '';
      } else {
        logger.e(_tag, 'Erreur API Mistral: ${response.statusCode} - ${response.body}');
        // En cas d'erreur API, retourner un feedback de fallback
        return 'Feedback simulé: Performance solide ! Votre présentation était engageante et bien articulée.';
      }
    } catch (e) {
      logger.e(_tag, 'Erreur communication Mistral: $e');
      // En cas d'exception, retourner un feedback de fallback
      return 'Feedback simulé: Bonne prestation ! Votre confiance transparaît dans votre façon de vous exprimer.';
    }
  }

  Future<Map<String, dynamic>> analyzeContent({
    required String prompt,
    int maxTokens = 800,
  }) async {
    // Vérifier si Mistral est activé
    if (!_isEnabled) {
      logger.i(_tag, 'Mistral désactivé, utilisation de l\'analyse simulée');
      return {
        'content_score': 0.8,
        'feedback': 'Analyse simulée: Excellente présentation ! Votre ton était confiant et votre message était clair.',
        'strengths': ['Clarté du message', 'Confiance dans le ton', 'Structure cohérente'],
        'improvements': ['Continuer la pratique régulière', 'Explorer de nouveaux sujets'],
      };
    }
    
    // Vérifier si la clé API est présente
    if (_apiKey.isEmpty || _apiKey == 'your_mistral_api_key') {
      logger.w(_tag, 'Clé API Mistral invalide, utilisation de l\'analyse simulée');
      return {
        'content_score': 0.75,
        'feedback': 'Analyse simulée: Très bonne performance ! Votre expression était naturelle et engageante.',
        'strengths': ['Expression naturelle', 'Engagement du public', 'Gestion du stress'],
        'improvements': ['Travailler la gestuelle', 'Varier l\'intonation'],
      };
    }
    
    try {
      logger.i(_tag, 'Analyse avec Mistral: $_endpoint');
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText = data['choices']?[0]?['message']?['content'] ?? '{}';
        
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
        logger.e(_tag, 'Erreur API Mistral: ${response.statusCode} - ${response.body}');
        // En cas d'erreur API, retourner une analyse de fallback
        return {
          'content_score': 0.7,
          'feedback': 'Analyse simulée: Performance satisfaisante ! Votre présentation montrait de la préparation.',
          'strengths': ['Préparation visible', 'Effort d\'articulation'],
          'improvements': ['Continuer l\'entraînement', 'Renforcer la confiance'],
        };
      }
    } catch (e) {
      logger.e(_tag, 'Erreur analyse Mistral: $e');
      // En cas d'exception, retourner une analyse de fallback
      return {
        'content_score': 0.65,
        'feedback': 'Analyse simulée: Bonne tentative ! Chaque pratique vous aide à progresser.',
        'strengths': ['Courage de pratiquer', 'Volonté d\'amélioration'],
        'improvements': ['Persévérer dans l\'entraînement', 'Gagner en assurance'],
      };
    }
  }
}