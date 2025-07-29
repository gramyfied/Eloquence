import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eloquence_2_0/presentation/providers/router_provider.dart'; // Import pour rootNavigatorKey
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/layered_scaffold.dart';
import '../features/confidence_boost/presentation/screens/confidence_boost_entry.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayeredScaffold(
          carouselState: CarouselVisibilityState.medium,
          showNavigation: false, // Désactiver car déjà gérée par MainScreen
          onCarouselTap: () {
            // Retour à l'accueil pour voir le carrousel en plein
            ref.read(navigationStateProvider).navigateTo('/home');
          },
          content: Container(
            padding: const EdgeInsets.only(
              top: 120,
              bottom: 120,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec titre
                const EloquenceGlassCard(
                  borderRadius: 16,
                  borderColor: EloquenceColors.cyan,
                  opacity: 0.2,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: EloquenceColors.cyan,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Exercices d\'éloquence',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Liste des exercices
                Expanded(
                  child: ListView(
                    children: [
                      _buildExerciseCard(
                        context,
                        ref,
                        'Confidence Boost Express',
                        'Gagnez en assurance en 3 minutes avec un sujet qui vous passionne',
                        Icons.psychology_rounded,
                        EloquenceColors.violet,
                        'confidence_boost',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Roulette des Virelangues Magiques',
                        'Exercice gamifié avec collection de gemmes cosmétiques et récompenses variables',
                        Icons.casino,
                        EloquenceColors.cyan,
                        'virelangue_roulette',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Souffle de Dragon : Équilibre Professionnel-Ludique 🐉',
                        'Exercice de respiration guidée gamifié avec progression Dragon et achievements',
                        Icons.air,
                        const Color(0xFF8B5CF6), // Violet Dragon
                        'dragon_breath',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Pitch Perfect',
                        'Maîtrisez l\'art du pitch en 90 secondes',
                        Icons.rocket_launch,
                        EloquenceColors.violet,
                        'pitch_perfect',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Interview Master',
                        'Brillez en entretien professionnel',
                        Icons.work,
                        EloquenceColors.cyan,
                        'interview_master',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Debate Champion',
                        'Argumentez avec force et conviction',
                        Icons.gavel,
                        EloquenceColors.violet,
                        'debate_champion',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    IconData icon,
    Color accentColor,
    String exerciseId,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          debugPrint('=== Exercise card tapped ===');
          debugPrint('Title: $title');
          debugPrint('Exercise ID: $exerciseId');
          
          try {
            // Navigation spéciale pour confidence_boost vers l'interface conversationnelle
            if (exerciseId == 'confidence_boost') {
              debugPrint('Navigating to confidence boost conversational interface');
              context.go('/confidence_boost');
            } else if (exerciseId == 'virelangue_roulette') {
              // Navigation spéciale pour la roulette des virelangues, en utilisant le navigateur racine
              debugPrint('Navigating to virelangue roulette using root navigator');
              context.go('/virelangue_roulette', extra: {});
            } else if (exerciseId == 'dragon_breath') {
              // Navigation spéciale pour l'exercice Souffle de Dragon
              debugPrint('Navigating to dragon breath exercise using root navigator');
              context.go('/dragon_breath', extra: {});
            } else {
              // Navigation normale vers exercise_detail avec l'ID
              debugPrint('Navigating to exercise detail with ID: $exerciseId');
              context.go('/exercise_detail/$exerciseId');
            }
            debugPrint('Navigation called successfully');
          } catch (e, s) {
            debugPrint('Error during navigation: $e');
            debugPrint('Stack trace: $s');
          }
        },
        child: EloquenceGlassCard(
          borderRadius: 16,
          borderColor: accentColor,
          opacity: 0.15,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha((255 * 0.7).round()),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: accentColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
