import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../widgets/dragon_animations_effects.dart';
import '../widgets/achievement_widgets.dart';
import '../widgets/dragon_progress_widget.dart';
import '../providers/dragon_breath_provider.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Écran de résultats après une session d'exercice "Souffle de Dragon"
class DragonBreathResultsScreen extends ConsumerStatefulWidget {
  final BreathingSession completedSession;
  final List<DragonAchievement> newAchievements;
  final bool hasLeveledUp;
  final DragonLevel? previousLevel;

  const DragonBreathResultsScreen({
    Key? key,
    required this.completedSession,
    required this.newAchievements,
    this.hasLeveledUp = false,
    this.previousLevel,
  }) : super(key: key);

  @override
  ConsumerState<DragonBreathResultsScreen> createState() => _DragonBreathResultsScreenState();
}

class _DragonBreathResultsScreenState extends ConsumerState<DragonBreathResultsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _celebrationController;
  late AnimationController _statsController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _statsAnimation;
  
  bool _showCelebration = false;
  bool _animationsCompleted = false;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));
    
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Animation principale
    await _mainController.forward();
    
    // Démarrer les statistiques
    _statsController.forward();
    
    // Si niveau supérieur, célébration spéciale
    if (widget.hasLeveledUp) {
      setState(() {
        _showCelebration = true;
      });
      _celebrationController.repeat();
    }
    
    // Marquer les animations comme terminées
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _animationsCompleted = true;
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _celebrationController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dragonBreathProvider);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EloquenceTheme.navy,
              (state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet).withOpacity(0.3),
              EloquenceTheme.navy,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Particules d'énergie de fond
            if (_animationsCompleted)
              AnimatedBuilder(
                animation: _celebrationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: DragonEnergyParticlesPainter(
                      animation: _celebrationController,
                      color: state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet,
                    ),
                  );
                },
              ),
            
            // Contenu principal
            SafeArea(
              child: _buildMainContent(state),
            ),
            
            // Animation de niveau supérieur (overlay)
            if (_showCelebration && widget.hasLeveledUp && widget.previousLevel != null)
              DragonLevelUpAnimation(
                fromLevel: widget.previousLevel!,
                toLevel: state.userProgress!.currentLevel,
                onComplete: () {
                  setState(() {
                    _showCelebration = false;
                  });
                  _celebrationController.stop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BreathingExerciseState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Header avec avatar Dragon
            AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildResultsHeader(state),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Statistiques de session
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSessionStats(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Progression Dragon
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _statsAnimation.value,
                  child: DragonProgressWidget(
                    progress: state.userProgress!,
                    showDetails: true,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Nouveaux achievements
            if (widget.newAchievements.isNotEmpty)
              AnimatedBuilder(
                animation: _statsAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _statsAnimation.value,
                    child: _buildNewAchievements(),
                  );
                },
              ),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _statsAnimation.value,
                  child: _buildActionButtons(),
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BreathingExerciseState state) {
    return Column(
      children: [
        // Message de félicitations
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EloquenceTheme.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar Dragon principal
              DragonGlowEffect(
                glowColor: state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet,
                intensity: 1.5,
                isActive: true,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet).withOpacity(0.9),
                        (state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet).withOpacity(0.3),
                      ],
                    ),
                    border: Border.all(
                      color: state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      state.userProgress?.currentLevel.emoji ?? '🐉',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                widget.hasLeveledUp ? 'NIVEAU SUPÉRIEUR!' : 'SESSION TERMINÉE!',
                style: EloquenceTheme.headline1.copyWith(
                  color: widget.hasLeveledUp
                      ? state.userProgress?.currentLevel.dragonColor ?? EloquenceTheme.violet
                      : EloquenceTheme.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                widget.hasLeveledUp
                    ? 'Tu es maintenant ${state.userProgress?.currentLevel.displayName ?? 'un Dragon'}!'
                    : 'Ta puissance vocale grandit!',
                style: EloquenceTheme.bodyLarge.copyWith(
                  color: EloquenceTheme.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStats() {
    final session = widget.completedSession;
    final quality = session.metrics?.qualityScore ?? 0.0;
    final qualityColor = quality >= 0.8
        ? EloquenceTheme.successGreen
        : quality >= 0.6
            ? EloquenceTheme.warningOrange
            : EloquenceTheme.errorRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de la session',
            style: EloquenceTheme.headline3.copyWith(
              color: EloquenceTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '⏱️',
                  'Durée',
                  '${(((session.endTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) - session.startTime.millisecondsSinceEpoch) / 60000).round()}min',
                  EloquenceTheme.cyan,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '🔥',
                  'Cycles',
                  '5', // TODO: Récupérer du vrai nombre de cycles
                  EloquenceTheme.warningOrange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '⭐',
                  'Qualité',
                  '${(quality * 100).round()}%',
                  qualityColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '💎',
                  'XP Gagné',
                  '+${session.xpGained}',
                  EloquenceTheme.violet,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '💰',
                  'Consistance',
                  '${((session.metrics?.consistency ?? 0.0) * 100).round()}%',
                  EloquenceTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '🎯',
                  'Contrôle',
                  '${((session.metrics?.controlScore ?? 0.0) * 100).round()}%',
                  EloquenceTheme.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: EloquenceTheme.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNewAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EloquenceTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EloquenceTheme.successGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                color: EloquenceTheme.successGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Nouveaux Achievements!',
                style: EloquenceTheme.headline3.copyWith(
                  color: EloquenceTheme.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          AchievementGridWidget(
            achievements: widget.newAchievements,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton continuer/rejouer
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: EloquenceTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: EloquenceTheme.cyan.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Retourner à l'écran d'exercice pour une nouvelle session
                Navigator.pop(context);
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh,
                      color: EloquenceTheme.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nouvelle Session',
                      style: EloquenceTheme.bodyLarge.copyWith(
                        color: EloquenceTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Bouton partager
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: EloquenceTheme.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EloquenceTheme.glassBorder,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // TODO: Implémenter le partage
                      _shareResults();
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share,
                            color: EloquenceTheme.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Partager',
                            style: EloquenceTheme.bodyMedium.copyWith(
                              color: EloquenceTheme.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton retour menu
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: EloquenceTheme.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EloquenceTheme.glassBorder,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Retourner au menu principal
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/exercises',
                        (route) => false,
                      );
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: EloquenceTheme.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Menu',
                            style: EloquenceTheme.bodyMedium.copyWith(
                              color: EloquenceTheme.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _shareResults() {
    final session = widget.completedSession;
    // TODO: Implémenter le partage des résultats
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de résultats - ${session.xpGained} XP gagnés!'),
        backgroundColor: EloquenceTheme.successGreen,
      ),
    );
  }
}