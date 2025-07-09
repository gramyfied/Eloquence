import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/layered_scaffold.dart';
import '../test_screen.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayeredScaffold(
          carouselState: CarouselVisibilityState.medium,
          showNavigation: true,
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
                EloquenceGlassCard(
                  borderRadius: 16,
                  borderColor: EloquenceColors.cyan,
                  opacity: 0.2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: EloquenceColors.cyan,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
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
                        'Gagnez en assurance en 3 minutes',
                        Icons.trending_up,
                        EloquenceColors.cyan,
                        'confidence_boost',
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
          print('=== Exercise card tapped ===');
          print('Title: $title');
          print('Exercise ID: $exerciseId');
          
          try {
            final navigationState = ref.read(navigationStateProvider);
            print('NavigationState obtained: $navigationState');
            
            navigationState.navigateTo(
              '/exercise_detail',
              context,
              exerciseId,
            );
            print('Navigation called successfully');
          } catch (e) {
            print('Error during navigation: $e');
            print('Stack trace: ${StackTrace.current}');
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
                    color: accentColor.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.7),
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