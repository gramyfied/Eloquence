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

/// Widget pour afficher la conversation en temps réel avec interface optimisée
class ConversationChatWidget extends StatefulWidget {
  final List<ConversationMessage> messages;
  final ScrollController? scrollController;
  final bool isAISpeaking;
  final bool isUserSpeaking;
  final String? currentTranscription;
  final VoidCallback? onMessageTap;

  const ConversationChatWidget({
    Key? key,
    required this.messages,
    this.scrollController,
    this.isAISpeaking = false,
    this.isUserSpeaking = false,
    this.currentTranscription,
    this.onMessageTap,
  }) : super(key: key);

  @override
  State<ConversationChatWidget> createState() => _ConversationChatWidgetState();
}

class _ConversationChatWidgetState extends State<ConversationChatWidget>
    with TickerProviderStateMixin {
  late AnimationController _typingAnimationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _typingAnimation;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Animation pour l'indicateur de frappe
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Animation pour les nouveaux messages
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Démarrer l'animation de frappe si nécessaire
    if (widget.isAISpeaking) {
      _typingAnimationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(ConversationChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Gérer les changements d'état de frappe
    if (widget.isAISpeaking != oldWidget.isAISpeaking) {
      if (widget.isAISpeaking) {
        _typingAnimationController.repeat(reverse: true);
      } else {
        _typingAnimationController.stop();
      }
    }
    
    // Animer les nouveaux messages
    if (widget.messages.length > oldWidget.messages.length) {
      _messageAnimationController.forward().then((_) {
        _messageAnimationController.reset();
        // Auto-scroll vers le bas pour le nouveau message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }
  
  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageAnimationController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

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
              controller: _scrollController,
              padding: const EdgeInsets.all(EloquenceSpacing.md),
              itemCount: widget.messages.length + (widget.currentTranscription != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < widget.messages.length) {
                  return _buildAnimatedMessageBubble(widget.messages[index], index);
                } else {
                  // Afficher la transcription en cours avec animation
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
    if (widget.isAISpeaking) {
      return AnimatedBuilder(
        animation: _typingAnimation,
        builder: (context, child) {
          return Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EloquenceColors.violet.withAlpha((255 * (0.5 + 0.5 * _typingAnimation.value)).round()),
                ),
              ),
              const SizedBox(width: EloquenceSpacing.xs),
              Text(
                'IA parle...',
                style: EloquenceTextStyles.caption.copyWith(
                  color: EloquenceColors.violet.withAlpha((255 * (0.7 + 0.3 * _typingAnimation.value)).round()),
                ),
              ),
            ],
          );
        },
      );
    } else if (widget.isUserSpeaking) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: EloquenceColors.cyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EloquenceColors.cyan.withAlpha(128),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
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
            // Avatar et nom avec animation
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  _buildCharacterAvatar(isUser),
                  const SizedBox(width: EloquenceSpacing.xs),
                ],
                Text(
                  isUser ? 'Vous' : 'Marie',
                  style: EloquenceTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: EloquenceSpacing.xs),
                  _buildCharacterAvatar(isUser),
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
    if (widget.currentTranscription == null || widget.currentTranscription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
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
                  color: EloquenceColors.cyan.withAlpha((255 * (0.2 + 0.1 * _typingAnimation.value)).round()),
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
                      color: EloquenceColors.cyan.withAlpha((255 * (0.5 + 0.3 * _typingAnimation.value)).round()),
                    ),
                  ),
                  const SizedBox(width: EloquenceSpacing.sm),
                  Flexible(
                    child: Text(
                      widget.currentTranscription!,
                      style: EloquenceTextStyles.body1.copyWith(
                        color: EloquenceColors.cyan.withAlpha((255 * (0.7 + 0.2 * _typingAnimation.value)).round()),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Message animé avec effet d'apparition fluide
  Widget _buildAnimatedMessageBubble(ConversationMessage message, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _messageAnimationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _messageAnimationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
        child: _buildMessageBubble(message),
      ),
    );
  }

  /// Avatar avec indicateur de personnage IA adaptatif
  Widget _buildCharacterAvatar(bool isUser) {
    if (isUser) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: EloquenceColors.cyan.withAlpha((255 * 0.2).round()),
        child: const Icon(
          Icons.person,
          size: 20,
          color: EloquenceColors.cyan,
        ),
      );
    }
    
    // Avatar IA avec indicateur d'animation si en train de parler
    return AnimatedBuilder(
      animation: widget.isAISpeaking ? _typingAnimationController : kAlwaysCompleteAnimation,
      builder: (context, child) {
        final scale = widget.isAISpeaking ? (1.0 + 0.1 * _typingAnimation.value) : 1.0;
        return Transform.scale(
          scale: scale,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: EloquenceColors.violet.withAlpha((255 * 0.2).round()),
            child: Icon(
              Icons.psychology,
              size: 20,
              color: widget.isAISpeaking
                ? EloquenceColors.violet.withAlpha((255 * (0.7 + 0.3 * _typingAnimation.value)).round())
                : EloquenceColors.violet,
            ),
          ),
        );
      },
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