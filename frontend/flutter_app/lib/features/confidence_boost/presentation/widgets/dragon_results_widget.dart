import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget de Résultats Dragon Spécialisé
/// 
/// ✅ FONCTIONNALITÉS DRAGON :
/// - Affichage spectaculaire des récompenses XP Dragon
/// - Animation de montée de niveau Dragon avec effets
/// - Achievements Dragon débloqués avec particules
/// - Progression de série avec flammes animées
/// - Encouragements personnalisés selon niveau Dragon
/// - Design system Eloquence parfaitement intégré
class DragonResultsWidget extends StatefulWidget {
  final BreathingMetrics metrics;
  final DragonProgress progress;
  final List<DragonAchievement> newAchievements;
  final int earnedXP;
  final bool levelUp;
  final DragonLevel? newLevel;
  final bool showFullAnimation;
  final VoidCallback? onAnimationComplete;

  const DragonResultsWidget({
    Key? key,
    required this.metrics,
    required this.progress,
    required this.newAchievements,
    required this.earnedXP,
    this.levelUp = false,
    this.newLevel,
    this.showFullAnimation = true,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<DragonResultsWidget> createState() => _DragonResultsWidgetState();
}

class _DragonResultsWidgetState extends State<DragonResultsWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _xpAnimationController;
  late AnimationController _achievementAnimationController;
  late AnimationController _levelUpAnimationController;
  late AnimationController _streakAnimationController;
  late AnimationController _particleController;
  
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _xpOpacityAnimation;
  late Animation<double> _achievementSlideAnimation;
  late Animation<double> _levelUpExplosionAnimation;
  late Animation<double> _streakFlameAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showFullAnimation) {
      _startAnimationSequence();
    }
  }

  void _initializeAnimations() {
    // Animation XP
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _xpScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.elasticOut),
    );
    
    _xpOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeOut),
    );

    // Animation achievements
    _achievementAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _achievementSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _achievementAnimationController, curve: Curves.bounceOut),
    );

    // Animation level up
    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _levelUpExplosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpAnimationController, curve: Curves.elasticOut),
    );

    // Animation streak
    _streakAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _streakFlameAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _streakAnimationController, curve: Curves.easeInOut),
    );

    // Animation particules
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 1. Animation XP
    await _xpAnimationController.forward();
    
    // 2. Animation achievements
    if (widget.newAchievements.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _achievementAnimationController.forward();
    }
    
    // 3. Animation level up
    if (widget.levelUp) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _levelUpAnimationController.forward();
    }
    
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    _achievementAnimationController.dispose();
    _levelUpAnimationController.dispose();
    _streakAnimationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.progress.currentLevel.dragonColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Particules de célébration si level up
          if (widget.levelUp)
            ...List.generate(12, (index) => _buildCelebrationParticle(index)),
          
          // Contenu principal
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildXPDisplay(),
              const SizedBox(height: 24),
              if (widget.levelUp && widget.newLevel != null) ...[
                _buildLevelUpCelebration(),
                const SizedBox(height: 24),
              ],
              if (widget.newAchievements.isNotEmpty) ...[
                _buildNewAchievements(),
                const SizedBox(height: 24),
              ],
              _buildProgressSection(),
              const SizedBox(height: 24),
              _buildStreakSection(),
              const SizedBox(height: 24),
              _buildPerformanceSummary(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.progress.currentLevel.dragonColor.withOpacity(0.8),
                widget.progress.currentLevel.dragonColor.withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: widget.progress.currentLevel.dragonColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              widget.progress.currentLevel.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '🎉 Session Dragon Terminée !',
          style: EloquenceTheme.headline2.copyWith(
            color: widget.progress.currentLevel.dragonColor,
          ),
        ),
      ],
    );
  }

  Widget _buildXPDisplay() {
    return AnimatedBuilder(
      animation: _xpAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _xpScaleAnimation.value,
          child: Opacity(
            opacity: _xpOpacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.progress.currentLevel.dragonColor.withOpacity(0.8),
                    widget.progress.currentLevel.dragonColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.progress.currentLevel.dragonColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '+${widget.earnedXP}',
                    style: EloquenceTheme.headline1.copyWith(
                      color: EloquenceTheme.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points d\'expérience Dragon',
                    style: EloquenceTheme.bodyLarge.copyWith(
                      color: EloquenceTheme.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelUpCelebration() {
    return AnimatedBuilder(
      animation: _levelUpAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.3 * _levelUpExplosionAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  EloquenceTheme.celebrationGold.withOpacity(0.3),
                  widget.newLevel!.dragonColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EloquenceTheme.celebrationGold,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.celebrationGold.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '🎊 NIVEAU SUPÉRIEUR ! 🎊',
                  style: EloquenceTheme.headline2.copyWith(
                    color: EloquenceTheme.celebrationGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.newLevel!.displayName,
                  style: EloquenceTheme.headline1.copyWith(
                    color: EloquenceTheme.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.newLevel!.description,
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Nouveaux achievements débloqués',
          style: EloquenceTheme.headline3.copyWith(
            color: EloquenceTheme.celebrationGold,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _achievementAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_achievementSlideAnimation.value, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.newAchievements
                    .map((achievement) => _buildAchievementCard(achievement))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(DragonAchievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 140,
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EloquenceTheme.celebrationGold.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EloquenceTheme.celebrationGold.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  EloquenceTheme.celebrationGold.withOpacity(0.8),
                  EloquenceTheme.celebrationGold.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: EloquenceTheme.celebrationGold,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.name,
            style: EloquenceTheme.bodyMedium.copyWith(
              color: EloquenceTheme.celebrationGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: EloquenceTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EloquenceTheme.successGreen.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              '+${achievement.xpReward} XP',
              style: EloquenceTheme.caption.copyWith(
                color: EloquenceTheme.successGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercentage = widget.progress.progressToNextLevel;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.progress.currentLevel.displayName,
              style: EloquenceTheme.headline3.copyWith(
                color: widget.progress.currentLevel.dragonColor,
              ),
            ),
            Text(
              '${widget.progress.totalXP} XP',
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: EloquenceTheme.glassBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: EloquenceTheme.glassBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progress.currentLevel.dragonColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.progress.sessionsToNextLevel > 0)
          Text(
            'Encore ${widget.progress.sessionsToNextLevel} sessions pour le niveau suivant',
            style: EloquenceTheme.caption.copyWith(
              color: EloquenceTheme.white.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  Widget _buildStreakSection() {
    return AnimatedBuilder(
      animation: _streakAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EloquenceTheme.warningOrange.withOpacity(0.2),
                EloquenceTheme.errorRed.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EloquenceTheme.warningOrange.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: _streakFlameAnimation.value,
                child: const Text('🔥', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Série de ${widget.progress.currentStreak} jours',
                      style: EloquenceTheme.bodyLarge.copyWith(
                        color: EloquenceTheme.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.progress.currentStreak == widget.progress.longestStreak && 
                        widget.progress.currentStreak > 1) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EloquenceTheme.celebrationGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: EloquenceTheme.celebrationGold.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '🏆 Nouveau record !',
                          style: EloquenceTheme.caption.copyWith(
                            color: EloquenceTheme.celebrationGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Résumé de performance',
          style: EloquenceTheme.headline3.copyWith(
            color: EloquenceTheme.violet,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceCard(
                '🎯',
                'Précision',
                '${(widget.metrics.completionPercentage * 100).toInt()}%',
                EloquenceTheme.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPerformanceCard(
                '⏱️',
                'Durée',
                _formatDuration(widget.metrics.actualDuration),
                EloquenceTheme.violet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceCard(
                '🌟',
                'Qualité',
                widget.metrics.isExcellent ? 'Excellente' : 
                widget.metrics.isSuccessful ? 'Bonne' : 'Correct',
                widget.metrics.isExcellent ? EloquenceTheme.celebrationGold :
                widget.metrics.isSuccessful ? EloquenceTheme.successGreen : EloquenceTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPerformanceCard(
                '🔄',
                'Régularité',
                '${(widget.metrics.consistency * 100).toInt()}%',
                EloquenceTheme.successGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: EloquenceTheme.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: EloquenceTheme.caption.copyWith(
              color: EloquenceTheme.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 6.0;
    final startX = 50.0 + random.nextDouble() * 300;
    final startY = 50.0 + random.nextDouble() * 200;
    
    return Positioned(
      left: startX,
      top: startY,
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          final progress = (_particleAnimation.value + random.nextDouble()) % 1.0;
          return Opacity(
            opacity: math.sin(progress * math.pi),
            child: Transform.translate(
              offset: Offset(
                math.sin(progress * 2 * math.pi) * 20,
                -progress * 50,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: EloquenceTheme.celebrationGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.celebrationGold.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}