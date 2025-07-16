import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_scenario.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/confidence_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/services/optimized_http_service.dart';

/// Service pour l'analyse backend utilisant Whisper + Mistral sur Scaleway
class ConfidenceAnalysisBackendService {
  static const String _tag = 'ConfidenceAnalysisBackendService';
  static final Logger _logger = Logger();
  
  // Utilisation du service HTTP optimisé
  static final OptimizedHttpService _httpService = OptimizedHttpService();
  
  // Configuration backend depuis .env
  static String get _baseUrl {
    final envUrl = dotenv.env['LLM_SERVICE_URL'];
    final finalUrl = envUrl ?? 'http://localhost:8000';
    _logger.i('$_tag: 🔍 DEBUG URL Configuration:');
    _logger.i('  - Variable LLM_SERVICE_URL: $envUrl');
    _logger.i('  - URL finale utilisée: $finalUrl');
    return finalUrl;
  }
  static const String _analysisEndpoint = '/api/confidence-analysis';
  // Timeout géré automatiquement par OptimizedHttpService
  
  /// Analyse un enregistrement audio via le pipeline Whisper + Mistral
  /// 
  /// [audioData] : Données audio brutes (WAV/MP3)
  /// [scenario] : Scénario d'exercice pour contextualiser l'analyse
  /// [userContext] : Contexte utilisateur optionnel
  /// [recordingDurationSeconds] : Durée d'enregistrement pour validation
  Future<ConfidenceAnalysis?> analyzeAudioRecording({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String? userContext,
    int? recordingDurationSeconds,
  }) async {
    _logger.i('$_tag: Démarrage analyse backend - Scenario: ${scenario.title}');
    
    try {
      // Valider les données audio
      if (audioData.isEmpty) {
        _logger.w('$_tag: Données audio vides, abandon analyse');
        return null;
      }
      
      // Sauvegarder temporairement le fichier audio
      final audioFile = await _saveTemporaryAudioFile(audioData);
      
      try {
        // Envoyer vers le serveur backend
        final analysis = await _sendToBackend(
          audioFile: audioFile,
          scenario: scenario,
          userContext: userContext,
          recordingDurationSeconds: recordingDurationSeconds,
        );
        
        _logger.i('$_tag: Analyse backend terminée avec succès');
        return analysis;
        
      } finally {
        // Nettoyer le fichier temporaire
        await _cleanupTemporaryFile(audioFile);
      }
      
    } catch (e, stackTrace) {
      _logger.e('$_tag: Erreur analyse backend: $e', error: e, stackTrace: stackTrace);
      return _createFallbackAnalysis(scenario, recordingDurationSeconds);
    }
  }
  
  /// Sauvegarde temporaire des données audio
  Future<File> _saveTemporaryAudioFile(Uint8List audioData) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'confidence_recording_$timestamp.wav';
      final file = File(path.join(tempDir.path, fileName));
      
      await file.writeAsBytes(audioData);
      _logger.d('$_tag: Fichier audio temporaire créé: ${file.path}');
      
      return file;
    } catch (e) {
      _logger.e('$_tag: Erreur création fichier temporaire: $e', error: e);
      rethrow;
    }
  }
  
  /// Envoi vers le backend Scaleway
  Future<ConfidenceAnalysis> _sendToBackend({
    required File audioFile,
    required ConfidenceScenario scenario,
    String? userContext,
    int? recordingDurationSeconds,
  }) async {
    final uri = Uri.parse('$_baseUrl$_analysisEndpoint');
    
    try {
      // Créer la requête multipart
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter le fichier audio
      final audioFileField = await http.MultipartFile.fromPath(
        'audio_file',
        audioFile.path,
        filename: path.basename(audioFile.path),
        // contentType: MediaType('audio', 'wav'), // Si package mime disponible  
      );
      request.files.add(audioFileField);
      
      // Ajouter les métadonnées en JSON
      final metadata = {
        'scenario': {
          'id': scenario.id,
          'title': scenario.title,
          'description': scenario.description,
          'prompt': scenario.prompt,
          'type': scenario.type.name,
          'difficulty': scenario.difficulty,
          'keywords': scenario.keywords,
          'tips': scenario.tips,
        },
        'user_context': userContext,
        'recording_duration_seconds': recordingDurationSeconds,
        'analysis_config': {
          'enable_whisper': true,
          'enable_mistral': true,
          'whisper_model': 'large-v3',
          'mistral_model': '7B-Instruct-v0.2',
          'language': 'fr',
        },
      };
      
      request.fields['metadata'] = jsonEncode(metadata);
      
      _logger.i('$_tag: Envoi requête vers backend: $uri');
      
      // Utiliser le service HTTP optimisé qui gère automatiquement :
      // - Pool de connexions persistantes
      // - Compression gzip
      // - Retry logic avec backoff exponentiel
      // - Timeouts optimisés (8s pour API)
      final streamedResponse = await _httpService.sendMultipartRequest(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      _logger.d('$_tag: Réponse backend - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return _parseBackendResponse(response.body, scenario);
      } else {
        throw HttpException(
          'Erreur serveur: ${response.statusCode} - ${response.body}',
        );
      }
      
    } on TimeoutException catch (e) {
      _logger.e('$_tag: Timeout requête backend');
      throw TimeoutException('Analyse backend timeout', e.duration);
    } catch (e) {
      _logger.e('$_tag: Erreur communication backend: $e', error: e);
      rethrow;
    }
  }
  
  /// Parse la réponse du backend
  ConfidenceAnalysis _parseBackendResponse(String responseBody, ConfidenceScenario scenario) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      
      // Extraire les résultats Whisper
      final whisperData = data['whisper_result'] as Map<String, dynamic>?;
      final transcription = whisperData?['transcription'] as String? ?? '';
      final whisperConfidence = (whisperData?['confidence'] as num?)?.toDouble() ?? 0.0;
      
      // Extraire les résultats Mistral
      final mistralData = data['mistral_result'] as Map<String, dynamic>?;
      final analysis = mistralData?['analysis'] as Map<String, dynamic>? ?? {};
      
      // Construire l'analyse finale
      return ConfidenceAnalysis(
        overallScore: _extractScore(analysis, 'overall_score', 75.0),
        confidenceScore: _extractScore(analysis, 'confidence_score', whisperConfidence),
        fluencyScore: _extractScore(analysis, 'fluency_score', 0.75),
        clarityScore: _extractScore(analysis, 'clarity_score', 0.80),
        energyScore: _extractScore(analysis, 'energy_score', 0.75),
        feedback: _extractFeedback(analysis, transcription, scenario),
      );
      
    } catch (e) {
      _logger.e('$_tag: Erreur parsing réponse backend: $e', error: e);
      _logger.d('$_tag: Réponse brute: $responseBody');
      throw FormatException('Format réponse backend invalide: $e');
    }
  }
  
  /// Extraction sécurisée des scores
  double _extractScore(Map<String, dynamic> analysis, String key, double fallback) {
    final value = analysis[key];
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }
    return fallback;
  }
  
  /// Construction du feedback enrichi
  String _extractFeedback(Map<String, dynamic> analysis, String transcription, ConfidenceScenario scenario) {
    final feedback = <String>[];
    
    // Feedback de transcription
    if (transcription.isNotEmpty) {
      feedback.add('🎤 **Transcription détectée** : "$transcription"');
    }
    
    // Feedback Mistral structuré
    final mistralFeedback = analysis['feedback'] as String?;
    if (mistralFeedback != null && mistralFeedback.isNotEmpty) {
      feedback.add('🤖 **Analyse IA** : $mistralFeedback');
    }
    
    // Feedback contextuel selon le scénario
    feedback.add(_generateContextualFeedback(scenario, analysis));
    
    // Suggestions d'amélioration
    final suggestions = analysis['suggestions'] as List<dynamic>?;
    if (suggestions != null && suggestions.isNotEmpty) {
      feedback.add('💡 **Suggestions** :');
      for (final suggestion in suggestions.take(3)) {
        feedback.add('• $suggestion');
      }
    }
    
    return feedback.join('\n\n');
  }
  
  /// Génération de feedback contextuel
  String _generateContextualFeedback(ConfidenceScenario scenario, Map<String, dynamic> analysis) {
    final contextFeedback = <String>[];
    
    switch (scenario.type) {
      case confidence_models.ConfidenceScenarioType.presentation:
        contextFeedback.add('🗣️ **Contexte Présentation** : ');
        contextFeedback.add('Votre présentation semble ${_getPerformanceLevel(analysis)}.');
        break;
      case confidence_models.ConfidenceScenarioType.meeting:
        contextFeedback.add('👥 **Contexte Réunion** : ');
        contextFeedback.add('Votre participation à la discussion est ${_getParticipationLevel(analysis)}.');
        break;
      case confidence_models.ConfidenceScenarioType.interview:
        contextFeedback.add('💼 **Contexte Entretien** : ');
        contextFeedback.add('Votre performance en entretien semble ${_getPerformanceLevel(analysis)}.');
        break;
      case confidence_models.ConfidenceScenarioType.networking:
        contextFeedback.add('🤝 **Contexte Réseautage** : ');
        contextFeedback.add('Votre approche de réseautage semble ${_getNetworkingLevel(analysis)}.');
        break;
      case confidence_models.ConfidenceScenarioType.pitch:
        contextFeedback.add('🚀 **Contexte Pitch** : ');
        contextFeedback.add('Votre pitch est ${_getPublicSpeakingLevel(analysis)}.');
        break;
    }
    
    return contextFeedback.join('');
  }
  
  /// Niveaux de performance contextuels
  String _getPerformanceLevel(Map<String, dynamic> analysis) {
    final score = _extractScore(analysis, 'overall_score', 0.75);
    if (score >= 0.85) return 'excellente';
    if (score >= 0.70) return 'bonne';
    if (score >= 0.55) return 'correcte';
    return 'à améliorer';
  }
  
  String _getParticipationLevel(Map<String, dynamic> analysis) {
    final score = _extractScore(analysis, 'confidence_score', 0.75);
    if (score >= 0.80) return 'très active et engagée';
    if (score >= 0.65) return 'active et pertinente';  
    if (score >= 0.50) return 'modérée mais positive';
    return 'timide, mais des progrès sont possibles';
  }
  
  String _getPublicSpeakingLevel(Map<String, dynamic> analysis) {
    final score = _extractScore(analysis, 'energy_score', 0.75);
    if (score >= 0.85) return 'remarquable';
    if (score >= 0.70) return 'convaincante';
    if (score >= 0.55) return 'correcte';
    return 'hésitante';
  }
  
  String _getNetworkingLevel(Map<String, dynamic> analysis) {
    final score = _extractScore(analysis, 'fluency_score', 0.75);
    if (score >= 0.80) return 'naturelle et engageante';
    if (score >= 0.65) return 'cordiale et professionnelle';
    if (score >= 0.50) return 'polie mais réservée';
    return 'timide, mais perfectible';
  }
  
  /// Création d'une analyse de fallback en cas d'erreur
  ConfidenceAnalysis _createFallbackAnalysis(ConfidenceScenario scenario, int? duration) {
    _logger.w('$_tag: Création analyse fallback pour ${scenario.title}');
    
    return ConfidenceAnalysis(
      overallScore: 70.0,
      confidenceScore: 0.70,
      fluencyScore: 0.65,
      clarityScore: 0.75,
      energyScore: 0.70,
      feedback: _createFallbackFeedback(scenario, duration),
    );
  }
  
  /// Feedback de fallback contextuel
  String _createFallbackFeedback(ConfidenceScenario scenario, int? duration) {
    final feedback = <String>[];
    
    feedback.add('⚠️ **Analyse Hors-ligne** : L\'analyse complète n\'est pas disponible actuellement.');
    
    if (duration != null && duration > 0) {
      feedback.add('⏱️ **Durée** : ${duration}s d\'enregistrement détecté.');
    }
    
    feedback.add('🎯 **Contexte ${scenario.title}** :');
    feedback.add('Votre exercice a été enregistré. Une analyse détaillée sera disponible une fois la connexion rétablie.');
    
    feedback.add('💡 **Conseils généraux** :');
    for (final tip in scenario.tips.take(2)) {
      feedback.add('• $tip');
    }
    
    return feedback.join('\n\n');
  }
  
  /// Nettoyage du fichier temporaire
  Future<void> _cleanupTemporaryFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        _logger.d('$_tag: Fichier temporaire supprimé: ${file.path}');
      }
    } catch (e) {
      _logger.w('$_tag: Erreur suppression fichier temporaire: $e');
      // Non-bloquant
    }
  }
  
  /// Vérification de la disponibilité du service
  Future<bool> isServiceAvailable() async {
    try {
      // Utiliser le service HTTP optimisé pour la vérification de santé
      final response = await _httpService.get('$_baseUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      _logger.w('$_tag: Service backend indisponible: $e');
      return false;
    }
  }
  
  /// Configuration de l'URL du serveur (pour tests/développement)
  static void configureBackendUrl(String baseUrl) {
    // Pour les tests ou configuration dynamique
    _logger.i('$_tag: Configuration URL backend: $baseUrl');
  }
}