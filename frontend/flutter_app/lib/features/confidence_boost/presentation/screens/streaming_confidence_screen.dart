import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/streaming_confidence_service.dart'; // Notre nouveau service
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/unified_logger_service.dart';

// Provider pour le StreamingConfidenceService (optionnel, mais bonne pratique)
final streamingConfidenceServiceProvider = Provider((ref) => StreamingConfidenceService());

class StreamingConfidenceScreen extends ConsumerStatefulWidget {
  const StreamingConfidenceScreen({super.key});

  @override
  _StreamingConfidenceScreenState createState() => _StreamingConfidenceScreenState();
}

class _StreamingConfidenceScreenState extends ConsumerState<StreamingConfidenceScreen> {
  late final StreamingConfidenceService _streamingService;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  String _partialTranscription = "";
  String _finalTranscription = "";
  String _aiResponse = "";
  bool _isRecording = false;
  String _sessionId = ""; // Pour stocker l'ID de session

  @override
  void initState() {
    super.initState();
    _streamingService = ref.read(streamingConfidenceServiceProvider);
    _initializeStreaming();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _streamingService.dispose(); // Libérer les ressources du service de streaming
    super.dispose();
  }
  
  Future<void> _initializeStreaming() async {
    // Demander la permission d'utiliser le microphone
    // Demander la permission d'utiliser le microphone
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      UnifiedLoggerService.error("Permission microphone non accordée.");
      setState(() {
        _partialTranscription = "Permission microphone nécessaire pour enregistrer.";
      });
      return;
    }

    try {
      await _recorder.openRecorder();
      UnifiedLoggerService.info("Enregistreur audio ouvert.");
    } catch (e) {
      UnifiedLoggerService.error("Erreur ouverture enregistreur: $e");
      setState(() {
        _partialTranscription = "Erreur d'initialisation de l'enregistreur: $e";
      });
      return;
    }
    
    _streamingService.results.listen((result) {
      setState(() {
        if (result.type == "partial_transcription") {
          _partialTranscription = result.text ?? "";
        } else if (result.type == "final_result") {
          _finalTranscription = result.transcription ?? "";
          _aiResponse = result.aiResponse ?? "";
          _partialTranscription = "";
          UnifiedLoggerService.info("Résultat final reçu: ${result.transcription}, AI: ${result.aiResponse}");
        }
      });
    }, onError: (e) {
      UnifiedLoggerService.error("Erreur de stream WebSocket: $e");
      setState(() {
        _aiResponse = "Erreur de connexion : $e";
        _isRecording = false;
      });
      _stopRecording();
    });
  }
  
  Future<void> _startRecording() async {
    _sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
    UnifiedLoggerService.info("Démarrage de l'enregistrement, session: $_sessionId");

    setState(() {
      _partialTranscription = "";
      _finalTranscription = "";
      _aiResponse = "";
      _isRecording = true;
    });

    try {
      await _streamingService.startStreaming(_sessionId);
      
      await _recorder.startRecorder(
        toStream: _streamingService.audioSink!, // Forcer non-nul
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
      );
      UnifiedLoggerService.info("Enregistrement démarré vers le stream.");
    } catch (e) {
      UnifiedLoggerService.error("Erreur au démarrage de l'enregistrement ou du streaming: $e");
      setState(() {
        _aiResponse = "Erreur au démarrage: $e";
        _isRecording = false;
      });
      await _stopRecording();
    }
  }
  
  Future<void> _stopRecording() async {
    UnifiedLoggerService.info("Arrêt de l'enregistrement.");
    await _recorder.stopRecorder();
    await _streamingService.stopStreaming();
    
    setState(() {
      _isRecording = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Boost Confidence - Streaming")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Transcription temps réel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Transcription temps réel:", 
                       style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_partialTranscription, 
                       style: TextStyle(color: Colors.blue.shade700)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Transcription finale
            if (_finalTranscription.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Vous avez dit:", 
                         style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_finalTranscription),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Réponse IA
            if (_aiResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Coach Marie:", 
                         style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_aiResponse),
                  ],
                ),
              ),
            
            const Spacer(),
            
            // Bouton enregistrement
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20), // Espace sous le bouton
          ],
        ),
      ),
    );
  }
}