import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/gamification_models.dart';
import '../widgets/confetti_painter.dart';
import '../providers/confidence_boost_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final ConfidenceAnalysis analysis;
  final Function() onContinue;

  const ResultsScreen({
    Key? key,
    required this.analysis,
    required this.onContinue,
  }) : super(key: key);

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _metricsController;
  late AnimationController _confettiController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _scaleAnimation;

  final List<ConfettiParticle> _confettiParticles = [];
  bool _showBadge = false;
  bool _needsConfettiGeneration = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _metricsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _metricsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.analysis.overallScore,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));
  }

  void _startAnimationSequence() async {
    if (!mounted) return;
    _scoreController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _metricsController.forward();

    if (widget.analysis.overallScore >= 65) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      _triggerCelebration();
    }
  }

  void _triggerCelebration() {
    setState(() {
      _showBadge = true;
      _needsConfettiGeneration = true;
    });
    _confettiController.forward();
  }

  void _generateConfetti(BuildContext context) {
    final random = Random();
    _confettiParticles.clear();
    final screenWidth = MediaQuery.of(context).size.width;
    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble() * screenWidth,
        y: -20,
        color: [
          ConfidenceBoostColors.celebrationGold,
          EloquenceColors.cyan,
          EloquenceColors.violet,
          ConfidenceBoostColors.successGreen,
        ][random.nextInt(4)],
        size: random.nextDouble() * 8 + 4,
        velocity: random.nextDouble() * 200 + 100,
        rotation: random.nextDouble() * 6.28,
        rotationSpeed: random.nextDouble() * 4 - 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsConfettiGeneration) {
      _generateConfetti(context);
      _needsConfettiGeneration = false;
    }
    final gamificationResult = ref.watch(confidenceBoostProvider).lastGamificationResult;

    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EloquenceSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onContinue,
                      ),
                      const Expanded(
                        child: Text(
                          'Résultats',
                          style: EloquenceTextStyles.headline2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: EloquenceSpacing.xl),
                          _buildAnimatedScoreCircle(),
                          const SizedBox(height: EloquenceSpacing.xl),
                          _buildMetricsSection(),
                          const SizedBox(height: EloquenceSpacing.xl),
                          if (gamificationResult != null)
                            _buildGamificationSection(gamificationResult),
                          const SizedBox(height: EloquenceSpacing.xl),
                          if (_showBadge && (gamificationResult == null || gamificationResult.newBadges.isEmpty))
                            _buildAchievementBadge(),
                          const SizedBox(height: EloquenceSpacing.xl),
                          _buildFeedbackSection(),
                          const SizedBox(height: EloquenceSpacing.xl),
                          _buildActionButtons(gamificationResult),
                          const SizedBox(height: EloquenceSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_confettiParticles.isNotEmpty)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: ConfettiPainter(
                      particles: _confettiParticles,
                      progress: _confettiController.value,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedScoreCircle() {
    return AnimatedBuilder(
      animation: _scoreController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getScoreGradient(_scoreAnimation.value),
              boxShadow: [
                BoxShadow(
                  color: EloquenceColors.cyan.withAlpha(76),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_scoreAnimation.value.round()}',
                    style: ConfidenceBoostTextStyles.scoreDisplay,
                  ),
                  Text(
                    '/100',
                    style: EloquenceTextStyles.body1.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsSection() {
    return AnimatedBuilder(
      animation: _metricsController,
      builder: (context, child) {
        return Column(
          children: [
            _buildAnimatedMetricBar('Confiance', widget.analysis.confidenceScore, EloquenceColors.cyan, 0),
            const SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar('Fluidité', widget.analysis.fluencyScore, EloquenceColors.violet, 200),
            const SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar('Clarté', widget.analysis.clarityScore, ConfidenceBoostColors.successGreen, 400),
            const SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar('Énergie', widget.analysis.energyScore, ConfidenceBoostColors.warningOrange, 600),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedMetricBar(String label, double value, Color color, int delay) {
    final delayedAnimation = Tween<double>(
      begin: 0.0,
      end: value,
    ).animate(CurvedAnimation(
      parent: _metricsController,
      curve: Interval((delay / 1000).clamp(0.0, 0.8), 1.0, curve: Curves.easeOutCubic),
    ));

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: EloquenceTextStyles.body1),
                Text(
                  '${(delayedAnimation.value * 100).round()}%',
                  style: EloquenceTextStyles.body1.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: EloquenceSpacing.sm),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: EloquenceColors.glassBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: delayedAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withAlpha(204), color]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(76),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementBadge() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(EloquenceSpacing.md),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  ConfidenceBoostColors.celebrationGold,
                  ConfidenceBoostColors.celebrationGold.withAlpha(204),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ConfidenceBoostColors.celebrationGold.withAlpha(127),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: EloquenceSpacing.sm),
                Text(
                  'NOUVEAU BADGE DÉBLOQUÉ',
                  style: EloquenceTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EloquenceSpacing.lg),
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: EloquenceColors.cyan, size: 20),
              const SizedBox(width: EloquenceSpacing.sm),
              Text(
                'Coaching IA',
                style: EloquenceTextStyles.body1.copyWith(color: EloquenceColors.cyan, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: EloquenceSpacing.md),
          Text(widget.analysis.feedback, style: EloquenceTextStyles.body1),
        ],
      ),
    );
  }

  Widget _buildActionButtons(GamificationResult? gamificationResult) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: EloquenceColors.cyanVioletGradient,
              borderRadius: EloquenceRadii.button,
            ),
            child: ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: EloquenceRadii.button),
              ),
              child: const Text('CONTINUER', style: EloquenceTextStyles.buttonLarge),
            ),
          ),
        ),
        const SizedBox(width: EloquenceSpacing.md),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: EloquenceColors.cyan),
            borderRadius: EloquenceRadii.button,
          ),
          child: TextButton(
            onPressed: () {
              // TODO: Implémenter la navigation vers la page des badges
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: EloquenceRadii.button),
            ),
            child: Text(
              'VOIR BADGES',
              style: EloquenceTextStyles.buttonLarge.copyWith(color: EloquenceColors.cyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationSection(GamificationResult gamificationResult) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EloquenceSpacing.lg),
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: ConfidenceBoostColors.celebrationGold, size: 24),
              const SizedBox(width: EloquenceSpacing.sm),
              Text(
                'Récompenses Gagnées',
                style: EloquenceTextStyles.body1.copyWith(color: ConfidenceBoostColors.celebrationGold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: EloquenceSpacing.lg),
          _buildXPSection(gamificationResult),
          const SizedBox(height: EloquenceSpacing.md),
          _buildLevelProgressBar(gamificationResult),
          const SizedBox(height: EloquenceSpacing.md),
          if (gamificationResult.newBadges.isNotEmpty) ...[
            _buildNewBadgesSection(gamificationResult),
            const SizedBox(height: EloquenceSpacing.md),
          ],
          _buildStreakSection(gamificationResult),
        ],
      ),
    );
  }

  Widget _buildXPSection(GamificationResult gamificationResult) {
    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 1500),
      tween: IntTween(begin: 0, end: gamificationResult.earnedXP),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: EloquenceColors.cyan, size: 20),
                SizedBox(width: EloquenceSpacing.sm),
                Text('XP Gagnés', style: EloquenceTextStyles.body1),
              ],
            ),
            Text(
              '+$value XP',
              style: EloquenceTextStyles.body1.copyWith(color: EloquenceColors.cyan, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelProgressBar(GamificationResult gamificationResult) {
    final currentLevelXP = gamificationResult.xpInCurrentLevel;
    final nextLevelXP = gamificationResult.xpRequiredForNextLevel;
    final progress = nextLevelXP > 0 ? currentLevelXP / nextLevelXP : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Niveau ${gamificationResult.newLevel}',
              style: EloquenceTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '$currentLevelXP / $nextLevelXP XP',
              style: EloquenceTextStyles.body1.copyWith(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: EloquenceSpacing.sm),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: progress),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                color: EloquenceColors.navy.withAlpha(76),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [EloquenceColors.cyan, ConfidenceBoostColors.celebrationGold],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: EloquenceColors.cyan.withAlpha(76),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewBadgesSection(GamificationResult gamificationResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouveaux Badges',
          style: EloquenceTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: EloquenceSpacing.sm),
        Wrap(
          spacing: EloquenceSpacing.sm,
          runSpacing: EloquenceSpacing.sm,
          children: gamificationResult.newBadges.map((badge) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: EloquenceSpacing.md, vertical: EloquenceSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          ConfidenceBoostColors.celebrationGold,
                          ConfidenceBoostColors.celebrationGold.withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ConfidenceBoostColors.celebrationGold.withAlpha(76),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getBadgeIcon(badge.id), color: Colors.white, size: 16),
                        const SizedBox(width: EloquenceSpacing.xs),
                        Text(
                          badge.name,
                          style: EloquenceTextStyles.body1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStreakSection(GamificationResult gamificationResult) {
    final streak = gamificationResult.streakInfo.currentStreak;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.local_fire_department, color: ConfidenceBoostColors.warningOrange, size: 20),
            SizedBox(width: EloquenceSpacing.sm),
            Text('Série Actuelle', style: EloquenceTextStyles.body1),
          ],
        ),
        TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 1000),
          tween: IntTween(begin: 0, end: streak),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              '$value jours',
              style: EloquenceTextStyles.body1.copyWith(color: ConfidenceBoostColors.warningOrange, fontWeight: FontWeight.bold),
            );
          },
        ),
      ],
    );
  }

  IconData _getBadgeIcon(String badgeId) {
    switch (badgeId) {
      case 'first_session':
        return Icons.play_arrow;
      case 'confident_speaker':
        return Icons.record_voice_over;
      case 'fluency_master':
        return Icons.speed;
      case 'clarity_champion':
        return Icons.clear;
      case 'energy_boost':
        return Icons.bolt;
      case 'perfect_score':
        return Icons.star;
      case 'high_performer':
        return Icons.trending_up;
      case 'consistency_king':
        return Icons.refresh;
      case 'streak_starter':
        return Icons.local_fire_department;
      case 'week_warrior':
        return Icons.calendar_view_week;
      case 'dedication_master':
        return Icons.fitness_center;
      case 'eloquence_expert':
        return Icons.psychology;
      default:
        return Icons.emoji_events;
    }
  }

  LinearGradient _getScoreGradient(double score) {
    if (score >= 0.8) {
      return const LinearGradient(
        colors: [ConfidenceBoostColors.successGreen, EloquenceColors.cyan],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (score >= 0.6) {
      return const LinearGradient(
        colors: [ConfidenceBoostColors.warningOrange, EloquenceColors.cyan],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return const LinearGradient(
        colors: [Colors.red, ConfidenceBoostColors.warningOrange],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }
}