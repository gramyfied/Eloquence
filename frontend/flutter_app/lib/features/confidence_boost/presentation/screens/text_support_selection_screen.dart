import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../providers/text_support_generator_provider.dart';

class TextSupportSelectionScreen extends ConsumerWidget {
  final ConfidenceScenario scenario;
  final Function(TextSupport) onSupportSelected;

  const TextSupportSelectionScreen({
    Key? key,
    required this.scenario,
    required this.onSupportSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    Future<TextSupport> generateSupport(SupportType supportType) async {
      final generator = ref.read(textSupportGeneratorProvider);
      return await generator.generateSupport(
        scenario: scenario,
        type: supportType,
        difficulty: scenario.difficulty,
      );
    }

    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support d\'exercice',
          style: EloquenceTextStyles.headline2,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(EloquenceSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez votre niveau de support',
              style: EloquenceTextStyles.headline1,
            ),
            const SizedBox(height: EloquenceSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  _buildSupportOption(
                    context: context,
                    title: 'Texte généré par IA',
                    description: 'Texte complet personnalisé pour vous guider',
                    icon: Icons.auto_awesome,
                    badge: 'Recommandé pour débuter',
                    badgeColor: ConfidenceBoostColors.successGreen,
                    supportType: SupportType.fullText,
                    onTap: () async {
                      final support = await generateSupport(SupportType.fullText);
                      onSupportSelected(support);
                    },
                  ),
                  const SizedBox(height: EloquenceSpacing.md),
                  _buildSupportOption(
                    context: context,
                    title: 'Texte à trous',
                    description: 'Structure avec blancs à remplir créativement',
                    icon: Icons.edit_note,
                    badge: 'Équilibre guidage/créativité',
                    badgeColor: EloquenceColors.cyan,
                    supportType: SupportType.fillInBlanks,
                    onTap: () async {
                      final support = await generateSupport(SupportType.fillInBlanks);
                      onSupportSelected(support);
                    },
                  ),
                  const SizedBox(height: EloquenceSpacing.md),
                  _buildSupportOption(
                    context: context,
                    title: 'Structure guidée',
                    description: 'Plan détaillé sans contraintes de mots',
                    icon: Icons.list_alt,
                    badge: 'Pour utilisateurs confirmés',
                    badgeColor: EloquenceColors.violet,
                    supportType: SupportType.guidedStructure,
                    onTap: () async {
                      final support = await generateSupport(SupportType.guidedStructure);
                      onSupportSelected(support);
                    },
                  ),
                  const SizedBox(height: EloquenceSpacing.md),
                  _buildSupportOption(
                    context: context,
                    title: 'Mots-clés imposés',
                    description: 'Défi créatif avec contraintes stimulantes',
                    icon: Icons.psychology,
                    badge: 'Challenge pour experts',
                    badgeColor: ConfidenceBoostColors.warningOrange,
                    supportType: SupportType.keywordChallenge,
                    onTap: () async {
                      final support = await generateSupport(SupportType.keywordChallenge);
                      onSupportSelected(support);
                    },
                  ),
                  const SizedBox(height: EloquenceSpacing.md),
                  _buildSupportOption(
                    context: context,
                    title: 'Improvisation libre',
                    description: 'Liberté totale avec coaching IA en temps réel',
                    icon: Icons.rocket_launch,
                    badge: 'Maîtrise complète',
                    badgeColor: Colors.red,
                    supportType: SupportType.freeImprovisation,
                    onTap: () async {
                      final support = await generateSupport(SupportType.freeImprovisation);
                      onSupportSelected(support);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required SupportType supportType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(EloquenceSpacing.lg),
        decoration: BoxDecoration(
          color: EloquenceColors.glassBackground,
          borderRadius: EloquenceRadii.card,
          border: EloquenceBorders.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: EloquenceColors.cyan, size: 24),
                const SizedBox(width: EloquenceSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: EloquenceTextStyles.headline2.copyWith(
                      height: 1.2, // Contrôle de la hauteur de ligne
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EloquenceSpacing.sm,
                    vertical: EloquenceSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: EloquenceTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: EloquenceSpacing.sm),
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
    );
  }
}
