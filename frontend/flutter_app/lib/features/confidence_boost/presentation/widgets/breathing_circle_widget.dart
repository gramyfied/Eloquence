import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Particule d'énergie pour l'animation
class EnergyParticle {
  double x;
  double y;
  double angle;
  double distance;
  double speed;
  Color color;
  double opacity;
  double size;

  EnergyParticle({
    required this.x,
    required this.y,
    required this.angle,
    required this.distance,
    required this.speed,
    required this.color,
    required this.opacity,
    required this.size,
  });

  factory EnergyParticle.random(double containerSize) {
    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = random.nextDouble() * containerSize * 0.3;
    
    return EnergyParticle(
      x: math.cos(angle) * distance,
      y: math.sin(angle) * distance,
      angle: angle,
      distance: distance,
      speed: 0.5 + random.nextDouble() * 1.5,
      color: EloquenceTheme.cyan,
      opacity: 0.3 + random.nextDouble() * 0.7,
      size: 2 + random.nextDouble() * 4,
    );
  }

  void update(double speedMultiplier) {
    distance += speed * speedMultiplier;
    x = math.cos(angle) * distance;
    y = math.sin(angle) * distance;
    
    // Variation d'opacité plus stable
    opacity = (0.3 + (math.sin(angle + distance * 0.01) * 0.4)).clamp(0.0, 1.0);
  }

  void reset(double containerSize) {
    final random = math.Random();
    angle = random.nextDouble() * 2 * math.pi;
    distance = 0;
    speed = 0.5 + random.nextDouble() * 1.5;
    opacity = 0.3 + random.nextDouble() * 0.7;
    size = 2 + random.nextDouble() * 4;
  }
}

/// Painter pour les particules d'énergie
class EnergyParticlesPainter extends CustomPainter {
  final List<EnergyParticle> particles;
  final Color phaseColor;
  final bool isActive;

  EnergyParticlesPainter({
    required this.particles,
    required this.phaseColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      if (particle.opacity <= 0 || particle.size <= 0) continue;
      
      final opacity = particle.opacity.clamp(0.0, 1.0);
      paint.color = phaseColor.withOpacity(opacity);
      
      final position = Offset(
        (center.dx + particle.x).clamp(0, size.width),
        (center.dy + particle.y).clamp(0, size.height),
      );

      final safeSize = particle.size.clamp(0.1, size.width / 4);
      
      // Dessiner la particule comme un petit cercle avec effet de lueur
      canvas.drawCircle(position, safeSize, paint);
      
      // Effet de lueur
      paint.color = phaseColor.withOpacity(opacity * 0.3);
      canvas.drawCircle(position, safeSize * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter pour les anneaux de progression
class ProgressRingsPainter extends CustomPainter {
  final double phaseProgress;
  final Color phaseColor;
  final double strokeWidth;

  ProgressRingsPainter({
    required this.phaseProgress,
    required this.phaseColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || strokeWidth <= 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final safeStrokeWidth = strokeWidth.clamp(1.0, size.width / 10);
    final radius = (size.width / 2 - safeStrokeWidth).clamp(safeStrokeWidth, size.width / 2);

    // Anneau de fond
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = safeStrokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Anneau de progression
    final progressPaint = Paint()
      ..color = phaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = safeStrokeWidth
      ..strokeCap = StrokeCap.round;

    final progress = phaseProgress.clamp(0.0, 1.0);
    final sweepAngle = 2 * math.pi * progress;
    
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Commencer en haut
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget cercle de respiration animé avec particules d'énergie
class BreathingCircleWidget extends StatefulWidget {
  final BreathingPhase currentPhase;
  final double phaseProgress;
  final int remainingSeconds;
  final double size;
  final bool isActive;
  final VoidCallback? onPhaseComplete;

  const BreathingCircleWidget({
    Key? key,
    required this.currentPhase,
    required this.phaseProgress,
    required this.remainingSeconds,
    this.size = 200,
    this.isActive = true,
    this.onPhaseComplete,
  }) : super(key: key);

  @override
  State<BreathingCircleWidget> createState() => _BreathingCircleWidgetState();
}

class _BreathingCircleWidgetState extends State<BreathingCircleWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  List<EnergyParticle> _particles = [];
  final int _maxParticles = 20;

  @override
  void initState() {
    super.initState();
    
    // Contrôleur pour l'animation de pulsation du cercle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Contrôleur pour les particules d'énergie
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50), // 60fps
      vsync: this,
    );
    
    // Contrôleur pour l'effet de lueur
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Initialiser les particules
    _initializeParticles();
    
    // Démarrer les animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _particleController.repeat();
    
    // Écouter les changements de particules
    _particleController.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    _particles.clear();
    for (int i = 0; i < _maxParticles; i++) {
      _particles.add(EnergyParticle.random(widget.size));
    }
  }

  void _updateParticles() {
    setState(() {
      final speed = _getParticleSpeed();
      for (var particle in _particles) {
        particle.update(speed);
        
        // Respawn les particules selon la direction
        bool shouldRespawn = false;
        if (speed > 0 && particle.distance > widget.size * 0.8) {
          // Particules s'éloignent - respawn quand trop loin
          shouldRespawn = true;
        } else if (speed < 0 && particle.distance < widget.size * 0.1) {
          // Particules convergent - respawn quand trop près du centre
          shouldRespawn = true;
        } else if (speed.abs() < 0.5 && particle.distance > widget.size * 0.6) {
          // Mouvement lent - respawn périodiquement
          shouldRespawn = true;
        }
        
        if (shouldRespawn) {
          particle.reset(widget.size);
        }
      }
    });
  }

  double _getParticleSpeed() {
    switch (widget.currentPhase) {
      case BreathingPhase.inspiration:
        return -1.0; // Particules convergent vers le centre
      case BreathingPhase.expiration:
        return 1.5; // Particules s'éloignent du centre
      case BreathingPhase.retention:
        return 0.2; // Particules bougent lentement
      default:
        return 0.5; // Mouvement normal
    }
  }

  Color _getCurrentPhaseColor() {
    return widget.currentPhase.phaseColor;
  }

  double _getCircleScale() {
    final progress = widget.phaseProgress.clamp(0.0, 1.0);
    switch (widget.currentPhase) {
      case BreathingPhase.inspiration:
        // Le cercle grandit pendant l'inspiration
        return (0.5 + (progress * 0.5)).clamp(0.1, 2.0);
      case BreathingPhase.expiration:
        // Le cercle rétrécit pendant l'expiration
        return (1.0 - (progress * 0.5)).clamp(0.1, 2.0);
      case BreathingPhase.retention:
        // Le cercle reste stable
        return 1.0;
      default:
        return 0.7;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Effet de lueur en arrière-plan
          _buildGlowEffect(),
          
          // Particules d'énergie
          _buildEnergyParticles(),
          
          // Cercle principal de respiration
          _buildMainCircle(),
          
          // Anneaux de progression
          _buildProgressRings(),
          
          // Timer central
          _buildCenterTimer(),
          
          // Instructions de phase
          _buildPhaseInstructions(),
        ],
      ),
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * 1.2,
          height: widget.size * 1.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getCurrentPhaseColor().withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 30 * _glowAnimation.value,
                spreadRadius: 10 * _glowAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnergyParticles() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: EnergyParticlesPainter(
        particles: _particles,
        phaseColor: _getCurrentPhaseColor(),
        isActive: widget.isActive,
      ),
    );
  }

  Widget _buildMainCircle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _getCircleScale() * _pulseAnimation.value;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getCurrentPhaseColor().withOpacity(0.8),
                  _getCurrentPhaseColor().withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressRings() {
    return SizedBox(
      width: widget.size * 0.9,
      height: widget.size * 0.9,
      child: CustomPaint(
        painter: ProgressRingsPainter(
          phaseProgress: widget.phaseProgress,
          phaseColor: _getCurrentPhaseColor(),
          strokeWidth: 4,
        ),
      ),
    );
  }

  Widget _buildCenterTimer() {
    return Container(
      width: widget.size * 0.25,
      height: widget.size * 0.25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EloquenceTheme.navy.withOpacity(0.8),
        border: Border.all(
          color: _getCurrentPhaseColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '${widget.remainingSeconds}',
          style: EloquenceTheme.timerDisplay.copyWith(
            fontSize: widget.size * 0.12,
            color: _getCurrentPhaseColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseInstructions() {
    return Positioned(
      bottom: widget.size * 0.05, // Position POSITIVE pour être visible
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: EloquenceTheme.navy.withOpacity(0.95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _getCurrentPhaseColor().withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCurrentPhaseColor().withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          widget.currentPhase.instruction,
          style: EloquenceTheme.bodyLarge.copyWith(
            color: _getCurrentPhaseColor(),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}