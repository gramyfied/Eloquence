import 'package:flutter/material.dart';
import '../../domain/entities/confidence_models.dart';

// Painter pour les confettis
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      // Mettre à jour la position
      particle.update(0.016); // Simule 60 FPS

      // Ne dessiner que si visible
      if (particle.y < size.height + 20) {
        paint.color = particle.color.withAlpha((255 * (1.0 - progress)).round());

        canvas.save();
        canvas.translate(particle.x, particle.y);
        canvas.rotate(particle.rotation);

        // Dessiner un rectangle arrondi pour le confetti
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.1),
        );

        canvas.drawRRect(rect, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}