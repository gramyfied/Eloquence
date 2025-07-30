import 'package:flutter/material.dart';

/// Thème simple et épuré pour "La Roulette des Virelangues Magiques"
/// Basé exactement sur les images fournies
class VirelangueRouletteTheme {
  
  // 🎨 COULEURS PRINCIPALES (selon les images)
  static const Color navyBackground = Color(0xFF1A1F2E);  // Navy uniforme
  static const Color cyanPrimary = Color(0xFF00D4FF);     // Cyan vif
  static const Color violetAccent = Color(0xFF8B5CF6);    // Violet
  static const Color whiteText = Color(0xFFFFFFFF);       // Blanc pur
  
  // 🌈 COULEURS DES SEGMENTS (selon l'image de la roue colorée)
  static const List<Color> wheelSegmentColors = [
    Color(0xFF00D4FF), // Cyan
    Color(0xFF8B5CF6), // Violet
    Color(0xFFFF6B9D), // Rose
    Color(0xFFFF9500), // Orange
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFF9B59B6), // Violet foncé
    Color(0xFF3498DB), // Bleu
    Color(0xFF2ECC71), // Vert
  ];
  
  // 💎 COULEURS DES GEMMES (selon l'image du bas)
  static const Color rubyGem = Color(0xFFE91E63);      // Rose/Rouge
  static const Color emeraldGem = Color(0xFF4CAF50);   // Vert
  static const Color diamondGem = Color(0xFF00BCD4);   // Cyan/Bleu
  
  // 🎯 COULEURS DE PERFORMANCE
  static const Color excellentGold = Color(0xFFFFD700);
  static const Color goodColor = Color(0xFF4CAF50);
  static const Color averageColor = Color(0xFFFF9800);
  static const Color poorColor = Color(0xFFF44336);
  
  // ✨ COULEURS D'EFFETS
  static const Color sparkleGold = Color(0xFFFFD700);   // Étincelles dorées
  
  /// 🎨 Retourne la couleur d'un segment selon son index
  static Color getSegmentColor(int index) {
    return wheelSegmentColors[index % wheelSegmentColors.length];
  }
  
  /// 💎 Retourne la couleur d'une gemme selon son type
  static Color getGemColor(String gemType) {
    switch (gemType.toLowerCase()) {
      case 'ruby':
        return rubyGem;
      case 'emerald':
        return emeraldGem;
      case 'diamond':
        return diamondGem;
      default:
        return cyanPrimary;
    }
  }
  
  /// 🎯 Retourne la couleur selon le score de performance
  static Color getPerformanceColor(double score) {
    if (score >= 0.9) return excellentGold;
    if (score >= 0.8) return goodColor;
    if (score >= 0.6) return averageColor;
    return poorColor;
  }
  
  /// ✨ Créer un dégradé magique cyan-violet
  static LinearGradient get magicGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanPrimary, violetAccent],
  );
  
  /// 🌟 Créer un dégradé doré pour les succès
  static LinearGradient get goldGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
  );
  
  /// 🎭 Créer un effet glassmorphisme
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        whiteText.withOpacity(0.1),
        whiteText.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: whiteText.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
  
  /// 🎨 Style de texte pour les titres
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: whiteText,
    height: 1.2,
  );
  
  /// 📱 Style de texte pour les virelangues
  static const TextStyle virelangueTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: whiteText,
    height: 1.3,
  );
  
  /// 🔢 Style de texte pour les scores
  static const TextStyle scoreStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: whiteText,
  );
  
  /// 🔘 Style de texte pour les boutons
  static const TextStyle buttonStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: whiteText,
  );
  
  /// ✨ Animation de particules magiques
  static List<BoxShadow> get magicGlow => [
    BoxShadow(
      color: cyanPrimary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 0),
    ),
    BoxShadow(
      color: violetAccent.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: 4,
      offset: const Offset(0, 0),
    ),
  ];
  
  /// 🎪 Décoration pour la roulette
  static BoxDecoration get wheelDecoration => BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        navyBackground.withOpacity(0.8),
        navyBackground,
      ],
    ),
    boxShadow: magicGlow,
  );
  
  /// 🏆 Décoration pour les gemmes
  static BoxDecoration gemDecoration(Color gemColor) => BoxDecoration(
    color: gemColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: gemColor.withOpacity(0.3),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: gemColor.withOpacity(0.2),
        blurRadius: 12,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  /// 🎯 Décoration pour le pointeur de la roulette
  static BoxDecoration get pointerDecoration => BoxDecoration(
    color: cyanPrimary,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: cyanPrimary.withOpacity(0.5),
        blurRadius: 15,
        spreadRadius: 2,
        offset: const Offset(0, 0),
      ),
    ],
  );
  
  /// 🌟 Décoration pour les boutons principaux
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: magicGradient,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: cyanPrimary.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  /// 🎪 Créer le thème Flutter complet
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navyBackground,
    primaryColor: cyanPrimary,
    colorScheme: const ColorScheme.dark(
      primary: cyanPrimary,
      secondary: violetAccent,
      surface: Color(0xFF2A2F45),
      background: navyBackground,
      onPrimary: whiteText,
      onSecondary: whiteText,
      onSurface: whiteText,
      onBackground: whiteText,
    ),
    
    // Configuration des boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cyanPrimary,
        foregroundColor: whiteText,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: buttonStyle,
      ),
    ),
    
    // Configuration du texte
    textTheme: const TextTheme(
      displayLarge: titleStyle,
      displayMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: whiteText,
      ),
      headlineSmall: virelangueTextStyle,
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: whiteText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: whiteText,
      ),
      labelLarge: buttonStyle,
    ),
    
    // Configuration des cartes
    cardTheme: CardThemeData(
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Configuration des app bars
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: whiteText,
      ),
      iconTheme: IconThemeData(color: whiteText),
    ),
  );
}

/// 🎭 Extension pour créer des effets visuels avancés
extension VirelangueVisualEffects on Widget {
  /// ✨ Ajouter un effet de lueur magique
  Widget withMagicGlow() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: VirelangueRouletteTheme.magicGlow,
      ),
      child: this,
    );
  }
  
  /// 🎪 Ajouter un effet glassmorphisme
  Widget withGlassmorphism() {
    return Container(
      decoration: VirelangueRouletteTheme.glassmorphismDecoration,
      child: this,
    );
  }
  
  /// 🌟 Animation de pulsation magique
  Widget withMagicPulse(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (controller.value * 0.05),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: VirelangueRouletteTheme.cyanPrimary.withOpacity(
                    0.3 + (controller.value * 0.2)
                  ),
                  blurRadius: 15 + (controller.value * 10),
                  spreadRadius: 2 + (controller.value * 2),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: this,
          ),
        );
      },
    );
  }
}