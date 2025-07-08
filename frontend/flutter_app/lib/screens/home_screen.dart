import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/layered_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, navigationState, child) {
        return LayeredScaffold(
          carouselState: CarouselVisibilityState.full,
          showNavigation: true,
          onCarouselTap: () {
            // Le carrousel est déjà interactif en mode full
          },
          content: Container(
            padding: const EdgeInsets.only(
              top: 80, // Réduit pour éviter de cacher les visages
              bottom: 120, // Augmenté pour éviter que le bouton cache du texte
            ),
            child: const SizedBox.shrink(), // Contenu vide pour laisser place au carrousel
          ),
        );
      },
    );
  }
}