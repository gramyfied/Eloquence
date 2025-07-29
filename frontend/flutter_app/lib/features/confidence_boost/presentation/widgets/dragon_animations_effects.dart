import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget d'animation de transition de niveau Dragon
class DragonLevelUpAnimation extends StatefulWidget {
  final DragonLevel fromLevel;
  final DragonLevel toLevel;
  final VoidCallback? onComplete;

  const DragonLevelUpAnimation({
    Key? key,
    required this.fromLevel,
    required this.toLevel,
    this.onComplete,
  }) : super(key: key);

  @override
  State<DragonLevelUpAnimation> createState() => _DragonLevelUpAnimationState();
}

class _DragonLevelUpAnimationState extends State<DragonLevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particlesController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimation();
  }

  void _startAnimation() async {
    _particlesController.repeat();
    await _mainController.forward();
    await _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particlesController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particules de fond
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: DragonEnergyParticlesPainter(
                  animation: _particlesController,
                  color: widget.toLevel.dragonColor,
                ),
              );
            },
          ),
          
          // Avatar Dragon avec transformation
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _rotationAnimation, _glowAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.toLevel.dragonColor.withOpacity(0.9),
                          widget.toLevel.dragonColor.withOpacity(0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.toLevel.dragonColor.withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.toLevel.emoji,
                        style: TextStyle(
                          fontSize: 80,
                          shadows: [
                            Shadow(
                              color: widget.toLevel.dragonColor.withOpacity(_glowAnimation.value),
                              blurRadius: 20 * _glowAnimation.value,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Texte de niveau
          Positioned(
            bottom: 200,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  children: [
                    Text(
                      'NIVEAU SUPÉRIEUR !',
                      style: EloquenceTheme.headline1.copyWith(
                        color: widget.toLevel.dragonColor,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: widget.toLevel.dragonColor.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.toLevel.displayName,
                      style: EloquenceTheme.headline2.copyWith(
                        color: EloquenceTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.toLevel.description,
                      style: EloquenceTheme.bodyLarge.copyWith(
                        color: EloquenceTheme.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour les particules d'énergie Dragon
class DragonEnergyParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  DragonEnergyParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Seed fixe pour cohérence

    for (int i = 0; i < 50; i++) {
      final progress = (animation.value + random.nextDouble()) % 1.0;
      final x = random.nextDouble() * size.width;
      final y = size.height * (1 - progress);
      final size_ = 2 + random.nextDouble() * 4;
      
      final opacity = math.sin(progress * math.pi);
      paint.color = color.withOpacity(opacity * 0.7);
      
      canvas.drawCircle(
        Offset(x, y),
        size_,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget de flux d'énergie suivant la respiration
class BreathingEnergyFlow extends StatefulWidget {
  final BreathingPhase currentPhase;
  final double progress; // 0.0 à 1.0 pour la phase actuelle

  const BreathingEnergyFlow({
    Key? key,
    required this.currentPhase,
    required this.progress,
  }) : super(key: key);

  @override
  State<BreathingEnergyFlow> createState() => _BreathingEnergyFlowState();
}

class _BreathingEnergyFlowState extends State<BreathingEnergyFlow>
    with TickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flowController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: EnergyFlowPainter(
            phase: widget.currentPhase,
            phaseProgress: widget.progress,
            animationProgress: _flowController.value,
          ),
        );
      },
    );
  }
}

/// Painter pour le flux d'énergie
class EnergyFlowPainter extends CustomPainter {
  final BreathingPhase phase;
  final double phaseProgress;
  final double animationProgress;

  EnergyFlowPainter({
    required this.phase,
    required this.phaseProgress,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 4;

    switch (phase) {
      case BreathingPhase.inspiration:
        _drawInspirationFlow(canvas, center, radius);
        break;
      case BreathingPhase.retention:
        _drawRetentionFlow(canvas, center, radius);
        break;
      case BreathingPhase.expiration:
        _drawExpirationFlow(canvas, center, radius);
        break;
      default:
        break;
    }
  }

  void _drawInspirationFlow(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = EloquenceTheme.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Spirale vers l'intérieur
    for (int i = 0; i < 5; i++) {
      final baseRadius = radius + (i * 20);
      final spiralRadius = math.max(10, baseRadius - (phaseProgress * 40));
      final path = Path();
      
      for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
        final currentRadius = spiralRadius * (1 - angle / (2 * math.pi) * 0.3);
        final x = center.dx + currentRadius * math.cos(angle + animationProgress * 2 * math.pi);
        final y = center.dy + currentRadius * math.sin(angle + animationProgress * 2 * math.pi);
        
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      paint.color = EloquenceTheme.cyan.withOpacity(0.3 + (i * 0.1));
      canvas.drawPath(path, paint);
    }
  }

  void _drawRetentionFlow(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = EloquenceTheme.warningOrange.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Pulsation stable au centre
    final pulseRadius = radius * (0.7 + 0.1 * math.sin(animationProgress * 2 * math.pi));
    
    canvas.drawCircle(center, pulseRadius, paint);
    
    // Anneaux d'énergie synchronisés
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    for (int i = 0; i < 3; i++) {
      final baseRadius = radius + (i * 25);
      final ringRadius = baseRadius + (math.sin(animationProgress * math.pi + i * 0.5) * 8);
      paint.color = EloquenceTheme.warningOrange.withOpacity(0.6 - (i * 0.15));
      canvas.drawCircle(center, ringRadius, paint);
    }
  }

  void _drawExpirationFlow(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = EloquenceTheme.successGreen.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Spirale vers l'extérieur améliorée
    for (int i = 0; i < 5; i++) {
      final baseRadius = radius - (i * 15);
      final spiralRadius = math.max(baseRadius, baseRadius + (phaseProgress * 60));
      final path = Path();
      
      for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
        final currentRadius = spiralRadius * (1 + angle / (2 * math.pi) * 0.4);
        final x = center.dx + currentRadius * math.cos(-angle + animationProgress * 2 * math.pi);
        final y = center.dy + currentRadius * math.sin(-angle + animationProgress * 2 * math.pi);
        
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      paint.color = EloquenceTheme.successGreen.withOpacity(0.8 - (i * 0.12));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget d'effet de glow pulsant
class DragonGlowEffect extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double intensity;
  final bool isActive;

  const DragonGlowEffect({
    Key? key,
    required this.child,
    required this.glowColor,
    this.intensity = 1.0,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<DragonGlowEffect> createState() => _DragonGlowEffectState();
}

class _DragonGlowEffectState extends State<DragonGlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DragonGlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_pulseAnimation.value * widget.intensity * 0.5),
                blurRadius: 20 * _pulseAnimation.value * widget.intensity,
                spreadRadius: 5 * _pulseAnimation.value * widget.intensity,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Widget d'animation de célébration pour achievements
class DragonCelebrationEffect extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  const DragonCelebrationEffect({
    Key? key,
    required this.child,
    required this.trigger,
    this.onComplete,
  }) : super(key: key);

  @override
  State<DragonCelebrationEffect> createState() => _DragonCelebrationEffectState();
}

class _DragonCelebrationEffectState extends State<DragonCelebrationEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(DragonCelebrationEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_hasTriggered) {
      _hasTriggered = true;
      _startCelebration();
    }
  }

  void _startCelebration() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onComplete?.call();
    _hasTriggered = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Widget de transition fluide entre phases
class BreathingPhaseTransition extends StatefulWidget {
  final BreathingPhase currentPhase;
  final Widget child;

  const BreathingPhaseTransition({
    Key? key,
    required this.currentPhase,
    required this.child,
  }) : super(key: key);

  @override
  State<BreathingPhaseTransition> createState() => _BreathingPhaseTransitionState();
}

class _BreathingPhaseTransitionState extends State<BreathingPhaseTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  BreathingPhase? _previousPhase;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _colorAnimation = ColorTween(
      begin: widget.currentPhase.phaseColor,
      end: widget.currentPhase.phaseColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BreathingPhaseTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPhase != oldWidget.currentPhase) {
      _previousPhase = oldWidget.currentPhase;
      _animatePhaseChange();
    }
  }

  void _animatePhaseChange() {
    _colorAnimation = ColorTween(
      begin: _previousPhase?.phaseColor ?? widget.currentPhase.phaseColor,
      end: widget.currentPhase.phaseColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                (_colorAnimation.value ?? widget.currentPhase.phaseColor).withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.3, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}