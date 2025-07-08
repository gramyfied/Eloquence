import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/layered_scaffold.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final String exerciseId;

  const ExerciseDetailScreen({Key? key, required this.exerciseId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, navigationState, child) {
        return LayeredScaffold(
          carouselState: CarouselVisibilityState.subtle,
          showNavigation: false, // Navigation cachée pendant l'exercice
          onCarouselTap: () {
            // Tap sur le carrousel pour revenir aux exercices
            context.read<NavigationState>().navigateTo('/exercises');
            Navigator.pop(context);
          },
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Header avec retour
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<NavigationState>().navigateTo('/exercises');
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Confidence Boost Express',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Équilibrer le bouton retour
                  ],
                ),

                const SizedBox(height: 40),

                // Description de l'exercice
                const EloquenceGlassCard(
                  borderRadius: 16,
                  borderColor: EloquenceColors.cyan,
                  opacity: 0.2,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 48,
                          color: EloquenceColors.cyan,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Parlez d\'un sujet qui vous passionne pendant 2 minutes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Playfair Display',
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'L\'IA analysera votre clarté, rythme et confiance pour vous donner des conseils personnalisés.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xB3FFFFFF),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bouton de démarrage
                SizedBox(
                  width: double.infinity,
                  child: EloquenceGlassCard(
                    borderRadius: 30,
                    borderColor: EloquenceColors.cyan,
                    opacity: 0.2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          context
                              .read<NavigationState>()
                              .startExercise(exerciseId);
                          // Navigation vers l'exercice actif
                          Navigator.pushNamed(
                            context,
                            '/exercise_active',
                            arguments: exerciseId,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                EloquenceColors.cyan,
                                EloquenceColors.violet,
                              ],
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Commencer l\'exercice',
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
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}