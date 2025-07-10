import 'dart:math';
import 'package:flutter/material.dart';
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

  List<ConfettiParticle> _confettiParticles = [];
  bool _showBadge = false;
  GamificationResult? _gamificationResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGamificationData();
    _startAnimationSequence();
  }

  void _loadGamificationData() {
    try {
      print("🎮 DEBUG: Attempting to read confidenceBoostProvider...");
      final provider = ref.read(confidenceBoostProvider);
      print("🎮 DEBUG: Provider obtained successfully");
      
      _gamificationResult = provider.lastGamificationResult;
      print("🎮 DEBUG: Provider lastGamificationResult: $_gamificationResult");
      
      if (_gamificationResult != null) {
        print("🎮 DEBUG: ✅ XP earned: ${_gamificationResult!.earnedXP}");
        print("🎮 DEBUG: ✅ New level: ${_gamificationResult!.newLevel}");
        print("🎮 DEBUG: ✅ New badges: ${_gamificationResult!.newBadges.length}");
        print("🎮 DEBUG: ✅ Level up: ${_gamificationResult!.levelUp}");
      } else {
        print("❌ DEBUG: Gamification result is NULL - XP section will not display");
        print("❌ DEBUG: CAUSE: No analysis session has been processed via _processGamification()");
        print("❌ DEBUG: SOLUTION: Complete a full exercise analysis to generate gamification data");
      }
    } catch (e) {
      print("💥 DEBUG: ERREUR loading gamification data: $e");
      print("💥 DEBUG: Provider might not be properly initialized");
    }
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
    // 1. Animation du score principal
    if (mounted) {
      _scoreController.forward();
    }

    // 2. Animation des métriques après 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _metricsController.forward();
    }

    // 3. Confettis et badge si score élevé
    if (widget.analysis.overallScore >= 65) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        _triggerCelebration();
      }
    }
  }

  void _triggerCelebration() {
    setState(() {
      _showBadge = true;
    });

    _generateConfetti();
    _confettiController.forward();
  }

  void _generateConfetti() {
    final random = Random();
    _confettiParticles.clear();

    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble() * MediaQuery.of(context).size.width,
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
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: Stack(
        children: [
          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EloquenceSpacing.lg),
              child: Column(
                children: [
                  // Header fixe
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          print("🔍 DEBUG: Close button pressed - using onContinue for PageView navigation");
                          widget.onContinue();
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Résultats',
                          style: EloquenceTextStyles.headline2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48), // Équilibrer avec le bouton close
                    ],
                  ),

                  // Contenu scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: EloquenceSpacing.xl),

                          // Score principal animé
                          _buildAnimatedScoreCircle(),

                          SizedBox(height: EloquenceSpacing.xl),

                          // Métriques détaillées
                          _buildMetricsSection(),

                          SizedBox(height: EloquenceSpacing.xl),

                          // Section Gamification
                          if (_gamificationResult != null) _buildGamificationSection(),

                          SizedBox(height: EloquenceSpacing.xl),

                          // Badge de réussite (si applicable) - remplacé par les nouveaux badges de gamification
                          // Les badges sont maintenant affichés dans la section gamification ci-dessus
                          // Pas besoin d'afficher le badge générique si on a des badges réels
                          if (_showBadge && (_gamificationResult == null || _gamificationResult!.newBadges.isEmpty))
                            _buildAchievementBadge(),

                          SizedBox(height: EloquenceSpacing.xl),

                          // Feedback textuel
                          _buildFeedbackSection(),

                          SizedBox(height: EloquenceSpacing.xl),

                          // Boutons d'action
                          _buildActionButtons(),

                          SizedBox(height: EloquenceSpacing.lg), // Padding bas
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Système de confettis
          if (_confettiParticles.isNotEmpty)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return IgnorePointer( // CORRECTION: Rendre transparent aux gestes
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
                  color: EloquenceColors.cyan.withOpacity(0.3),
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
                    '${_scoreAnimation.value.round()}', // Score déjà sur base 100
                    style: ConfidenceBoostTextStyles.scoreDisplay,
                  ),
                  Text(
                    '/100',
                    style: EloquenceTextStyles.body1.copyWith(
                      color: Colors.white70,
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

  Widget _buildMetricsSection() {
    return AnimatedBuilder(
      animation: _metricsController,
      builder: (context, child) {
        return Column(
          children: [
            _buildAnimatedMetricBar(
              'Confiance',
              widget.analysis.confidenceScore,
              EloquenceColors.cyan,
              0,
            ),
            SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar(
              'Fluidité',
              widget.analysis.fluencyScore,
              EloquenceColors.violet,
              200,
            ),
            SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar(
              'Clarté',
              widget.analysis.clarityScore,
              ConfidenceBoostColors.successGreen,
              400,
            ),
            SizedBox(height: EloquenceSpacing.md),
            _buildAnimatedMetricBar(
              'Énergie',
              widget.analysis.energyScore,
              ConfidenceBoostColors.warningOrange,
              600,
            ),
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
      curve: Interval(
        (delay / 1000).clamp(0.0, 0.8),
        1.0,
        curve: Curves.easeOutCubic,
      ),
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
                  style: EloquenceTextStyles.body1.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: EloquenceSpacing.sm),
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
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
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
                  ConfidenceBoostColors.celebrationGold.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ConfidenceBoostColors.celebrationGold.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 24),
                SizedBox(width: EloquenceSpacing.sm),
                Text(
                  'NOUVEAU BADGE DÉBLOQUÉ',
                  style: EloquenceTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
              Icon(Icons.psychology, color: EloquenceColors.cyan, size: 20),
              SizedBox(width: EloquenceSpacing.sm),
              Text(
                'Coaching IA',
                style: EloquenceTextStyles.body1.copyWith(
                  color: EloquenceColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: EloquenceSpacing.md),
          Text(
            widget.analysis.feedback,
            style: EloquenceTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
                shape: RoundedRectangleBorder(
                  borderRadius: EloquenceRadii.button,
                ),
              ),
              child: Text(
                'CONTINUER',
                style: EloquenceTextStyles.buttonLarge,
              ),
            ),
          ),
        ),
        SizedBox(width: EloquenceSpacing.md),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: EloquenceColors.cyan),
            borderRadius: EloquenceRadii.button,
          ),
          child: TextButton(
            onPressed: () {
              print("🏆 DEBUG: Bouton 'VOIR BADGES' cliqué - mais pas d'implémentation");
              print("🏆 DEBUG: Gamification result exists: ${_gamificationResult != null}");
              if (_gamificationResult != null) {
                print("🏆 DEBUG: New badges count: ${_gamificationResult!.newBadges.length}");
              }
              // TODO: Implémenter la navigation vers la page des badges
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: EloquenceRadii.button,
              ),
            ),
            child: Text(
              'VOIR BADGES',
              style: EloquenceTextStyles.buttonLarge.copyWith(
                color: EloquenceColors.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationSection() {
    if (_gamificationResult == null) return SizedBox.shrink();

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
          // Header de la section
          Row(
            children: [
              Icon(Icons.emoji_events, color: ConfidenceBoostColors.celebrationGold, size: 24),
              SizedBox(width: EloquenceSpacing.sm),
              Text(
                'Récompenses Gagnées',
                style: EloquenceTextStyles.body1.copyWith(
                  color: ConfidenceBoostColors.celebrationGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: EloquenceSpacing.lg),

          // XP gagnés avec animation
          _buildXPSection(),
          SizedBox(height: EloquenceSpacing.md),

          // Barre de progression du niveau
          _buildLevelProgressBar(),
          SizedBox(height: EloquenceSpacing.md),

          // Badges débloqués (s'il y en a)
          if (_gamificationResult!.newBadges.isNotEmpty) ...[
            _buildNewBadgesSection(),
            SizedBox(height: EloquenceSpacing.md),
          ],

          // Streak actuel
          _buildStreakSection(),
        ],
      ),
    );
  }

  Widget _buildXPSection() {
    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 1500),
      tween: IntTween(begin: 0, end: _gamificationResult!.earnedXP),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: EloquenceColors.cyan, size: 20),
                SizedBox(width: EloquenceSpacing.sm),
                Text(
                  'XP Gagnés',
                  style: EloquenceTextStyles.body1,
                ),
              ],
            ),
            Text(
              '+$value XP',
              style: EloquenceTextStyles.body1.copyWith(
                color: EloquenceColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelProgressBar() {
    final currentLevelXP = _gamificationResult!.xpInCurrentLevel;
    final nextLevelXP = _gamificationResult!.xpRequiredForNextLevel;
    final progress = nextLevelXP > 0 ? currentLevelXP / nextLevelXP : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Niveau ${_gamificationResult!.newLevel}',
              style: EloquenceTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentLevelXP / $nextLevelXP XP',
              style: EloquenceTextStyles.body1.copyWith(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: EloquenceSpacing.sm),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: progress),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                color: EloquenceColors.navy.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EloquenceColors.cyan,
                        ConfidenceBoostColors.celebrationGold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: EloquenceColors.cyan.withOpacity(0.3),
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

  Widget _buildNewBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouveaux Badges',
          style: EloquenceTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EloquenceSpacing.sm),
        Wrap(
          spacing: EloquenceSpacing.sm,
          runSpacing: EloquenceSpacing.sm,
          children: _gamificationResult!.newBadges.map((badge) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EloquenceSpacing.md,
                      vertical: EloquenceSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          ConfidenceBoostColors.celebrationGold,
                          ConfidenceBoostColors.celebrationGold.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ConfidenceBoostColors.celebrationGold.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getBadgeIcon(badge.id),
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: EloquenceSpacing.xs),
                        Text(
                          badge.name,
                          style: EloquenceTextStyles.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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

  Widget _buildStreakSection() {
    final streak = _gamificationResult!.streakInfo.currentStreak;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, color: ConfidenceBoostColors.warningOrange, size: 20),
            SizedBox(width: EloquenceSpacing.sm),
            Text(
              'Série Actuelle',
              style: EloquenceTextStyles.body1,
            ),
          ],
        ),
        TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 1000),
          tween: IntTween(begin: 0, end: streak),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              '$value jours',
              style: EloquenceTextStyles.body1.copyWith(
                color: ConfidenceBoostColors.warningOrange,
                fontWeight: FontWeight.bold,
              ),
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
    if (score >= 0.8) { // score est entre 0 et 1
      return LinearGradient(
        colors: [ConfidenceBoostColors.successGreen, EloquenceColors.cyan],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (score >= 0.6) {
      return LinearGradient(
        colors: [ConfidenceBoostColors.warningOrange, EloquenceColors.cyan],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return LinearGradient(
        colors: [Colors.red, ConfidenceBoostColors.warningOrange],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }
}