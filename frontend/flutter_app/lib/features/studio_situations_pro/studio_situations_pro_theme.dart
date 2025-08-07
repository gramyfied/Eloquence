import 'package:flutter/material.dart';
import 'package:eloquence_2_0/core/theme/eloquence_unified_theme.dart';

// Définition des éléments de thème spécifiques à Studio Situations Pro,
// basés sur le Design System Eloquence Unifié.

/// PALETTE DE COULEURS ELOQUENCE STRICTE pour Studio Situations Pro
class StudioSituationsProColors {
  // Couleurs principales Eloquence
  static const Color navy = EloquenceTheme.navy;
  static const Color cyan = EloquenceTheme.cyan;
  static const Color violet = EloquenceTheme.violet;
  static const Color white = EloquenceTheme.white;
  
  // Transparences glassmorphisme Eloquence
  static const Color glassBackground = EloquenceTheme.glassBackground;
  static const Color glassBorder = EloquenceTheme.glassBorder;
  static const Color glassWhite = EloquenceTheme.glassWhite;
  static const Color glassAccent = EloquenceTheme.glassAccent;
  
  // Couleurs sémantiques Eloquence (autorisées)
  static const Color successGreen = EloquenceTheme.successGreen;
  static const Color warningOrange = EloquenceTheme.warningOrange;
  static const Color errorRed = EloquenceTheme.errorRed;
  static const Color celebrationGold = EloquenceTheme.celebrationGold;
  
  // Couleurs spécifiques aux simulations (basées sur palette Eloquence)
  static const Color tvStudio = EloquenceTheme.cyan;          // Débat TV - Cyan principal
  static const Color boardroom = EloquenceTheme.navy;         // Réunion - Navy principal
  static const Color salesRoom = EloquenceTheme.successGreen; // Vente - Vert succès
  static const Color interviewRoom = EloquenceTheme.violet;   // Entretien - Violet principal
  static const Color conference = EloquenceTheme.warningOrange; // Conférence - Orange attention
}

/// DÉGRADÉS ELOQUENCE pour Studio Situations Pro
class StudioSituationsProGradients {
  // Dégradé principal Eloquence
  static const LinearGradient primary = EloquenceTheme.primaryGradient;
  
  // Dégradé de fond Eloquence
  static const LinearGradient background = EloquenceTheme.backgroundGradient;
  
  // Dégradé halo Eloquence
  static const RadialGradient halo = EloquenceTheme.haloGradient;
  
  // Dégradés spécialisés par simulation
  static const LinearGradient tvStudio = LinearGradient(
    colors: [EloquenceTheme.cyan, EloquenceTheme.cyanDark], // Cyan vers cyan foncé
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient interview = LinearGradient(
    colors: [EloquenceTheme.violet, EloquenceTheme.violetDark], // Violet vers violet foncé
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// TYPOGRAPHIE ELOQUENCE pour Studio Situations Pro
class StudioSituationsProTypography {
  static const String primaryFont = EloquenceTheme.primaryFontFamily;
  static const String displayFont = EloquenceTheme.displayFontFamily;
  static const String monoFont = EloquenceTheme.monoFontFamily;
  
  // Styles Eloquence existants
  static const TextStyle displayLarge = EloquenceTheme.headline1;
  static const TextStyle headlineLarge = EloquenceTheme.headline2;
  static const TextStyle headlineMedium = EloquenceTheme.headline3;
  static const TextStyle bodyLarge = EloquenceTheme.bodyLarge;
  static const TextStyle bodyMedium = EloquenceTheme.bodyMedium;
  static const TextStyle bodySmall = EloquenceTheme.bodySmall;
  static const TextStyle buttonLarge = EloquenceTheme.buttonLarge;
  static const TextStyle caption = EloquenceTheme.caption;
  
  // Styles spécialisés métriques
  static TextStyle metricsDisplay = EloquenceTheme.timerDisplay.copyWith(
    fontSize: 24, // Ajusté pour correspondre au prompt, EloquenceTheme.timerDisplay est à 36
    letterSpacing: 1.0, // Ajusté pour correspondre au prompt
  );
}

/// Espacements Eloquence
class EloquenceSpacing {
  static const double xs = EloquenceTheme.spacingXs;
  static const double sm = EloquenceTheme.spacingSm;
  static const double md = EloquenceTheme.spacingMd;
  static const double lg = EloquenceTheme.spacingLg;
  static const double xl = EloquenceTheme.spacingXl;
  static const double xxl = EloquenceTheme.spacingXxl;
  static const double xxxl = EloquenceTheme.spacingXxxl;
}

/// Rayons de bordure Eloquence
class EloquenceRadii {
  static const BorderRadius button = EloquenceTheme.borderRadiusMedium;
  static const BorderRadius card = EloquenceTheme.borderRadiusLarge;
  static const BorderRadius circle = EloquenceTheme.borderRadiusCircle;
  static const BorderRadius small = EloquenceTheme.borderRadiusSmall;
  static const BorderRadius medium = EloquenceTheme.borderRadiusMedium;
  static const BorderRadius large = EloquenceTheme.borderRadiusLarge;
  static const BorderRadius xLarge = EloquenceTheme.borderRadiusXLarge;
}

/// Bordures Eloquence
class EloquenceBorders {
  static const Border card = EloquenceTheme.borderThin;
  static const Border thin = EloquenceTheme.borderThin;
  static const Border medium = EloquenceTheme.borderMedium;
  static const Border thick = EloquenceTheme.borderThick;
}

/// Ombres Eloquence
class EloquenceShadows {
  static const List<BoxShadow> card = EloquenceTheme.shadowMedium;
  static const List<BoxShadow> small = EloquenceTheme.shadowSmall;
  static const List<BoxShadow> medium = EloquenceTheme.shadowMedium;
  static const List<BoxShadow> large = EloquenceTheme.shadowLarge;
  static const List<BoxShadow> glow = EloquenceTheme.shadowGlow;
}

/// Durées d'animation Eloquence et Courbes
// Courbes d'animation
class EloquenceCurves {
  static const Curve standard = EloquenceTheme.curveStandard;
  static const Curve enter = EloquenceTheme.curveEnter;
  static const Curve exit = EloquenceTheme.curveExit;
  static const Curve emphasized = EloquenceTheme.curveEmphasized;
  static const Curve elastic = EloquenceTheme.curveElastic;
  static const Curve bounce = EloquenceTheme.curveBounce;
}

// Durées d'animation
class EloquenceDurations {
  static const Duration fast = EloquenceTheme.animationFast;
  static const Duration medium = EloquenceTheme.animationMedium;
  static const Duration slow = EloquenceTheme.animationSlow;
  static const Duration xSlow = EloquenceTheme.animationXSlow;
}