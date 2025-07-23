import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mixins/livekit_exercise_mixin.dart';

/// Template d'exercice utilisant l'architecture LiveKit universelle
/// 
/// Pour créer un nouvel exercice :
/// 1. Copier ce fichier
/// 2. Renommer la classe et le fichier
/// 3. Changer exerciseType dans initializeAudio()
/// 4. Implémenter les 4 méthodes callback
/// 5. Personnaliser l'interface utilisateur
/// 
/// C'est tout ! L'audio LiveKit est géré automatiquement.
class ExerciseTemplateScreen extends ConsumerStatefulWidget {
  const ExerciseTemplateScreen({super.key});

  @override
  ConsumerState<ExerciseTemplateScreen> createState() => _ExerciseTemplateScreenState();
}

class _ExerciseTemplateScreenState extends ConsumerState<ExerciseTemplateScreen>
    with LiveKitExerciseMixin {

  // État de l'exercice
  String _currentTranscription = '';
  String _lastAIResponse = '';
  List<String> _conversationHistory = [];
  Map<String, dynamic> _currentMetrics = {};

  @override
  void initState() {
    super.initState();
    
    // Initialisation audio automatique après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeAudio(
        exerciseType: 'template_exercise', // ← Changer selon votre exercice
        config: {
          'difficulty': 'intermediate',
          'language': 'fr',
          'duration_minutes': 10,
          // Ajouter configuration spécifique à votre exercice
        },
      );
    });
  }

  @override
  void dispose() {
    // Nettoyage automatique de l'audio
    cleanupAudio();
    super.dispose();
  }

  // ========================================
  // IMPLÉMENTATION DES CALLBACKS LIVEKIT (OBLIGATOIRE)
  // ========================================

  @override
  void onTranscriptionReceived(String text) {
    setState(() {
      _currentTranscription = text;
      // Ajouter à l'historique si c'est une phrase complète
      if (text.endsWith('.') || text.endsWith('!') || text.endsWith('?')) {
        _conversationHistory.add('Vous: $text');
      }
    });
    
    // Optionnel : envoyer des données à l'IA
    sendToAI(
      type: 'user_speech',
      data: {
        'transcription': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void onAIResponseReceived(String response) {
    setState(() {
      _lastAIResponse = response;
      _conversationHistory.add('IA: $response');
    });
  }

  @override
  void onMetricsReceived(Map<String, dynamic> metrics) {
    setState(() {
      _currentMetrics = metrics;
    });
  }

  @override
  void onAudioError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur audio: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Reconnecter',
          onPressed: reconnectAudio,
        ),
      ),
    );
  }

  // ========================================
  // CALLBACKS OPTIONNELS
  // ========================================

  @override
  void onAudioInitialized() {
    super.onAudioInitialized();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎤 Audio connecté ! Vous pouvez commencer à parler.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ========================================
  // INTERFACE UTILISATEUR
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Exercice'),
        actions: [
          // Indicateur d'état audio
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildAudioStatusIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'état de connexion
          _buildConnectionStatus(),
          
          // Zone de transcription en temps réel
          _buildTranscriptionArea(),
          
          // Zone de conversation
          Expanded(
            child: _buildConversationArea(),
          ),
          
          // Zone de métriques
          _buildMetricsArea(),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isAudioActive ? Colors.green.shade50 : Colors.red.shade50,
      child: Row(
        children: [
          Icon(
            isAudioActive ? Icons.mic : Icons.mic_off,
            color: isAudioActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isAudioActive 
              ? '🎤 Microphone actif - Parlez naturellement'
              : '❌ Microphone inactif',
            style: TextStyle(
              color: isAudioActive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (!isAudioActive && !isAudioInitializing)
            buildReconnectButton(),
        ],
      ),
    );
  }

  Widget _buildTranscriptionArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transcription en temps réel:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTranscription.isEmpty 
              ? 'En attente de votre voix...'
              : _currentTranscription,
            style: TextStyle(
              fontSize: 16,
              color: _currentTranscription.isEmpty 
                ? Colors.grey 
                : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Historique de conversation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _conversationHistory.isEmpty
              ? const Center(
                  child: Text(
                    'La conversation apparaîtra ici...',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _conversationHistory.length,
                  itemBuilder: (context, index) {
                    final message = _conversationHistory[index];
                    final isUser = message.startsWith('Vous:');
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isUser ? Colors.blue.shade700 : Colors.green.shade700,
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsArea() {
    if (_currentMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métriques en temps réel:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: _currentMetrics.entries.map((entry) {
              return Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isAudioActive ? _sendTestMessage : null,
              icon: const Icon(Icons.send),
              label: const Text('Test IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _clearConversation,
              icon: const Icon(Icons.clear),
              label: const Text('Effacer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ACTIONS
  // ========================================

  void _sendTestMessage() {
    sendToAI(
      type: 'test_message',
      data: {
        'message': 'Message de test depuis l\'interface',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _clearConversation() {
    setState(() {
      _conversationHistory.clear();
      _currentTranscription = '';
      _lastAIResponse = '';
      _currentMetrics.clear();
    });
  }
}
