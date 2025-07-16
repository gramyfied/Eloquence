import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../../../presentation/widgets/eloquence_components.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/confidence_session.dart';
import '../../domain/entities/gamification_models.dart' as gamification;

class ConfidenceResultsView extends StatefulWidget {
  final SessionRecord session;
  final VoidCallback onRetry;
  final VoidCallback onComplete;
  
  const ConfidenceResultsView({
    Key? key,
    required this.session,
    required this.onRetry,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ConfidenceResultsView> createState() => _ConfidenceResultsViewState();
}

class _ConfidenceResultsViewState extends State<ConfidenceResultsView>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _badgeController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _badgeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));
    
    _badgeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));
    
    // Démarrer les animations
    _scoreController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _badgeController.forward();
    });
  }
  
  @override
  void dispose() {
    _scoreController.dispose();
    _badgeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final analysis = widget.session.analysis;
    final overallScore = _calculateOverallScore(analysis);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Score global
          _buildOverallScore(overallScore),
          
          const SizedBox(height: 32),
          
          // Scores détaillés
          _buildDetailedScores(analysis),
          
          const SizedBox(height: 32),
          
          // Feedback personnalisé
          _buildFeedback(analysis),
          
          const SizedBox(height: 32),
          
          // Badges débloqués
          if (widget.session.newBadges.isNotEmpty)
            _buildUnlockedBadges(),
          
          const SizedBox(height: 40),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildOverallScore(double score) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                EloquenceColors.cyan.withAlpha((255 * 0.3).round()),
                EloquenceColors.violet.withAlpha((255 * 0.1).round()),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: EloquenceColors.cyan.withAlpha((255 * 0.5).round()),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de progression
              CustomPaint(
                size: const Size(200, 200),
                painter: _CircularScorePainter(
                  progress: _scoreAnimation.value * score / 100,
                  strokeWidth: 12,
                ),
              ),
              
              // Score au centre
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(score * _scoreAnimation.value).toInt()}',
                    style: EloquenceTextStyles.headline1.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Score global',
                    style: EloquenceTextStyles.caption.copyWith(
                      color: EloquenceColors.cyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailedScores(confidence_models.ConfidenceAnalysis analysis) {
    return EloquenceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyse détaillée',
            style: EloquenceTextStyles.h3.copyWith(
              color: EloquenceColors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreItem(
            'Confiance',
            analysis.confidenceScore,
            EloquenceColors.cyan,
            Icons.psychology,
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            'Fluidité',
            analysis.fluencyScore,
            EloquenceColors.violet,
            Icons.waves,
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            'Clarté',
            analysis.clarityScore,
            EloquenceColors.cyan,
            Icons.record_voice_over,
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            'Énergie',
            analysis.energyScore,
            EloquenceColors.violet,
            Icons.bolt,
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreItem(
    String label,
    double score,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.2).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: EloquenceTextStyles.bodyMedium.copyWith(
                        color: EloquenceColors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${score.toInt()}%',
                    style: EloquenceTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: (score / 100) * _scoreAnimation.value,
                    backgroundColor: color.withAlpha((255 * 0.2).round()),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeedback(confidence_models.ConfidenceAnalysis analysis) {
    return EloquenceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: EloquenceColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Feedback personnalisé',
                  style: EloquenceTextStyles.h3.copyWith(
                    color: EloquenceColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.feedback,
            style: EloquenceTextStyles.bodyLarge.copyWith(
              color: EloquenceColors.white.withAlpha((255 * 0.9).round()),
            ),
          ),
          if (analysis.improvements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Suggestions d\'amélioration',
              style: EloquenceTextStyles.bodyMedium.copyWith(
                color: EloquenceColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...analysis.improvements.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: EloquenceColors.violet,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: EloquenceTextStyles.bodyMedium.copyWith(
                        color: EloquenceColors.white.withAlpha((255 * 0.8).round()),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
  
  Widget _buildUnlockedBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges débloqués',
          style: EloquenceTextStyles.h3.copyWith(
            color: EloquenceColors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.session.newBadges.length,
            itemBuilder: (context, index) {
              final badge = widget.session.newBadges[index];
              return AnimatedBuilder(
                animation: _badgeAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _badgeAnimation.value,
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: EloquenceColors.cyanVioletGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: EloquenceColors.cyan.withAlpha((255 * 0.5).round()),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getBadgeEmoji(badge),
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              _getBadgeName(badge),
                              style: EloquenceTextStyles.caption.copyWith(
                                color: EloquenceColors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: OutlinedButton(
            onPressed: widget.onRetry,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: EloquenceColors.cyan, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Réessayer',
              style: EloquenceTextStyles.buttonLarge.copyWith(
                color: EloquenceColors.cyan,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 1,
          child: ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: EloquenceColors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Terminer',
              style: EloquenceTextStyles.buttonLarge.copyWith(
                color: EloquenceColors.navy,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  double _calculateOverallScore(confidence_models.ConfidenceAnalysis analysis) {
    return (analysis.confidenceScore + 
            analysis.fluencyScore + 
            analysis.clarityScore + 
            analysis.energyScore) / 4;
  }
  
  String _getBadgeEmoji(gamification.Badge badge) {
    // Pour l'instant, on retourne un emoji par défaut.
    // Idéalement, l'icône serait un chemin d'asset.
    return '🏆';
  }
  
  String _getBadgeName(gamification.Badge badge) {
    return badge.name;
  }
}

class _CircularScorePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  
  _CircularScorePainter({
    required this.progress,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Cercle de fond
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = EloquenceColors.glassBackground;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Arc de progression
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [EloquenceColors.cyan, EloquenceColors.violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(_CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}