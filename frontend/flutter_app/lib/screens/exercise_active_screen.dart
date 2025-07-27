import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/layered_scaffold.dart';

class ExerciseActiveScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseActiveScreen({Key? key, required this.exerciseId}) : super(key: key);

  @override
  ExerciseActiveScreenState createState() => ExerciseActiveScreenState();
}

class ExerciseActiveScreenState extends ConsumerState<ExerciseActiveScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.exerciseId == 'confidence_boost') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/confidence_boost');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affiche un loader pendant la redirection
    if (widget.exerciseId == 'confidence_boost') {
      return const Scaffold(
        backgroundColor: EloquenceColors.navy,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final navigationNotifier = ref.read(navigationStateProvider.notifier);

    return LayeredScaffold(
      carouselState: CarouselVisibilityState.minimal,
      showNavigation: false,
      onCarouselTap: () {
        navigationNotifier.endExercise();
        context.pop();
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
              'ID: ${widget.exerciseId}',
              style: EloquenceTextStyles.quote,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EloquenceColors.cyan,
              ),
              onPressed: () {
                navigationNotifier.endExercise();
                context.pop();
              },
              child: const Text("Terminer l'exercice"),
            )
          ],
        ),
      ),
    );
  }
}