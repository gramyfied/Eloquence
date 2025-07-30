import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget pour afficher une achievement avec animation
class AchievementWidget extends StatefulWidget {
  final DragonAchievement achievement;
  final bool showProgress;
  final VoidCallback? onTap;

  const AchievementWidget({
    Key? key,
    required this.achievement,
    this.showProgress = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<AchievementWidget> createState() => _AchievementWidgetState();
}

class _AchievementWidgetState extends State<AchievementWidget>
    with TickerProviderStateMixin {
  late AnimationController _unlockAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.achievement.isUnlocked) {
      _unlockAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(AchievementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.achievement.isUnlocked && !oldWidget.achievement.isUnlocked) {
      _unlockAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _rotationAnimation,
          _pulseAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.achievement.isUnlocked 
                ? _scaleAnimation.value 
                : (widget.showProgress ? _pulseAnimation.value : 1.0),
            child: Transform.rotate(
              angle: widget.achievement.isUnlocked 
                  ? _rotationAnimation.value 
                  : 0.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.achievement.isUnlocked
                        ? [
                            EloquenceTheme.celebrationGold.withOpacity(0.3),
                            EloquenceTheme.celebrationGold.withOpacity(0.1),
                          ]
                        : [
                            EloquenceTheme.glassBackground.withOpacity(0.5),
                            EloquenceTheme.glassBackground.withOpacity(0.2),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.achievement.isUnlocked
                        ? EloquenceTheme.celebrationGold.withOpacity(0.6)
                        : EloquenceTheme.glassBorder.withOpacity(0.3),
                    width: widget.achievement.isUnlocked ? 2 : 1,
                  ),
                  boxShadow: widget.achievement.isUnlocked
                      ? [
                          BoxShadow(
                            color: EloquenceTheme.celebrationGold.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji et badge unlock
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.achievement.isUnlocked
                                ? EloquenceTheme.celebrationGold.withOpacity(0.2)
                                : EloquenceTheme.white.withOpacity(0.1),
                            border: Border.all(
                              color: widget.achievement.isUnlocked
                                  ? EloquenceTheme.celebrationGold
                                  : EloquenceTheme.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.achievement.emoji,
                              style: TextStyle(
                                fontSize: 28,
                                color: widget.achievement.isUnlocked
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        
                        if (widget.achievement.isUnlocked)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: EloquenceTheme.successGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: EloquenceTheme.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Nom de l'achievement
                    Text(
                      widget.achievement.name,
                      style: EloquenceTheme.bodyMedium.copyWith(
                        color: widget.achievement.isUnlocked
                            ? EloquenceTheme.celebrationGold
                            : EloquenceTheme.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      widget.achievement.description,
                      style: EloquenceTheme.caption.copyWith(
                        color: widget.achievement.isUnlocked
                            ? EloquenceTheme.white.withOpacity(0.9)
                            : EloquenceTheme.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Récompense XP
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.achievement.isUnlocked
                            ? EloquenceTheme.celebrationGold.withOpacity(0.2)
                            : EloquenceTheme.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.achievement.isUnlocked
                              ? EloquenceTheme.celebrationGold.withOpacity(0.5)
                              : EloquenceTheme.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '+${widget.achievement.xpReward} XP',
                        style: EloquenceTheme.caption.copyWith(
                          color: widget.achievement.isUnlocked
                              ? EloquenceTheme.celebrationGold
                              : EloquenceTheme.white.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Barre de progression si nécessaire
                    if (widget.showProgress && !widget.achievement.isUnlocked) ...[
                      const SizedBox(height: 12),
                      _buildProgressBar(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.achievement.progress;
    
    return Column(
      children: [
        Text(
          '${(progress * 100).toInt()}%',
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: EloquenceTheme.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                EloquenceTheme.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la grille d'achievements
class AchievementGridWidget extends StatelessWidget {
  final List<DragonAchievement> achievements;
  final Function(DragonAchievement)? onAchievementTap;

  const AchievementGridWidget({
    Key? key,
    required this.achievements,
    this.onAchievementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: EloquenceTheme.borderRadiusLarge,
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: EloquenceTheme.celebrationGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements Dragon',
                style: EloquenceTheme.headline3.copyWith(
                  color: EloquenceTheme.white,
                ),
              ),
              const Spacer(),
              _buildAchievementStats(),
            ],
          ),
          
          const SizedBox(height: 20),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return AchievementWidget(
                achievement: achievement,
                showProgress: true,
                onTap: () => onAchievementTap?.call(achievement),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStats() {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EloquenceTheme.celebrationGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EloquenceTheme.celebrationGold.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$unlockedCount/$totalCount',
        style: EloquenceTheme.bodyMedium.copyWith(
          color: EloquenceTheme.celebrationGold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget pour la popup d'achievement débloqué
class AchievementUnlockedDialog extends StatefulWidget {
  final DragonAchievement achievement;
  final VoidCallback? onClose;

  const AchievementUnlockedDialog({
    Key? key,
    required this.achievement,
    this.onClose,
  }) : super(key: key);

  @override
  State<AchievementUnlockedDialog> createState() => _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState extends State<AchievementUnlockedDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _fadeAnimation,
          _sparkleAnimation,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Particules de célébration
              ...List.generate(15, (index) => _buildSparkleParticle(index)),
              
              // Contenu principal
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          EloquenceTheme.celebrationGold.withOpacity(0.9),
                          EloquenceTheme.celebrationGold.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: EloquenceTheme.celebrationGold,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EloquenceTheme.celebrationGold.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre
                        Text(
                          '🎉 Achievement Débloqué ! 🎉',
                          style: EloquenceTheme.headline2.copyWith(
                            color: EloquenceTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Achievement
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: EloquenceTheme.white.withOpacity(0.2),
                            border: Border.all(
                              color: EloquenceTheme.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EloquenceTheme.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.achievement.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Nom de l'achievement
                        Text(
                          widget.achievement.name,
                          style: EloquenceTheme.headline3.copyWith(
                            color: EloquenceTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Description
                        Text(
                          widget.achievement.description,
                          style: EloquenceTheme.bodyMedium.copyWith(
                            color: EloquenceTheme.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Récompense XP
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: EloquenceTheme.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: EloquenceTheme.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.achievement.xpReward} XP',
                                style: EloquenceTheme.bodyLarge.copyWith(
                                  color: EloquenceTheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Bouton fermer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onClose?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EloquenceTheme.white,
                              foregroundColor: EloquenceTheme.celebrationGold,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continuer',
                              style: EloquenceTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSparkleParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 6.0;
    final delay = random.nextDouble() * 2.0;
    final duration = 1.0 + random.nextDouble() * 2.0;
    
    return Positioned(
      left: random.nextDouble() * 300,
      top: random.nextDouble() * 400,
      child: AnimatedBuilder(
        animation: _sparkleAnimation,
        builder: (context, child) {
          final progress = (_sparkleAnimation.value + delay) % 1.0;
          return Opacity(
            opacity: math.sin(progress * math.pi),
            child: Transform.scale(
              scale: math.sin(progress * math.pi) * 1.5,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: EloquenceTheme.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.white.withOpacity(0.6),
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
}