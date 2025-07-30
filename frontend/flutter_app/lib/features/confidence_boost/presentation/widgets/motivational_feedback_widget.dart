import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget pour afficher des feedbacks motivants avec animations
class MotivationalFeedbackWidget extends StatefulWidget {
  final String message;
  final MotivationalFeedbackType type;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final bool autoHide;

  const MotivationalFeedbackWidget({
    Key? key,
    required this.message,
    this.type = MotivationalFeedbackType.encouragement,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 3),
    this.autoHide = true,
  }) : super(key: key);

  @override
  State<MotivationalFeedbackWidget> createState() => _MotivationalFeedbackWidgetState();
}

class _MotivationalFeedbackWidgetState extends State<MotivationalFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer l'animation d'entrée
    _slideController.forward();
    
    // Auto-hide si activé
    if (widget.autoHide) {
      Future.delayed(widget.displayDuration, () {
        if (mounted) {
          _hideWidget();
        }
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _hideWidget() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Particules scintillantes pour les succès
            if (widget.type == MotivationalFeedbackType.achievement)
              ...List.generate(8, (index) => _buildSparkleParticle(index)),
            
            // Contenu principal
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.type == MotivationalFeedbackType.celebration 
                      ? _pulseAnimation.value 
                      : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.type.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.type.borderColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.type.shadowColor,
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icône avec animation
                        _buildAnimatedIcon(),
                        
                        const SizedBox(height: 12),
                        
                        // Message principal
                        Text(
                          widget.message,
                          style: EloquenceTheme.bodyLarge.copyWith(
                            color: EloquenceTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        // Bouton de fermeture si pas d'auto-hide
                        if (!widget.autoHide) ...[
                          const SizedBox(height: 16),
                          _buildDismissButton(),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EloquenceTheme.white.withOpacity(0.2),
        border: Border.all(
          color: EloquenceTheme.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: widget.type == MotivationalFeedbackType.achievement 
              ? _sparkleAnimation 
              : _pulseAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: widget.type == MotivationalFeedbackType.achievement 
                  ? _sparkleAnimation.value * 2 * math.pi 
                  : 0,
              child: Text(
                widget.type.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSparkleParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 6.0;
    final startX = 50.0 + random.nextDouble() * 200;
    final startY = 50.0 + random.nextDouble() * 100;
    
    return Positioned(
      left: startX,
      top: startY,
      child: AnimatedBuilder(
        animation: _sparkleAnimation,
        builder: (context, child) {
          final progress = (_sparkleAnimation.value + random.nextDouble()) % 1.0;
          return Opacity(
            opacity: math.sin(progress * math.pi),
            child: Transform.translate(
              offset: Offset(
                math.sin(progress * 2 * math.pi) * 20,
                -progress * 30,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: EloquenceTheme.celebrationGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.celebrationGold.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissButton() {
    return GestureDetector(
      onTap: _hideWidget,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: EloquenceTheme.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: EloquenceTheme.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Compris',
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Types de feedback motivant
enum MotivationalFeedbackType {
  encouragement,
  achievement,
  celebration,
  guidance,
  warning,
}

extension MotivationalFeedbackTypeExtension on MotivationalFeedbackType {
  String get emoji {
    switch (this) {
      case MotivationalFeedbackType.encouragement:
        return '💪';
      case MotivationalFeedbackType.achievement:
        return '🎉';
      case MotivationalFeedbackType.celebration:
        return '✨';
      case MotivationalFeedbackType.guidance:
        return '🧭';
      case MotivationalFeedbackType.warning:
        return '⚠️';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case MotivationalFeedbackType.encouragement:
        return [
          EloquenceTheme.cyan.withOpacity(0.8),
          EloquenceTheme.cyan.withOpacity(0.6),
        ];
      case MotivationalFeedbackType.achievement:
        return [
          EloquenceTheme.celebrationGold.withOpacity(0.9),
          EloquenceTheme.celebrationGold.withOpacity(0.7),
        ];
      case MotivationalFeedbackType.celebration:
        return [
          EloquenceTheme.successGreen.withOpacity(0.8),
          EloquenceTheme.successGreen.withOpacity(0.6),
        ];
      case MotivationalFeedbackType.guidance:
        return [
          EloquenceTheme.violet.withOpacity(0.8),
          EloquenceTheme.violet.withOpacity(0.6),
        ];
      case MotivationalFeedbackType.warning:
        return [
          EloquenceTheme.warningOrange.withOpacity(0.8),
          EloquenceTheme.warningOrange.withOpacity(0.6),
        ];
    }
  }

  Color get borderColor {
    switch (this) {
      case MotivationalFeedbackType.encouragement:
        return EloquenceTheme.cyan;
      case MotivationalFeedbackType.achievement:
        return EloquenceTheme.celebrationGold;
      case MotivationalFeedbackType.celebration:
        return EloquenceTheme.successGreen;
      case MotivationalFeedbackType.guidance:
        return EloquenceTheme.violet;
      case MotivationalFeedbackType.warning:
        return EloquenceTheme.warningOrange;
    }
  }

  Color get shadowColor {
    return borderColor.withOpacity(0.3);
  }
}

/// Widget pour afficher une série de messages motivants
class MotivationalFeedbackQueue extends StatefulWidget {
  final List<MotivationalMessage> messages;
  final VoidCallback? onComplete;

  const MotivationalFeedbackQueue({
    Key? key,
    required this.messages,
    this.onComplete,
  }) : super(key: key);

  @override
  State<MotivationalFeedbackQueue> createState() => _MotivationalFeedbackQueueState();
}

class _MotivationalFeedbackQueueState extends State<MotivationalFeedbackQueue> {
  int currentIndex = 0;
  bool isVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.messages.isNotEmpty) {
      _showNextMessage();
    }
  }

  void _showNextMessage() {
    if (currentIndex < widget.messages.length) {
      setState(() {
        isVisible = true;
      });
    } else {
      widget.onComplete?.call();
    }
  }

  void _onMessageDismiss() {
    setState(() {
      isVisible = false;
      currentIndex++;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showNextMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible || currentIndex >= widget.messages.length) {
      return const SizedBox.shrink();
    }

    final currentMessage = widget.messages[currentIndex];
    
    return MotivationalFeedbackWidget(
      message: currentMessage.text,
      type: currentMessage.type,
      onDismiss: _onMessageDismiss,
      displayDuration: currentMessage.duration,
    );
  }
}

/// Modèle pour un message motivant
class MotivationalMessage {
  final String text;
  final MotivationalFeedbackType type;
  final Duration duration;

  const MotivationalMessage({
    required this.text,
    this.type = MotivationalFeedbackType.encouragement,
    this.duration = const Duration(seconds: 3),
  });
}

/// Générateur de messages motivants basé sur la performance
class DragonMotivationalGenerator {
  static List<MotivationalMessage> generateSessionMessages(
    BreathingMetrics metrics,
    DragonProgress progress,
    List<DragonAchievement> newAchievements,
  ) {
    final messages = <MotivationalMessage>[];
    
    // Messages d'achievements
    for (final achievement in newAchievements) {
      messages.add(MotivationalMessage(
        text: '🎉 ${achievement.name} débloqué ! ${achievement.description}',
        type: MotivationalFeedbackType.achievement,
        duration: const Duration(seconds: 4),
      ));
    }
    
    // Messages de performance
    if (metrics.isExcellent) {
      messages.add(MotivationalMessage(
        text: 'Performance exceptionnelle ! Ton dragon intérieur brille de mille feux ! ✨',
        type: MotivationalFeedbackType.celebration,
      ));
    } else if (metrics.isSuccessful) {
      messages.add(MotivationalMessage(
        text: 'Excellent contrôle du souffle ! Tu maîtrises de mieux en mieux ton énergie ! 💪',
        type: MotivationalFeedbackType.encouragement,
      ));
    } else if (metrics.completionPercentage >= 0.5) {
      messages.add(MotivationalMessage(
        text: 'Bon travail ! Continue à pratiquer pour libérer tout ton potentiel ! 🔥',
        type: MotivationalFeedbackType.encouragement,
      ));
    }
    
    // Messages de progression de niveau
    if (progress.progressToNextLevel > 0.8) {
      messages.add(MotivationalMessage(
        text: 'Tu es presque prêt pour le niveau suivant ! Plus que quelques sessions ! 🚀',
        type: MotivationalFeedbackType.guidance,
      ));
    }
    
    // Messages de série
    if (progress.currentStreak >= 7) {
      messages.add(MotivationalMessage(
        text: 'Série incroyable de ${progress.currentStreak} jours ! Ta constance forge ton pouvoir ! 👑',
        type: MotivationalFeedbackType.celebration,
      ));
    }
    
    return messages;
  }

  static List<MotivationalMessage> generateEncouragementMessages(DragonLevel level) {
    switch (level) {
      case DragonLevel.apprenti:
        return [
          const MotivationalMessage(
            text: 'Chaque grand dragon a commencé par une première flamme ! 🔥',
            type: MotivationalFeedbackType.encouragement,
          ),
          const MotivationalMessage(
            text: 'Respire profondément et laisse ton énergie se développer ! 💨',
            type: MotivationalFeedbackType.guidance,
          ),
        ];
        
      case DragonLevel.maitre:
        return [
          const MotivationalMessage(
            text: 'Ton souffle gagne en puissance ! Continue à forger ton énergie ! ⚡',
            type: MotivationalFeedbackType.encouragement,
          ),
          const MotivationalMessage(
            text: 'Un maître du souffle sait que la régularité est la clé ! 🎯',
            type: MotivationalFeedbackType.guidance,
          ),
        ];
        
      case DragonLevel.sage:
        return [
          const MotivationalMessage(
            text: 'Ta sagesse grandit avec chaque respiration contrôlée ! 🌟',
            type: MotivationalFeedbackType.encouragement,
          ),
          const MotivationalMessage(
            text: 'Inspire la sérénité, expire la puissance ! 🧘‍♂️',
            type: MotivationalFeedbackType.guidance,
          ),
        ];
        
      case DragonLevel.legende:
        return [
          const MotivationalMessage(
            text: 'Ton souffle commande le respect ! Tu es une légende vivante ! 👑',
            type: MotivationalFeedbackType.celebration,
          ),
          const MotivationalMessage(
            text: 'Continue à inspirer les autres dragons par ton exemple ! ✨',
            type: MotivationalFeedbackType.encouragement,
          ),
        ];
    }
  }
}