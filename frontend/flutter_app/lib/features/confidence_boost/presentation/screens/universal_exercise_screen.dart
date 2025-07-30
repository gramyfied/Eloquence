import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/universal_audio_exercise_service.dart';
import '../providers/universal_exercise_provider.dart';
import '../widgets/animated_microphone_button.dart';
import '../widgets/avatar_with_halo.dart';
import '../../domain/entities/api_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

class UniversalExerciseScreen extends ConsumerStatefulWidget {
  final AudioExerciseConfig exerciseConfig;

  const UniversalExerciseScreen({
    Key? key,
    required this.exerciseConfig,
  }) : super(key: key);

  @override
  ConsumerState<UniversalExerciseScreen> createState() => _UniversalExerciseScreenState();
}

class _UniversalExerciseScreenState extends ConsumerState<UniversalExerciseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(universalExerciseProvider.notifier).startExercise(widget.exerciseConfig);
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseState = ref.watch(universalExerciseProvider);
    final exerciseNotifier = ref.read(universalExerciseProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        title: Text(widget.exerciseConfig.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header avec description
              _buildHeader(),
              const SizedBox(height: 30),
              
              // Avatar avec halo de statut
              _buildAvatarSection(exerciseState),
              const SizedBox(height: 30),
              
              // Zone de conversation
              _buildConversationSection(exerciseState),
              const SizedBox(height: 30),
              
              // Métriques en temps réel
              _buildMetricsSection(exerciseState),
              const SizedBox(height: 30),
              
              // Contrôles audio
              _buildAudioControls(exerciseState, exerciseNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            widget.exerciseConfig.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.exerciseConfig.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UniversalExerciseProvider exerciseState) {
    return Column(
      children: [
        AvatarWithHalo(
          characterName: 'assistant',
          isActive: exerciseState.isRecording || exerciseState.isProcessing,
        ),
        const SizedBox(height: 15),
        Text(
          exerciseState.statusMessage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConversationSection(UniversalExerciseProvider exerciseState) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: exerciseState.messages.isEmpty
            ? const Center(
                child: Text(
                  '💬 Commencez à parler pour débuter l\'exercice',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: exerciseState.messages.length,
                itemBuilder: (context, index) {
                  final message = exerciseState.messages[index];
                  final isUser = message.role == ConversationRole.user;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF4CAF50).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? '👤 Vous' : '🤖 Assistant IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMetricsSection(UniversalExerciseProvider exerciseState) {
    if (exerciseState.metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Métriques en temps réel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'Confiance',
                '${(exerciseState.confidence * 100).toInt()}%',
                Icons.psychology,
              ),
              _buildMetricItem(
                'Messages',
                '${exerciseState.messages.length}',
                Icons.chat,
              ),
              _buildMetricItem(
                'Phase',
                _getPhaseDisplayName(exerciseState.currentPhase),
                Icons.timeline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControls(UniversalExerciseProvider exerciseState, UniversalExerciseProvider exerciseNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton d'annulation
        if (exerciseState.currentPhase != ExercisePhase.setup)
          FloatingActionButton(
            onPressed: () {
              exerciseNotifier.resetExercise();
              Navigator.pop(context);
            },
            backgroundColor: Colors.red.withOpacity(0.8),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        
        // Bouton microphone principal
        AnimatedMicrophoneButton(
          isRecording: exerciseState.isRecording,
          isEnabled: exerciseState.currentPhase == ExercisePhase.ready ||
                     exerciseState.currentPhase == ExercisePhase.feedback,
          onPressed: () {
            if (exerciseState.isRecording) {
              exerciseNotifier.stopListening();
            } else {
              exerciseNotifier.startListening();
            }
          },
          size: 80,
        ),
        
        // Bouton de finalisation
        if (exerciseState.messages.isNotEmpty && 
            exerciseState.currentPhase != ExercisePhase.processing)
          FloatingActionButton(
            onPressed: () async {
              await exerciseNotifier.finishExercise();
              if (mounted) {
                _showCompletionDialog(context);
              }
            },
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.check, color: Colors.white),
          ),
      ],
    );
  }

  String _getPhaseDisplayName(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.setup:
        return 'Config';
      case ExercisePhase.ready:
        return 'Prêt';
      case ExercisePhase.listening:
        return 'Écoute';
      case ExercisePhase.processing:
        return 'Analyse';
      case ExercisePhase.feedback:
        return 'Feedback';
      case ExercisePhase.completed:
        return 'Terminé';
      case ExercisePhase.error:
        return 'Erreur';
    }
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Exercice terminé !'),
        content: const Text(
          'Félicitations ! Vous avez terminé cet exercice avec succès.\n\n'
          'Consultez vos résultats dans l\'historique de vos sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialog
              Navigator.of(context).pop(); // Retourne à l'écran précédent
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ref.read(universalExerciseProvider.notifier).resetExercise();
    super.dispose();
  }
}