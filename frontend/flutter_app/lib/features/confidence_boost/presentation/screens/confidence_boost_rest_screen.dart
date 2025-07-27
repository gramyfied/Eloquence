import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/api_models.dart';
import '../../data/services/confidence_api_service.dart';

/// 🚀 ÉCRAN BOOST CONFIDENCE REST SIMPLIFIÉ
/// 
/// Remplace l'écran complexe de 2318 lignes par une approche REST simple :
/// ✅ Flutter Sound pour enregistrement audio local
/// ✅ HTTP Upload vers backend 192.168.1.44:8000
/// ✅ Interface chat conversationnelle simple
/// ✅ Réponse IA directe par API REST
/// ✅ Optimisé mobile (≈300 lignes vs 2318)
class ConfidenceBoostRestScreen extends ConsumerStatefulWidget {
  final ConfidenceScenario scenario;

  const ConfidenceBoostRestScreen({
    Key? key,
    required this.scenario,
  }) : super(key: key);

  @override
  ConsumerState<ConfidenceBoostRestScreen> createState() => _ConfidenceBoostRestScreenState();
}

class _ConfidenceBoostRestScreenState extends ConsumerState<ConfidenceBoostRestScreen> {
  final Logger _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  
  // 🎤 AUDIO RECORDING avec Flutter Sound
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  
  // 💬 CONVERSATION
  List<ChatMessage> _messages = [];
  bool _isAIThinking = false;
  bool _isInitialized = false;
  
  // 🌐 API SERVICE  
  late ConfidenceApiService _apiService;
  ConfidenceSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recordingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🎯 INITIALISATION SIMPLE
  Future<void> _initializeScreen() async {
    try {
      _apiService = ConfidenceApiService();
      
      // Initialiser Flutter Sound
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      
      // Créer session
      _currentSession = await _apiService.createSession(
        scenarioId: widget.scenario.id,
        userId: 'user_mobile', // TODO: récupérer l'ID utilisateur réel
      );
      
      // Message de bienvenue
      _addMessage(ChatMessage(
        text: _getWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      setState(() => _isInitialized = true);
      _logger.i('✅ Écran REST initialisé avec session: ${_currentSession?.sessionId}');
      
    } catch (e) {
      _logger.e('❌ Erreur initialisation: $e');
      _addMessage(ChatMessage(
        text: 'Erreur de connexion. Vérifiez que le backend est accessible sur 192.168.1.44:8000',
        isUser: false,
        isError: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 🎤 DÉMARRER ENREGISTREMENT
  Future<void> _startRecording() async {
    try {
      // Vérifier permission microphone
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showError('Permission microphone refusée');
        return;
      }

      // Créer fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioPath = '${tempDir.path}/recording_$timestamp.wav';

      // Démarrer enregistrement
      await _recorder!.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Timer pour durée
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });

      _logger.i('🎤 Enregistrement démarré: $_audioPath');

    } catch (e) {
      _logger.e('❌ Erreur démarrage enregistrement: $e');
      _showError('Erreur enregistrement: $e');
    }
  }

  /// 🛑 ARRÊTER ENREGISTREMENT ET UPLOAD
  Future<void> _stopRecording() async {
    try {
      await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isAIThinking = true;
      });

      if (_audioPath != null && File(_audioPath!).existsSync()) {
        // Ajouter message utilisateur (placeholder)
        _addMessage(ChatMessage(
          text: '🎤 Enregistrement audio (${_recordingDuration.inSeconds}s)',
          isUser: true,
          timestamp: DateTime.now(),
        ));

        // Upload et analyse
        await _uploadAndAnalyze();
      }

    } catch (e) {
      _logger.e('❌ Erreur arrêt enregistrement: $e');
      _showError('Erreur arrêt enregistrement: $e');
      setState(() => _isAIThinking = false);
    }
  }

  /// 📤 UPLOAD AUDIO ET ANALYSE
  Future<void> _uploadAndAnalyze() async {
    try {
      if (_audioPath == null || _currentSession == null) return;

      final audioFile = File(_audioPath!);
      final audioBytes = await audioFile.readAsBytes();

      // Appel API confidence-analysis
      final result = await _apiService.analyzeAudio(
        sessionId: _currentSession!.sessionId,
        audioData: audioBytes,
      );

      // Ajouter réponse IA
      _addMessage(ChatMessage(
        text: result.aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        analysis: result,
      ));

      // Nettoyer fichier temporaire
      await audioFile.delete();
      _audioPath = null;

    } catch (e) {
      _logger.e('❌ Erreur upload/analyse: $e');
      _addMessage(ChatMessage(
        text: 'Erreur lors de l\'analyse. Le backend est-il accessible ?',
        isUser: false,
        isError: true,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() => _isAIThinking = false);
    }
  }

  /// 💬 AJOUTER MESSAGE
  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  /// 📜 SCROLL TO BOTTOM
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ⚠️ AFFICHER ERREUR
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 👋 MESSAGE DE BIENVENUE
  String _getWelcomeMessage() {
    switch (widget.scenario.type) {
      case ConfidenceScenarioType.presentation:
        return "Bonjour ! Je suis Marie, votre cliente. Présentez-moi votre proposition et commencez quand vous êtes prêt !";
      case ConfidenceScenarioType.interview:
        return "Bonjour ! Je suis Thomas, votre recruteur. Présentez-vous et expliquez pourquoi vous souhaitez rejoindre notre équipe.";
      default:
        return "Bonjour ! Commençons cet exercice Boost Confidence. Appuyez sur le microphone pour parler !";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Boost Confidence',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.scenario.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isInitialized 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ZONE CONVERSATION
                Expanded(child: _buildConversationArea()),
                
                // CONTRÔLES AUDIO
                _buildAudioControls(),
              ],
            ),
    );
  }

  /// 💬 ZONE CONVERSATION
  Widget _buildConversationArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1F2E),
        border: Border.all(color: const Color(0xFF2A3441)),
      ),
      child: Column(
        children: [
          // Header conversation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Color(0xFF2A3441),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF00D4FF),
                  radius: 16,
                  child: Icon(Icons.psychology, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Marie - IA Coach',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_isAIThinking) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF)),
                  ),
                ],
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
        ],
      ),
    );
  }

  /// 💬 BULLE MESSAGE
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: message.isError ? Colors.red : const Color(0xFF00D4FF),
              radius: 12,
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: message.isUser 
                    ? const Color(0xFF8B5CF6)
                    : (message.isError ? Colors.red.withOpacity(0.2) : const Color(0xFF2A3441)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (message.analysis != null) ...[
                    const SizedBox(height: 8),
                    _buildAnalysisPreview(message.analysis!),
                  ],
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF8B5CF6),
              radius: 12,
              child: Icon(Icons.person, color: Colors.white, size: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// 📊 APERÇU ANALYSE
  Widget _buildAnalysisPreview(ConfidenceAnalysisResult analysis) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF00D4FF).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Score: ${(analysis.confidenceScore * 100).toStringAsFixed(1)}/100',
            style: const TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (analysis.metrics.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: analysis.metrics.entries.take(3).map((entry) {
                return Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎤 CONTRÔLES AUDIO
  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Durée enregistrement
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.withOpacity(0.2),
              ),
              child: Text(
                '${_recordingDuration.inMinutes}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          
          // Bouton microphone principal
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [Colors.red, Colors.red.shade700]
                      : [const Color(0xFF00D4FF), const Color(0xFF0EA5E9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF00D4FF)).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          
          // Statut
          if (_isAIThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF00D4FF).withOpacity(0.2),
              ),
              child: const Text(
                'IA réfléchit...',
                style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// 📱 MODÈLE MESSAGE CHAT
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final ConfidenceAnalysisResult? analysis;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.analysis,
  });
}