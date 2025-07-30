import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget d'avatar IA animé pour les interventions narratives
class AnimatedAIAvatarWidget extends StatefulWidget {
  final double size;
  final bool isActive;
  final bool isSpeaking;
  final VoidCallback? onTap;
  final Color primaryColor;
  final Color secondaryColor;

  const AnimatedAIAvatarWidget({
    super.key,
    this.size = 80,
    this.isActive = false,
    this.isSpeaking = false,
    this.onTap,
    this.primaryColor = const Color(0xFF6366F1), // Violet
    this.secondaryColor = const Color(0xFF0EA5E9), // Cyan
  });

  @override
  State<AnimatedAIAvatarWidget> createState() => _AnimatedAIAvatarWidgetState();
}

class _AnimatedAIAvatarWidgetState extends State<AnimatedAIAvatarWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breathingController;
  late AnimationController _orbitalController;
  late AnimationController _glowController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _orbitalAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation (cœur de l'avatar)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animation de rotation des particules
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Animation de respiration (expansion/contraction)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animation orbitale des points lumineux
    _orbitalController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    // Animation de lueur d'activité
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _setupAnimations();
    _startAnimations();
  }
  
  void _setupAnimations() {
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _orbitalAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _orbitalController,
      curve: Curves.linear,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() {
    _rotationController.repeat();
    _orbitalController.repeat();
    _breathingController.repeat(reverse: true);
    
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(AnimatedAIAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _glowController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _breathingController.dispose();
    _orbitalController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lueur de fond
            _buildGlowEffect(),
            
            // Particules orbitales
            _buildOrbitalParticles(),
            
            // Corps principal de l'avatar
            _buildMainAvatar(),
            
            // Particules de respiration
            _buildBreathingParticles(),
            
            // Indicateur d'activité vocale
            if (widget.isSpeaking) _buildSpeechIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.primaryColor.withOpacity(0.1 * _glowAnimation.value),
                widget.secondaryColor.withOpacity(0.05 * _glowAnimation.value),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrbitalParticles() {
    return AnimatedBuilder(
      animation: _orbitalAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: List.generate(6, (index) {
              final angle = (index * math.pi / 3) + _orbitalAnimation.value;
              final radius = widget.size * 0.35;
              final x = math.cos(angle) * radius;
              final y = math.sin(angle) * radius;
              
              return Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index.isEven ? widget.primaryColor : widget.secondaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: (index.isEven ? widget.primaryColor : widget.secondaryColor)
                            .withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildMainAvatar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _breathingAnimation]),
      builder: (context, child) {
        final scale = widget.isActive 
            ? _pulseAnimation.value * _breathingAnimation.value
            : _breathingAnimation.value;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.primaryColor,
                  widget.secondaryColor,
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: widget.secondaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icône centrale
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: widget.size * 0.25,
                ),
                
                // Effet de brillance animé
                _buildShimmerEffect(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBreathingParticles() {
    if (!widget.isActive) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 1.2,
          height: widget.size * 1.2,
          child: Stack(
            children: List.generate(8, (index) {
              final angle = (index * math.pi / 4);
              final radius = (widget.size * 0.4) * _breathingAnimation.value;
              final x = math.cos(angle) * radius;
              final y = math.sin(angle) * radius;
              
              return Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.6 / _breathingAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildSpeechIndicator() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: widget.size * 0.25,
              height: widget.size * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic,
                color: Colors.white,
                size: widget.size * 0.12,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget d'avatar IA pour les interventions dans les histoires
class StoryAIAvatarWidget extends StatelessWidget {
  final bool isActive;
  final bool isSpeaking;
  final VoidCallback? onTap;
  final String? message;

  const StoryAIAvatarWidget({
    super.key,
    this.isActive = true,
    this.isSpeaking = false,
    this.onTap,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedAIAvatarWidget(
          size: 80,
          isActive: isActive,
          isSpeaking: isSpeaking,
          onTap: onTap,
          primaryColor: const Color(0xFF8B5CF6), // Purple
          secondaryColor: const Color(0xFF06B6D4), // Cyan
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}