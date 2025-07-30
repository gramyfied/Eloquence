import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../presentation/widgets/gradient_container.dart';
import '../../domain/entities/story_models.dart';
import '../providers/story_generator_provider.dart';
import 'story_library_screen.dart';
import 'story_element_selection_screen.dart';
import 'story_narration_screen.dart';

/// Écran d'accueil du générateur d'histoires infinies
class StoryGeneratorHomeScreen extends ConsumerStatefulWidget {
  const StoryGeneratorHomeScreen({super.key});

  @override
  ConsumerState<StoryGeneratorHomeScreen> createState() => _StoryGeneratorHomeScreenState();
}

class _StoryGeneratorHomeScreenState extends ConsumerState<StoryGeneratorHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation principale pour l'entrée
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animation flottante pour l'effet magique
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
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
    
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer les animations
    _startAnimations();
    
    // Charger les données utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyGeneratorProvider.notifier).loadUserStats();
    });
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _floatingAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyGeneratorProvider);
    
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
                      // Header compact
                      _buildCompactHeader(context),
                      
                      // Contenu principal dans Expanded pour éviter overflow
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              
                              // Statistiques compactes
                              _buildCompactStats(storyState),
                              
                              const SizedBox(height: 16),
                              
                              // Bouton principal compact
                              _buildCompactGenerateButton(context),
                              
                              const SizedBox(height: 16),
                              
                              // Actions rapides compactes
                              Expanded(
                                child: _buildCompactQuickActions(context),
                              ),
                              
                              const SizedBox(height: 16),
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
      
      // Bouton flottant pour accès rapide à la bibliothèque
      floatingActionButton: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_floatingAnimation.value * 0.1),
            child: FloatingActionButton(
              onPressed: () => _openLibrary(context),
              backgroundColor: EloquenceTheme.cyan,
              elevation: 8 + (_floatingAnimation.value * 4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      EloquenceTheme.cyan,
                      EloquenceTheme.cyan.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      height: isSmallScreen ? 80 : 90,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Générateur d\'Histoires',
                  style: EloquenceTheme.headline2.copyWith(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Libérez votre créativité ✨',
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _floatingAnimation.value * 0.1,
                child: Container(
                  width: isSmallScreen ? 40 : 50,
                  height: isSmallScreen ? 40 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [EloquenceTheme.cyan, EloquenceTheme.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(StoryGeneratorState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatItem(
              '${state.userStats?.totalStories ?? 0}',
              'Histoires',
              Icons.book,
              EloquenceTheme.cyan,
              isSmallScreen,
            ),
          ),
          Expanded(
            child: _buildCompactStatItem(
              '${((((state.userStats?.averageCreativity ?? 0) + (state.userStats?.averageCollaboration ?? 0) + (state.userStats?.averageFluidity ?? 0)) / 3) * 100).toInt()}%',
              'Score',
              Icons.star,
              EloquenceTheme.violet,
              isSmallScreen,
            ),
          ),
          Expanded(
            child: _buildCompactStatItem(
              '${state.userStats?.currentStreak ?? 0}',
              'Série',
              Icons.local_fire_department,
              Colors.orange,
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String value, String label, IconData icon, Color color, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        Text(
          value,
          style: EloquenceTheme.headline3.copyWith(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: EloquenceTheme.bodySmall.copyWith(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactGenerateButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_floatingAnimation.value * 0.02),
          child: Container(
            width: double.infinity,
            height: isSmallScreen ? 50 : 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [EloquenceTheme.cyan, EloquenceTheme.violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.cyan.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _startStoryGeneration(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      'Générer une Histoire',
                      style: EloquenceTheme.headline3.copyWith(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, EloquenceTheme.cyan.withOpacity(0.05)],
        ),
        boxShadow: [
          BoxShadow(
            color: EloquenceTheme.cyan.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: EloquenceTheme.cyan,
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 6),
              Text(
                'Actions Rapides',
                style: EloquenceTheme.headline3.copyWith(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: EloquenceTheme.violet,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactActionButton(
                          'Histoire Aléatoire',
                          Icons.shuffle,
                          EloquenceTheme.cyan,
                          () => _startRandomStory(context),
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: _buildCompactActionButton(
                          'Défi Genre',
                          Icons.category,
                          EloquenceTheme.violet,
                          () => _startGenreChallenge(context),
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactActionButton(
                          'Speed Mode',
                          Icons.speed,
                          Colors.orange,
                          () => _startSpeedNarration(context),
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: _buildCompactActionButton(
                          'Bibliothèque',
                          Icons.auto_stories,
                          Colors.green,
                          () => _openLibrary(context),
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(String label, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EloquenceTheme.bodySmall.copyWith(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainGenerateButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_floatingAnimation.value * 0.02),
          child: Container(
            width: double.infinity,
            height: isSmallScreen ? 70 : 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  EloquenceTheme.cyan,
                  EloquenceTheme.violet,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.cyan.withOpacity(0.4),
                  blurRadius: 20 + (_floatingAnimation.value * 10),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => _startStoryGeneration(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Générer une Histoire',
                            style: EloquenceTheme.headline3.copyWith(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : isMediumScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(StoryGeneratorState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: EloquenceTheme.cyan,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Flexible(
                child: Text(
                  'Vos Statistiques',
                  style: EloquenceTheme.headline3.copyWith(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Histoires',
                  '${state.userStats?.totalStories ?? 0}',
                  Icons.book,
                  isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Score Moyen',
                  '${((((state.userStats?.averageCreativity ?? 0) + (state.userStats?.averageCollaboration ?? 0) + (state.userStats?.averageFluidity ?? 0)) / 3) * 100).toInt()}%',
                  Icons.star,
                  isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Série',
                  '${state.userStats?.currentStreak ?? 0}',
                  Icons.local_fire_department,
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          icon,
          color: EloquenceTheme.cyan,
          size: isSmallScreen ? 24 : 32,
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: EloquenceTheme.headline3.copyWith(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: EloquenceTheme.violet,
            ),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: EloquenceTheme.bodyMedium.copyWith(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            EloquenceTheme.cyan.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EloquenceTheme.cyan.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: EloquenceTheme.cyan,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Actions Rapides',
                style: EloquenceTheme.headline3.copyWith(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: EloquenceTheme.violet,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Histoire Aléatoire',
                      Icons.shuffle,
                      EloquenceTheme.cyan,
                      () => _startRandomStory(context),
                      isSmallScreen,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Défi Genre',
                      Icons.category,
                      EloquenceTheme.violet,
                      () => _startGenreChallenge(context),
                      isSmallScreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Speed Mode',
                      Icons.speed,
                      Colors.orange,
                      () => _startSpeedNarration(context),
                      isSmallScreen,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Bibliothèque',
                      Icons.auto_stories,
                      Colors.green,
                      () => _openLibrary(context),
                      isSmallScreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: isSmallScreen ? 80 : 90,
          ),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isSmallScreen ? 24 : 28,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EloquenceTheme.bodyMedium.copyWith(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChallenges(StoryGeneratorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Défis du Jour',
            style: EloquenceTheme.headline3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Relevez ces défis pour gagner des récompenses spéciales !',
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStories(StoryGeneratorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histoires Récentes',
            style: EloquenceTheme.headline3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Continuez ou réécoutez vos dernières créations',
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesDisplay(StoryGeneratorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges Débloqués',
            style: EloquenceTheme.headline3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos accomplissements dans le générateur d\'histoires',
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Actions de navigation
  void _startStoryGeneration(BuildContext context) {
    logger.i('StoryGeneratorHome', 'Démarrage génération d\'histoire standard');
    // Navigation vers l'écran de sélection d'éléments
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryElementSelectionScreen(),
      ),
    );
  }

  void _startRandomStory(BuildContext context) {
    logger.i('StoryGeneratorHome', 'Démarrage histoire aléatoire');
    // Générer automatiquement 3 éléments aléatoires et commencer
    ref.read(storyGeneratorProvider.notifier).generateRandomStory();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryNarrationScreen(),
      ),
    );
  }

  void _startGenreChallenge(BuildContext context) {
    logger.i('StoryGeneratorHome', 'Démarrage défi de genre');
    // Navigation vers sélection de genre puis narration
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryElementSelectionScreen(),
      ),
    );
  }

  void _startSpeedNarration(BuildContext context) {
    logger.i('StoryGeneratorHome', 'Démarrage narration rapide');
    // Mode narration rapide (60 secondes)
    ref.read(storyGeneratorProvider.notifier).setSpeedMode(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryElementSelectionScreen(),
      ),
    );
  }

  void _startChallenge(BuildContext context, Map<String, dynamic> challenge) {
    logger.i('StoryGeneratorHome', 'Démarrage défi: ${challenge['title']}');
    // Commencer un défi spécifique
    ref.read(storyGeneratorProvider.notifier).startChallenge(challenge);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryElementSelectionScreen(),
      ),
    );
  }

  void _viewStory(BuildContext context, Story story) {
    logger.i('StoryGeneratorHome', 'Visualisation histoire: ${story.title}');
    // Navigation vers la vue détaillée de l'histoire - TODO: Implémenter écran détail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lecture d\'histoire: ${story.title}'),
        backgroundColor: EloquenceTheme.cyan,
      ),
    );
  }

  void _openLibrary(BuildContext context) {
    logger.i('StoryGeneratorHome', 'Ouverture bibliothèque');
    // Navigation vers la bibliothèque d'histoires
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryLibraryScreen(),
      ),
    );
  }
}