import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget d'animation de célébration avec confettis
class CelebrationAnimationWidget extends StatefulWidget {
  final bool isActive;
  final Widget child;
  final Duration duration;
  final int particleCount;

  const CelebrationAnimationWidget({
    super.key,
    required this.isActive,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 50,
  });

  @override
  State<CelebrationAnimationWidget> createState() => _CelebrationAnimationWidgetState();
}

class _CelebrationAnimationWidgetState extends State<CelebrationAnimationWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  
  late Animation<double> _confettiAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  
  List<ConfettiParticle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    _generateParticles();
    
    if (widget.isActive) {
      _startCelebration();
    }
  }
  
  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1,
        speedX: (_random.nextDouble() - 0.5) * 0.02,
        speedY: _random.nextDouble() * 0.02 + 0.01,
        color: _getRandomColor(),
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        shape: ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)],
      );
    });
  }
  
  Color _getRandomColor() {
    final colors = [
      const Color(0xFF6366F1), // Violet
      const Color(0xFF0EA5E9), // Cyan
      const Color(0xFFF59E0B), // Jaune
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF10B981), // Vert
      const Color(0xFFEC4899), // Rose
    ];
    return colors[_random.nextInt(colors.length)];
  }
  
  void _startCelebration() {
    _confettiController.forward();
    _pulseController.forward();
    _sparkleController.repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(CelebrationAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startCelebration();
      } else {
        _confettiController.stop();
        _pulseController.stop();
        _sparkleController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenu principal avec effet de pulsation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isActive ? _pulseAnimation.value : 1.0,
              child: widget.child,
            );
          },
        ),
        
        // Confettis animés
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _confettiAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
        
        // Étoiles scintillantes
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SparklePainter(
                      progress: _sparkleAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Particule de confetti
class ConfettiParticle {
  double x;
  double y;
  final double speedX;
  final double speedY;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  final ConfettiShape shape;
  
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });
  
  void update() {
    x += speedX;
    y += speedY;
    rotation += rotationSpeed;
  }
}

/// Formes de confettis
enum ConfettiShape {
  circle,
  square,
  triangle,
  heart,
  star,
}

/// Painter pour les confettis
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  
  ConfettiPainter({
    required this.particles,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Mettre à jour la position selon le progrès
      final currentY = particle.y + (particle.speedY * progress * size.height * 2);
      final currentX = particle.x * size.width + (particle.speedX * progress * size.width);
      
      // Ne dessiner que si visible
      if (currentY > -50 && currentY < size.height + 50 &&
          currentX > -50 && currentX < size.width + 50) {
        
        final paint = Paint()
          ..color = particle.color.withOpacity(1.0 - (progress * 0.5))
          ..style = PaintingStyle.fill;
        
        canvas.save();
        canvas.translate(currentX, currentY);
        canvas.rotate(particle.rotation + (progress * particle.rotationSpeed * 10));
        
        _drawShape(canvas, particle.shape, particle.size, paint);
        
        canvas.restore();
      }
    }
  }
  
  void _drawShape(Canvas canvas, ConfettiShape shape, double size, Paint paint) {
    switch (shape) {
      case ConfettiShape.circle:
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
      case ConfettiShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size, height: size),
          paint,
        );
        break;
      case ConfettiShape.triangle:
        final path = Path()
          ..moveTo(0, -size / 2)
          ..lineTo(-size / 2, size / 2)
          ..lineTo(size / 2, size / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ConfettiShape.heart:
        _drawHeart(canvas, size, paint);
        break;
      case ConfettiShape.star:
        _drawStar(canvas, size, paint);
        break;
    }
  }
  
  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final halfSize = size / 2;
    
    path.moveTo(0, halfSize * 0.3);
    path.cubicTo(-halfSize * 0.6, -halfSize * 0.3, -halfSize, 0, -halfSize * 0.5, halfSize * 0.5);
    path.lineTo(0, halfSize);
    path.lineTo(halfSize * 0.5, halfSize * 0.5);
    path.cubicTo(halfSize, 0, halfSize * 0.6, -halfSize * 0.3, 0, halfSize * 0.3);
    
    canvas.drawPath(path, paint);
  }
  
  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = radius * math.cos(angle - math.pi / 2);
      final y = radius * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Painter pour les étoiles scintillantes
class SparklePainter extends CustomPainter {
  final double progress;
  final _random = math.Random(42); // Seed fixe pour des positions constantes
  
  SparklePainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final sparkleCount = 20;
    
    for (int i = 0; i < sparkleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final sparkleSize = _random.nextDouble() * 6 + 2;
      
      // Animation de scintillement
      final sparkleProgress = (progress + (i * 0.1)) % 1.0;
      final opacity = (math.sin(sparkleProgress * math.pi * 2) + 1) / 2;
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      // Dessiner une étoile scintillante
      canvas.save();
      canvas.translate(x, y);
      
      // Croix principale
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: sparkleSize, height: 2),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 2, height: sparkleSize),
        paint,
      );
      
      // Croix diagonale plus petite
      canvas.rotate(math.pi / 4);
      final smallSize = sparkleSize * 0.6;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: smallSize, height: 1),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 1, height: smallSize),
        paint,
      );
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}