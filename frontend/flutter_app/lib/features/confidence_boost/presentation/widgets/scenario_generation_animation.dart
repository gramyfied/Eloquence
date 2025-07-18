import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/animation/eloquence_animation_service.dart';

/// Widget d'animation pour la génération de scénarios et l'analyse
/// 
/// ✅ OPTIMISÉ DESIGN SYSTEM ELOQUENCE :
/// - Animations conformes aux spécifications exactes (durées, courbes)
/// - Service d'animation centralisé pour performance optimale
/// - Courbes easeOutCubic et easeInOut standardisées
/// - Palette stricte : navy, cyan, violet, white uniquement
/// - Durées calibrées mobile : fast (150ms), medium (300ms), slow (500ms)
class ScenarioGenerationAnimation extends StatefulWidget {
  final String currentStage;
  final String stageDescription;
  final bool isUsingMobileOptimization;
  final double progress;
  
  const ScenarioGenerationAnimation({
    Key? key,
    required this.currentStage,
    required this.stageDescription,
    this.isUsingMobileOptimization = false,
    this.progress = 0.0,
  }) : super(key: key);

  @override
  State<ScenarioGenerationAnimation> createState() => _ScenarioGenerationAnimationState();
}

class _ScenarioGenerationAnimationState extends State<ScenarioGenerationAnimation>
    with TickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  final List<String> _stages = [
    'Connexion aux services',
    'Préparation audio',
    'Analyse Vosk',
    'Traitement IA',
    'Finalisation',
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Animation de rotation continue - OPTIMISÉE
    _rotationController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.xSlow,
    );
    
    // Animation de pulsation - CONFORMES DESIGN SYSTEM
    _pulseController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.slow,
    );
    
    // Animation de progression - COURBES STANDARDISÉES
    _progressController = EloquenceAnimationService.createFeedbackAnimation(
      vsync: this,
      speed: AnimationSpeed.medium,
    );
    
    // Animations conformes aux spécifications Design System Eloquence
    _rotationAnimation = EloquenceAnimationService.createRotationAnimation(_rotationController);
    _pulseAnimation = EloquenceAnimationService.createPulseAnimation(_pulseController);
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: EloquenceTheme.curveEmphasized,
    ));
  }
  
  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _progressController.forward();
  }
  
  @override
  void didUpdateWidget(ScenarioGenerationAnimation oldWidget) {
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
    return Padding(
      padding: EdgeInsets.all(EloquenceTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicateur de chargement principal
          _buildMainLoadingIndicator(),
          
          SizedBox(height: EloquenceTheme.spacingXl),
          
          // Étape actuelle
          _buildCurrentStage(),
          
          SizedBox(height: EloquenceTheme.spacingLg),
          
          // Description de l'étape
          _buildStageDescription(),
          
          SizedBox(height: EloquenceTheme.spacingXl),
          
          // Barre de progression globale
          _buildProgressBar(),
          
          SizedBox(height: EloquenceTheme.spacingXl),
          
          // Indicateur d'optimisation mobile
          if (widget.isUsingMobileOptimization)
            _buildMobileOptimizationIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildMainLoadingIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: EloquenceTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.cyan.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de rotation externe
                Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EloquenceTheme.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _LoadingCirclePainter(),
                    ),
                  ),
                ),
                
                // Icône centrale
                Icon(
                  _getStageIcon(),
                  size: 40,
                  color: EloquenceTheme.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCurrentStage() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingMd,
        vertical: EloquenceTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        borderRadius: EloquenceTheme.borderRadiusLarge,
        color: EloquenceTheme.glassBackground,
        border: EloquenceTheme.borderThin,
      ),
      child: Text(
        widget.currentStage,
        style: EloquenceTheme.headline3.copyWith(
          color: EloquenceTheme.cyan,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildStageDescription() {
    return Text(
      widget.stageDescription,
      style: EloquenceTheme.bodyLarge.copyWith(
        color: EloquenceTheme.white.withOpacity(0.9),
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildProgressBar() {
    return Column(
      children: [
        // Barre de progression principale
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: EloquenceTheme.glassBackground,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(EloquenceTheme.cyan),
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: EloquenceTheme.spacingMd),
        
        // Étapes de progression
        _buildStageIndicators(),
      ],
    );
  }
  
  Widget _buildStageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isActive = _getCurrentStageIndex() >= index;
        final isCurrent = _getCurrentStageIndex() == index;
        
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive 
                      ? (isCurrent ? EloquenceTheme.cyan : EloquenceTheme.violet)
                      : EloquenceTheme.glassBackground,
                  border: Border.all(
                    color: isActive ? Colors.transparent : EloquenceTheme.glassBorder,
                    width: 1,
                  ),
                ),
              ),
              SizedBox(height: EloquenceTheme.spacingSm),
              Text(
                stage,
                style: EloquenceTheme.caption.copyWith(
                  color: isActive 
                      ? EloquenceTheme.white
                      : EloquenceTheme.white.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildMobileOptimizationIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingMd,
        vertical: EloquenceTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        borderRadius: EloquenceTheme.borderRadiusMedium,
        color: EloquenceTheme.violet.withOpacity(0.2),
        border: Border.all(
          color: EloquenceTheme.violet.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed_rounded,
            size: 16,
            color: EloquenceTheme.violet,
          ),
          SizedBox(width: EloquenceTheme.spacingSm),
          Text(
            'Optimisation mobile active',
            style: EloquenceTheme.caption.copyWith(
              color: EloquenceTheme.violet,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getStageIcon() {
    switch (widget.currentStage.toLowerCase()) {
      case 'connexion aux services':
        return Icons.link_rounded;
      case 'préparation audio':
        return Icons.settings_voice_rounded;
      case 'analyse vosk':
        return Icons.hearing_rounded;
      case 'traitement ia':
        return Icons.psychology_rounded;
      case 'finalisation':
        return Icons.check_circle_rounded;
      default:
        return Icons.autorenew_rounded;
    }
  }
  
  int _getCurrentStageIndex() {
    return _stages.indexWhere((stage) => 
        stage.toLowerCase() == widget.currentStage.toLowerCase());
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

class _LoadingCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Dessiner des points sur le cercle
    final paint = Paint()
      ..color = EloquenceTheme.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8;
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        2,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_LoadingCirclePainter oldDelegate) => false;
}