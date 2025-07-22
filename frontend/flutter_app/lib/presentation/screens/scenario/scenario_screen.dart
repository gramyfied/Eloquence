import 'package:flutter/material.dart';
import 'package:eloquence_2_0/widgets/layered_scaffold.dart';
import 'package:eloquence_2_0/core/navigation/navigation_state.dart';

class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LayeredScaffold(
      carouselState: CarouselVisibilityState.medium,
      showNavigation: false, // Désactiver car déjà gérée par MainScreen
      content: Center(
        child: Text(
          'Écran des Scénarios',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
