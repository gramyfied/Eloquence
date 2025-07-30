import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget affichant la progression et le niveau Dragon
class DragonProgressWidget extends StatefulWidget {
  final DragonProgress progress;
  final bool showDetails;
  final VoidCallback? onTap;

  const DragonProgressWidget({
    Key? key,
    required this.progress,
    this.showDetails = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<DragonProgressWidget> createState() => _DragonProgressWidgetState();
}

class _DragonProgressWidgetState extends State<DragonProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _levelAnimationController;
  late AnimationController _xpAnimationController;
  late Animation<double> _levelScaleAnimation;
  late Animation<double> _xpProgressAnimation;

  @override
  void initState() {
    super.initState();
    
    _levelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _levelScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _xpProgressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.progressToNextLevel,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer les animations
    _levelAnimationController.forward();
    _xpAnimationController.forward();
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    _xpAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.progress.currentLevel.dragonColor.withOpacity(0.1),
              EloquenceTheme.glassBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: EloquenceTheme.borderRadiusLarge,
          border: Border.all(
            color: widget.progress.currentLevel.dragonColor.withOpacity(0.3),
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
        child: widget.showDetails 
            ? _buildDetailedView() 
            : _buildCompactView(),
      ),
    );
  }

  Widget _buildCompactView() {
    return Row(
      children: [
        // Avatar Dragon animé
        _buildDragonAvatar(),
        
        const SizedBox(width: 16),
        
        // Infos niveau et progression
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.progress.currentLevel.displayName,
                    style: EloquenceTheme.bodyLarge.copyWith(
                      color: widget.progress.currentLevel.dragonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.progress.currentLevel.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Text(
                widget.progress.currentLevel.description,
                style: EloquenceTheme.bodySmall.copyWith(
                  color: EloquenceTheme.white.withOpacity(0.8),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Barre de progression XP
              _buildXPProgressBar(),
            ],
          ),
        ),
        
        // Stats rapides
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildDetailedView() {
    return Column(
      children: [
        // Header avec avatar et niveau
        Row(
          children: [
            _buildDragonAvatar(size: 80),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.progress.currentLevel.displayName,
                    style: EloquenceTheme.headline2.copyWith(
                      color: widget.progress.currentLevel.dragonColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.progress.currentLevel.description,
                    style: EloquenceTheme.bodyMedium.copyWith(
                      color: EloquenceTheme.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Progression XP détaillée
        _buildDetailedXPProgress(),
        
        const SizedBox(height: 24),
        
        // Statistiques détaillées
        _buildDetailedStats(),
        
        const SizedBox(height: 20),
        
        // Achievements récents
        _buildRecentAchievements(),
      ],
    );
  }

  Widget _buildDragonAvatar({double size = 60}) {
    return AnimatedBuilder(
      animation: _levelScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _levelScaleAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.progress.currentLevel.dragonColor.withOpacity(0.8),
                  widget.progress.currentLevel.dragonColor.withOpacity(0.3),
                ],
                stops: const [0.0, 1.0],
              ),
              border: Border.all(
                color: widget.progress.currentLevel.dragonColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.progress.currentLevel.dragonColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.progress.currentLevel.emoji,
                style: TextStyle(fontSize: size * 0.4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildXPProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP: ${widget.progress.totalXP}',
              style: EloquenceTheme.caption.copyWith(
                color: widget.progress.currentLevel.dragonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.progress.sessionsToNextLevel > 0)
              Text(
                '${widget.progress.sessionsToNextLevel} sessions restantes',
                style: EloquenceTheme.caption.copyWith(
                  color: EloquenceTheme.white.withOpacity(0.6),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        AnimatedBuilder(
          animation: _xpProgressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: EloquenceTheme.glassBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _xpProgressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progress.currentLevel.dragonColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        _buildStatItem(
          '🔥',
          widget.progress.totalSessions.toString(),
          'Sessions',
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          '⚡',
          widget.progress.currentStreak.toString(),
          'Série',
        ),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedXPProgress() {
    final nextLevel = _getNextLevel();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.progress.currentLevel.dragonColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression vers ${nextLevel?.displayName ?? "Niveau Max"}',
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: EloquenceTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(widget.progress.progressToNextLevel * 100).toInt()}%',
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: widget.progress.currentLevel.dragonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildXPProgressBar(),
          
          if (widget.progress.sessionsToNextLevel > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Encore ${widget.progress.sessionsToNextLevel} sessions pour devenir ${nextLevel?.displayName}',
              style: EloquenceTheme.caption.copyWith(
                color: EloquenceTheme.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques Dragon',
            style: EloquenceTheme.bodyLarge.copyWith(
              color: EloquenceTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailedStatItem(
                  '🔥',
                  'Sessions totales',
                  widget.progress.totalSessions.toString(),
                  EloquenceTheme.cyan,
                ),
              ),
              Expanded(
                child: _buildDetailedStatItem(
                  '⚡',
                  'Série actuelle',
                  widget.progress.currentStreak.toString(),
                  EloquenceTheme.violet,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailedStatItem(
                  '👑',
                  'Plus longue série',
                  widget.progress.longestStreak.toString(),
                  EloquenceTheme.celebrationGold,
                ),
              ),
              Expanded(
                child: _buildDetailedStatItem(
                  '🌟',
                  'Qualité moyenne',
                  '${(widget.progress.averageQuality * 100).toInt()}%',
                  EloquenceTheme.successGreen,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailedStatItem(
            '⏱️',
            'Temps total de pratique',
            _formatDuration(widget.progress.totalPracticeTime),
            EloquenceTheme.warningOrange,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatItem(
    String emoji,
    String label,
    String value,
    Color color, {
    bool fullWidth = false,
  }) {
    Widget content = Column(
      crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              value,
              style: EloquenceTheme.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.white.withOpacity(0.7),
          ),
          textAlign: fullWidth ? TextAlign.start : TextAlign.center,
        ),
      ],
    );
    
    if (fullWidth) {
      return content;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: content,
    );
  }

  Widget _buildRecentAchievements() {
    final recentAchievements = widget.progress.achievements
        .where((a) => a.isUnlocked)
        .take(3)
        .toList();
    
    if (recentAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EloquenceTheme.celebrationGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements récents',
            style: EloquenceTheme.bodyLarge.copyWith(
              color: EloquenceTheme.celebrationGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...recentAchievements.map((achievement) => 
            _buildAchievementItem(achievement)
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(DragonAchievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EloquenceTheme.celebrationGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EloquenceTheme.celebrationGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            achievement.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.celebrationGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  achievement.description,
                  style: EloquenceTheme.caption.copyWith(
                    color: EloquenceTheme.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${achievement.xpReward} XP',
            style: EloquenceTheme.caption.copyWith(
              color: EloquenceTheme.celebrationGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  DragonLevel? _getNextLevel() {
    switch (widget.progress.currentLevel) {
      case DragonLevel.apprenti:
        return DragonLevel.maitre;
      case DragonLevel.maitre:
        return DragonLevel.sage;
      case DragonLevel.sage:
        return DragonLevel.legende;
      case DragonLevel.legende:
        return null; // Niveau maximum
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Widget pour afficher l'évolution des niveaux
class DragonLevelEvolutionWidget extends StatelessWidget {
  final DragonLevel currentLevel;
  final double progress;

  const DragonLevelEvolutionWidget({
    Key? key,
    required this.currentLevel,
    required this.progress,
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
          Text(
            'Évolution du Dragon',
            style: EloquenceTheme.headline3.copyWith(
              color: EloquenceTheme.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DragonLevel.values.map((level) => 
              _buildLevelNode(level)
            ).toList(),
          ),
          
          const SizedBox(height: 16),
          
          _buildEvolutionLine(),
        ],
      ),
    );
  }

  Widget _buildLevelNode(DragonLevel level) {
    final isActive = level == currentLevel;
    final isCompleted = level.index < currentLevel.index;
    final isNext = level.index == currentLevel.index + 1;
    
    Color nodeColor;
    if (isCompleted) {
      nodeColor = level.dragonColor;
    } else if (isActive) {
      nodeColor = level.dragonColor;
    } else {
      nodeColor = EloquenceTheme.white.withOpacity(0.3);
    }
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nodeColor.withOpacity(isActive ? 1.0 : 0.3),
            border: Border.all(
              color: nodeColor,
              width: isActive ? 3 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: nodeColor.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              level.emoji,
              style: TextStyle(
                fontSize: isActive ? 24 : 20,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          level.displayName.split(' ').first, // Premier mot seulement
          style: EloquenceTheme.caption.copyWith(
            color: isActive ? nodeColor : EloquenceTheme.white.withOpacity(0.6),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEvolutionLine() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            currentLevel.dragonColor,
            currentLevel.dragonColor.withOpacity(0.3),
            EloquenceTheme.white.withOpacity(0.1),
          ],
          stops: [0.0, progress, 1.0],
        ),
      ),
    );
  }
}