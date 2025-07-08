import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/layered_scaffold.dart';

class ExerciseActiveScreen extends StatelessWidget {
  final String exerciseId;

  const ExerciseActiveScreen({Key? key, required this.exerciseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Rediriger vers l'exercice spécialisé si c'est confidence_boost
    if (exerciseId == 'confidence_boost') {
      const userId = 'default_user';
      
      // Navigation immédiate sans callback
      Navigator.pushReplacementNamed(
        context,
        '/confidence_boost',
        arguments: userId,
      );
      
      // Widget minimal (ne sera pas affiché)
      return const SizedBox.shrink();
    }
    return Consumer<NavigationState>(
      builder: (context, navigationState, child) {
        return LayeredScaffold(
          carouselState: CarouselVisibilityState.minimal,
          showNavigation: false,
          onCarouselTap: () {
            context.read<NavigationState>().endExercise();
            Navigator.pop(context);
          },
          content: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Exercice en cours...',
                  style: EloquenceTextStyles.logoTitle,
                ),
                const SizedBox(height: 20),
                Text(
                  'ID: $exerciseId',
                  style: EloquenceTextStyles.quote,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EloquenceColors.cyan,
                  ),
                  onPressed: () {
                     context.read<NavigationState>().endExercise();
                     Navigator.pop(context);
                  },
                  child: const Text("Terminer l'exercice"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}