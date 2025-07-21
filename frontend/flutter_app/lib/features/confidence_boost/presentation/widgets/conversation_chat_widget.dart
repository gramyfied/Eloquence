import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';

/// Rôle dans la conversation
enum ConversationRole {
  user,
  assistant,
  system,
}

/// Message de conversation
class ConversationMessage {
  final String text;
  final ConversationRole role;
  final DateTime timestamp;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.audioUrl,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Widget pour afficher la conversation en temps réel
class ConversationChatWidget extends StatelessWidget {
  final List<ConversationMessage> messages;
  final ScrollController? scrollController;
  final bool isAISpeaking;
  final bool isUserSpeaking;
  final String? currentTranscription;

  const ConversationChatWidget({
    Key? key,
    required this.messages,
    this.scrollController,
    this.isAISpeaking = false,
    this.isUserSpeaking = false,
    this.currentTranscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(EloquenceSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: EloquenceColors.glassBackground,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: EloquenceColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: EloquenceSpacing.sm),
                Text(
                  'Conversation en cours',
                  style: EloquenceTextStyles.body1.copyWith(
                    color: EloquenceColors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Indicateur d'état
                _buildStatusIndicator(),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(EloquenceSpacing.md),
              itemCount: messages.length + (currentTranscription != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  return _buildMessageBubble(messages[index]);
                } else {
                  // Afficher la transcription en cours
                  return _buildTranscriptionBubble();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (isAISpeaking) {
      return Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: EloquenceColors.violet,
            ),
          ),
          const SizedBox(width: EloquenceSpacing.xs),
          Text(
            'IA parle...',
            style: EloquenceTextStyles.caption.copyWith(
              color: EloquenceColors.violet,
            ),
          ),
        ],
      );
    } else if (isUserSpeaking) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: EloquenceColors.cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: EloquenceSpacing.xs),
          Text(
            'Vous parlez...',
            style: EloquenceTextStyles.caption.copyWith(
              color: EloquenceColors.cyan,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    final isUser = message.role == ConversationRole.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? EloquenceColors.cyan : EloquenceColors.violet;
    final crossAlignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: EdgeInsets.only(
        bottom: EloquenceSpacing.md,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Align(
        alignment: alignment,
        child: Column(
          crossAxisAlignment: crossAlignment,
          children: [
            // Avatar et nom
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withAlpha((255 * 0.2).round()),
                    child: Icon(
                      Icons.psychology,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: EloquenceSpacing.xs),
                ],
                Text(
                  isUser ? 'Vous' : 'Assistant IA',
                  style: EloquenceTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: EloquenceSpacing.xs),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withAlpha((255 * 0.2).round()),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: EloquenceSpacing.xs),

            // Bulle de message
            Container(
              padding: const EdgeInsets.all(EloquenceSpacing.md),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: Border.all(
                  color: color.withAlpha((255 * 0.3).round()),
                ),
              ),
              child: Text(
                message.text,
                style: EloquenceTextStyles.body1.copyWith(
                  color: Colors.white,
                ),
              ),
            ),

            // Timestamp
            const SizedBox(height: EloquenceSpacing.xs),
            Text(
              _formatTimestamp(message.timestamp),
              style: EloquenceTextStyles.caption.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionBubble() {
    if (currentTranscription == null || currentTranscription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: EloquenceSpacing.md,
        left: 48,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(EloquenceSpacing.md),
          decoration: BoxDecoration(
            color: EloquenceColors.cyan.withAlpha((255 * 0.05).round()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EloquenceColors.cyan.withAlpha((255 * 0.2).round()),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EloquenceColors.cyan.withAlpha((255 * 0.5).round()),
                ),
              ),
              const SizedBox(width: EloquenceSpacing.sm),
              Flexible(
                child: Text(
                  currentTranscription!,
                  style: EloquenceTextStyles.body1.copyWith(
                    color: EloquenceColors.cyan.withAlpha((255 * 0.7).round()),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}