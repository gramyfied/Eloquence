import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget d'avatar avec halo lumineux pour les personnages IA
/// 
/// Fonctionnalités :
/// - Effet halo adaptatif selon le personnage
/// - Animations de présence et d'activité
/// - Design System Eloquence intégré
/// - Support des personnages Thomas et Marie
class AvatarWithHalo extends StatefulWidget {
  final String characterName;
  final String? avatarImagePath;
  final double size;
  final bool isActive;
  final bool isAnimated;
  final Color? primaryColor;
  final IconData? fallbackIcon;
  
  const AvatarWithHalo({
    Key? key,
    required this.characterName,
    this.avatarImagePath,
    this.size = 80.0,
    this.isActive = false,
    this.isAnimated = true,
    this.primaryColor,
    this.fallbackIcon,
  }) : super(key: key);

  @override
  State<AvatarWithHalo> createState() => _AvatarWithHaloState();
}

class _AvatarWithHaloState extends State<AvatarWithHalo>
    with TickerProviderStateMixin {
  
  late AnimationController _haloController;
  late AnimationController _pulseController;
  late AnimationController _presenceController;
  
  late Animation<double> _haloAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _presenceAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isAnimated) {
      _startAnimations();
    }
  }
  
  void _initializeAnimations() {
    // Animation du halo rotatif
    _haloController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Animation de pulsation d'activité
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animation de présence (entrée/sortie)
    _presenceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _haloAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _haloController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _presenceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _presenceController,
      curve: Curves.elasticOut,
    ));
  }
  
  void _startAnimations() {
    _haloController.repeat();
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
    _presenceController.forward();
  }
  
  @override
  void didUpdateWidget(AvatarWithHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
    
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }
  
  void _stopAnimations() {
    _haloController.stop();
    _pulseController.stop();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _haloAnimation,
        _pulseAnimation,
        _presenceAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _presenceAnimation.value * 
                 (widget.isActive ? _pulseAnimation.value : 1.0),
          child: SizedBox(
            width: widget.size * 1.4,
            height: widget.size * 1.4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo lumineux rotatif
                if (widget.isActive) _buildHalo(),
                
                // Avatar principal
                _buildAvatar(),
                
                // Indicateur d'activité
                if (widget.isActive) _buildActivityIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHalo() {
    final color = _getCharacterColor();
    
    return Transform.rotate(
      angle: _haloAnimation.value,
      child: Container(
        width: widget.size * 1.3,
        height: widget.size * 1.3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.transparent,
              EloquenceTheme.withOpacity(color, 0.1),
              EloquenceTheme.withOpacity(color, 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _HaloPainter(
            color: color,
            progress: _haloAnimation.value,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    final color = _getCharacterColor();
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            EloquenceTheme.withOpacity(color, 0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: EloquenceTheme.withOpacity(Colors.white, 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: EloquenceTheme.withOpacity(color, 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _buildAvatarContent(),
    );
  }
  
  Widget _buildAvatarContent() {
    if (widget.avatarImagePath != null) {
      return ClipOval(
        child: Image.asset(
          widget.avatarImagePath!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        ),
      );
    }
    
    return _buildFallbackAvatar();
  }
  
  Widget _buildFallbackAvatar() {
    return Center(
      child: Icon(
        widget.fallbackIcon ?? _getCharacterIcon(),
        size: widget.size * 0.5,
        color: Colors.white,
      ),
    );
  }
  
  Widget _buildActivityIndicator() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: widget.size * 0.25,
        height: widget.size * 0.25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EloquenceColors.cyan,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: EloquenceTheme.withOpacity(EloquenceColors.cyan, 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Color _getCharacterColor() {
    if (widget.primaryColor != null) {
      return widget.primaryColor!;
    }
    
    switch (widget.characterName.toLowerCase()) {
      case 'thomas':
        return EloquenceColors.violet;
      case 'marie':
        return EloquenceColors.cyan;
      default:
        return EloquenceColors.violet;
    }
  }
  
  IconData _getCharacterIcon() {
    switch (widget.characterName.toLowerCase()) {
      case 'thomas':
        return Icons.business_rounded;
      case 'marie':
        return Icons.person_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }
  
  @override
  void dispose() {
    _haloController.dispose();
    _pulseController.dispose();
    _presenceController.dispose();
    super.dispose();
  }
}

class _HaloPainter extends CustomPainter {
  final Color color;
  final double progress;
  
  _HaloPainter({
    required this.color,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Dessiner des étoiles scintillantes autour du halo
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi / 8) + progress;
      final distance = radius * (0.7 + 0.1 * math.sin(progress + i));
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      final opacity = (math.sin(progress * 2 + i) + 1) / 2;
      paint.color = EloquenceTheme.withOpacity(color, opacity * 0.6);
      
      _drawStar(canvas, Offset(x, y), 3, paint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      
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
  bool shouldRepaint(_HaloPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}