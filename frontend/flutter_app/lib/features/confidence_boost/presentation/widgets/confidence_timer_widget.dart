import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../presentation/theme/eloquence_design_system.dart';

class ConfidenceTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final int elapsedSeconds;
  
  const ConfidenceTimerWidget({
    Key? key,
    required this.totalSeconds,
    required this.elapsedSeconds,
  }) : super(key: key);

  @override
  State<ConfidenceTimerWidget> createState() => _ConfidenceTimerWidgetState();
}

class _ConfidenceTimerWidgetState extends State<ConfidenceTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = widget.elapsedSeconds / widget.totalSeconds;
    final remainingSeconds = widget.totalSeconds - widget.elapsedSeconds;
    
    return Column(
      children: [
        // Timer circulaire
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EloquenceColors.glassBackground,
                  border: Border.all(
                    color: EloquenceColors.glassBorder,
                    width: 2,
                  ),
                ),
              ),
              
              // Cercle de progression
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _CircularProgressPainter(
                      progress: progress,
                      strokeWidth: 8,
                    ),
                  );
                },
              ),
              
              // Temps au centre
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(remainingSeconds),
                    style: EloquenceTextStyles.headline1.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'restant',
                    style: EloquenceTextStyles.caption.copyWith(
                      color: EloquenceColors.cyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Barre de progression linéaire
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: EloquenceColors.glassBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(EloquenceColors.cyan),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Peinture pour le cercle de progression
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [EloquenceColors.cyan, EloquenceColors.violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Dessiner l'arc de progression
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Commencer en haut
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}