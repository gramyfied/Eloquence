import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/entities/virelangue_models.dart';
import '../theme/virelangue_roulette_theme.dart';

/// Widget de roulette animée 60fps qui tourne et tombe sur un virelangue
/// Animation réaliste avec décélération et arrêt précis
class SpinningWheel60fps extends StatefulWidget {
  final List<Virelangue> virelangues;
  final Virelangue? targetVirelangue;
  final VoidCallback? onSpinComplete;
  final double size;
  final bool autoSpin;

  const SpinningWheel60fps({
    super.key,
    required this.virelangues,
    this.targetVirelangue,
    this.onSpinComplete,
    this.size = 280,
    this.autoSpin = false,
  });

  @override
  State<SpinningWheel60fps> createState() => SpinningWheel60fpsState();
}

class SpinningWheel60fpsState extends State<SpinningWheel60fps>
    with TickerProviderStateMixin {
  
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late Ticker _ticker;
  
  double _currentRotation = 0.0;
  bool _isSpinning = false;
  int? _targetSegmentIndex;
  
  // Paramètres d'animation réalistes
  static const int _totalSpins = 5; // Nombre de tours complets
  static const double _decelerationFactor = 0.3; // Facteur de décélération
  static const Duration _spinDuration = Duration(milliseconds: 3500); // 3.5 secondes

  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: _spinDuration,
      vsync: this,
    );

    // Animation avec courbe de décélération réaliste
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutExpo, // Courbe de décélération naturelle
    ));

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        widget.onSpinComplete?.call();
      }
    });

    // Démarrage automatique si demandé
    if (widget.autoSpin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startSpin();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SpinningWheel60fps oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.targetVirelangue != oldWidget.targetVirelangue) {
      _calculateTargetSegment();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  /// Calcule l'index du segment cible
  void _calculateTargetSegment() {
    if (widget.targetVirelangue != null && widget.virelangues.isNotEmpty) {
      _targetSegmentIndex = widget.virelangues.indexWhere(
        (v) => v.id == widget.targetVirelangue!.id,
      );
      if (_targetSegmentIndex == -1) {
        _targetSegmentIndex = 0; // Fallback au premier segment
      }
    } else {
      _targetSegmentIndex = math.Random().nextInt(widget.virelangues.length);
    }
  }

  /// Démarre l'animation de rotation 60fps (méthode publique)
  void startSpin() {
    if (_isSpinning || widget.virelangues.isEmpty) return;

    _calculateTargetSegment();
    
    setState(() {
      _isSpinning = true;
    });

    // Calcul de la rotation finale pour tomber sur le bon segment
    final segmentAngle = 2 * math.pi / widget.virelangues.length;
    final targetAngle = (_targetSegmentIndex ?? 0) * segmentAngle;
    
    // Animation avec rotations multiples + angle cible précis
    final totalRotation = (_totalSpins * 2 * math.pi) + (2 * math.pi - targetAngle);
    
    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + totalRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutExpo,
    ));

    _spinController.forward(from: 0);
  }

  /// Force l'arrêt de la roulette
  void stopSpin() {
    if (!_isSpinning) return;
    
    _spinController.stop();
    setState(() {
      _isSpinning = false;
      _currentRotation = _spinAnimation.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isSpinning) {
          startSpin();
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Roulette principale avec animation
            AnimatedBuilder(
              animation: _spinAnimation,
              builder: (context, child) {
                final rotation = _isSpinning ? _spinAnimation.value : _currentRotation;
                
                return Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          VirelangueRouletteTheme.navyBackground,
                          VirelangueRouletteTheme.navyBackground.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: RealisticWheelPainter(
                        virelangues: widget.virelangues,
                        targetVirelangue: widget.targetVirelangue,
                        isSpinning: _isSpinning,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Pointeur de sélection (triangle cyan en haut)
            _buildRealisticPointer(),
            
            // Centre de la roulette avec icône
            _buildWheelCenter(),
            
            // Effets de particules lors du spin
            if (_isSpinning) _buildSpinEffects(),
          ],
        ),
      ),
    );
  }

  /// Construit le pointeur triangulaire réaliste
  Widget _buildRealisticPointer() {
    return Positioned(
      top: 8,
      child: Container(
        width: 40,
        height: 30,
        child: CustomPaint(
          painter: TrianglePointerPainter(),
        ),
      ),
    );
  }

  /// Centre de la roulette avec animation
  Widget _buildWheelCenter() {
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: -(_isSpinning ? _spinAnimation.value : _currentRotation),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isSpinning ? Icons.blur_circular : Icons.casino,
              color: VirelangueRouletteTheme.navyBackground,
              size: _isSpinning ? 32 : 28,
            ),
          ),
        );
      },
    );
  }

  /// Effets visuels pendant le spin
  Widget _buildSpinEffects() {
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size + 20,
          height: widget.size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: VirelangueRouletteTheme.cyanPrimary.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: VirelangueRouletteTheme.cyanPrimary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Painter pour le triangle pointeur
class TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VirelangueRouletteTheme.cyanPrimary
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(size.width / 4, 0);
    path.lineTo(3 * size.width / 4, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Contour blanc
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter réaliste pour la roulette avec segments colorés
class RealisticWheelPainter extends CustomPainter {
  final List<Virelangue> virelangues;
  final Virelangue? targetVirelangue;
  final bool isSpinning;

  // Palette de couleurs vibrantes inspirée de l'image
  static const List<Color> wheelColors = [
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Violet
    Color(0xFF4CAF50), // Vert
    Color(0xFFFFB300), // Ambre
    Color(0xFFE91E63), // Rose
    Color(0xFF2196F3), // Bleu
    Color(0xFFFF7043), // Orange profond
    Color(0xFF8BC34A), // Vert clair
  ];

  const RealisticWheelPainter({
    required this.virelangues,
    this.targetVirelangue,
    this.isSpinning = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (virelangues.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final segmentAngle = 2 * math.pi / virelangues.length;

    for (int i = 0; i < virelangues.length; i++) {
      final virelangue = virelangues[i];
      final startAngle = i * segmentAngle - math.pi / 2;
      final isTarget = targetVirelangue?.id == virelangue.id;

      // Dessiner le segment avec effet de brillance
      _drawEnhancedSegment(
        canvas,
        center,
        radius,
        startAngle,
        segmentAngle,
        i,
        isTarget,
      );

      // Dessiner le texte avec effet de lisibilité
      if (!isSpinning) {
        _drawSegmentText(
          canvas,
          center,
          radius,
          startAngle,
          segmentAngle,
          virelangue,
          isTarget,
        );
      }
    }

    // Contour extérieur brillant
    _drawOuterGlow(canvas, center, radius);
  }

  /// Dessine un segment avec effets visuels améliorés
  void _drawEnhancedSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double segmentAngle,
    int index,
    bool isTarget,
  ) {
    final baseColor = wheelColors[index % wheelColors.length];
    
    // Gradient radial pour l'effet de profondeur
    final gradient = RadialGradient(
      center: Alignment.center,
      colors: [
        baseColor.withOpacity(0.9),
        baseColor,
        baseColor.withOpacity(0.7),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      segmentAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Contour entre segments
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    canvas.drawPath(path, strokePaint);

    // Surbrillance pour le segment cible
    if (isTarget) {
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);
      
      canvas.drawPath(path, highlightPaint);
    }
  }

  /// Dessine le texte sur les segments
  void _drawSegmentText(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double segmentAngle,
    Virelangue virelangue,
    bool isTarget,
  ) {
    final textAngle = startAngle + segmentAngle / 2;
    final textRadius = radius * 0.65;
    
    final textX = center.dx + math.cos(textAngle) * textRadius;
    final textY = center.dy + math.sin(textAngle) * textRadius;

    // Texte tronqué et stylisé
    final truncatedText = _truncateText(virelangue.text, 12);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: truncatedText,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isTarget ? FontWeight.bold : FontWeight.w600,
          fontSize: isTarget ? 13 : 11,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );

    textPainter.layout(maxWidth: radius * 0.4);

    // Rotation du texte pour lisibilité
    canvas.save();
    canvas.translate(textX, textY);
    
    double textRotation = textAngle;
    if (textAngle > math.pi / 2 && textAngle < 3 * math.pi / 2) {
      textRotation += math.pi;
    }
    
    canvas.rotate(textRotation);
    
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    
    canvas.restore();
  }

  /// Dessine l'effet de brillance extérieur
  void _drawOuterGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = VirelangueRouletteTheme.cyanPrimary.withOpacity(0.4)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center, radius + 2, glowPaint);
  }

  /// Tronque le texte si nécessaire
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }

  @override
  bool shouldRepaint(covariant RealisticWheelPainter oldDelegate) {
    return oldDelegate.virelangues != virelangues ||
           oldDelegate.targetVirelangue != targetVirelangue ||
           oldDelegate.isSpinning != isSpinning;
  }
}