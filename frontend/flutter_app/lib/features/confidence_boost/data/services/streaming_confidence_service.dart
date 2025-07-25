import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart'; // Pour AppConfig.apiBaseUrl

/// Représente le résultat du stream de confiance (partiel ou final)
class ConfidenceStreamResult {
  final String type; // "partial_transcription" ou "final_result"
  final String? text; // Pour partial_transcription
  final String? transcription; // Pour final_result
  final String? aiResponse; // Pour final_result
  final double? confidenceScore;
  final Map<String, dynamic>? metrics; // Utiliser dynamic pour les valeurs

  ConfidenceStreamResult({
    required this.type,
    this.text,
    this.transcription,
    this.aiResponse,
    this.confidenceScore,
    this.metrics,
  });

  factory ConfidenceStreamResult.fromJson(Map<String, dynamic> json) {
    return ConfidenceStreamResult(
      type: json['type'] as String,
      text: json['text'] as String?,
      transcription: json['transcription'] as String?,
      aiResponse: json['ai_response'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'ConfidenceStreamResult(type: $type, text: $text, transcription: $transcription, aiResponse: $aiResponse, confidenceScore: $confidenceScore, metrics: $metrics)';
  }
}

/// Service pour gérer le streaming audio via WebSocket et recevoir les résultats d'analyse
class StreamingConfidenceService {
  WebSocketChannel? _channel;
  final StreamController<ConfidenceStreamResult> _resultController =
      StreamController<ConfidenceStreamResult>.broadcast();

  /// Stream public pour écouter les résultats de l'API de streaming
  Stream<ConfidenceStreamResult> get results => _resultController.stream;

  // Nouvelle propriété pour exposer le StreamSink du WebSocket
  StreamSink<Uint8List>? get audioSink => _channel?.sink as StreamSink<Uint8List>?;

  /// Démarre la connexion WebSocket
  Future<void> startStreaming(String sessionId) async {
    // Utiliser AppConfig.apiBaseUrl et remplacer http/https par ws/wss
    final baseUri = Uri.parse(AppConfig.apiBaseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final uri = Uri.parse('$wsScheme://${baseUri.host}:${baseUri.port}/ws/confidence-stream/$sessionId');

    debugPrint('📡 Connexion WebSocket à: $uri');
    
    try {
      _channel = WebSocketChannel.connect(uri);

      // Écouter les réponses du serveur
      _channel!.stream.listen(
        (data) {
          if (kDebugMode) {
            debugPrint('📝 Données brutes reçues via WebSocket: $data');
          }
          try {
            final result = ConfidenceStreamResult.fromJson(jsonDecode(data));
            _resultController.add(result);
            if (kDebugMode) {
              debugPrint('✅ Résultat WebSocket traité: $result');
            }
          } catch (e) {
            debugPrint('❌ Erreur de parsing JSON WebSocket: $e, Données: $data');
          }
        },
        onError: (error) {
          debugPrint('❌ Erreur WebSocket: $error');
          _resultController.addError(error);
        },
        onDone: () {
          debugPrint('🛑 WebSocket fermé');
          _channel = null;
          if (!_resultController.isClosed) {
            //_resultController.close(); // Fermer le controller uniquement quand on n'en a plus besoin
          }
        },
        cancelOnError: true
      ); // Annule l'abonscription en cas d'erreur
      
      debugPrint('✅ WebSocket connecté pour session: $sessionId');

    } catch (e) {
      debugPrint('❌ Échec de la connexion WebSocket: $e');
      _resultController.addError('Échec de la connexion au service de streaming: $e');
      rethrow;
    }
  }

  /// Ancien sendAudioChunk devenu inutile avec l'exposition de audioSink
  /// Maintenu pour compatibilité si d'autres parties du code l'appellent directement
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (_channel != null && _channel!.sink != null) {
      if (kDebugMode) {
        debugPrint('📤 Envoi chunk audio via sendAudioChunk dépraecié (${audioData.length} bytes)');
      }
      _channel!.sink.add(audioData);
    } else {
      debugPrint('⚠️ WebSocket non connecté, impossible d\'envoyer le chunk audio.');
    }
  }
  
  /// Arrête le streaming et ferme le WebSocket
  Future<void> stopStreaming() async {
    debugPrint('⏳ Fermeture du WebSocket...');
    await _channel?.sink.close();
    _channel = null;
    debugPrint('🛑 WebSocket fermé.');
    // Ne ferme pas le controller ici car il peut être réutilisé pour de nouvelles sessions
    // ou si l'on veut continuer à écouter après la fermeture du canal.
  }

  /// Nettoie les ressources (à appeler lors de la destruction de l'objet)
  void dispose() {
    _channel?.sink.close();
    _resultController.close();
    debugPrint('🗑️ Ressources StreamingConfidenceService libérées.');
  }
}