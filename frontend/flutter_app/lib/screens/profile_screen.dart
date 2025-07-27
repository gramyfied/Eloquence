import 'package:flutter/material.dart';
import 'package:eloquence_2_0/widgets/layered_scaffold.dart';
import 'package:eloquence_2_0/core/navigation/navigation_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LayeredScaffold(
      carouselState: CarouselVisibilityState.subtle,
      showNavigation: false, // Désactiver car déjà gérée par MainScreen
      content: Center(
        child: Text(
          'Écran de Profil',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
