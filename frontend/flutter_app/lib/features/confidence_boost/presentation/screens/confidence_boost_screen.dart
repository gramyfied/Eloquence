import 'package:flutter/material.dart';
import 'confidence_boost_main_screen.dart';

class ConfidenceBoostScreen extends StatelessWidget {
  final String userId;

  const ConfidenceBoostScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirige vers le nouvel écran principal de la fonctionnalité
    return const ConfidenceBoostMainScreen();
  }
}