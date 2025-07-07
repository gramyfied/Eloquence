import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

// Palette de Couleurs STRICTE
class EloquenceColors {
  // Couleurs principales (JAMAIS d'autres couleurs)
  static const Color navy = Color(0xFF1A1F2E);           // Background principal
  static const Color cyan = Color(0xFF00D4FF);           // Éléments interactifs
  static const Color violet = Color(0xFF8B5CF6);         // Accents et badges
  
  // Transparences glassmorphisme
  static const Color glassBackground = Color(0x331A1F2E); // rgba(26, 31, 46, 0.2)
  static const Color glassBorder = Color(0x5200D4FF);     // rgba(0, 212, 255, 0.32)
  static const Color glassWhite = Color(0x1AFFFFFF);      // rgba(255, 255, 255, 0.1)
  
  // Dégradés obligatoires
  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const RadialGradient haloGradient = RadialGradient(
    colors: [
      Color(0x4D00D4FF), // cyan avec opacité 0.3
      Color(0x1A8B5CF6), // violet avec opacité 0.1
    ],
  );
}

// Typography System OBLIGATOIRE
class EloquenceTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.3,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    letterSpacing: 0,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xB3FFFFFF), // white avec opacité 0.7
    letterSpacing: 0.5,
  );
}

// Espacements STANDARDISÉS
class EloquenceSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}