import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../../../presentation/widgets/eloquence_components.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'animated_tap_effect.dart';

class ConfidenceScenarioCard extends StatelessWidget {
  final ConfidenceScenario scenario;
  final VoidCallback onTap;

  const ConfidenceScenarioCard({
    Key? key,
    required this.scenario,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedTapEffect(
      onTap: onTap,
      child: EloquenceGlassCard(
        child: Row(
          children: [
            // Icône du scénario
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: EloquenceColors.cyanVioletGradient,
              ),
              child: Center(
                child: Text(
                  scenario.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: EloquenceTextStyles.headline2.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.description,
                    style: EloquenceTextStyles.caption.copyWith(
                      color: EloquenceColors.white.withAlpha((255 * 0.7).round()),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Durée
                      _buildInfoChip(
                        icon: Icons.timer_outlined,
                        label: '${scenario.durationSeconds}s',
                      ),
                      const SizedBox(width: 12),
                      // Difficulté
                      _buildInfoChip(
                        icon: Icons.signal_cellular_alt,
                        label: _getDifficultyLabel(scenario.difficulty),
                        color: _getDifficultyColor(scenario.difficulty),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Flèche
            Icon(
              Icons.arrow_forward_ios,
              color: EloquenceColors.white.withAlpha((255 * 0.5).round()),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? EloquenceColors.cyan).withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? EloquenceColors.cyan).withAlpha((255 * 0.3).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? EloquenceColors.cyan,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: EloquenceTextStyles.caption.copyWith(
              color: color ?? EloquenceColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return 'Intermédiaire';
    }
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return EloquenceColors.cyan;
      case 'intermediate':
        return EloquenceColors.violet;
      case 'advanced':
        return EloquenceColors.error;
      default:
        return EloquenceColors.violet;
    }
  }
}