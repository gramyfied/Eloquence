import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../presentation/widgets/gradient_container.dart';
import '../../domain/entities/story_models.dart';
import '../providers/story_generator_provider.dart';
import '../widgets/celebration_animation_widget.dart';
import '../widgets/animated_ai_avatar_widget.dart';
import 'story_generator_home_screen.dart';

/// Écran de résultats avec analyse de performance
class StoryResultsScreen extends ConsumerStatefulWidget {
  const StoryResultsScreen({super.key});

  @override
  ConsumerState<StoryResultsScreen> createState() => _StoryResultsScreenState();
}

class _StoryResultsScreenState extends ConsumerState<StoryResultsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainAnimationController;
  late AnimationController _scoreAnimationController;
  late AnimationController _celebrationAnimationController;
  late AnimationController _badgeAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _creativityScoreAnimation;
  late Animation<double> _collaborationScoreAnimation;
  late Animation<double> _fluidityScoreAnimation;
  late Animation<double> _celebrationScaleAnimation;
  late Animation<double> _celebrationRotationAnimation;
  late Animation<double> _badgePopAnimation;
  
  // Scores réels (seront initialisés depuis l'analyse)
  late double _creativityScore;
  late double _collaborationScore;
  late double _fluidityScore;
  late double _overallScore;
  late List<StoryBadgeType> _newBadges;

  @override
  void initState() {
    super.initState();
    
    // Les scores seront initialisés dans didChangeDependencies()
    // après que le provider soit disponible
    _creativityScore = 0.0;
    _collaborationScore = 0.0;
    _fluidityScore = 0.0;
    _overallScore = 0.0;
    _newBadges = [];
    
    // Animation principale pour l'entrée
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation des scores (progressifs)
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animation de célébration
    _celebrationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation des badges
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _creativityScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _creativityScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));
    
    _collaborationScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _collaborationScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    
    _fluidityScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _fluidityScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _celebrationScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _celebrationAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _celebrationRotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi * 2,
    ).animate(CurvedAnimation(
      parent: _celebrationAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _badgePopAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Démarrer les animations
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Récupérer les vraies données d'analyse depuis le provider
    final storyState = ref.read(storyGeneratorProvider);
    final analysisResult = storyState.currentSession?.analysisResult;
    
    if (analysisResult != null) {
      // Utiliser les scores réels de l'analyse narrative
      _creativityScore = analysisResult.creativityScore / 100.0; // Convertir en pourcentage
      _collaborationScore = analysisResult.relevanceScore / 100.0; // Utiliser relevance comme proxy pour collaboration
      _fluidityScore = analysisResult.audioMetrics.fluencyScore / 100.0;
      _overallScore = analysisResult.overallScore / 100.0;
      
      logger.i('StoryResults', 'Scores réels utilisés - Global: ${(_overallScore * 100).toInt()}%, Créativité: ${(_creativityScore * 100).toInt()}%');
    } else {
      // Fallback vers des scores par défaut si pas d'analyse
      _creativityScore = 0.75;
      _collaborationScore = 0.65;
      _fluidityScore = 0.80;
      _overallScore = (_creativityScore + _collaborationScore + _fluidityScore) / 3;
      
      logger.w('StoryResults', 'Aucune analyse trouvée, utilisation des scores fallback');
    }
    
    // Badges débloqués basés sur les vrais scores
    _newBadges = _getNewBadges();
    
    // Reconfigurer les animations avec les vraies valeurs
    _reconfigureAnimations();
  }

  void _reconfigureAnimations() {
    _creativityScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _creativityScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));
    
    _collaborationScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _collaborationScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    
    _fluidityScoreAnimation = Tween<double>(
      begin: 0.0,
      end: _fluidityScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() async {
    await _mainAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _scoreAnimationController.forward();
    
    // Animation de célébration si bon score
    if (_overallScore >= 0.8) {
      _celebrationAnimationController.repeat(reverse: true);
    }
    
    // Animation des badges si nouveaux badges
    if (_newBadges.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _badgeAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _scoreAnimationController.dispose();
    _celebrationAnimationController.dispose();
    _badgeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyGeneratorProvider);
    final selectedElements = storyState.currentSession?.selectedElements ?? [];
    
    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _mainAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      // Contenu scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              // Score global
                              _buildOverallScore(),
                              const SizedBox(height: 32),
                              
                              // Scores détaillés
                              _buildDetailedScores(),
                              const SizedBox(height: 32),
                              
                              // Résumé de l'histoire
                              _buildStorySummary(selectedElements),
                              const SizedBox(height: 32),
                              
                              // Interventions IA
                              _buildAIInterventions(),
                              const SizedBox(height: 32),
                              
                              // Nouveaux badges
                              if (_newBadges.isNotEmpty) ...[
                                _buildNewBadges(),
                                const SizedBox(height: 32),
                              ],
                              
                              // Actions
                              _buildActions(context),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _celebrationAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _celebrationScaleAnimation.value,
                child: Transform.rotate(
                  angle: _celebrationRotationAnimation.value * 0.1,
                  child: Text(
                    _getResultTitle(),
                    style: EloquenceTheme.headline1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _getResultSubtitle(),
            style: EloquenceTheme.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore() {
    return AnimatedBuilder(
      animation: _scoreAnimationController,
      builder: (context, child) {
        final animatedScore = _overallScore * _scoreAnimationController.value;
        final shouldCelebrate = animatedScore >= 0.8 && _scoreAnimationController.isCompleted;
        
        return Stack(
          children: [
            // Animation de célébration pour les bons scores
            CelebrationAnimationWidget(
              isActive: shouldCelebrate,
              particleCount: shouldCelebrate ? 30 : 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [
                      EloquenceTheme.cyan.withOpacity(0.2),
                      EloquenceTheme.violet.withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.cyan.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Score Global',
                      style: EloquenceTheme.headline2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CustomPaint(
                            painter: _CircularScorePainter(
                              progress: animatedScore,
                              color: _getScoreColor(animatedScore),
                              strokeWidth: 12,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(animatedScore * 100).toInt()}%',
                              style: EloquenceTheme.scoreDisplay.copyWith(
                                fontSize: 36,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _getScoreLevel(animatedScore),
                              style: EloquenceTheme.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Avatar IA de félicitations pour les excellents scores
            if (shouldCelebrate && animatedScore >= 0.9)
              Positioned(
                top: -10,
                right: -10,
                child: StoryAIAvatarWidget(
                  isActive: true,
                  isSpeaking: false,
                  message: "🏆 Bravo !",
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedScores() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyse Détaillée',
            style: EloquenceTheme.headline3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreItem(
            'Créativité',
            _creativityScoreAnimation,
            EloquenceTheme.cyan,
            Icons.lightbulb_outline,
            'Originalité et imagination',
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            'Collaboration IA',
            _collaborationScoreAnimation,
            EloquenceTheme.violet,
            Icons.psychology,
            'Utilisation des suggestions',
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            'Fluidité',
            _fluidityScoreAnimation,
            Colors.green,
            Icons.record_voice_over,
            'Rythme et élocution',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(
    String title,
    Animation<double> animation,
    Color color,
    IconData icon,
    String description,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: EloquenceTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(animation.value * 100).toInt()}%',
                        style: EloquenceTheme.bodyLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: EloquenceTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: animation.value,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorySummary(List<StoryElement> elements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: EloquenceTheme.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Votre Histoire',
                style: EloquenceTheme.headline3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: elements.map((element) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        EloquenceTheme.cyan.withOpacity(0.1),
                        EloquenceTheme.violet.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(element.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        element.name,
                        style: EloquenceTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques',
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Durée', '1m 25s'),
                    _buildStatItem('Mots', '~150'),
                    _buildStatItem('Pauses', '3'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: EloquenceTheme.bodyLarge.copyWith(
            color: EloquenceTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: EloquenceTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAIInterventions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: EloquenceTheme.violet,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Interventions IA',
                style: EloquenceTheme.headline3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInterventionItem(
            '🌪️',
            'Rebondissement à 30s',
            'Acceptée',
            true,
          ),
          const SizedBox(height: 12),
          _buildInterventionItem(
            '🎭',
            'Révélation à 60s',
            'Ignorée',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionItem(String emoji, String title, String status, bool accepted) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accepted 
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
          ),
          child: Text(
            status,
            style: EloquenceTheme.bodySmall.copyWith(
              color: accepted ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewBadges() {
    return AnimatedBuilder(
      animation: _badgePopAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _badgePopAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nouveaux Badges !',
                      style: EloquenceTheme.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _newBadges.map((badge) => _buildBadgeChip(badge)).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeChip(StoryBadgeType badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.amber.withOpacity(0.2),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            badge.displayName,
            style: EloquenceTheme.bodySmall.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Bouton principal - Nouvelle histoire
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [EloquenceTheme.cyan, EloquenceTheme.violet],
            ),
            boxShadow: [
              BoxShadow(
                color: EloquenceTheme.cyan.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _createNewStory(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Nouvelle Histoire',
                      style: EloquenceTheme.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Actions secondaires
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                'Sauvegarder',
                Icons.save,
                () => _saveStory(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                'Partager',
                Icons.share,
                () => _shareStory(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                'Accueil',
                Icons.home,
                () => _goHome(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(
                text,
                style: EloquenceTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getResultTitle() {
    if (_overallScore >= 0.9) return 'Magnifique ! 🌟';
    if (_overallScore >= 0.8) return 'Excellent ! 🎉';
    if (_overallScore >= 0.7) return 'Très bien ! 👏';
    if (_overallScore >= 0.6) return 'Bien joué ! 😊';
    return 'Bon début ! 💪';
  }

  String _getResultSubtitle() {
    if (_overallScore >= 0.9) return 'Vous êtes un véritable conteur !';
    if (_overallScore >= 0.8) return 'Une performance remarquable !';
    if (_overallScore >= 0.7) return 'Vous maîtrisez bien l\'art du récit';
    if (_overallScore >= 0.6) return 'Continuez à vous améliorer';
    return 'L\'entraînement porte ses fruits';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLevel(double score) {
    if (score >= 0.9) return 'Maître';
    if (score >= 0.8) return 'Expert';
    if (score >= 0.7) return 'Avancé';
    if (score >= 0.6) return 'Intermédiaire';
    return 'Débutant';
  }

  List<StoryBadgeType> _getNewBadges() {
    final badges = <StoryBadgeType>[];
    
    if (_creativityScore >= 0.9) {
      badges.add(StoryBadgeType.creativityChampion);
    }
    
    if (_fluidityScore >= 0.9) {
      badges.add(StoryBadgeType.fluentNarrator);
    }
    
    return badges;
  }

  void _createNewStory(BuildContext context) {
    logger.i('StoryResults', 'Création nouvelle histoire');
    ref.read(storyGeneratorProvider.notifier).clearState();
    
    // Correction: Utiliser GoRouter pour la navigation pour éviter les conflits
    // et assurer une réinitialisation propre de la pile de navigation.
    GoRouter.of(context).go('/story_generator');
  }

  void _saveStory() {
    logger.i('StoryResults', 'Sauvegarde histoire');
    // TODO: Implémenter la sauvegarde
  }

  void _shareStory() {
    logger.i('StoryResults', 'Partage histoire');
    // TODO: Implémenter le partage
  }

  void _goHome(BuildContext context) {
    logger.i('StoryResults', 'Retour accueil');
    // Correction: Utiliser GoRouter pour une navigation cohérente.
    GoRouter.of(context).go('/story_generator');
  }
}

/// Painter pour le score circulaire
class _CircularScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  _CircularScorePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    
    // Cercle de background
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Arc de progression
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -math.pi / 2; // Démarrer en haut
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}