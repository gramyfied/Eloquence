import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/scenario_models.dart';
import '../providers/scenario_provider.dart';
import '../widgets/scenario_card_widget.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// ÉCRAN 1 : Configuration du scénario IA
/// Interface de sélection et personnalisation des paramètres d'exercice
class ScenarioConfigurationScreen extends ConsumerStatefulWidget {
  const ScenarioConfigurationScreen({super.key});

  @override
  ConsumerState<ScenarioConfigurationScreen> createState() => _ScenarioConfigurationScreenState();
}

class _ScenarioConfigurationScreenState extends ConsumerState<ScenarioConfigurationScreen>
    with TickerProviderStateMixin {
  
  // Configuration par défaut
  ScenarioType selectedScenario = ScenarioType.jobInterview;
  double difficulty = 0.5; // 0.0 = Easy, 1.0 = Hard
  int selectedDuration = 10; // minutes
  AIPersonalityType selectedPersonality = AIPersonalityType.friendly;

  // Contrôleurs d'animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: EloquenceTheme.animationMedium,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: EloquenceTheme.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: EloquenceTheme.curveEnter,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: EloquenceTheme.curveEmphasized,
    ));

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScenarioSelection(),
                          const SizedBox(height: EloquenceTheme.spacingXl),
                          _buildDifficultySection(),
                          const SizedBox(height: EloquenceTheme.spacingXl),
                          _buildDurationSection(),
                          const SizedBox(height: EloquenceTheme.spacingXl),
                          _buildPersonalitySection(),
                          const SizedBox(height: EloquenceTheme.spacingXxxl),
                          _buildStartButton(),
                          const SizedBox(height: EloquenceTheme.spacingLg),
                        ],
                      ),
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingLg,
        vertical: EloquenceTheme.spacingMd,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: EloquenceTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(width: EloquenceTheme.spacingSm),
          Expanded(
            child: Text(
              "CONFIGURATION SCÉNARIO IA",
              style: EloquenceTheme.headline2.copyWith(
                color: EloquenceTheme.cyan,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Équilibrer avec le bouton back
        ],
      ),
    );
  }

  Widget _buildScenarioSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sélection du Scénario",
          style: EloquenceTheme.headline3,
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Text(
          "Choisissez le type de conversation que vous souhaitez pratiquer",
          style: EloquenceTheme.bodySmall,
        ),
        const SizedBox(height: EloquenceTheme.spacingLg),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: EloquenceTheme.spacingMd,
          crossAxisSpacing: EloquenceTheme.spacingMd,
          childAspectRatio: 1.3,
          children: ScenarioType.values.map((type) {
            return ScenarioCardWidget(
              type: type,
              isSelected: selectedScenario == type,
              onTap: () => setState(() => selectedScenario = type),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Niveau de Difficulté",
          style: EloquenceTheme.headline3,
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Text(
          "Ajustez le niveau de défi selon vos compétences",
          style: EloquenceTheme.bodySmall,
        ),
        const SizedBox(height: EloquenceTheme.spacingLg),
        EloquenceComponents.glassContainer(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Facile",
                    style: EloquenceTheme.bodyMedium.copyWith(
                      color: difficulty <= 0.33 ? EloquenceTheme.cyan : EloquenceTheme.white.withOpacity(0.7),
                      fontWeight: difficulty <= 0.33 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    "Moyen",
                    style: EloquenceTheme.bodyMedium.copyWith(
                      color: difficulty > 0.33 && difficulty <= 0.66 ? EloquenceTheme.cyan : EloquenceTheme.white.withOpacity(0.7),
                      fontWeight: difficulty > 0.33 && difficulty <= 0.66 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    "Difficile",
                    style: EloquenceTheme.bodyMedium.copyWith(
                      color: difficulty > 0.66 ? EloquenceTheme.cyan : EloquenceTheme.white.withOpacity(0.7),
                      fontWeight: difficulty > 0.66 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EloquenceTheme.spacingMd),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: EloquenceTheme.cyan,
                  inactiveTrackColor: EloquenceTheme.cyan.withOpacity(0.3),
                  thumbColor: EloquenceTheme.violet,
                  overlayColor: EloquenceTheme.violet.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: difficulty,
                  onChanged: (value) => setState(() => difficulty = value),
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              const SizedBox(height: EloquenceTheme.spacingSm),
              Text(
                _getDifficultyDescription(),
                style: EloquenceTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Durée de Session",
          style: EloquenceTheme.headline3,
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Text(
          "Combien de temps souhaitez-vous pratiquer ?",
          style: EloquenceTheme.bodySmall,
        ),
        const SizedBox(height: EloquenceTheme.spacingLg),
        Row(
          children: [5, 10, 15].map((duration) {
            final isSelected = selectedDuration == duration;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: EloquenceTheme.spacingXs),
                child: GestureDetector(
                  onTap: () => setState(() => selectedDuration = duration),
                  child: AnimatedContainer(
                    duration: EloquenceTheme.animationMedium,
                    curve: EloquenceTheme.curveStandard,
                    padding: const EdgeInsets.symmetric(vertical: EloquenceTheme.spacingLg),
                    decoration: BoxDecoration(
                      gradient: isSelected ? EloquenceTheme.primaryGradient : null,
                      color: isSelected ? null : EloquenceTheme.glassBackground,
                      borderRadius: EloquenceTheme.borderRadiusMedium,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : EloquenceTheme.glassBorder,
                        width: 1,
                      ),
                      boxShadow: isSelected ? EloquenceTheme.shadowGlow : EloquenceTheme.shadowSmall,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$duration",
                          style: EloquenceTheme.headline3.copyWith(
                            color: isSelected ? EloquenceTheme.white : EloquenceTheme.cyan,
                          ),
                        ),
                        const SizedBox(height: EloquenceTheme.spacingXs),
                        Text(
                          "min",
                          style: EloquenceTheme.bodySmall.copyWith(
                            color: isSelected ? EloquenceTheme.white.withOpacity(0.8) : EloquenceTheme.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personnalité IA",
          style: EloquenceTheme.headline3,
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Text(
          "Choisissez comment l'IA doit interagir avec vous",
          style: EloquenceTheme.bodySmall,
        ),
        const SizedBox(height: EloquenceTheme.spacingLg),
        EloquenceComponents.glassContainer(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AIPersonalityType>(
              value: selectedPersonality,
              isExpanded: true,
              dropdownColor: EloquenceTheme.navy,
              style: EloquenceTheme.bodyMedium,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: EloquenceTheme.cyan,
                size: 24,
              ),
              items: AIPersonalityType.values.map((personality) {
                return DropdownMenuItem(
                  value: personality,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          personality.displayName,
                          style: EloquenceTheme.bodyMedium.copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          personality.description,
                          style: EloquenceTheme.bodySmall.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedPersonality = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: EloquenceTheme.primaryGradient,
          borderRadius: EloquenceTheme.borderRadiusLarge,
          boxShadow: EloquenceTheme.shadowGlow,
        ),
        child: ElevatedButton(
          onPressed: _startScenario,
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
                Icons.play_arrow,
                color: EloquenceTheme.white,
                size: 24,
              ),
              const SizedBox(width: EloquenceTheme.spacingSm),
              Text(
                "Démarrer la Session",
                style: EloquenceTheme.buttonLarge.copyWith(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDifficultyDescription() {
    if (difficulty <= 0.33) {
      return "Rythme doux, retours encourageants, scénarios de base";
    } else if (difficulty <= 0.66) {
      return "Défi modéré, retours équilibrés, scénarios réalistes";
    } else {
      return "Rythme rapide, questions challengeantes, scénarios professionnels";
    }
  }

  void _startScenario() {
    final configuration = ScenarioConfiguration(
      type: selectedScenario,
      difficulty: difficulty,
      durationMinutes: selectedDuration,
      personality: selectedPersonality,
    );

    // Sauvegarder la configuration dans le provider
    ref.read(scenarioProvider.notifier).setConfiguration(configuration);

    // Navigation vers l'écran d'exercice avec GoRouter
    GoRouter.of(context).go(
      '/scenario_exercise',
      extra: configuration.toJson(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
