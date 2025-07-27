import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/navigation/navigation_state.dart';
import '../widgets/layered_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On écoute les changements du carouselState pour reconstruire si nécessaire
    final carouselState = ref.watch(navigationStateProvider.select((state) => state.carouselState));

    return LayeredScaffold(
      carouselState: carouselState,
      showNavigation: false, // Désactiver car déjà gérée par MainScreen
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
  }
}
