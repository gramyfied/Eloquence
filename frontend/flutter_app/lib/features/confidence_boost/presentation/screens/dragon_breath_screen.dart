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

    // Initialiser le provider au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dragonBreathProvider.notifier).initialize();
    });
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
          body: Container(
            decoration: const BoxDecoration(
              gradient: EloquenceTheme.backgroundGradient,
            ),
            child: _buildScreenContent(state),
          ),
        );
      },
    );
  }

  Widget _buildScreenContent(BreathingExerciseState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: EloquenceTheme.cyan),
            SizedBox(height: 20),
            Text("Préparation du souffle...", style: EloquenceTheme.bodyLarge),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: EloquenceTheme.errorRed, size: 48),
              const SizedBox(height: 16),
              Text(
                "Oups, une erreur est survenue",
                style: EloquenceTheme.headline3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: EloquenceTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(dragonBreathProvider.notifier).initialize(),
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EloquenceTheme.cyan,
                  foregroundColor: EloquenceTheme.navy,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        BreathingPhaseTransition(
          currentPhase: state.currentPhase,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                if (state.isActive)
                  BreathingEnergyFlow(
                    currentPhase: state.currentPhase,
                    progress: state.phaseProgress,
                  ),
                SafeArea(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          ),
        ),
        if (_showLevelUpAnimation)
          if (state.userProgress != null)
            DragonLevelUpAnimation(
              fromLevel: _previousLevel ?? state.userProgress!.currentLevel,
              toLevel: state.userProgress!.currentLevel,
              onComplete: () {
                setState(() {
                  _showLevelUpAnimation = false;
                  _previousLevel = null;
                });
              },
            ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, BreathingExerciseState state) {
    // Le header et le contenu principal ne sont construits que si userProgress est disponible
    if (state.userProgress == null) {
      // Normalement géré par l'écran de chargement, mais sécurité supplémentaire
      return const Center(child: Text("Chargement des données utilisateur..."));
    }
    return Column(
      children: [
        _buildDragonHeader(state.userProgress!),
        Expanded(
          child: state.isActive
              ? _buildActiveExercise(state)
              : _buildPreExercise(state),
        ),
      ],
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
      height: 8,
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: EloquenceTheme.white.withOpacity(0.3),
          width: 1,
        ),
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

  Widget _buildPreExercise(BreathingExerciseState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Header motivationnel pour l'écran de démarrage
              _buildStartScreenHeader(state),
              
              const Spacer(),
              
              // Bouton de démarrage
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: EloquenceTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.cyan.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(60),
                    onTap: _startExercise,
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: EloquenceTheme.white,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                "DÉMARRER",
                style: EloquenceTheme.bodyLarge.copyWith(letterSpacing: 2),
              ),
              
              const Spacer(flex: 2),
              
              _buildBottomControls(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveExercise(BreathingExerciseState state) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableHeight = constraints.maxHeight;
      final compactMode = availableHeight < 600; // Mode compact pour petits écrans
      
      return Column(
        children: [
          // Contenu principal sans scroll, parfaitement dimensionné
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: compactMode ? 8 : 16,
              ),
              child: Column(
                children: [
                  // Header motivationnel compact
                  _buildCompactMotivationalHeader(state, compactMode),
                  
                  // Espace flexible
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: BreathingCircleWidget(
                        currentPhase: state.currentPhase,
                        phaseProgress: state.phaseProgress,
                        remainingSeconds: state.remainingSeconds,
                        size: compactMode
                            ? (availableHeight * 0.25).clamp(150.0, 200.0)
                            : (availableHeight * 0.3).clamp(180.0, 250.0),
                        isActive: state.isActive,
                      ),
                    ),
                  ),
                  
                  // Métriques condensées
                  _buildCompactSessionMetrics(state, compactMode),
                  
                  SizedBox(height: compactMode ? 8 : 12),
                  
                  // Messages motivants condensés
                  _buildCompactMotivationalMessages(state, compactMode),
                ],
              ),
            ),
          ),
          // Contrôles en bas
          _buildBottomControls(state),
        ],
      );
    });
  }

  Widget _buildCompactMotivationalHeader(BreathingExerciseState state, bool compactMode) {
    String headerText = "Ta puissance grandit...";
    IconData icon = Icons.local_fire_department;
    
    return Container(
      padding: EdgeInsets.all(compactMode ? 12 : 16),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(compactMode ? 12 : 16),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: EloquenceTheme.cyan,
            size: compactMode ? 24 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: (compactMode ? EloquenceTheme.bodyLarge : EloquenceTheme.headline3).copyWith(
                    color: EloquenceTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!compactMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Respire avec puissance",
                    style: EloquenceTheme.bodySmall.copyWith(
                      color: EloquenceTheme.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header spécifique pour l'écran de démarrage avec plus d'espace
  Widget _buildStartScreenHeader(BreathingExerciseState state) {
    return Column(
      children: [
        Icon(
          Icons.air,
          color: EloquenceTheme.cyan,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          "Libère ta puissance vocale",
          style: EloquenceTheme.headline2.copyWith(
            color: EloquenceTheme.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            state.exercise.benefits,
            style: EloquenceTheme.bodyLarge.copyWith(
              color: EloquenceTheme.white.withOpacity(0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSessionMetrics(BreathingExerciseState state, bool compactMode) {
    return Container(
      padding: EdgeInsets.all(compactMode ? 10 : 14),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(compactMode ? 10 : 14),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactMetricItem(
            '🔥',
            'Cycle',
            '${state.currentCycle}/${state.exercise.totalCycles}',
            EloquenceTheme.cyan,
            compactMode,
          ),
          _buildCompactMetricItem(
            '⚡',
            'Phase',
            state.currentPhase.displayName,
            state.currentPhase.phaseColor,
            compactMode,
          ),
          _buildCompactMetricItem(
            '👑',
            'XP',
            '${state.userProgress?.totalXP ?? 0}',
            EloquenceTheme.violet,
            compactMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricItem(String emoji, String label, String value, Color color, bool compactMode) {
    if (compactMode) {
      // Mode horizontal ultra-compact
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: EloquenceTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // Mode vertical compact
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: EloquenceTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: EloquenceTheme.caption.copyWith(
              color: EloquenceTheme.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCompactMotivationalMessages(BreathingExerciseState state, bool compactMode) {
    if (state.motivationalMessages.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(compactMode ? 8 : 12),
      decoration: BoxDecoration(
        color: EloquenceTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compactMode ? 8 : 12),
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
            size: compactMode ? 16 : 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.motivationalMessages.last,
              style: (compactMode ? EloquenceTheme.bodySmall : EloquenceTheme.bodyMedium).copyWith(
                color: EloquenceTheme.successGreen,
                fontWeight: FontWeight.w500,
              ),
              maxLines: compactMode ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BreathingExerciseState state) {
    if (!state.isActive) {
      // Masquer les contrôles avant le démarrage
      return SizedBox(height: 60);
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton pause/reprendre
            FloatingActionButton(
              heroTag: 'pause',
              mini: true,
              onPressed: () => ref.read(dragonBreathProvider.notifier).togglePause(),
              backgroundColor: EloquenceTheme.violet.withOpacity(0.8),
              child: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                color: EloquenceTheme.white,
                size: 20,
              ),
            ),
            
            // Bouton principal (Stop)
            FloatingActionButton(
              heroTag: 'stop',
              onPressed: _stopExercise,
              backgroundColor: EloquenceTheme.errorRed.withOpacity(0.8),
              child: const Icon(
                Icons.stop,
                color: EloquenceTheme.white,
              ),
            ),

            // Bouton paramètres
            FloatingActionButton(
              heroTag: 'settings',
              mini: true,
              onPressed: () => _showExerciseSettings(context),
              backgroundColor: EloquenceTheme.white.withOpacity(0.2),
              child: const Icon(Icons.settings, color: EloquenceTheme.white, size: 20),
            ),
          ],
        ));
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
    final state = ref.read(dragonBreathProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(state),
    );
  }

  Widget _buildSettingsBottomSheet(BreathingExerciseState state) {
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
              '${state.exercise.inspirationDuration} secondes',
              () => _showDurationSelector(context, 'inspiration', state.exercise.inspirationDuration),
            ),
            
            _buildSettingItem(
              '💨',
              'Durée d\'expiration',
              '${state.exercise.expirationDuration} secondes',
              () => _showDurationSelector(context, 'expiration', state.exercise.expirationDuration),
            ),
            
            _buildSettingItem(
              '🔄',
              'Nombre de cycles',
              '${state.exercise.totalCycles} cycles',
              () => _showCycleSelector(context, state.exercise.totalCycles),
            ),
            
            if (state.exercise.retentionDuration > 0)
              _buildSettingItem(
                '⏸️',
                'Durée de rétention',
                '${state.exercise.retentionDuration} secondes',
                () => _showDurationSelector(context, 'retention', state.exercise.retentionDuration),
              ),
            
            _buildSettingItem(
              '⏯️',
              'Durée de pause',
              '${state.exercise.pauseDuration} secondes',
              () => _showDurationSelector(context, 'pause', state.exercise.pauseDuration),
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

  /// Affiche un sélecteur de durée
  void _showDurationSelector(BuildContext context, String type, int currentValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDurationSelector(type, currentValue),
    );
  }

  /// Affiche un sélecteur de cycles
  void _showCycleSelector(BuildContext context, int currentValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCycleSelector(currentValue),
    );
  }

  Widget _buildDurationSelector(String type, int currentValue) {
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
              _getDurationTitle(type),
              style: EloquenceTheme.headline3.copyWith(
                color: EloquenceTheme.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sélecteur de durée
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _getDurationOptions(type).length,
                itemBuilder: (context, index) {
                  final duration = _getDurationOptions(type)[index];
                  final isSelected = duration == currentValue;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? EloquenceTheme.cyan.withOpacity(0.2) : EloquenceTheme.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _updateExerciseDuration(type, duration);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? EloquenceTheme.cyan : EloquenceTheme.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$duration secondes',
                                style: EloquenceTheme.bodyMedium.copyWith(
                                  color: EloquenceTheme.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleSelector(int currentValue) {
    final cycleOptions = [3, 5, 7, 10, 15, 20];
    
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
              'Nombre de cycles',
              style: EloquenceTheme.headline3.copyWith(
                color: EloquenceTheme.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sélecteur de cycles
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: cycleOptions.length,
                itemBuilder: (context, index) {
                  final cycles = cycleOptions[index];
                  final isSelected = cycles == currentValue;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? EloquenceTheme.cyan.withOpacity(0.2) : EloquenceTheme.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ref.read(dragonBreathProvider.notifier).updateExerciseConfig(totalCycles: cycles);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? EloquenceTheme.cyan : EloquenceTheme.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$cycles cycles',
                                style: EloquenceTheme.bodyMedium.copyWith(
                                  color: EloquenceTheme.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDurationTitle(String type) {
    switch (type) {
      case 'inspiration':
        return 'Durée d\'inspiration';
      case 'expiration':
        return 'Durée d\'expiration';
      case 'retention':
        return 'Durée de rétention';
      case 'pause':
        return 'Durée de pause';
      default:
        return 'Durée';
    }
  }

  List<int> _getDurationOptions(String type) {
    switch (type) {
      case 'inspiration':
        return [2, 3, 4, 5, 6, 8];
      case 'expiration':
        return [4, 5, 6, 7, 8, 10, 12];
      case 'retention':
        return [0, 2, 3, 4, 5, 6];
      case 'pause':
        return [1, 2, 3, 4, 5];
      default:
        return [1, 2, 3, 4, 5, 6];
    }
  }

  void _updateExerciseDuration(String type, int duration) {
    switch (type) {
      case 'inspiration':
        ref.read(dragonBreathProvider.notifier).updateExerciseConfig(inspirationDuration: duration);
        break;
      case 'expiration':
        ref.read(dragonBreathProvider.notifier).updateExerciseConfig(expirationDuration: duration);
        break;
      case 'retention':
        ref.read(dragonBreathProvider.notifier).updateExerciseConfig(retentionDuration: duration);
        break;
      case 'pause':
        ref.read(dragonBreathProvider.notifier).updateExerciseConfig(pauseDuration: duration);
        break;
    }
  }
}