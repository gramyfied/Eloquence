import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_scenario.dart';

class ScenarioSelectionScreen extends StatelessWidget {
  final Function(ConfidenceScenario) onScenarioSelected;

  const ScenarioSelectionScreen({Key? key, required this.onScenarioSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EloquenceSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec progression utilisateur
              _buildProgressHeader(),
              const SizedBox(height: EloquenceSpacing.xl),

              // Titre principal
              const Text(
                'Choisissez votre scénario',
                style: EloquenceTextStyles.headline1,
              ),
              const SizedBox(height: EloquenceSpacing.lg),

              // Liste des scénarios
              Expanded(
                child: ListView(
                  children: [
                    _buildScenarioCard(
                      title: 'Présentation Professionnelle',
                      description: 'Présentez votre projet avec assurance',
                      difficulty: 'Débutant',
                      difficultyColor: EloquenceColors.cyan,
                      icon: Icons.business_center,
                      scenario: const ConfidenceScenario.professional(),
                    ),
                    const SizedBox(height: EloquenceSpacing.md),
                    _buildScenarioCard(
                      title: 'Entretien d\'Embauche',
                      description: 'Brillez lors de votre prochain entretien',
                      difficulty: 'Intermédiaire',
                      difficultyColor: EloquenceColors.violet,
                      icon: Icons.work,
                      scenario: const ConfidenceScenario.interview(),
                    ),
                    const SizedBox(height: EloquenceSpacing.md),
                    _buildScenarioCard(
                      title: 'Prise de Parole Publique',
                      description: 'Captivez votre audience avec confiance',
                      difficulty: 'Avancé',
                      difficultyColor: ConfidenceBoostColors.warningOrange,
                      icon: Icons.mic,
                      scenario: const ConfidenceScenario.publicSpeaking(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(EloquenceSpacing.md),
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Row(
        children: [
          const Text('Level 5', style: EloquenceTextStyles.headline2),
          const Spacer(),
          Text('350 XP', style: EloquenceTextStyles.body1.copyWith(
            color: EloquenceColors.cyan,
          )),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String description,
    required String difficulty,
    required Color difficultyColor,
    required IconData icon,
    required ConfidenceScenario scenario,
  }) {
    return GestureDetector(
      onTap: () => onScenarioSelected(scenario),
      child: Container(
        padding: const EdgeInsets.all(EloquenceSpacing.lg),
        decoration: BoxDecoration(
          color: EloquenceColors.glassBackground,
          borderRadius: EloquenceRadii.card,
          border: EloquenceBorders.card,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: difficultyColor.withAlpha((255 * 0.2).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: difficultyColor, size: 28),
            ),
            const SizedBox(width: EloquenceSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EloquenceTextStyles.headline2.copyWith(
                      height: 1.2, // Contrôle de la hauteur de ligne
                    ),
                  ),
                  const SizedBox(height: EloquenceSpacing.xs),
                  Text(
                    description,
                    style: EloquenceTextStyles.body1.copyWith(
                      color: Colors.white70,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EloquenceSpacing.sm,
                vertical: EloquenceSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: difficultyColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                difficulty,
                style: EloquenceTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}