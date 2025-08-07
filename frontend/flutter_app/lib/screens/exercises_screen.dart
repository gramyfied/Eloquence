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
                        'Générateur d\'Histoires Infinies 📚✨',
                        'Créez des histoires épiques avec l\'IA et améliorez votre narration',
                        Icons.auto_stories,
                        const Color(0xFFFF6B35), // Orange narratif
                        'story_generator',
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'L\'Accordeur Vocal Cosmique 🌌',
                        'Guidez un vaisseau spatial avec votre voix et collectez des cristaux d\'énergie',
                        Icons.rocket,
                        const Color(0xFF00BCD4), // Cyan cosmique
                        'cosmic_voice',
                        isUnderDevelopment: true,
                      ),
                      const SizedBox(height: 16),
                      _buildExerciseCard(
                        context,
                        ref,
                        'Le Tribunal des Idées ⚖️',
                        'Défendez des positions absurdes devant un juge IA impartial et développez vos talents d\'argumentation',
                        Icons.gavel,
                        const Color(0xFF8B4513), // Marron justice
                        'tribunal_idees',
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
    String exerciseId, {
    bool isUnderDevelopment = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isUnderDevelopment ? () {
          // Afficher un dialog pour exercice en développement
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accentColor, width: 1),
                ),
                title: Row(
                  children: [
                    Icon(Icons.construction, color: accentColor, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '🚧 En cours de développement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Cet exercice est actuellement en cours de développement et sera bientôt disponible.\n\nNous travaillons sur l\'intégration du contrôle vocal en temps réel pour une expérience optimale !',
                  style: TextStyle(
                    color: Colors.white.withAlpha((255 * 0.8).round()),
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Compris',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } : () {
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
            } else if (exerciseId == 'story_generator') {
              // Navigation spéciale pour le Générateur d'Histoires Infinies
              debugPrint('Navigating to story generator home screen using root navigator');
              context.go('/story_generator', extra: {});
            } else if (exerciseId == 'cosmic_voice') {
              // Navigation spéciale pour l'Accordeur Vocal Cosmique
              debugPrint('Navigating to cosmic voice exercise using root navigator');
              context.go('/cosmic_voice', extra: {});
            } else if (exerciseId == 'tribunal_idees') {
              // Navigation spéciale pour le Tribunal des Idées
              debugPrint('Navigating to tribunal idees exercise using root navigator');
              context.go('/tribunal_idees', extra: {});
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
        child: Stack(
          children: [
            EloquenceGlassCard(
              borderRadius: 16,
              borderColor: isUnderDevelopment ? Colors.orange : accentColor,
              opacity: isUnderDevelopment ? 0.08 : 0.15,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (isUnderDevelopment ? Colors.orange : accentColor).withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUnderDevelopment ? Icons.construction : icon,
                        color: isUnderDevelopment ? Colors.orange : accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isUnderDevelopment ? Colors.white.withAlpha((255 * 0.6).round()) : Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              if (isUnderDevelopment)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha((255 * 0.2).round()),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange, width: 1),
                                  ),
                                  child: const Text(
                                    'BIENTÔT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUnderDevelopment
                              ? 'Exercice en cours de développement - Architecture vocale en cours d\'optimisation'
                              : description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((255 * (isUnderDevelopment ? 0.5 : 0.7)).round()),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isUnderDevelopment ? Icons.schedule : Icons.arrow_forward_ios,
                      color: isUnderDevelopment ? Colors.orange : accentColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
