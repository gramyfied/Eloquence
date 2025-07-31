import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../domain/entities/feedback_models.dart';
import '../providers/scenario_provider.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// ÉCRAN 3 : Feedback et résultats
/// Interface de présentation des résultats avec animations et conseils
class ScenarioFeedbackScreen extends ConsumerStatefulWidget {
  const ScenarioFeedbackScreen({super.key});

  @override
  ConsumerState<ScenarioFeedbackScreen> createState() => _ScenarioFeedbackScreenState();
}

class _ScenarioFeedbackScreenState extends ConsumerState<ScenarioFeedbackScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _confettiController;
  late AnimationController _scoreController;
  late AnimationController _cardController;
  
  SessionResults? results;
  int finalScore = 0;
  List<String> strengths = [];
  List<String> improvements = [];
  String coachMessage = "";
  List<String> nextSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadResults();
    _startAnimations();
  }

  void _initializeAnimations() {
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _scoreController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _loadResults() {
    final scenarioState = ref.read(scenarioProvider);
    results = scenarioState.lastResults;
    
    if (results != null) {
      _calculateResults();
    } else {
      // Résultats par défaut si pas de données
      finalScore = 75;
      strengths = ["Clarity", "Confidence"];
      improvements = ["Pace", "Intonation"];
      coachMessage = "Good effort! Keep practicing to improve your skills.";
      nextSteps = [
        "Practice regularly (3x per week)",
        "Focus on speaking pace",
        "Work on voice modulation",
      ];
    }
  }

  void _startAnimations() {
    _confettiController.forward();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      _cardController.forward();
    });
  }

  void _calculateResults() {
    if (results == null) return;
    
    finalScore = results!.analysis.overallScore;
    
    // Analyser les forces
    strengths = [];
    if (results!.analysis.clarityScore > 0.7) strengths.add("Clarity");
    if (results!.analysis.confidenceLevel > 0.7) strengths.add("Confidence");
    if (results!.analysis.paceScore > 0.7) strengths.add("Pace");
    if (results!.analysis.engagementScore > 0.7) strengths.add("Engagement");
    
    // Analyser les améliorations
    improvements = [];
    if (results!.analysis.clarityScore <= 0.7) improvements.add("Clarity");
    if (results!.analysis.confidenceLevel <= 0.7) improvements.add("Confidence");
    if (results!.analysis.paceScore <= 0.7) improvements.add("Pace");
    if (results!.analysis.engagementScore <= 0.7) improvements.add("Engagement");
    
    // Message du coach
    coachMessage = _generateCoachMessage();
    
    // Prochaines étapes
    nextSteps = _generateNextSteps();
  }

  String _generateCoachMessage() {
    if (finalScore >= 90) {
      return "Performance excellente ! Vous avez démontré de solides compétences en communication et de la confiance.";
    } else if (finalScore >= 80) {
      return "Excellent travail ! Vous montrez de bons progrès. Concentrez-vous sur les domaines d'amélioration pour atteindre le niveau suivant.";
    } else if (finalScore >= 70) {
      return "Bon effort ! Vous avez une base solide. Continuez à pratiquer pour renforcer votre confiance.";
    } else if (finalScore >= 60) {
      return "Vous êtes sur la bonne voie ! Une pratique régulière vous aidera à vous améliorer considérablement.";
    } else {
      return "Continuez à pratiquer ! Chaque session vous aide à développer de meilleures compétences de communication.";
    }
  }

  List<String> _generateNextSteps() {
    final steps = <String>[];
    
    if (improvements.contains("Clarity")) {
      steps.add("Travaillez sur l'articulation et la prononciation");
    }
    if (improvements.contains("Confidence")) {
      steps.add("Enregistrez-vous en parlant pour gagner en confiance");
    }
    if (improvements.contains("Pace")) {
      steps.add("Pratiquez le contrôle de votre vitesse d'élocution");
    }
    if (improvements.contains("Engagement")) {
      steps.add("Travaillez à maintenir l'attention de l'audience");
    }
    
    steps.add("Augmentez progressivement la durée des sessions");
    steps.add("Essayez différents types de scénarios");
    
    return steps.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: EloquenceTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confettis
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(_confettiController.value),
                    size: Size.infinite,
                  );
                },
              ),
              
              // Contenu principal
              SingleChildScrollView(
                padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
                child: Column(
                  children: [
                    const SizedBox(height: EloquenceTheme.spacingXl),
                    _buildScoreCard(),
                    const SizedBox(height: EloquenceTheme.spacingXl),
                    _buildStrengthsAndImprovements(),
                    const SizedBox(height: EloquenceTheme.spacingXl),
                    _buildCoachFeedback(),
                    const SizedBox(height: EloquenceTheme.spacingXl),
                    _buildNextSteps(),
                    const SizedBox(height: EloquenceTheme.spacingXl),
                    _buildActionButtons(),
                    const SizedBox(height: EloquenceTheme.spacingLg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return AnimatedBuilder(
      animation: _scoreController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * _scoreController.value,
          child: EloquenceComponents.glassContainer(
            padding: const EdgeInsets.all(EloquenceTheme.spacingXl),
            child: Column(
              children: [
                Text(
                  "Résumé de Performance",
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: EloquenceTheme.spacingLg),
                AnimatedBuilder(
                  animation: _scoreController,
                  builder: (context, child) {
                    int animatedScore = (finalScore * _scoreController.value).round();
                    return Text(
                      animatedScore.toString(),
                      style: EloquenceTheme.scoreDisplay.copyWith(
                        foreground: Paint()
                          ..shader = EloquenceTheme.primaryGradient.createShader(
                            const Rect.fromLTWH(0, 0, 200, 70),
                          ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: EloquenceTheme.spacingSm),
                Text(
                  _getScoreMessage(finalScore),
                  style: EloquenceTheme.headline3.copyWith(
                    color: EloquenceTheme.cyan,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStrengthsAndImprovements() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardController.value)),
          child: Opacity(
            opacity: _cardController.value,
            child: Row(
              children: [
                Expanded(child: _buildStrengthsCard()),
                const SizedBox(width: EloquenceTheme.spacingMd),
                Expanded(child: _buildImprovementsCard()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStrengthsCard() {
    return EloquenceComponents.glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: EloquenceTheme.successGreen,
                size: 20,
              ),
              const SizedBox(width: EloquenceTheme.spacingSm),
              Text(
                "Points Forts",
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: EloquenceTheme.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: EloquenceTheme.spacingMd),
          ...strengths.map((strength) => Padding(
            padding: const EdgeInsets.only(bottom: EloquenceTheme.spacingSm),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: EloquenceTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: EloquenceTheme.spacingSm),
                Expanded(
                  child: Text(
                    strength,
                    style: EloquenceTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildImprovementsCard() {
    return EloquenceComponents.glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: EloquenceTheme.warningOrange,
                size: 20,
              ),
              const SizedBox(width: EloquenceTheme.spacingSm),
              Text(
                "Améliorations",
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: EloquenceTheme.warningOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: EloquenceTheme.spacingMd),
          ...improvements.map((improvement) => Padding(
            padding: const EdgeInsets.only(bottom: EloquenceTheme.spacingSm),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: EloquenceTheme.warningOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: EloquenceTheme.spacingSm),
                Expanded(
                  child: Text(
                    improvement,
                    style: EloquenceTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCoachFeedback() {
    return EloquenceComponents.glassContainer(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: EloquenceTheme.primaryGradient,
            ),
            child: const Icon(
              Icons.person,
              color: EloquenceTheme.white,
              size: 30,
            ),
          ),
          const SizedBox(width: EloquenceTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Coach IA",
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: EloquenceTheme.spacingSm),
                Text(
                  coachMessage,
                  style: EloquenceTheme.bodyMedium.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return EloquenceComponents.glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Prochaines Étapes",
            style: EloquenceTheme.headline3.copyWith(
              color: EloquenceTheme.cyan,
            ),
          ),
          const SizedBox(height: EloquenceTheme.spacingMd),
          ...nextSteps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: EloquenceTheme.spacingSm),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  color: EloquenceTheme.cyan,
                  size: 16,
                ),
                const SizedBox(width: EloquenceTheme.spacingSm),
                Expanded(
                  child: Text(
                    step,
                    style: EloquenceTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: EloquenceTheme.primaryGradient,
              borderRadius: EloquenceTheme.borderRadiusLarge,
              boxShadow: EloquenceTheme.shadowGlow,
            ),
            child: ElevatedButton(
              onPressed: _shareResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: EloquenceTheme.borderRadiusLarge,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.share,
                    color: EloquenceTheme.white,
                    size: 20,
                  ),
                  const SizedBox(width: EloquenceTheme.spacingSm),
                  Text(
                    "Partager les Résultats",
                    style: EloquenceTheme.buttonLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _retryExercise,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EloquenceTheme.violet),
                  shape: RoundedRectangleBorder(
                    borderRadius: EloquenceTheme.borderRadiusLarge,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: EloquenceTheme.spacingMd),
                ),
                child: Text(
                  "Recommencer",
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.violet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: EloquenceTheme.spacingMd),
            Expanded(
              child: OutlinedButton(
                onPressed: _newScenario,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EloquenceTheme.cyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: EloquenceTheme.borderRadiusLarge,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: EloquenceTheme.spacingMd),
                ),
                child: Text(
                  "Nouveau Scénario",
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return "Excellent !";
    if (score >= 80) return "Très Bien !";
    if (score >= 70) return "Bien Joué !";
    if (score >= 60) return "Bon Effort !";
    return "Continuez à Pratiquer !";
  }

  void _shareResults() {
    // Logique de partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Résultats partagés avec succès !"),
        backgroundColor: EloquenceTheme.successGreen,
      ),
    );
  }

  void _retryExercise() {
    // Retourner aux scénarios avec GoRouter
    GoRouter.of(context).go('/scenarios');
  }

  void _newScenario() {
    // Retourner aux scénarios avec GoRouter
    GoRouter.of(context).go('/scenarios');
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}

// Custom Painters
class ConfettiPainter extends CustomPainter {
  final double animationValue;

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = [
      EloquenceTheme.cyan,
      EloquenceTheme.violet,
      EloquenceTheme.successGreen,
      EloquenceTheme.warningOrange,
      EloquenceTheme.celebrationGold,
    ];
    
    for (int i = 0; i < 50; i++) {
      paint.color = colors[i % colors.length];
      
      double x = (i * 37) % size.width;
      double y = (animationValue * size.height + i * 23) % size.height;
      
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
