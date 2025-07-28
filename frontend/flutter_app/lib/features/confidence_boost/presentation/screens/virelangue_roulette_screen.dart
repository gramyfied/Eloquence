import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/virelangue_models.dart';
import '../providers/virelangue_exercise_provider.dart';
import '../widgets/animated_microphone_button.dart';
import '../widgets/virelangue_wheel.dart';
import '../widgets/spinning_wheel_60fps.dart';
import '../widgets/virelangue_result_panel.dart';
import '../theme/virelangue_roulette_theme.dart';

/// Écran principal de la "Roulette des Virelangues Magiques" - Design épuré
/// Layout centré avec roue comme élément principal selon les images
class VirelangueRouletteScreen extends ConsumerStatefulWidget {
  const VirelangueRouletteScreen({super.key});

  @override
  ConsumerState<VirelangueRouletteScreen> createState() =>
      _VirelangueRouletteScreenState();
}

class _VirelangueRouletteScreenState
    extends ConsumerState<VirelangueRouletteScreen> with TickerProviderStateMixin {
  
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;
  
  // S'assurer que la session est démarrée une seule fois.
  bool _sessionInitialized = false;
  bool _isWheelSpinning = false;
  
  // Clé globale pour contrôler la roue 60fps
  final GlobalKey<SpinningWheel60fpsState> _wheelKey = GlobalKey<SpinningWheel60fpsState>();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Animation plus longue pour la roue
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0, // 6 tours complets
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isWheelSpinning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sessionInitialized = false; // Réinitialisé pour permettre une nouvelle session propre
    _rotationController.dispose();
    super.dispose();
  }

  /// Fait tourner la roue avec animation 60fps et sélectionne un virelangue
  Future<void> _spinWheelAndSelectVirelangue(VirelangueExerciseNotifier notifier) async {
    if (_isWheelSpinning) return;
    
    setState(() {
      _isWheelSpinning = true;
    });
    
    // Déclencher l'animation de la roulette 60fps
    _wheelKey.currentState?.startSpin();
    
    // Attendre un délai réaliste puis sélectionner le virelangue
    await Future.delayed(const Duration(milliseconds: 2000)); // Délai pour l'animation 60fps
    
    // Sélectionner un nouveau virelangue (logique du provider)
    await notifier.spinWheelForNewVirelangue();
    
    // L'état _isWheelSpinning sera mis à false par onSpinComplete
  }
  
  @override
  Widget build(BuildContext context) {
    // Écoute l'état complet du provider.
    final state = ref.watch(virelangueExerciseProvider);
    // Obtient une référence au notifier pour appeler les méthodes.
    final notifier = ref.read(virelangueExerciseProvider.notifier);

    // Démarrer la première session si ce n'est pas déjà fait.
    if (!_sessionInitialized && !state.isLoading) {
      _sessionInitialized = true;
      Future.microtask(() => notifier.startNewSession(userId: 'user_eloquence_demo'));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VirelangueRouletteTheme.navyBackground,
              VirelangueRouletteTheme.navyBackground.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _buildBody(context, state, notifier),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, VirelangueExerciseState state, VirelangueExerciseNotifier notifier) {
    
    // Si on a des résultats, afficher l'écran de résultats
    if (state.pronunciationResults.isNotEmpty) {
      return VirelangueResultPanel(
        virelangue: state.currentVirelangue!,
        results: state.pronunciationResults,
        recentRewards: state.collectedGems,
        onNextVirelangue: () => notifier.spinWheelForNewVirelangue(),
        onTryAgain: () => notifier.startNewSession(userId: state.userId),
      );
    }

    // Chargement initial
    if (state.isLoading && state.currentVirelangue == null) {
      return _buildLoadingScreen();
    }

    // Erreur
    if (state.error != null) {
      return _buildErrorScreen(state.error.toString());
    }

    // Interface responsive sans overflow - Solution définitive
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        
        return Column(
          children: [
            // Header minimal - 56px fixe
            _buildMinimalHeader(context),
            
            // Contenu principal - Expanded pour utiliser l'espace restant
            Expanded(
              child: SingleChildScrollView(
                child: _buildMainContent(context, state, notifier, constraints.maxHeight - 109), // 56 header + 53 gemmes
              ),
            ),
            
            // Système de gemmes minimal - 53px fixe
            _buildMinimalGemSystem(state.userGems),
          ],
        );
      },
    );
  }

  /// Header minimal pour économiser l'espace
  Widget _buildMinimalHeader(BuildContext context) {
    return Container(
      height: 56, // Réduit au minimum
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: VirelangueRouletteTheme.whiteText.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              iconSize: 16,
              icon: Icon(
                Icons.arrow_back,
                color: VirelangueRouletteTheme.whiteText,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Contenu principal responsive
  Widget _buildMainContent(BuildContext context, VirelangueExerciseState state, VirelangueExerciseNotifier notifier, double availableHeight) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre responsive
          _buildResponsiveTitle(availableHeight),
          
          SizedBox(height: availableHeight * 0.03), // 3% de l'espace disponible
          
          // Roue centrale avec animation 60fps
          SpinningWheel60fps(
            key: _wheelKey,
            virelangues: state.availableVirelangues,
            targetVirelangue: state.currentVirelangue,
            autoSpin: false, // Ne démarre jamais automatiquement
            size: (availableHeight * 0.32).clamp(180.0, 260.0),
            onSpinComplete: () {
              setState(() {
                _isWheelSpinning = false;
              });
            },
          ),
          
          SizedBox(height: availableHeight * 0.03),
          
          // Contenu central
          _buildCenterContent(state, notifier),
        ],
      ),
    );
  }

  /// Titre responsive
  Widget _buildResponsiveTitle(double availableHeight) {
    final fontSize = (availableHeight * 0.04).clamp(18.0, 24.0); // Plus petit
    
    return Text(
      'La Roulette des\nVirelangues Magiques',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: VirelangueRouletteTheme.whiteText,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
    );
  }

  /// Système de gemmes minimal - 53px total
  Widget _buildMinimalGemSystem(GemCollection gems) {
    return Container(
      height: 53, // Réduit de 1px
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), // Réduit le padding vertical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMinimalGem('💎', gems.diamonds, VirelangueRouletteTheme.diamondGem),
          _buildMinimalGem('💚', gems.emeralds, VirelangueRouletteTheme.emeraldGem),
          _buildMinimalGem('💖', gems.rubies, VirelangueRouletteTheme.rubyGem),
        ],
      ),
    );
  }

  /// Gemme minimale pour éviter l'overflow
  Widget _buildMinimalGem(String emoji, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 1), // Réduit de 2 à 1
        Text(
          '$count',
          style: TextStyle(
            color: VirelangueRouletteTheme.whiteText,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Contenu central selon l'état
  Widget _buildCenterContent(VirelangueExerciseState state, VirelangueExerciseNotifier notifier) {
    // Aucun virelangue sélectionné - Bouton pour faire tourner
    if (state.currentVirelangue == null) {
      return Container(
        width: 260, // Réduit
        height: 50, // Réduit
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VirelangueRouletteTheme.cyanPrimary,
              VirelangueRouletteTheme.violetAccent,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: VirelangueRouletteTheme.cyanPrimary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: state.isLoading || _isWheelSpinning ? null : () => _spinWheelAndSelectVirelangue(notifier),
            child: Center(
              child: state.isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Text(
                      'FAIRE TOURNER LA ROULETTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Plus petit
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // Virelangue sélectionné - Interface d'enregistrement compacte
    return Column(
      children: [
        // Texte du virelangue
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24), // Réduit
          padding: const EdgeInsets.all(20), // Réduit
          decoration: BoxDecoration(
            color: VirelangueRouletteTheme.whiteText.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16), // Réduit
            border: Border.all(
              color: VirelangueRouletteTheme.whiteText.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            state.currentVirelangue!.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VirelangueRouletteTheme.whiteText,
              fontSize: 16, // Réduit
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 24), // Réduit
        
        // Boutons d'action compacts
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton "Nouveau tour"
            Container(
              height: 44, // Réduit
              padding: const EdgeInsets.symmetric(horizontal: 20), // Réduit
              decoration: BoxDecoration(
                color: VirelangueRouletteTheme.whiteText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: VirelangueRouletteTheme.whiteText.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _spinWheelAndSelectVirelangue(notifier),
                  child: Center(
                    child: Text(
                      'Nouveau tour',
                      style: TextStyle(
                        color: VirelangueRouletteTheme.whiteText,
                        fontSize: 13, // Réduit
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 20), // Réduit
            
            // Bouton microphone
            AnimatedMicrophoneButton(
              isRecording: state.isRecording,
              size: 54, // Réduit
              onPressed: () {
                if (state.isRecording) {
                  notifier.stopRecording();
                } else {
                  notifier.startRecording();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Écran de chargement simplifié
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                VirelangueRouletteTheme.cyanPrimary,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Préparation de la magie...',
            style: TextStyle(
              color: VirelangueRouletteTheme.whiteText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Écran d'erreur simplifié
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: VirelangueRouletteTheme.poorColor,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            'Erreur: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VirelangueRouletteTheme.poorColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}