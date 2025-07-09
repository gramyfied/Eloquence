import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../widgets/confetti_painter.dart';

class ResultsScreen extends StatefulWidget {
  final ConfidenceAnalysis analysis;
  final Function() onContinue;

  const ResultsScreen({
    Key? key,
    required this.analysis,
    required this.onContinue,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _metricsController;
  late AnimationController _confettiController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _scaleAnimation;

  List<ConfettiParticle> _confettiParticles = [];
  bool _showBadge = false;

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
    // 1. Animation du score principal
    _scoreController.forward();

    // 2. Animation des métriques après 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    _metricsController.forward();

    // 3. Confettis et badge si score élevé
    if (widget.analysis.overallScore >= 80) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _triggerCelebration();
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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
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

                  SizedBox(height: EloquenceSpacing.xl),

                  // Score principal animé
                  _buildAnimatedScoreCircle(),

                  SizedBox(height: EloquenceSpacing.xl),

                  // Métriques détaillées
                  _buildMetricsSection(),

                  SizedBox(height: EloquenceSpacing.xl),

                  // Badge de réussite (si applicable)
                  if (_showBadge) _buildAchievementBadge(),

                  Spacer(),

                  // Feedback textuel
                  _buildFeedbackSection(),

                  SizedBox(height: EloquenceSpacing.xl),

                  // Boutons d'action
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Système de confettis
          if (_confettiParticles.isNotEmpty)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    progress: _confettiController.value,
                  ),
                  size: MediaQuery.of(context).size,
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
                    '${(_scoreAnimation.value * 100).round()}', // Score sur 100
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
              // Voir les badges
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