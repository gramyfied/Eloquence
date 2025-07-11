import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'prosody_analysis_interface.dart';
import '../../../../core/utils/logger.dart';

/// Service d'intégration avec le système d'évaluation Whisper temps réel
///
/// Ce service communique avec le backend whisper-realtime sur le port 8006 pour :
/// - Analyse Whisper large-v3-turbo pour la transcription précise
/// - Évaluation temps réel via WebSocket
/// - Métriques prosodiques avancées et recommandations personnalisées
class HybridSpeechEvaluationService implements ProsodyAnalysisInterface {
  static const String _tag = 'HybridSpeechEvaluationService';
  static final Logger _logger = Logger();

  // Configuration par défaut du service
  late String _baseUrl;
  late String _websocketUrl;
  late Duration _timeout;
  
  // État des connexions
  WebSocketChannel? _websocketChannel;
  StreamController<Map<String, dynamic>>? _realtimeController;
  bool _isConnected = false;

  HybridSpeechEvaluationService({
    String baseUrl = 'http://192.168.1.44:8006',
    Duration timeout = const Duration(seconds: 45),  // Augmenté pour Whisper processing
  }) {
    _baseUrl = baseUrl;
    _websocketUrl = baseUrl.replaceFirst('http', 'ws');
    _timeout = timeout;
    _realtimeController = StreamController<Map<String, dynamic>>.broadcast();
  }

  /// Stream pour les mises à jour temps réel VOSK
  Stream<Map<String, dynamic>> get realtimeUpdates => _realtimeController!.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      final isHealthy = response.statusCode == 200;
      _logger.i('$_tag: Service whisper-realtime ${isHealthy ? "disponible" : "indisponible"}');
      return isHealthy;
    } catch (e) {
      _logger.w('$_tag: Erreur vérification service whisper-realtime: $e');
      return false;
    }
  }

  @override
  void configure({
    required String voskServerUrl,
    Map<String, String>? modelPaths,
    Duration? timeout,
  }) {
    _baseUrl = voskServerUrl;
    _websocketUrl = voskServerUrl.replaceFirst('http', 'ws');
    if (timeout != null) _timeout = timeout;
    _logger.i('$_tag: Service configuré pour $voskServerUrl');
  }

  @override
  Future<ProsodyAnalysisResult?> analyzeProsody({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String language = 'fr',
  }) async {
    _logger.i('$_tag: Démarrage analyse Whisper temps réel pour ${scenario.title}');
    
    try {
      // Créer une requête multipart pour envoyer le fichier audio
      final uri = Uri.parse('$_baseUrl/evaluate/final');
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter le fichier audio en tant que multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',  // nom du champ attendu par le service
          audioData,
          filename: 'audio_sample.wav',
        ),
      );
      
      // Ajouter les métadonnées du scénario comme champs de formulaire
      request.fields['scenario_title'] = scenario.title;
      request.fields['scenario_description'] = scenario.description;
      request.fields['scenario_difficulty'] = scenario.difficulty;
      request.fields['scenario_keywords'] = scenario.keywords.join(',');
      request.fields['language'] = language;
      
      // Envoyer la requête multipart
      final streamResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = _parseWhisperAnalysisResult(data);
        _logger.i('$_tag: ✅ Analyse Whisper temps réel complétée avec succès');
        return result;
      } else {
        _logger.w('$_tag: ⚠️ Échec analyse Whisper, code: ${response.statusCode}, body: ${response.body}');
        return null;
      }
      
    } catch (e) {
      _logger.e('$_tag: ❌ Erreur analyse prosodique Whisper: $e', error: e);
      return null;
    }
  }

  /// Démarrer une session d'évaluation temps réel
  Future<String?> startRealtimeEvaluation({
    required ConfidenceScenario scenario,
    String language = 'fr',
  }) async {
    try {
      final sessionId = await _createEvaluationSession(scenario, language);
      if (sessionId == null) return null;

      // Établir la connexion WebSocket pour le feedback temps réel
      await _connectWebSocket(sessionId);
      
      _logger.i('$_tag: Session temps réel démarrée: $sessionId');
      return sessionId;
    } catch (e) {
      _logger.e('$_tag: Erreur démarrage session temps réel: $e');
      return null;
    }
  }

  /// Envoyer des données audio en temps réel
  Future<void> sendRealtimeAudio(Uint8List audioChunk) async {
    if (_websocketChannel != null && _isConnected) {
      try {
        final audioBase64 = base64Encode(audioChunk);
        final message = json.encode({
          'type': 'audio_data',
          'data': audioBase64,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        _websocketChannel!.sink.add(message);
      } catch (e) {
        _logger.w('$_tag: Erreur envoi audio temps réel: $e');
      }
    }
  }

  /// Terminer une session d'évaluation
  Future<ProsodyAnalysisResult?> finishRealtimeEvaluation(String sessionId) async {
    try {
      // Envoyer signal de fin
      if (_websocketChannel != null && _isConnected) {
        final message = json.encode({
          'type': 'session_end',
          'session_id': sessionId,
        });
        _websocketChannel!.sink.add(message);
      }

      // Récupérer les résultats finaux
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId/results'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = _parseWhisperAnalysisResult(data);
        
        // Fermer la connexion WebSocket
        await _disconnectWebSocket();
        
        _logger.i('$_tag: Session terminée avec succès: $sessionId');
        return result;
      } else {
        _logger.w('$_tag: Erreur récupération résultats: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('$_tag: Erreur fin de session: $e');
      await _disconnectWebSocket();
      return null;
    }
  }

  // === IMPLÉMENTATIONS D'ANALYSES SPÉCIFIQUES ===

  @override
  Future<SpeechRateAnalysis?> analyzeSpeechRate(Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/speech-rate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language': 'fr',
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSpeechRateAnalysis(data);
      }
    } catch (e) {
      _logger.w('$_tag: Erreur analyse débit: $e');
    }
    return null;
  }

  @override
  Future<IntonationAnalysis?> analyzeIntonation(Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/intonation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language': 'fr',
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseIntonationAnalysis(data);
      }
    } catch (e) {
      _logger.w('$_tag: Erreur analyse intonation: $e');
    }
    return null;
  }

  @override
  Future<PauseAnalysis?> analyzePauses(Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/pauses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language': 'fr',
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePauseAnalysis(data);
      }
    } catch (e) {
      _logger.w('$_tag: Erreur analyse pauses: $e');
    }
    return null;
  }

  @override
  Future<EnergyAnalysis?> analyzeVocalEnergy(Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/energy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language': 'fr',
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseEnergyAnalysis(data);
      }
    } catch (e) {
      _logger.w('$_tag: Erreur analyse énergie: $e');
    }
    return null;
  }

  @override
  Future<DisfluencyAnalysis?> analyzeDisfluencies(Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/disfluencies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'language': 'fr',
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisfluencyAnalysis(data);
      }
    } catch (e) {
      _logger.w('$_tag: Erreur analyse disfluences: $e');
    }
    return null;
  }

  // === MÉTHODES PRIVÉES ===

  Future<String?> _createEvaluationSession(ConfidenceScenario scenario, String language) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'scenario': {
            'id': scenario.id,
            'title': scenario.title,
            'description': scenario.description,
            'difficulty': scenario.difficulty,
            'keywords': scenario.keywords,
          },
          'language': language,
          'real_time': true,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['session_id'] as String?;
      }
    } catch (e) {
      _logger.e('$_tag: Erreur création session: $e');
    }
    return null;
  }

  Future<ProsodyAnalysisResult?> _performHybridAnalysis(
    String sessionId, 
    Uint8List audioData, 
    ConfidenceScenario scenario
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'session_id': sessionId,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWhisperAnalysisResult(data);
      }
    } catch (e) {
      _logger.e('$_tag: Erreur analyse hybride: $e');
    }
    return null;
  }

  Future<void> _connectWebSocket(String sessionId) async {
    try {
      _websocketChannel = WebSocketChannel.connect(
        Uri.parse('$_websocketUrl/sessions/$sessionId/realtime'),
      );
      
      _websocketChannel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data);
            _realtimeController!.add(message);
          } catch (e) {
            _logger.w('$_tag: Erreur décodage message WebSocket: $e');
          }
        },
        onError: (error) {
          _logger.w('$_tag: Erreur WebSocket: $error');
          _isConnected = false;
        },
        onDone: () {
          _logger.i('$_tag: Connexion WebSocket fermée');
          _isConnected = false;
        },
      );
      
      _isConnected = true;
      _logger.i('$_tag: WebSocket connecté pour session $sessionId');
    } catch (e) {
      _logger.e('$_tag: Erreur connexion WebSocket: $e');
      _isConnected = false;
    }
  }

  Future<void> _disconnectWebSocket() async {
    if (_websocketChannel != null) {
      await _websocketChannel!.sink.close();
      _websocketChannel = null;
    }
    _isConnected = false;
  }

  // === PARSERS POUR LES RÉSULTATS ===

  ProsodyAnalysisResult _parseWhisperAnalysisResult(Map<String, dynamic> data) {
    // Parser pour les résultats du service whisper-realtime
    final evaluation = data['evaluation'] as Map<String, dynamic>? ?? {};
    final metrics = evaluation['metrics'] as Map<String, dynamic>? ?? {};
    
    return ProsodyAnalysisResult(
      overallProsodyScore: evaluation['overall_score']?.toDouble() ?? 75.0,
      speechRate: _parseSpeechRateFromWhisper(metrics),
      intonation: _parseIntonationFromWhisper(metrics),
      pauses: _parsePauseFromWhisper(metrics),
      energy: _parseEnergyFromWhisper(metrics),
      disfluency: _parseDisfluencyFromWhisper(metrics),
      detailedFeedback: evaluation['feedback'] ?? data['detailed_feedback'] ?? 'Analyse Whisper complétée',
      analysisTimestamp: DateTime.now(),
    );
  }

  // Parsers adaptés pour le format whisper-realtime
  SpeechRateAnalysis _parseSpeechRateFromWhisper(Map<String, dynamic> metrics) {
    final speechRate = metrics['speech_rate'] as Map<String, dynamic>? ?? {};
    return SpeechRateAnalysis(
      wordsPerMinute: speechRate['words_per_minute']?.toDouble() ?? 120.0,
      syllablesPerSecond: speechRate['syllables_per_second']?.toDouble() ?? 2.0,
      fluencyScore: speechRate['fluency_score']?.toDouble() ?? 0.75,
      feedback: speechRate['feedback'] ?? 'Débit de parole approprié',
      category: SpeechRateCategory.optimal,
    );
  }

  IntonationAnalysis _parseIntonationFromWhisper(Map<String, dynamic> metrics) {
    final intonation = metrics['intonation'] as Map<String, dynamic>? ?? {};
    return IntonationAnalysis(
      f0Mean: intonation['f0_mean']?.toDouble() ?? 150.0,
      f0Std: intonation['f0_std']?.toDouble() ?? 25.0,
      f0Range: intonation['f0_range']?.toDouble() ?? 100.0,
      clarityScore: intonation['clarity_score']?.toDouble() ?? 0.78,
      feedback: intonation['feedback'] ?? 'Intonation naturelle détectée',
      pattern: IntonationPattern.natural,
    );
  }

  PauseAnalysis _parsePauseFromWhisper(Map<String, dynamic> metrics) {
    final pauses = metrics['pauses'] as Map<String, dynamic>? ?? {};
    return PauseAnalysis(
      totalPauses: pauses['total_pauses'] ?? 3,
      averagePauseDuration: pauses['average_duration']?.toDouble() ?? 0.8,
      pauseRate: pauses['pause_rate']?.toDouble() ?? 0.15,
      rhythmScore: pauses['rhythm_score']?.toDouble() ?? 0.72,
      feedback: pauses['feedback'] ?? 'Rythme bien contrôlé',
      pauseSegments: [],
    );
  }

  EnergyAnalysis _parseEnergyFromWhisper(Map<String, dynamic> metrics) {
    final energy = metrics['energy'] as Map<String, dynamic>? ?? {};
    return EnergyAnalysis(
      averageEnergy: energy['average_energy']?.toDouble() ?? 0.65,
      energyVariance: energy['energy_variance']?.toDouble() ?? 0.12,
      normalizedEnergyScore: energy['normalized_score']?.toDouble() ?? 0.73,
      feedback: energy['feedback'] ?? 'Énergie vocale équilibrée',
      profile: EnergyProfile.balanced,
    );
  }

  DisfluencyAnalysis _parseDisfluencyFromWhisper(Map<String, dynamic> metrics) {
    final disfluency = metrics['disfluency'] as Map<String, dynamic>? ?? {};
    return DisfluencyAnalysis(
      hesitationCount: disfluency['hesitation_count'] ?? 1,
      fillerWordsCount: disfluency['filler_words_count'] ?? 2,
      repetitionCount: disfluency['repetition_count'] ?? 0,
      severityScore: disfluency['severity_score']?.toDouble() ?? 0.15,
      feedback: disfluency['feedback'] ?? 'Quelques hésitations normales',
      events: [],
    );
  }

  SpeechRateAnalysis _parseSpeechRateAnalysis(Map<String, dynamic> data) {
    return SpeechRateAnalysis(
      wordsPerMinute: data['words_per_minute']?.toDouble() ?? 0.0,
      syllablesPerSecond: data['syllables_per_second']?.toDouble() ?? 0.0,
      fluencyScore: data['fluency_score']?.toDouble() ?? 0.0,
      feedback: data['feedback'] ?? '',
      category: _parseSpeechRateCategory(data['category']),
    );
  }

  IntonationAnalysis _parseIntonationAnalysis(Map<String, dynamic> data) {
    return IntonationAnalysis(
      f0Mean: data['f0_mean']?.toDouble() ?? 0.0,
      f0Std: data['f0_std']?.toDouble() ?? 0.0,
      f0Range: data['f0_range']?.toDouble() ?? 0.0,
      clarityScore: data['clarity_score']?.toDouble() ?? 0.0,
      feedback: data['feedback'] ?? '',
      pattern: _parseIntonationPattern(data['pattern']),
    );
  }

  PauseAnalysis _parsePauseAnalysis(Map<String, dynamic> data) {
    final pauseSegments = (data['pause_segments'] as List?)
        ?.map((segment) => PauseSegment(
              startTime: segment['start_time']?.toDouble() ?? 0.0,
              duration: segment['duration']?.toDouble() ?? 0.0,
              type: _parsePauseType(segment['type']),
            ))
        .toList() ?? [];

    return PauseAnalysis(
      totalPauses: data['total_pauses'] ?? 0,
      averagePauseDuration: data['average_pause_duration']?.toDouble() ?? 0.0,
      pauseRate: data['pause_rate']?.toDouble() ?? 0.0,
      rhythmScore: data['rhythm_score']?.toDouble() ?? 0.0,
      feedback: data['feedback'] ?? '',
      pauseSegments: pauseSegments,
    );
  }

  EnergyAnalysis _parseEnergyAnalysis(Map<String, dynamic> data) {
    return EnergyAnalysis(
      averageEnergy: data['average_energy']?.toDouble() ?? 0.0,
      energyVariance: data['energy_variance']?.toDouble() ?? 0.0,
      normalizedEnergyScore: data['normalized_energy_score']?.toDouble() ?? 0.0,
      feedback: data['feedback'] ?? '',
      profile: _parseEnergyProfile(data['profile']),
    );
  }

  DisfluencyAnalysis _parseDisfluencyAnalysis(Map<String, dynamic> data) {
    final events = (data['events'] as List?)
        ?.map((event) => DisfluencyEvent(
              timestamp: event['timestamp']?.toDouble() ?? 0.0,
              type: _parseDisfluencyType(event['type']),
              detectedText: event['detected_text'] ?? '',
            ))
        .toList() ?? [];

    return DisfluencyAnalysis(
      hesitationCount: data['hesitation_count'] ?? 0,
      fillerWordsCount: data['filler_words_count'] ?? 0,
      repetitionCount: data['repetition_count'] ?? 0,
      severityScore: data['severity_score']?.toDouble() ?? 0.0,
      feedback: data['feedback'] ?? '',
      events: events,
    );
  }

  // === PARSERS D'ÉNUMÉRATIONS ===

  SpeechRateCategory _parseSpeechRateCategory(String? category) {
    switch (category) {
      case 'too_slow': return SpeechRateCategory.tooSlow;
      case 'too_fast': return SpeechRateCategory.tooFast;
      default: return SpeechRateCategory.optimal;
    }
  }

  IntonationPattern _parseIntonationPattern(String? pattern) {
    switch (pattern) {
      case 'monotone': return IntonationPattern.monotone;
      case 'exaggerated': return IntonationPattern.exaggerated;
      case 'irregular': return IntonationPattern.irregular;
      default: return IntonationPattern.natural;
    }
  }

  PauseType _parsePauseType(String? type) {
    switch (type) {
      case 'hesitation': return PauseType.hesitation;
      case 'breath': return PauseType.breath;
      case 'long': return PauseType.long;
      default: return PauseType.natural;
    }
  }

  EnergyProfile _parseEnergyProfile(String? profile) {
    switch (profile) {
      case 'too_low': return EnergyProfile.tooLow;
      case 'too_high': return EnergyProfile.tooHigh;
      case 'inconsistent': return EnergyProfile.inconsistent;
      default: return EnergyProfile.balanced;
    }
  }

  DisfluencyType _parseDisfluencyType(String? type) {
    switch (type) {
      case 'filler_word': return DisfluencyType.fillerWord;
      case 'repetition': return DisfluencyType.repetition;
      case 'restart': return DisfluencyType.restart;
      case 'correction': return DisfluencyType.correction;
      default: return DisfluencyType.hesitation;
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _disconnectWebSocket();
    _realtimeController?.close();
    _logger.i('$_tag: Service nettoyé');
  }
}