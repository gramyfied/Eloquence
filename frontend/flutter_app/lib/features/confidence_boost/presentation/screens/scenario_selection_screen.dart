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
              SizedBox(height: EloquenceSpacing.xl),

              // Titre principal
              Text(
                'Choisissez votre scénario',
                style: EloquenceTextStyles.headline1,
              ),
              SizedBox(height: EloquenceSpacing.lg),

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
                      scenario: ConfidenceScenario.professional(),
                    ),
                    SizedBox(height: EloquenceSpacing.md),
                    _buildScenarioCard(
                      title: 'Entretien d\'Embauche',
                      description: 'Brillez lors de votre prochain entretien',
                      difficulty: 'Intermédiaire',
                      difficultyColor: EloquenceColors.violet,
                      icon: Icons.work,
                      scenario: ConfidenceScenario.interview(),
                    ),
                    SizedBox(height: EloquenceSpacing.md),
                    _buildScenarioCard(
                      title: 'Prise de Parole Publique',
                      description: 'Captivez votre audience avec confiance',
                      difficulty: 'Avancé',
                      difficultyColor: ConfidenceBoostColors.warningOrange,
                      icon: Icons.mic,
                      scenario: ConfidenceScenario.publicSpeaking(),
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
          Text('Level 5', style: EloquenceTextStyles.headline2),
          Spacer(),
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
                color: difficultyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: difficultyColor, size: 28),
            ),
            SizedBox(width: EloquenceSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: EloquenceTextStyles.headline2),
                  SizedBox(height: EloquenceSpacing.xs),
                  Text(description, style: EloquenceTextStyles.body1.copyWith(
                    color: Colors.white70,
                  )),
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