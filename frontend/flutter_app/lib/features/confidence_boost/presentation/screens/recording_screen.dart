import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../../core/config/app_config.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/ai_character_models.dart';
import '../../data/services/conversation_manager.dart';
import '../providers/confidence_boost_provider.dart';
import '../widgets/conversation_chat_widget.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final ConfidenceScenario scenario;
  final TextSupport textSupport;
  final String sessionId;
  final Function(Duration) onRecordingComplete;

  const RecordingScreen({
    Key? key,
    required this.scenario,
    required this.textSupport,
    required this.sessionId,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'RecordingScreen';
  final Logger _logger = Logger();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  // Conversation
  final ConversationManager _conversationManager = ConversationManager();
  final List<ConversationMessage> _messages = [];
  final ScrollController _chatScrollController = ScrollController();
  bool _isConversationActive = false;
  bool _isAISpeaking = false;
  bool _isUserSpeaking = false;
  StreamSubscription<ConversationEvent>? _eventSubscription;
  StreamSubscription<TranscriptionSegment>? _transcriptionSubscription;
  StreamSubscription<ConversationMetrics>? _metricsSubscription;
  
  // Recording legacy
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  Uint8List? _audioData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeConversation();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    _chatScrollController.dispose();
    _eventSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _metricsSubscription?.cancel();
    _conversationManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.scenario.title,
          style: EloquenceTextStyles.headline2,
        ),
      ),
      body: Column(
        children: [
          // Section de conversation ou texte en haut
          Expanded(
            flex: 3,
            child: _isConversationActive
                ? ConversationChatWidget(
                    messages: _messages,
                    scrollController: _chatScrollController,
                    isAISpeaking: _isAISpeaking,
                    isUserSpeaking: _isUserSpeaking,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(EloquenceSpacing.lg),
                    child: _buildTextSupportDisplay(),
                  ),
          ),
          
          // Section des contrôles en bas (fixe)
          Container(
            padding: const EdgeInsets.all(EloquenceSpacing.lg),
            decoration: const BoxDecoration(
              color: EloquenceColors.navy,
              border: Border(
                top: BorderSide(
                  color: EloquenceColors.glassBackground,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer
                Text(
                  _formatDuration(_recordingDuration),
                  style: ConfidenceBoostTextStyles.timerDisplay,
                ),

                const SizedBox(height: EloquenceSpacing.md),

                // Waveform visualizer
                _buildWaveformVisualizer(),

                // Status d'analyse
                _buildAnalysisStatus(),

                const SizedBox(height: EloquenceSpacing.md),

                // Bouton d'enregistrement
                _buildRecordButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSupportDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EloquenceSpacing.lg),
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet, color: EloquenceColors.cyan, size: 20),
              const SizedBox(width: EloquenceSpacing.sm),
              Expanded(
                child: Text(
                  'Support : ${_getSupportTypeName(widget.textSupport.type)}',
                  style: EloquenceTextStyles.body1.copyWith(
                    color: EloquenceColors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: EloquenceSpacing.md),
          _buildSupportContent(),
        ],
      ),
    );
  }

  Widget _buildSupportContent() {
    switch (widget.textSupport.type) {
      case SupportType.fillInBlanks:
        return _buildFillInBlanksContent();
      // TODO: Implement other cases
      // case SupportType.guidedStructure:
      //   return _buildStructureContent();
      // case SupportType.keywordChallenge:
      //   return _buildKeywordContent();
      default:
        return Text(
          widget.textSupport.content,
          style: EloquenceTextStyles.body1,
        );
    }
  }

  Widget _buildFillInBlanksContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: EloquenceTextStyles.body1,
            children: _parseTextWithBlanks(widget.textSupport.content),
          ),
        ),
        if (widget.textSupport.suggestedWords.isNotEmpty) ...[
          const SizedBox(height: EloquenceSpacing.md),
          Text(
            '💡 Suggestions disponibles:',
            style: EloquenceTextStyles.body1.copyWith(
              color: EloquenceColors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: EloquenceSpacing.sm),
          Wrap(
            spacing: EloquenceSpacing.sm,
            runSpacing: EloquenceSpacing.sm,
            children: widget.textSupport.suggestedWords.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EloquenceSpacing.sm,
                  vertical: EloquenceSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: EloquenceColors.violet.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EloquenceColors.violet.withAlpha((255 * 0.5).round()),
                  ),
                ),
                child: Text(
                  word,
                  style: EloquenceTextStyles.caption.copyWith(
                    color: EloquenceColors.violet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<TextSpan> _parseTextWithBlanks(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('___');

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));

      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: '_____',
          style: TextStyle(
            backgroundColor: EloquenceColors.cyan.withAlpha((255 * 0.3).round()),
            color: EloquenceColors.cyan,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    return spans;
  }

  Widget _buildWaveformVisualizer() {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(25, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final height = _isRecording
                  ? (20 + (Random().nextDouble() * 40)).clamp(8.0, 60.0)
                  : 8.0;

              final color = Color.lerp(
                EloquenceColors.cyan,
                EloquenceColors.violet,
                index / 25,
              )!;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withAlpha((255 * 0.6).round())],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _isRecording && height > 30
                      ? [
                          BoxShadow(
                            color: color.withAlpha((255 * 0.6).round()),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? (1.0 + (_pulseController.value * 0.1)) : 1.0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isRecording
                    ? RadialGradient(
                        colors: [Colors.red, Colors.red.shade700],
                      )
                    : EloquenceColors.cyanVioletGradient,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : EloquenceColors.cyan)
                        .withAlpha((255 * 0.5).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisStatus() {
    final provider = ref.watch(confidenceBoostProvider);
    
    if (provider.isGeneratingSupport) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: EloquenceSpacing.md),
        padding: const EdgeInsets.all(EloquenceSpacing.md),
        decoration: BoxDecoration(
          color: EloquenceColors.cyan.withAlpha((255 * 0.1).round()),
          borderRadius: EloquenceRadii.card,
          border: Border.all(color: EloquenceColors.cyan.withAlpha((255 * 0.3).round())),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EloquenceColors.cyan,
              ),
            ),
            const SizedBox(width: EloquenceSpacing.sm),
            Text(
              'Analyse en cours...',
              style: EloquenceTextStyles.body1.copyWith(
                color: EloquenceColors.cyan,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _toggleRecording() {
    if (_isConversationActive) {
      // Mode conversation
      if (_conversationManager.state == ConversationState.ready) {
        _startConversation();
      } else if (_conversationManager.state == ConversationState.userSpeaking ||
                 _conversationManager.state == ConversationState.aiSpeaking) {
        _pauseConversation();
      } else if (_conversationManager.state == ConversationState.paused) {
        _resumeConversation();
      }
    } else {
      // Mode enregistrement classique
      setState(() {
        _isRecording = !_isRecording;
      });

      if (_isRecording) {
        _startRecording();
      } else {
        _stopRecording();
      }
    }
  }

  void _startRecording() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });

    // L'enregistrement réel sera géré par le système audio natif
    // Ici on démarre juste l'interface visuelle
  }

  void _stopRecording() {
    _pulseController.stop();
    _waveController.stop();
    _timer?.cancel();

    // Simuler des données audio pour les tests
    _audioData = Uint8List.fromList(List.generate(1024, (index) => index % 256));

    // Déclencher l'analyse avec le provider en utilisant les bons paramètres
    final provider = ref.read(confidenceBoostProvider.notifier);
    provider.analyzePerformance(
      scenario: widget.scenario,
      textSupport: widget.textSupport,
      recordingDuration: _recordingDuration,
      audioData: _audioData,
    ).then((_) {
      // Analyse terminée, retourner à l'écran précédent
      widget.onRecordingComplete(_recordingDuration);
    }).catchError((error) {
      if (!mounted) return;
      // Gérer les erreurs d'analyse
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'analyse: $error'),
          backgroundColor: Colors.red,
        ),
      );
      widget.onRecordingComplete(_recordingDuration);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }

  String _getSupportTypeName(SupportType type) {
    switch (type) {
      case SupportType.fullText:
        return 'Texte complet';
      case SupportType.fillInBlanks:
        return 'Texte à trous';
      case SupportType.guidedStructure:
        return 'Structure guidée';
      case SupportType.keywordChallenge:
        return 'Mots-clés imposés';
      case SupportType.freeImprovisation:
        return 'Improvisation libre';
    }
  }

  // ========== MÉTHODES DE CONVERSATION ==========

  /// Initialise la conversation si le scénario le permet
  Future<void> _initializeConversation() async {
    // Déterminer si on doit activer le mode conversation
    // Pour l'instant, activer pour tous les scénarios sauf le texte complet
    if (widget.textSupport.type != SupportType.fullText) {
      _isConversationActive = true;
      
      // S'abonner aux événements
      _subscribeToConversationEvents();
      
      // Initialiser la conversation
      await _setupConversation();
    }
  }

  /// Configure la conversation avec LiveKit et Mistral
  Future<void> _setupConversation() async {
    try {
      _logger.i('[$_tag] Configuration de la conversation pour ${widget.scenario.title}');
      
      // CORRECTION: Appel à l'API backend pour obtenir des tokens valides
      final sessionData = await _createSessionWithBackend();
      
      if (sessionData == null) {
        _logger.e('[$_tag] Échec création session backend');
        setState(() {
          _isConversationActive = false;
        });
        return;
      }
      
      // Créer un profil utilisateur adaptatif de base
      final userProfile = UserAdaptiveProfile(
        userId: sessionData['user_id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        confidenceLevel: 5, // Sur 10
        experienceLevel: 5, // Sur 10
        strengths: ['Clarté', 'Structure'],
        weaknesses: ['Fluence', 'Gestion du stress'],
        preferredTopics: [widget.scenario.title],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 1,
        averageScore: 0.7,
      );
      
      final initialized = await _conversationManager.initializeConversation(
        scenario: widget.scenario,
        userProfile: userProfile,
        livekitUrl: sessionData['livekit_url'],
        livekitToken: sessionData['livekit_token'],
      );
      
      if (initialized) {
        _logger.i('[$_tag] Conversation initialisée avec succès');
        
        // Ajouter un message système
        setState(() {
          _messages.add(ConversationMessage(
            text: '🎯 Prêt pour votre ${widget.scenario.title}',
            role: ConversationRole.system,
          ));
        });
      } else {
        _logger.e('[$_tag] Échec initialisation conversation');
        // Fallback sur le mode enregistrement classique
        setState(() {
          _isConversationActive = false;
        });
      }
    } catch (e) {
      _logger.e('[$_tag] Erreur configuration conversation: $e');
      setState(() {
        _isConversationActive = false;
      });
    }
  }

  /// S'abonne aux événements de conversation
  void _subscribeToConversationEvents() {
    // Événements principaux
    _eventSubscription = _conversationManager.events.listen((event) {
      _handleConversationEvent(event);
    });
    
    // Transcriptions en temps réel
    _transcriptionSubscription = _conversationManager.transcriptions.listen((segment) {
      _handleTranscription(segment);
    });
    
    // Métriques
    _metricsSubscription = _conversationManager.metrics.listen((metrics) {
      _updateConversationMetrics(metrics);
    });
  }

  /// Gère les événements de conversation
  void _handleConversationEvent(ConversationEvent event) {
    _logger.d('[$_tag] Événement conversation: ${event.type}');
    
    switch (event.type) {
      case ConversationEventType.conversationStarted:
        setState(() {
          _isRecording = true;
          _startTimer();
        });
        break;
        
      case ConversationEventType.aiMessage:
        final data = event.data as Map<String, dynamic>;
        setState(() {
          _messages.add(ConversationMessage(
            text: data['message'],
            role: ConversationRole.assistant,
            metadata: {
              'character': data['character'],
              'emotion': data['emotion'],
              'suggestions': data['suggestions'],
            },
          ));
          _isAISpeaking = true;
          _isUserSpeaking = false;
        });
        _scrollToBottom();
        break;
        
      case ConversationEventType.listeningStarted:
        setState(() {
          _isAISpeaking = false;
          _isUserSpeaking = true;
        });
        break;
        
      case ConversationEventType.stateChanged:
        final state = ConversationState.values.firstWhere(
          (s) => s.name == event.data,
        );
        _updateUIForState(state);
        break;
        
      case ConversationEventType.error:
        _showError(event.data.toString());
        break;
        
      default:
        break;
    }
  }

  /// Gère les transcriptions en temps réel
  void _handleTranscription(TranscriptionSegment segment) {
    if (!segment.isFinal) {
      // Transcription partielle - mettre à jour le dernier message utilisateur
      final lastUserIndex = _messages.lastIndexWhere(
        (msg) => msg.role == ConversationRole.user,
      );
      
      if (lastUserIndex >= 0) {
        setState(() {
          _messages[lastUserIndex] = ConversationMessage(
            text: segment.text,
            role: ConversationRole.user,
            timestamp: _messages[lastUserIndex].timestamp,
          );
        });
      } else {
        // Créer un nouveau message utilisateur
        setState(() {
          _messages.add(ConversationMessage(
            text: segment.text,
            role: ConversationRole.user,
          ));
        });
      }
    } else {
      // Transcription finale
      final lastUserIndex = _messages.lastIndexWhere(
        (msg) => msg.role == ConversationRole.user,
      );
      
      if (lastUserIndex >= 0) {
        setState(() {
          _messages[lastUserIndex] = ConversationMessage(
            text: segment.text,
            role: ConversationRole.user,
            timestamp: _messages[lastUserIndex].timestamp,
            metadata: {'confidence': segment.confidence},
          );
        });
      }
    }
    
    _scrollToBottom();
  }

  /// Met à jour les métriques de conversation
  void _updateConversationMetrics(ConversationMetrics metrics) {
    setState(() {
      _recordingDuration = metrics.totalDuration;
    });
  }

  /// Met à jour l'UI selon l'état de conversation
  void _updateUIForState(ConversationState state) {
    switch (state) {
      case ConversationState.aiSpeaking:
        setState(() {
          _isAISpeaking = true;
          _isUserSpeaking = false;
        });
        _pulseController.repeat(reverse: true);
        break;
        
      case ConversationState.userSpeaking:
        setState(() {
          _isAISpeaking = false;
          _isUserSpeaking = true;
        });
        _waveController.repeat(reverse: true);
        break;
        
      case ConversationState.processing:
      case ConversationState.aiThinking:
        setState(() {
          _isAISpeaking = false;
          _isUserSpeaking = false;
        });
        break;
        
      case ConversationState.paused:
      case ConversationState.ended:
        setState(() {
          _isAISpeaking = false;
          _isUserSpeaking = false;
        });
        _pulseController.stop();
        _waveController.stop();
        break;
        
      default:
        break;
    }
  }

  /// Démarre la conversation
  Future<void> _startConversation() async {
    _logger.i('[$_tag] Démarrage de la conversation');
    
    setState(() {
      _messages.clear();
      _messages.add(ConversationMessage(
        text: '🎬 Début de la conversation...',
        role: ConversationRole.system,
      ));
    });
    
    await _conversationManager.startConversation();
  }

  /// Met en pause la conversation
  void _pauseConversation() {
    _logger.i('[$_tag] Pause de la conversation');
    _conversationManager.pauseConversation();
    _timer?.cancel();
  }

  /// Reprend la conversation
  void _resumeConversation() {
    _logger.i('[$_tag] Reprise de la conversation');
    _conversationManager.resumeConversation();
    _startTimer();
  }

  /// Démarre le timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConversationActive) {
        // Le temps est géré par ConversationManager
        return;
      }
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  /// Scroll automatique vers le bas du chat
  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Affiche une erreur
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Crée une session avec l'API backend
  Future<Map<String, dynamic>?> _createSessionWithBackend() async {
    try {
      _logger.i('[$_tag] Création session avec API backend');
      
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final scenarioId = widget.scenario.id ?? 'confidence_boost';
      
      final requestBody = {
        'user_id': userId,
        'scenario_id': scenarioId,
        'language': 'fr',
      };
      
      _logger.d('[$_tag] Requête: ${AppConfig.apiBaseUrl}/api/sessions');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/sessions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout création session', const Duration(seconds: 10));
        },
      );
      
      _logger.d('[$_tag] Réponse status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final sessionData = json.decode(response.body) as Map<String, dynamic>;
        _logger.i('[$_tag] ✅ Session créée: ${sessionData['session_id']}');
        return sessionData;
      } else {
        _logger.e('[$_tag] ❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
      
    } catch (e) {
      _logger.e('[$_tag] ❌ Erreur création session: $e');
      return null;
    }
  }
}