import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Design System Eloquence Unifié - Spécifications Visuelles Exactes
/// Version consolidée avec toutes les spécifications de couleurs, typographie, animations
class EloquenceTheme {
  
  // ========== PALETTE DE COULEURS STRICTE ==========
  
  /// Couleurs principales (JAMAIS d'autres couleurs dans l'app)
  static const Color navy = Color(0xFF1A1F2E);           // Background principal
  static const Color cyan = Color(0xFF00D4FF);           // Éléments interactifs primaires
  static const Color violet = Color(0xFF8B5CF6);         // Accents et badges
  static const Color white = Color(0xFFFFFFFF);          // Texte principal
  
  /// Variantes Cyan (pour hiérarchie visuelle)
  static const Color cyanLight = Color(0xFF33E0FF);      // Hover states
  static const Color cyanDark = Color(0xFF00B8E6);       // Active states
  
  /// Variantes Violet (pour hiérarchie visuelle)
  static const Color violetLight = Color(0xFFA78BFA);    // Hover states
  static const Color violetDark = Color(0xFF7C3AED);     // Active states
  
  /// Transparences Glassmorphisme (EXACTES)
  static const Color glassBackground = Color(0x331A1F2E); // navy à 20% opacité
  static const Color glassBorder = Color(0x5200D4FF);     // cyan à 32% opacité
  static const Color glassWhite = Color(0x1AFFFFFF);      // white à 10% opacité
  static const Color glassAccent = Color(0x408B5CF6);     // violet à 25% opacité
  
  /// Couleurs sémantiques (ajouts minimaux autorisés)
  static const Color successGreen = Color(0xFF4ECDC4);
  static const Color warningOrange = Color(0xFFFFB347);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color celebrationGold = Color(0xFFFFD700);
  
  // ========== DÉGRADÉS OBLIGATOIRES ==========
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [navy, Color(0xFF252B3E)], // Navy avec variante plus claire
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const RadialGradient haloGradient = RadialGradient(
    colors: [
      Color(0x4D00D4FF), // cyan à 30% opacité
      Color(0x1A8B5CF6), // violet à 10% opacité
      Colors.transparent,
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  static const LinearGradient glassSurfaceGradient = LinearGradient(
    colors: [glassWhite, glassBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ========== SYSTÈME TYPOGRAPHIQUE ==========
  
  static const String primaryFontFamily = 'Inter';
  static const String displayFontFamily = 'Playfair Display';
  static const String monoFontFamily = 'JetBrains Mono';
  
  /// Titres et en-têtes
  static const TextStyle headline1 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: white,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: -0.2,
    height: 1.4,
  );
  
  /// Texte de corps
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: white,
    letterSpacing: 0,
    height: 1.6,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: white,
    letterSpacing: 0,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xB3FFFFFF), // white à 70% opacité
    letterSpacing: 0.25,
    height: 1.4,
  );
  
  /// Texte d'interface
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: 0.25,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xB3FFFFFF), // white à 70% opacité
    letterSpacing: 0.5,
  );
  
  /// Styles spécialisés
  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: white,
    letterSpacing: -1.0,
  );
  
  static const TextStyle timerDisplay = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: 2.0,
  );
  
  // ========== ESPACEMENTS STANDARDISÉS ==========
  
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingXxxl = 64.0;
  
  // ========== RAYONS DE BORDURE ==========
  
  static const Radius radiusSmall = Radius.circular(8.0);
  static const Radius radiusMedium = Radius.circular(12.0);
  static const Radius radiusLarge = Radius.circular(16.0);
  static const Radius radiusXLarge = Radius.circular(24.0);
  static const Radius radiusCircle = Radius.circular(100.0);
  
  static const BorderRadius borderRadiusSmall = BorderRadius.all(radiusSmall);
  static const BorderRadius borderRadiusMedium = BorderRadius.all(radiusMedium);
  static const BorderRadius borderRadiusLarge = BorderRadius.all(radiusLarge);
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(radiusXLarge);
  static const BorderRadius borderRadiusCircle = BorderRadius.all(radiusCircle);
  
  // ========== OMBRES ET EFFETS ==========
  
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacité
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacité
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacité
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: Color(0x4D00D4FF), // cyan à 30% opacité
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];
  
  /// Effet de flou glassmorphisme
  static final ImageFilter glassBlur = ImageFilter.blur(sigmaX: 15, sigmaY: 15);
  
  // ========== BORDURES ==========
  
  static const Border borderThin = Border.fromBorderSide(
    BorderSide(color: glassBorder, width: 1),
  );
  
  static const Border borderMedium = Border.fromBorderSide(
    BorderSide(color: glassBorder, width: 1.5),
  );
  
  static const Border borderThick = Border.fromBorderSide(
    BorderSide(color: glassBorder, width: 2),
  );
  
  // ========== DURÉES D'ANIMATION ==========
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationXSlow = Duration(milliseconds: 800);
  
  // ========== COURBES D'ANIMATION ==========
  
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveEnter = Curves.easeOut;
  static const Curve curveExit = Curves.easeIn;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;
  
  // ========== MÉTHODES UTILITAIRES ==========
  
  /// Obtient une couleur avec opacité
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Obtient une couleur avec canal alpha
  static Color withAlpha(Color color, int alpha) {
    return color.withAlpha(alpha);
  }
  
  /// Crée un dégradé personnalisé
  static LinearGradient createGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }
  
  /// Crée une ombre personnalisée
  static List<BoxShadow> createShadow({
    required Color color,
    double blurRadius = 8,
    Offset offset = const Offset(0, 2),
    double opacity = 0.1,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
  
  // ========== THÈME FLUTTER MATERIAL ==========
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: cyan,
      scaffoldBackgroundColor: navy,
      
      // Configuration des couleurs
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: violet,
        tertiary: successGreen,
        error: errorRed,
        surface: navy,
        onSurface: white,
        onPrimary: white,
        onSecondary: white,
        outline: glassBorder,
      ),
      
      // Configuration typographique
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        headlineLarge: headline2,
        headlineMedium: headline3,
        headlineSmall: bodyLarge,
        titleLarge: bodyLarge,
        titleMedium: bodyMedium,
        titleSmall: bodySmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: buttonLarge,
        labelMedium: buttonMedium,
        labelSmall: caption,
      ),
      
      // Configuration des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
          textStyle: buttonLarge,
        ),
      ),
      
      // Configuration des cartes
      cardTheme: CardThemeData(
        color: glassBackground,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      
      // Configuration des app bars
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: headline3,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

/// Extensions pour faciliter l'utilisation
extension EloquenceThemeExtensions on BuildContext {
  EloquenceTheme get theme => EloquenceTheme();
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

/// Composants pré-stylisés pour cohérence
class EloquenceComponents {
  
  /// Container glassmorphique standard
  static Widget glassContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? color,
    Border? border,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(EloquenceTheme.spacingMd),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? EloquenceTheme.glassBackground,
        borderRadius: borderRadius ?? EloquenceTheme.borderRadiusLarge,
        border: border ?? EloquenceTheme.borderThin,
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: child,
    );
  }
  
  /// Bouton gradient standard
  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isPrimary = true,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? EloquenceTheme.primaryGradient : null,
        color: onPressed == null ? Colors.grey : null,
        borderRadius: EloquenceTheme.borderRadiusMedium,
        boxShadow: onPressed != null ? EloquenceTheme.shadowMedium : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: EloquenceTheme.spacingLg,
            vertical: EloquenceTheme.spacingMd,
          ),
        ),
        icon: icon != null ? Icon(icon, color: EloquenceTheme.white) : const SizedBox.shrink(),
        label: Text(
          text,
          style: EloquenceTheme.buttonLarge,
        ),
      ),
    );
  }
  
  /// Badge coloré standard
  static Widget coloredBadge({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingSm,
        vertical: EloquenceTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: EloquenceTheme.borderRadiusSmall,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: EloquenceTheme.spacingXs),
          ],
          Text(
            text,
            style: EloquenceTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}