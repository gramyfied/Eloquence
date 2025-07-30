import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/virelangue_models.dart';
import '../theme/virelangue_roulette_theme.dart';

/// Roulette simplifiée selon le design des images
/// Design épuré avec segments colorés variés et pointer simple
class VirelangueWheel extends StatefulWidget {
  final List<Virelangue> virelangues;
  final Animation<double> rotationAnimation;
  final bool isSpinning;
  final Virelangue? selectedVirelangue;
  final VoidCallback? onTap;
  final double size;

  const VirelangueWheel({
    super.key,
    required this.virelangues,
    required this.rotationAnimation,
    this.isSpinning = false,
    this.selectedVirelangue,
    this.onTap,
    this.size = 280,
  });

  @override
  State<VirelangueWheel> createState() => _VirelangueWheelState();
}

class _VirelangueWheelState extends State<VirelangueWheel>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.rotationAnimation,
          _pulseAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSpinning ? 1.0 : _pulseAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Roulette principale
                  _buildSimpleWheel(),
                  
                  // Pointeur de sélection
                  _buildSimplePointer(),
                  
                  // Centre simple
                  _buildSimpleCenter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit la roulette simplifiée selon les images
  Widget _buildSimpleWheel() {
    if (widget.virelangues.isEmpty) {
      return _buildLoadingWheel();
    }

    return Transform.rotate(
      angle: widget.rotationAnimation.value * 2 * math.pi,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VirelangueRouletteTheme.navyBackground,
          border: Border.all(
            color: VirelangueRouletteTheme.whiteText.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: SimpleWheelPainter(
            virelangues: widget.virelangues,
            selectedVirelangue: widget.selectedVirelangue,
          ),
        ),
      ),
    );
  }

  /// Construit une roulette de chargement simple
  Widget _buildLoadingWheel() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VirelangueRouletteTheme.navyBackground,
        border: Border.all(
          color: VirelangueRouletteTheme.whiteText.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  VirelangueRouletteTheme.cyanPrimary,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(
                color: VirelangueRouletteTheme.whiteText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pointeur simple selon les images
  Widget _buildSimplePointer() {
    return Positioned(
      top: 15,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VirelangueRouletteTheme.whiteText,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down,
          color: VirelangueRouletteTheme.navyBackground,
          size: 20,
        ),
      ),
    );
  }

  /// Centre simple de la roue
  Widget _buildSimpleCenter() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VirelangueRouletteTheme.whiteText,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: -widget.rotationAnimation.value * 2 * math.pi,
        child: Icon(
          Icons.casino,
          color: VirelangueRouletteTheme.navyBackground,
          size: 24,
        ),
      ),
    );
  }
}

/// Painter simplifié pour dessiner les segments colorés de la roue
class SimpleWheelPainter extends CustomPainter {
  final List<Virelangue> virelangues;
  final Virelangue? selectedVirelangue;

  // Couleurs des segments selon le design des images
  static const List<Color> segmentColors = [
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Violet  
    Color(0xFF4CAF50), // Vert
    Color(0xFFFFC107), // Jaune/Or
    Color(0xFFE91E63), // Rose/Magenta
    Color(0xFF2196F3), // Bleu
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Bleu gris
  ];

  const SimpleWheelPainter({
    required this.virelangues,
    this.selectedVirelangue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (virelangues.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final segmentAngle = 2 * math.pi / virelangues.length;

    for (int i = 0; i < virelangues.length; i++) {
      final virelangue = virelangues[i];
      final startAngle = i * segmentAngle - math.pi / 2;
      final isSelected = selectedVirelangue?.id == virelangue.id;

      // Dessiner le segment
      _drawSegment(
        canvas,
        center,
        radius,
        startAngle,
        segmentAngle,
        i,
        isSelected,
      );

      // Dessiner le texte
      _drawSegmentText(
        canvas,
        center,
        radius,
        startAngle,
        segmentAngle,
        virelangue,
        isSelected,
      );
    }
  }

  /// Dessine un segment de la roue avec couleurs variées
  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double segmentAngle,
    int index,
    bool isSelected,
  ) {
    final segmentColor = segmentColors[index % segmentColors.length];
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isSelected 
          ? segmentColor.withOpacity(1.0)
          : segmentColor.withOpacity(0.8);

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

    // Contour blanc subtil entre les segments
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = VirelangueRouletteTheme.whiteText.withOpacity(0.2)
      ..strokeWidth = 1.5;

    canvas.drawPath(path, strokePaint);

    // Surbrillance pour le segment sélectionné
    if (isSelected) {
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = VirelangueRouletteTheme.whiteText
        ..strokeWidth = 3;
      
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
    bool isSelected,
  ) {
    final textAngle = startAngle + segmentAngle / 2;
    final textRadius = radius * 0.7;
    
    final textX = center.dx + math.cos(textAngle) * textRadius;
    final textY = center.dy + math.sin(textAngle) * textRadius;

    // Style de texte simple et lisible
    final textPainter = TextPainter(
      text: TextSpan(
        text: _truncateText(virelangue.text, 15),
        style: TextStyle(
          color: VirelangueRouletteTheme.whiteText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: isSelected ? 12 : 10,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Rotation du texte pour lisibilité
    canvas.save();
    canvas.translate(textX, textY);
    
    // Ajuster la rotation selon la position
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

  /// Tronque le texte si trop long
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  @override
  bool shouldRepaint(covariant SimpleWheelPainter oldDelegate) {
    return oldDelegate.virelangues != virelangues ||
           oldDelegate.selectedVirelangue != selectedVirelangue;
  }
}

/// Widget d'animation de la roulette pour les états spéciaux
class AnimatedVirelangueWheel extends StatefulWidget {
  final List<Virelangue> virelangues;
  final Virelangue? selectedVirelangue;
  final bool isSpinning;
  final VoidCallback? onSpinComplete;
  final double size;

  const AnimatedVirelangueWheel({
    super.key,
    required this.virelangues,
    this.selectedVirelangue,
    this.isSpinning = false,
    this.onSpinComplete,
    this.size = 280,
  });

  @override
  State<AnimatedVirelangueWheel> createState() => _AnimatedVirelangueWheelState();
}

class _AnimatedVirelangueWheelState extends State<AnimatedVirelangueWheel>
    with TickerProviderStateMixin {
  
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0, // 6 tours complets
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutQuart,
    ));

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSpinComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedVirelangueWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _stopSpin();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _startSpin() {
    _spinController.forward(from: 0);
  }

  void _stopSpin() {
    _spinController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return VirelangueWheel(
      virelangues: widget.virelangues,
      rotationAnimation: _spinAnimation,
      isSpinning: widget.isSpinning,
      selectedVirelangue: widget.selectedVirelangue,
      size: widget.size,
    );
  }
}