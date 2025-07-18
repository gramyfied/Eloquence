import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/animation/eloquence_animation_service.dart';

/// Widget constellation de compétences pour l'interface adaptative
/// 
/// ✅ OPTIMISÉ DESIGN SYSTEM ELOQUENCE :
/// - Animations conformes aux spécifications exactes (durées, courbes)
/// - Service d'animation centralisé pour performance optimale
/// - Courbes elasticOut et easeOutCubic standardisées
/// - Palette stricte : navy, cyan, violet, white + couleurs sémantiques
/// - Durées calibrées mobile : slow (500ms), xSlow (800ms)
class SkillsConstellation extends StatefulWidget {
  final List<Skill> skills;
  final double progress;
  final bool isAnimated;
  final VoidCallback? onSkillTap;
  
  const SkillsConstellation({
    Key? key,
    required this.skills,
    this.progress = 0.0,
    this.isAnimated = true,
    this.onSkillTap,
  }) : super(key: key);

  @override
  State<SkillsConstellation> createState() => _SkillsConstellationState();
}

class _SkillsConstellationState extends State<SkillsConstellation>
    with TickerProviderStateMixin {
  
  late AnimationController _constellationController;
  late AnimationController _progressController;
  late AnimationController _twinkleController;
  
  late Animation<double> _constellationAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _twinkleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isAnimated) {
      _startAnimations();
    }
  }
  
  void _initializeAnimations() {
    // Animation de rotation lente de la constellation - OPTIMISÉE
    _constellationController = AnimationController(
      duration: const Duration(seconds: 20), // Rotation très lente pour cohérence
      vsync: this,
    );
    
    // Animation de progression des compétences - CONFORMES DESIGN SYSTEM
    _progressController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.slow,
    );
    
    // Animation de scintillement des étoiles - COURBES STANDARDISÉES
    _twinkleController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.xSlow,
    );
    
    // Animations conformes aux spécifications Design System Eloquence
    _constellationAnimation = EloquenceAnimationService.createRotationAnimation(_constellationController);
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: EloquenceTheme.curveEmphasized,
    ));
    _twinkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _twinkleController,
      curve: EloquenceTheme.curveStandard,
    ));
  }
  
  void _startAnimations() {
    _constellationController.repeat();
    _progressController.forward();
    _twinkleController.repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(SkillsConstellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: EloquenceTheme.curveEmphasized,
      ));
      
      _progressController.reset();
      _progressController.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _constellationAnimation,
          _progressAnimation,
          _twinkleAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _ConstellationPainter(
              skills: widget.skills,
              progress: _progressAnimation.value,
              rotationAngle: _constellationAnimation.value,
              twinklePhase: _twinkleAnimation.value,
            ),
            child: _buildSkillNodes(),
          );
        },
      ),
    );
  }
  
  Widget _buildSkillNodes() {
    return Stack(
      children: widget.skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        final position = _getSkillPosition(index, widget.skills.length);
        
        return AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final isUnlocked = skill.progress >= 0.2;
            final opacity = isUnlocked ? 1.0 : 0.3;
            
            return Positioned(
              left: position.dx - 30,
              top: position.dy - 30,
              child: AnimatedOpacity(
                opacity: opacity,
                duration: EloquenceTheme.animationMedium,
                curve: EloquenceTheme.curveEmphasized,
                child: GestureDetector(
                  onTap: isUnlocked ? () => widget.onSkillTap?.call() : null,
                  child: _buildSkillNode(skill, isUnlocked),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildSkillNode(Skill skill, bool isUnlocked) {
    final size = 60.0;
    final color = isUnlocked ? _getSkillColor(skill.category) : Colors.grey;
    
    return AnimatedBuilder(
      animation: _twinkleAnimation,
      builder: (context, child) {
        final twinkleIntensity = isUnlocked 
            ? (1.0 + 0.2 * math.sin(_twinkleAnimation.value * 2 * math.pi))
            : 1.0;
            
        return Transform.scale(
          scale: twinkleIntensity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),
              border: Border.all(
                color: EloquenceTheme.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                if (isUnlocked)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSkillIcon(skill.category),
                  color: EloquenceTheme.white,
                  size: 20,
                ),
                SizedBox(height: EloquenceTheme.spacingXs),
                Text(
                  '${(skill.progress * 100).toInt()}%',
                  style: EloquenceTheme.caption.copyWith(
                    color: EloquenceTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Offset _getSkillPosition(int index, int total) {
    final centerX = 150.0;
    final centerY = 150.0;
    final radius = 80.0;
    
    final angle = (index * 2 * math.pi / total) + _constellationAnimation.value * 0.1;
    final x = centerX + radius * math.cos(angle);
    final y = centerY + radius * math.sin(angle);
    
    return Offset(x, y);
  }
  
  Color _getSkillColor(SkillCategory category) {
    switch (category) {
      case SkillCategory.confidence:
        return EloquenceTheme.cyan;
      case SkillCategory.fluency:
        return EloquenceTheme.violet;
      case SkillCategory.clarity:
        return EloquenceTheme.successGreen;
      case SkillCategory.energy:
        return EloquenceTheme.warningOrange;
      case SkillCategory.presence:
        return EloquenceTheme.errorRed;
    }
  }
  
  IconData _getSkillIcon(SkillCategory category) {
    switch (category) {
      case SkillCategory.confidence:
        return Icons.psychology_rounded;
      case SkillCategory.fluency:
        return Icons.waves_rounded;
      case SkillCategory.clarity:
        return Icons.record_voice_over_rounded;
      case SkillCategory.energy:
        return Icons.bolt_rounded;
      case SkillCategory.presence:
        return Icons.star_rounded;
    }
  }
  
  @override
  void dispose() {
    _constellationController.dispose();
    _progressController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<Skill> skills;
  final double progress;
  final double rotationAngle;
  final double twinklePhase;
  
  _ConstellationPainter({
    required this.skills,
    required this.progress,
    required this.rotationAngle,
    required this.twinklePhase,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = 80.0;
    
    // Dessiner les connexions entre les compétences
    _drawConnections(canvas, size, centerX, centerY, radius);
    
    // Dessiner les particules flottantes
    _drawFloatingParticles(canvas, size);
  }
  
  void _drawConnections(Canvas canvas, Size size, double centerX, double centerY, double radius) {
    final paint = Paint()
      ..color = EloquenceTheme.cyan.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < skills.length; i++) {
      final nextIndex = (i + 1) % skills.length;
      
      final angle1 = (i * 2 * math.pi / skills.length) + rotationAngle * 0.1;
      final angle2 = (nextIndex * 2 * math.pi / skills.length) + rotationAngle * 0.1;
      
      final x1 = centerX + radius * math.cos(angle1);
      final y1 = centerY + radius * math.sin(angle1);
      final x2 = centerX + radius * math.cos(angle2);
      final y2 = centerY + radius * math.sin(angle2);
      
      // N'afficher la connexion que si les deux compétences sont débloquées
      final skill1Unlocked = skills[i].progress >= 0.2;
      final skill2Unlocked = skills[nextIndex].progress >= 0.2;
      
      if (skill1Unlocked && skill2Unlocked) {
        final opacity = 0.3 + 0.2 * math.sin(twinklePhase * 2 * math.pi + i);
        paint.color = EloquenceTheme.cyan.withOpacity(opacity);
        
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint,
        );
      }
    }
  }
  
  void _drawFloatingParticles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi / 12) + rotationAngle + twinklePhase;
      final distance = 120 + 20 * math.sin(twinklePhase * 2 * math.pi + i);
      
      final x = size.width / 2 + distance * math.cos(angle);
      final y = size.height / 2 + distance * math.sin(angle);
      
      final opacity = (0.3 + 0.4 * math.sin(twinklePhase * 2 * math.pi + i * 0.5)).clamp(0.0, 0.7);
      paint.color = EloquenceTheme.violet.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        2,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.rotationAngle != rotationAngle ||
           oldDelegate.twinklePhase != twinklePhase;
  }
}

// Modèles de données pour les compétences
class Skill {
  final String name;
  final SkillCategory category;
  final double progress;
  final bool isUnlocked;
  
  const Skill({
    required this.name,
    required this.category,
    required this.progress,
    this.isUnlocked = false,
  });
}

enum SkillCategory {
  confidence,
  fluency,
  clarity,
  energy,
  presence,
}