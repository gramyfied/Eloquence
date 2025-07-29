import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dragon_breath_models.dart';
import '../widgets/breathing_circle_widget.dart';
import '../widgets/dragon_animations_effects.dart';
import '../providers/dragon_breath_provider.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Écran principal de l'exercice "Souffle de Dragon"
class DragonBreathScreen extends ConsumerStatefulWidget {
  const DragonBreathScreen({super.key});

  @override
  ConsumerState<DragonBreathScreen> createState() => _DragonBreathScreenState();
}

class _DragonBreathScreenState extends ConsumerState<DragonBreathScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _dragonAnimationController;
  late AnimationController _celebrationController;
  late AnimationController _phaseProgressController;
  late Animation<double> _dragonScaleAnimation;
  late Animation<double> _smoothPhaseProgress;
  
  Timer? _exerciseTimer;
  bool _showLevelUpAnimation = false;
  DragonLevel? _previousLevel;
  int _lastRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    
    // Animation du dragon
    _dragonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation de célébration
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Animation de progression de phase
    _phaseProgressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _dragonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _dragonAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _smoothPhaseProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _phaseProgressController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer l'animation du dragon
    _dragonAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _exerciseTimer?.cancel();
    _dragonAnimationController.dispose();
    _celebrationController.dispose();
    _phaseProgressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(dragonBreathProvider);
        
        // Détecter les changements de secondes pour une animation fluide
        if (state.remainingSeconds != _lastRemainingSeconds) {
          _lastRemainingSeconds = state.remainingSeconds;
          if (state.isActive && !state.isPaused) {
            _phaseProgressController.forward(from: 0.0);
          }
        }

        return Scaffold(
          body: Stack(
            children: [
              // Contenu principal avec animations
              BreathingPhaseTransition(
                currentPhase: state.currentPhase,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: EloquenceTheme.backgroundGradient,
                  ),
                  child: Stack(
                    children: [
                      // Flux d'énergie de fond
                      if (state.isActive)
                        BreathingEnergyFlow(
                          currentPhase: state.currentPhase,
                          progress: state.phaseProgress,
                        ),
                      
                      // Contenu principal
                      SafeArea(
                        child: _buildBody(context, state),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Animation de niveau supérieur (overlay)
              if (_showLevelUpAnimation)
                DragonLevelUpAnimation(
                  fromLevel: _previousLevel ?? state.userProgress.currentLevel,
                  toLevel: state.userProgress.currentLevel,
                  onComplete: () {
                    setState(() {
                      _showLevelUpAnimation = false;
                      _previousLevel = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BreathingExerciseState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        
        return Column(
          children: [
            // Header avec niveau Dragon
            _buildDragonHeader(state.userProgress),
            
            // Contenu principal scrollable
            Expanded(
              child: SingleChildScrollView(
                child: _buildMainContent(context, state, screenHeight - 120),
              ),
            ),
            
            // Contrôles en bas
            _buildBottomControls(state),
          ],
        );
      },
    );
  }

  Widget _buildDragonHeader(DragonProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton retour
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EloquenceTheme.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EloquenceTheme.glassBorder,
                width: 1,
              ),
            ),
            child: IconButton(
              iconSize: 20,
              icon: const Icon(
                Icons.arrow_back,
                color: EloquenceTheme.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre et niveau
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Souffle de Dragon',
                  style: EloquenceTheme.headline2.copyWith(
                    color: EloquenceTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      progress.currentLevel.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      progress.currentLevel.displayName,
                      style: EloquenceTheme.bodySmall.copyWith(
                        color: progress.currentLevel.dragonColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgressBar(progress),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Avatar Dragon animé avec effet de glow
          DragonGlowEffect(
            glowColor: progress.currentLevel.dragonColor,
            intensity: 1.2,
            isActive: true,
            child: AnimatedBuilder(
              animation: _dragonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _dragonScaleAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          progress.currentLevel.dragonColor.withOpacity(0.8),
                          progress.currentLevel.dragonColor.withOpacity(0.3),
                        ],
                      ),
                      border: Border.all(
                        color: progress.currentLevel.dragonColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        progress.currentLevel.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(DragonProgress progress) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress.progressToNextLevel,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress.currentLevel.dragonColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, BreathingExerciseState state, double availableHeight) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          
          // Instructions motivantes
          _buildMotivationalHeader(state),
          
          SizedBox(height: availableHeight * 0.05),
          
          // Cercle de respiration principal
          BreathingCircleWidget(
            currentPhase: state.currentPhase,
            phaseProgress: state.phaseProgress,
            remainingSeconds: state.remainingSeconds,
            size: (availableHeight * 0.35).clamp(200.0, 300.0),
            isActive: state.isActive,
          ),
          
          SizedBox(height: availableHeight * 0.05),
          
          // Métriques de session
          _buildSessionMetrics(state),
          
          SizedBox(height: availableHeight * 0.04),
          
          // Messages motivants
          _buildMotivationalMessages(state),
        ],
      ),
    );
  }

  Widget _buildMotivationalHeader(BreathingExerciseState state) {
    String headerText;
    IconData icon;
    
    if (!state.isActive) {
      headerText = "Libère ta puissance vocale";
      icon = Icons.air;
    } else {
      headerText = "Ta puissance grandit...";
      icon = Icons.local_fire_department;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [
          Icon(
            icon,
            color: EloquenceTheme.cyan,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            headerText,
            style: EloquenceTheme.headline3.copyWith(
              color: EloquenceTheme.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.exercise.benefits,
            style: EloquenceTheme.bodyMedium.copyWith(
              color: EloquenceTheme.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetrics(BreathingExerciseState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: EloquenceTheme.borderRadiusLarge,
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            '🔥',
            'Cycle',
            '${state.currentCycle}/${state.exercise.totalCycles}',
            EloquenceTheme.cyan,
          ),
          _buildMetricItem(
            '⚡',
            'Phase',
            state.currentPhase.displayName,
            state.currentPhase.phaseColor,
          ),
          _buildMetricItem(
            '👑',
            'XP Total',
            '${state.userProgress.totalXP}',
            EloquenceTheme.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: EloquenceTheme.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessages(BreathingExerciseState state) {
    if (state.motivationalMessages.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EloquenceTheme.successGreen.withOpacity(0.1),
        borderRadius: EloquenceTheme.borderRadiusLarge,
        border: Border.all(
          color: EloquenceTheme.successGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: EloquenceTheme.successGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.motivationalMessages.last,
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.successGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BreathingExerciseState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EloquenceTheme.navy.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: EloquenceTheme.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton pause/reprendre
          if (state.isActive)
            FloatingActionButton(
              onPressed: () {
                ref.read(dragonBreathProvider.notifier).togglePause();
              },
              backgroundColor: EloquenceTheme.warningOrange.withOpacity(0.8),
              child: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                color: EloquenceTheme.white,
              ),
            ),
          
          // Bouton principal (Start/Stop)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: state.isActive 
                  ? LinearGradient(
                      colors: [EloquenceTheme.errorRed, EloquenceTheme.warningOrange],
                    )
                  : EloquenceTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: (state.isActive ? EloquenceTheme.errorRed : EloquenceTheme.cyan)
                      .withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  if (state.isActive) {
                    _stopExercise();
                  } else {
                    _startExercise();
                  }
                },
                child: Center(
                  child: Icon(
                    state.isActive ? Icons.stop : Icons.play_arrow,
                    color: EloquenceTheme.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          
          // Bouton paramètres
          FloatingActionButton(
            onPressed: () {
              _showExerciseSettings(context);
            },
            backgroundColor: EloquenceTheme.violet.withOpacity(0.8),
            child: const Icon(
              Icons.settings,
              color: EloquenceTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  void _startExercise() {
    print("🐉 Démarrage de l'exercice Souffle de Dragon");
    ref.read(dragonBreathProvider.notifier).startExercise();
  }

  void _stopExercise() {
    print("🛑 Arrêt de l'exercice Souffle de Dragon");
    ref.read(dragonBreathProvider.notifier).stopExercise();
  }

  void _showExerciseSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: EloquenceTheme.navy,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EloquenceTheme.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Personnaliser l\'exercice',
              style: EloquenceTheme.headline3.copyWith(
                color: EloquenceTheme.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Options de configuration
            _buildSettingItem(
              '⏱️',
              'Durée d\'inspiration',
              '4 secondes',
              () {
                // TODO: Implémenter le changement de durée
              },
            ),
            
            _buildSettingItem(
              '💨',
              'Durée d\'expiration',
              '6 secondes',
              () {
                // TODO: Implémenter le changement de durée
              },
            ),
            
            _buildSettingItem(
              '🔄',
              'Nombre de cycles',
              '5 cycles',
              () {
                // TODO: Implémenter le changement de cycles
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String emoji, String title, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EloquenceTheme.bodyMedium.copyWith(
                          color: EloquenceTheme.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        value,
                        style: EloquenceTheme.bodySmall.copyWith(
                          color: EloquenceTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: EloquenceTheme.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}