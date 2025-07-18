import 'package:flutter/material.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/animation/eloquence_animation_service.dart';

/// Widget de microphone animé pour l'interface adaptative Boost Confidence
///
/// ✅ OPTIMISÉ DESIGN SYSTEM ELOQUENCE :
/// - Animations conformes aux spécifications exactes (durées, courbes)
/// - Palette stricte : navy, cyan, violet, white uniquement
/// - Micro-interactions tactiles optimisées mobile
/// - Service d'animation centralisé pour performance
/// - Courbes easeOutCubic et elasticOut standardisées
class AnimatedMicrophoneButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback? onPressed;
  final double size;
  final bool isEnabled;
  
  const AnimatedMicrophoneButton({
    Key? key,
    required this.isRecording,
    this.onPressed,
    this.size = 120.0,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<AnimatedMicrophoneButton> createState() => _AnimatedMicrophoneButtonState();
}

class _AnimatedMicrophoneButtonState extends State<AnimatedMicrophoneButton>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Animation de pulsation continue durant l'enregistrement - OPTIMISÉE
    _pulseController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.slow,
    );
    
    // Animation de scale au tap - MICRO-INTERACTION OPTIMISÉE
    _scaleController = EloquenceAnimationService.createMicroInteraction(
      vsync: this,
    );
    
    // Animation de ripple d'onde sonore - FEEDBACK VISUEL OPTIMISÉ
    _rippleController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.xSlow,
    );
    
    // Animations conformes aux spécifications Design System
    _pulseAnimation = EloquenceAnimationService.createPulseAnimation(_pulseController);
    _scaleAnimation = EloquenceAnimationService.createScaleAnimation(_scaleController);
    _rippleAnimation = EloquenceAnimationService.createFadeAnimation(_rippleController);
  }
  
  @override
  void didUpdateWidget(AnimatedMicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startRecordingAnimations();
      } else {
        _stopRecordingAnimations();
      }
    }
  }
  
  void _startRecordingAnimations() {
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
  }
  
  void _stopRecordingAnimations() {
    _pulseController.stop();
    _rippleController.stop();
    _pulseController.reset();
    _rippleController.reset();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _scaleController.forward();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _scaleController.reverse();
      widget.onPressed?.call();
    }
  }
  
  void _handleTapCancel() {
    if (widget.isEnabled) {
      _scaleController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _scaleAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ondes sonores animées pendant l'enregistrement
              if (widget.isRecording) ..._buildSoundWaves(),
              
              // Bouton principal
              Transform.scale(
                scale: _scaleAnimation.value * (widget.isRecording ? _pulseAnimation.value : 1.0),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getMicrophoneGradient(),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isRecording ? EloquenceTheme.cyan : EloquenceTheme.violet)
                            .withOpacity(0.4),
                        blurRadius: widget.isRecording ? 30 : 20,
                        spreadRadius: widget.isRecording ? 10 : 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: widget.size * 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  List<Widget> _buildSoundWaves() {
    return List.generate(3, (index) {
      final delay = index * 0.3;
      final size = widget.size * (1.5 + index * 0.3);
      
      return AnimatedBuilder(
        animation: _rippleController,
        builder: (context, child) {
          final progress = (_rippleAnimation.value + delay) % 1.0;
          
          return Positioned.fill(
            child: Container(
              width: size * progress,
              height: size * progress,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EloquenceTheme.cyan.withOpacity(
                    (1.0 - progress) * 0.6,
                  ),
                  width: 2,
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  Gradient _getMicrophoneGradient() {
    if (!widget.isEnabled) {
      return LinearGradient(
        colors: [
          Colors.grey.withOpacity(0.5),
          Colors.grey.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    if (widget.isRecording) {
      return LinearGradient(
        colors: [
          EloquenceTheme.cyan,
          EloquenceTheme.violet,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    return LinearGradient(
      colors: [
        EloquenceTheme.violet.withOpacity(0.8),
        EloquenceTheme.navy.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }
}
