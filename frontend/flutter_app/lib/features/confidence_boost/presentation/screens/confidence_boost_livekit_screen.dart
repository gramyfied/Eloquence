import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../providers/confidence_livekit_provider.dart';
import '../widgets/animated_microphone_button.dart';
import '../widgets/avatar_with_halo.dart';
import '../../data/services/confidence_livekit_service.dart';

/// Écran principal Confidence Boost avec LiveKit
/// REMPLACE complètement universal_exercise_screen.dart
class ConfidenceBoostLiveKitScreen extends ConsumerStatefulWidget {
  final ConfidenceScenario scenario;

  const ConfidenceBoostLiveKitScreen({
    super.key,
    required this.scenario,
  });

  @override
  ConsumerState<ConfidenceBoostLiveKitScreen> createState() =>
      _ConfidenceBoostLiveKitScreenState();
}

class _ConfidenceBoostLiveKitScreenState
    extends ConsumerState<ConfidenceBoostLiveKitScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Animation pour les effets visuels
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Démarrer la session LiveKit automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLiveKitSession();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  /// Démarrer la session LiveKit
  Future<void> _startLiveKitSession() async {
    final notifier = ref.read(confidenceLiveKitProvider.notifier);
    
    final success = await notifier.startSession(
      scenario: widget.scenario,
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (success) {
      _pulseController.repeat(reverse: true);
    } else {
      if (mounted) {
        _showErrorSnackBar('Impossible de démarrer la session LiveKit');
      }
    }
  }

  /// Envoyer un message texte (pour test/debug)
  Future<void> _sendTestMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final notifier = ref.read(confidenceLiveKitProvider.notifier);
    await notifier.sendMessage(message);
    
    _messageController.clear();
    _scrollToBottom();
  }

  /// Terminer la session
  Future<void> _endSession() async {
    final notifier = ref.read(confidenceLiveKitProvider.notifier);
    await notifier.endSession();
    
    if (mounted) {
      context.pop();
    }
  }

  /// Faire défiler vers le bas
  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Afficher erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _startLiveKitSession,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(confidenceLiveKitProvider);
    final isConnected = ref.watch(livekitConnectionStateProvider);
    
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await _endSession();
          },
        ),
        title: Text(
          widget.scenario.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Indicateur de connexion LiveKit
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'LiveKit' : 'Déconnecté',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec avatar et phase actuelle
          _buildHeader(state),
          
          // Zone de conversation principale
          Expanded(
            child: _buildConversationArea(state),
          ),
          
          // Zone de contrôles en bas
          _buildControlsArea(state),
        ],
      ),
    );
  }

  /// En-tête avec avatar et informations de phase
  Widget _buildHeader(ConfidenceLiveKitState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar avec animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AvatarWithHalo(
                  characterName: 'thomas',
                  size: 80,
                  isActive: state.isListening || state.isProcessing,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Phase actuelle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getPhaseColor(state.currentPhase).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getPhaseColor(state.currentPhase),
                width: 1,
              ),
            ),
            child: Text(
              _getPhaseText(state.currentPhase),
              style: TextStyle(
                color: _getPhaseColor(state.currentPhase),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Transcription temps réel
          if (state.currentTranscription != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.currentTranscription!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Zone de conversation avec messages
  Widget _buildConversationArea(ConfidenceLiveKitState state) {
    if (state.conversationMessages.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'La conversation va commencer...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Parlez naturellement, l\'IA vous écoute',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _chatScrollController,
        itemCount: state.conversationMessages.length,
        itemBuilder: (context, index) {
          final message = state.conversationMessages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  /// Bulle de message
  Widget _buildMessageBubble(ConversationMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: EloquenceColors.violet,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? EloquenceColors.violet
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  /// Zone de contrôles
  Widget _buildControlsArea(ConfidenceLiveKitState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Métriques temps réel
          if (state.latestMetrics != null)
            _buildMetricsDisplay(state.latestMetrics!),
          
          const SizedBox(height: 16),
          
          // Champ de message (pour test/debug)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Message de test...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendTestMessage(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: state.isReady ? _sendTestMessage : null,
                icon: const Icon(Icons.send),
                color: EloquenceColors.violet,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bouton microphone principal
          AnimatedMicrophoneButton(
            isRecording: state.isListening || state.isProcessing,
            onPressed: () {
              // Le microphone est automatiquement actif avec LiveKit
              // Cette action peut déclencher des événements spéciaux si nécessaire
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bouton terminer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _endSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Terminer la session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage des métriques temps réel
  Widget _buildMetricsDisplay(ConfidenceMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('Confiance', metrics.confidenceLevel, Colors.blue),
          _buildMetricItem('Clarté', metrics.voiceClarity, Colors.green),
          _buildMetricItem('Rythme', metrics.speakingPace, Colors.orange),
          _buildMetricItem('Énergie', metrics.energyLevel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Couleur selon la phase
  Color _getPhaseColor(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.connecting:
        return Colors.orange;
      case ExercisePhase.connected:
      case ExercisePhase.ready:
        return Colors.green;
      case ExercisePhase.listening:
        return Colors.blue;
      case ExercisePhase.processing:
        return Colors.purple;
      case ExercisePhase.responding:
        return Colors.cyan;
      case ExercisePhase.error:
        return Colors.red;
      case ExercisePhase.ended:
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  /// Texte selon la phase
  String _getPhaseText(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.idle:
        return 'En attente';
      case ExercisePhase.connecting:
        return 'Connexion...';
      case ExercisePhase.connected:
        return 'Connecté';
      case ExercisePhase.ready:
        return 'Prêt à commencer';
      case ExercisePhase.listening:
        return 'Écoute active';
      case ExercisePhase.processing:
        return 'Traitement...';
      case ExercisePhase.responding:
        return 'Réponse de l\'IA';
      case ExercisePhase.reconnecting:
        return 'Reconnexion...';
      case ExercisePhase.ended:
        return 'Session terminée';
      case ExercisePhase.error:
        return 'Erreur';
      case ExercisePhase.disconnected:
        return 'Déconnecté';
      default:
        return 'État inconnu';
    }
  }
}