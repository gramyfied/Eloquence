import 'package:flutter/material.dart';

class EloquenceColors {
  static const Color navy = Color(0xFF1A1F2E);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color white = Color(0xFFFFFFFF);

  // Couleurs glassmorphisme
  static const Color glassBackground = Color(0x331A1F2E);
  static const Color glassBorder = Color(0x5200D4FF);
  static const Color glassHighlight = Color(0x1AFFFFFF);
}

class EloquenceTextStyles {
  // Titres
  static const TextStyle logoTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    color: EloquenceColors.white,
    letterSpacing: 4,
    fontFamily: 'Playfair Display',
  );

  // Citations
  static const TextStyle quote = TextStyle(
    fontSize: 18,
    fontFamily: 'Playfair Display',
    color: EloquenceColors.white,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Noms d'orateurs
  static const TextStyle oratorName = TextStyle(
    fontSize: 16, // Réduit de 20 à 16
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  // Métadonnées
  static const TextStyle metadata = TextStyle(
    fontSize: 14,
    color: Color(0xB3FFFFFF),
    fontFamily: 'Inter',
  );

  // Boutons
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: EloquenceColors.white,
    fontFamily: 'Inter',
  );
}