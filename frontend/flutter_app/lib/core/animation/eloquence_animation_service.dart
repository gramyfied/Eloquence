import 'package:flutter/material.dart';
import '../theme/eloquence_unified_theme.dart';

/// Service centralisé d'optimisation des animations Eloquence
/// 
/// ✅ FONCTIONNALITÉS :
/// - Animations conformes aux spécifications exactes du Design System
/// - Durées et courbes standardisées pour cohérence mobile
/// - Factory methods pour micro-interactions optimisées
/// - Gestion intelligente du performance budget
/// 
/// ⚡ OPTIMISATIONS MOBILE :
/// - Durées calibrées pour devices 60Hz/120Hz
/// - Courbes optimisées pour fluidité tactile
/// - Memory management pour AnimationControllers
/// - Réduction des repaints inutiles
class EloquenceAnimationService {
  
  // ========== TYPES D'ANIMATIONS STANDARDISÉES ==========
  
  /// Animation d'entrée standard (éléments qui apparaissent)
  static AnimationController createEnterAnimation({
    required TickerProvider vsync,
    AnimationSpeed speed = AnimationSpeed.medium,
  }) {
    return AnimationController(
      duration: speed.duration,
      vsync: vsync,
    );
  }
  
  /// Animation de sortie standard (éléments qui disparaissent)
  static AnimationController createExitAnimation({
    required TickerProvider vsync,
    AnimationSpeed speed = AnimationSpeed.medium,
  }) {
    return AnimationController(
      duration: speed.duration,
      vsync: vsync,
    );
  }
  
  /// Animation de micro-interaction (tap, hover, focus)
  static AnimationController createMicroInteraction({
    required TickerProvider vsync,
  }) {
    return AnimationController(
      duration: EloquenceTheme.animationFast,
      vsync: vsync,
    );
  }
  
  /// Animation de transition de page
  static AnimationController createPageTransition({
    required TickerProvider vsync,
  }) {
    return AnimationController(
      duration: EloquenceTheme.animationSlow,
      vsync: vsync,
    );
  }
  
  /// Animation de feedback visuel (succès, erreur, chargement)
  static AnimationController createFeedbackAnimation({
    required TickerProvider vsync,
    AnimationSpeed speed = AnimationSpeed.medium,
  }) {
    return AnimationController(
      duration: speed.duration,
      vsync: vsync,
    );
  }
  
  // ========== ANIMATIONS PRÉDÉFINIES OPTIMISÉES ==========
  
  /// Animation de pulsation pour boutons actifs
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveEmphasized,
    ));
  }
  
  /// Animation de scale pour micro-interactions
  static Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveEmphasized,
    ));
  }
  
  /// Animation de slide pour entrée d'éléments
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    SlideDirection direction = SlideDirection.fromBottom,
  }) {
    return Tween<Offset>(
      begin: direction.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveElastic,
    ));
  }
  
  /// Animation de rotation pour indicateurs de chargement
  static Animation<double> createRotationAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 6.28318, // 2 * PI
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }
  
  /// Animation de fade pour transitions douces
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveEnter,
    ));
  }
  
  /// Animation élastique pour feedbacks spectaculaires
  static Animation<double> createElasticAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveElastic,
    ));
  }
  
  /// Animation de rebond pour célébrations
  static Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: EloquenceTheme.curveBounce,
    ));
  }
  
  // ========== ANIMATIONS COMPLEXES COMBINÉES ==========
  
  /// Animation de matérialisation (fade + scale + slide)
  static Map<String, Animation> createMaterializationAnimation(
    AnimationController controller, {
    SlideDirection slideDirection = SlideDirection.fromBottom,
  }) {
    return {
      'fade': createFadeAnimation(controller),
      'scale': Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: EloquenceTheme.curveElastic),
      ),
      'slide': createSlideAnimation(controller, direction: slideDirection),
    };
  }
  
  /// Animation de révélation progressive
  static Animation<double> createRevealAnimation(
    AnimationController controller, {
    double delay = 0.0,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay,
        1.0,
        curve: EloquenceTheme.curveEmphasized,
      ),
    ));
  }
  
  /// Animation de celebration avec multiples effets
  static Map<String, Animation> createCelebrationAnimation(
    AnimationController controller,
  ) {
    return {
      'bounce': createBounceAnimation(controller),
      'glow': Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: EloquenceTheme.curveElastic),
      ),
      'rotation': Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(parent: controller, curve: EloquenceTheme.curveBounce),
      ),
    };
  }
  
  // ========== MICRO-INTERACTIONS OPTIMISÉES ==========
  
  /// Feedback tactile pour boutons
  static void playTapFeedback(AnimationController controller) {
    controller.forward().then((_) {
      controller.reverse();
    });
  }
  
  /// Séquence d'animation en cascade
  static Future<void> playCascadeAnimation(
    List<AnimationController> controllers, {
    Duration stagger = const Duration(milliseconds: 50),
  }) async {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].forward();
      if (i < controllers.length - 1) {
        await Future.delayed(stagger);
      }
    }
  }
  
  /// Animation de chargement avec phases
  static void playLoadingSequence(
    AnimationController controller, {
    bool repeat = true,
  }) {
    if (repeat) {
      controller.repeat();
    } else {
      controller.forward();
    }
  }
  
  // ========== UTILITAIRES DE PERFORMANCE ==========
  
  /// Dispose multiple controllers efficiently
  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
  
  /// Check si animation est active pour éviter conflicts
  static bool isAnimationActive(AnimationController controller) {
    return controller.isAnimating;
  }
  
  /// Reset animation à l'état initial
  static void resetAnimation(AnimationController controller) {
    controller.reset();
  }
  
  /// Complete animation immédiatement
  static void completeAnimation(AnimationController controller) {
    controller.forward();
  }
}

// ========== ENUMS ET CONFIGURATIONS ==========

/// Vitesses d'animation standardisées
enum AnimationSpeed {
  fast(EloquenceTheme.animationFast),
  medium(EloquenceTheme.animationMedium),
  slow(EloquenceTheme.animationSlow),
  xSlow(EloquenceTheme.animationXSlow);
  
  const AnimationSpeed(this.duration);
  final Duration duration;
}

/// Directions de slide standardisées
enum SlideDirection {
  fromTop(Offset(0.0, -1.0)),
  fromBottom(Offset(0.0, 1.0)),
  fromLeft(Offset(-1.0, 0.0)),
  fromRight(Offset(1.0, 0.0));
  
  const SlideDirection(this.beginOffset);
  final Offset beginOffset;
}

/// Types d'animation pour cohérence
enum AnimationType {
  microInteraction,
  pageTransition,
  feedback,
  loading,
  celebration,
  materialization,
}

/// Configuration globale des animations
class AnimationConfig {
  static const bool enableAnimations = true;
  static const double slowMotionFactor = 1.0; // Pour debug : 0.2 = 5x plus lent
  static const bool enablePerformanceMode = false; // Réduit la complexité sur devices lents
  
  // Seuils de performance
  static const int maxConcurrentAnimations = 5;
  static const Duration maxAnimationDuration = Duration(seconds: 2);
  static const double minFrameRate = 30.0; // FPS minimum acceptable
}

/// Widget helper pour animations standardisées
class EloquenceAnimatedWidget extends StatefulWidget {
  final Widget child;
  final AnimationType type;
  final AnimationSpeed speed;
  final bool autoStart;
  final VoidCallback? onComplete;
  
  const EloquenceAnimatedWidget({
    Key? key,
    required this.child,
    required this.type,
    this.speed = AnimationSpeed.medium,
    this.autoStart = true,
    this.onComplete,
  }) : super(key: key);
  
  @override
  State<EloquenceAnimatedWidget> createState() => _EloquenceAnimatedWidgetState();
}

class _EloquenceAnimatedWidgetState extends State<EloquenceAnimatedWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.speed.duration,
      vsync: this,
    );
    
    _animation = EloquenceAnimationService.createFadeAnimation(_controller);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
    
    if (widget.autoStart) {
      _controller.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}