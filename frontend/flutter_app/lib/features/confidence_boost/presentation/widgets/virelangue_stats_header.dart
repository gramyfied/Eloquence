import 'package:flutter/material.dart';

import '../../domain/entities/virelangue_models.dart';

/// Widget d'en-tête affichant les statistiques de session
/// 
/// 📊 FONCTIONNALITÉS STATISTIQUES :
/// - Affichage des métriques de session en temps réel
/// - Progression visuelle et indicateurs
/// - Scores, combos et streaks
/// - Animations de mise à jour des valeurs
/// - Interface adaptative selon l'espace disponible
/// - Indicateurs visuels de performance
/// - Feedback motivationnel basé sur les résultats
class VirelangueStatsHeader extends StatefulWidget {
  final VirelangueExerciseState exerciseState;
  final bool compact;
  final EdgeInsets padding;

  const VirelangueStatsHeader({
    super.key,
    required this.exerciseState,
    this.compact = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<VirelangueStatsHeader> createState() => _VirelangueStatsHeaderState();
}

class _VirelangueStatsHeaderState extends State<VirelangueStatsHeader>
    with TickerProviderStateMixin {
  
  late AnimationController _countController;
  late AnimationController _pulseController;
  late Animation<double> _countAnimation;
  late Animation<double> _pulseAnimation;
  
  double _previousScore = 0.0;
  int _previousCombo = 0;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePreviousValues();
  }

  @override
  void didUpdateWidget(VirelangueStatsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForUpdates(oldWidget.exerciseState);
  }

  @override
  void dispose() {
    _countController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _countController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _countAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutBack,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializePreviousValues() {
    _previousScore = widget.exerciseState.sessionScore;
    _previousCombo = widget.exerciseState.currentCombo;
    _previousStreak = widget.exerciseState.currentStreak;
  }

  void _checkForUpdates(VirelangueExerciseState oldState) {
    bool hasUpdate = false;
    
    if (widget.exerciseState.sessionScore != oldState.sessionScore) {
      _previousScore = oldState.sessionScore;
      hasUpdate = true;
    }
    
    if (widget.exerciseState.currentCombo != oldState.currentCombo) {
      _previousCombo = oldState.currentCombo;
      hasUpdate = true;
    }
    
    if (widget.exerciseState.currentStreak != oldState.currentStreak) {
      _previousStreak = oldState.currentStreak;
      hasUpdate = true;
    }
    
    if (hasUpdate) {
      _countController.forward(from: 0);
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.compact 
          ? _buildCompactLayout(theme)
          : _buildFullLayout(theme),
    );
  }

  /// Construit la version complète de l'en-tête
  Widget _buildFullLayout(ThemeData theme) {
    return Column(
      children: [
        // Ligne principale avec score et virelangue actuel
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildCurrentVirelangueInfo(theme),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildScoreDisplay(theme),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Ligne des statistiques
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              theme,
              'Tentatives',
              widget.exerciseState.currentAttempt.toString(),
              Icons.repeat,
              Colors.blue,
            ),
            _buildStatItem(
              theme,
              'Combo',
              widget.exerciseState.currentCombo.toString(),
              Icons.whatshot,
              Colors.orange,
            ),
            _buildStatItem(
              theme,
              'Série',
              widget.exerciseState.currentStreak.toString(),
              Icons.trending_up,
              Colors.green,
            ),
            _buildStatItem(
              theme,
              'Gemmes',
              widget.exerciseState.collectedGems.length.toString(),
              Icons.diamond,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  /// Construit la version compacte de l'en-tête
  Widget _buildCompactLayout(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildCurrentVirelangueInfo(theme),
        ),
        const SizedBox(width: 12),
        _buildCompactStats(theme),
      ],
    );
  }

  /// Construit les informations du virelangue actuel
  Widget _buildCurrentVirelangueInfo(ThemeData theme) {
    final currentVirelangue = widget.exerciseState.currentVirelangue;
    
    if (currentVirelangue == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.casino,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Faites tourner la roulette !',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getDifficultyColor(currentVirelangue.difficulty).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de difficulté
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(currentVirelangue.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentVirelangue.difficulty.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.gps_fixed,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${(currentVirelangue.targetScore * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Texte du virelangue
          Text(
            _truncateText(currentVirelangue.text, widget.compact ? 40 : 80),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: widget.compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Construit l'affichage du score
  Widget _buildScoreDisplay(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Score',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, child) {
                    final animatedScore = _previousScore + 
                        (_countAnimation.value * (widget.exerciseState.sessionScore - _previousScore));
                    
                    return Text(
                      '${(animatedScore * 100).toInt()}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construit un élément de statistique
  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Construit les statistiques compactes
  Widget _buildCompactStats(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactStatItem(
          theme,
          widget.exerciseState.sessionScore,
          Icons.analytics,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildCompactStatItem(
          theme,
          widget.exerciseState.currentCombo.toDouble(),
          Icons.whatshot,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildCompactStatItem(
          theme,
          widget.exerciseState.currentStreak.toDouble(),
          Icons.trending_up,
          Colors.green,
        ),
      ],
    );
  }

  /// Construit un élément de statistique compact
  Widget _buildCompactStatItem(
    ThemeData theme,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            value is double && value == value.toInt() 
                ? value.toInt().toString()
                : value.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtient la couleur selon la difficulté
  Color _getDifficultyColor(VirelangueDifficulty difficulty) {
    switch (difficulty) {
      case VirelangueDifficulty.easy:
        return Colors.green;
      case VirelangueDifficulty.medium:
        return Colors.orange;
      case VirelangueDifficulty.hard:
        return Colors.red;
      case VirelangueDifficulty.expert:
        return Colors.purple;
    }
  }

  /// Tronque le texte si nécessaire
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

/// Widget de barre de progression pour les sessions
class SessionProgressBar extends StatefulWidget {
  final int currentAttempt;
  final int maxAttempts;
  final double currentScore;
  final double targetScore;
  final Color? progressColor;

  const SessionProgressBar({
    super.key,
    required this.currentAttempt,
    required this.maxAttempts,
    required this.currentScore,
    required this.targetScore,
    this.progressColor,
  });

  @override
  State<SessionProgressBar> createState() => _SessionProgressBarState();
}

class _SessionProgressBarState extends State<SessionProgressBar>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentScore / widget.targetScore,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.forward();
  }

  @override
  void didUpdateWidget(SessionProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.currentScore != oldWidget.currentScore ||
        widget.targetScore != oldWidget.targetScore) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.currentScore / widget.targetScore,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = widget.progressColor ?? theme.colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${widget.currentAttempt}/${widget.maxAttempts}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value.clamp(0.0, 1.0),
              backgroundColor: progressColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(widget.currentScore * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Objectif: ${(widget.targetScore * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}