import 'dart:async';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../../../core/utils/logger.dart';

/// Interface pour l'analyse prosodique utilisant Kaldi (future implémentation)
/// 
/// Cette interface définit les contrats pour l'analyse prosodique avancée
/// qui sera implémentée avec Kaldi pour l'analyse de débit, intonation, pauses, etc.
abstract class ProsodyAnalysisInterface {
  /// Analyse prosodique complète d'un enregistrement audio
  /// 
  /// [audioData] : Données audio brutes
  /// [scenario] : Contexte du scénario pour adapter l'analyse
  /// [language] : Langue de l'analyse ('fr' par défaut)
  /// 
  /// Retourne un [ProsodyAnalysisResult] ou null si l'analyse échoue
  Future<ProsodyAnalysisResult?> analyzeProsody({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String language = 'fr',
  });
  
  /// Analyse de débit de parole (mots par minute)
  Future<SpeechRateAnalysis?> analyzeSpeechRate(Uint8List audioData);
  
  /// Analyse d'intonation et modulation vocale
  Future<IntonationAnalysis?> analyzeIntonation(Uint8List audioData);
  
  /// Analyse des pauses et rythme
  Future<PauseAnalysis?> analyzePauses(Uint8List audioData);
  
  /// Analyse de l'énergie vocale et volume
  Future<EnergyAnalysis?> analyzeVocalEnergy(Uint8List audioData);
  
  /// Détection d'hésitations et disfluences
  Future<DisfluencyAnalysis?> analyzeDisfluencies(Uint8List audioData);
  
  /// Vérification de la disponibilité du service Kaldi
  Future<bool> isAvailable();
  
  /// Configuration du service (serveur Kaldi, modèles, etc.)
  void configure({
    required String kaldiServerUrl,
    Map<String, String>? modelPaths,
    Duration? timeout,
  });
}

/// Résultat complet de l'analyse prosodique
class ProsodyAnalysisResult {
  final double overallProsodyScore;
  final SpeechRateAnalysis speechRate;
  final IntonationAnalysis intonation;
  final PauseAnalysis pauses;
  final EnergyAnalysis energy;
  final DisfluencyAnalysis disfluency;
  final String detailedFeedback;
  final DateTime analysisTimestamp;
  
  const ProsodyAnalysisResult({
    required this.overallProsodyScore,
    required this.speechRate,
    required this.intonation,
    required this.pauses,
    required this.energy,
    required this.disfluency,
    required this.detailedFeedback,
    required this.analysisTimestamp,
  });
  
  /// Conversion vers ConfidenceAnalysis pour intégration
  ConfidenceAnalysis toConfidenceAnalysis() {
    return ConfidenceAnalysis(
      overallScore: overallProsodyScore,
      confidenceScore: _calculateConfidenceFromProsody(),
      fluencyScore: speechRate.fluencyScore,
      clarityScore: intonation.clarityScore,
      energyScore: energy.normalizedEnergyScore,
      feedback: _generateIntegratedFeedback(),
    );
  }
  
  double _calculateConfidenceFromProsody() {
    // Pondération des différents aspects prosodiques
    return (speechRate.fluencyScore * 0.3 +
            intonation.clarityScore * 0.25 +
            pauses.rhythmScore * 0.25 +
            energy.normalizedEnergyScore * 0.15 +
            (1.0 - disfluency.severityScore) * 0.05);
  }
  
  String _generateIntegratedFeedback() {
    final feedback = <String>[];
    
    feedback.add('🎵 **Analyse Prosodique Complète**\n');
    
    // Feedback débit
    feedback.add('⏱️ **Débit** : ${speechRate.feedback}');
    
    // Feedback intonation
    feedback.add('🎼 **Intonation** : ${intonation.feedback}');
    
    // Feedback pauses
    feedback.add('⏸️ **Rythme** : ${pauses.feedback}');
    
    // Feedback énergie
    feedback.add('🔊 **Énergie** : ${energy.feedback}');
    
    // Feedback disfluences
    if (disfluency.severityScore > 0.3) {
      feedback.add('⚠️ **Hésitations** : ${disfluency.feedback}');
    }
    
    feedback.add('\n$detailedFeedback');
    
    return feedback.join('\n\n');
  }
}

/// Analyse du débit de parole
class SpeechRateAnalysis {
  final double wordsPerMinute;
  final double syllablesPerSecond;
  final double fluencyScore; // 0.0 à 1.0
  final String feedback;
  final SpeechRateCategory category;
  
  const SpeechRateAnalysis({
    required this.wordsPerMinute,
    required this.syllablesPerSecond,
    required this.fluencyScore,
    required this.feedback,
    required this.category,
  });
}

enum SpeechRateCategory {
  tooSlow,     // < 120 mots/min
  optimal,     // 120-180 mots/min
  tooFast,     // > 180 mots/min
}

/// Analyse d'intonation
class IntonationAnalysis {
  final double f0Mean;           // Fréquence fondamentale moyenne
  final double f0Std;            // Écart-type de F0
  final double f0Range;          // Étendue de F0
  final double clarityScore;     // Score de clarté (0.0 à 1.0)
  final String feedback;
  final IntonationPattern pattern;
  
  const IntonationAnalysis({
    required this.f0Mean,
    required this.f0Std,
    required this.f0Range,
    required this.clarityScore,
    required this.feedback,
    required this.pattern,
  });
}

enum IntonationPattern {
  monotone,        // Intonation plate
  natural,         // Intonation naturelle
  exaggerated,     // Intonation exagérée
  irregular,       // Intonation irrégulière
}

/// Analyse des pauses
class PauseAnalysis {
  final int totalPauses;
  final double averagePauseDuration;
  final double pauseRate;           // Pauses par minute
  final double rhythmScore;         // Score de rythme (0.0 à 1.0)
  final String feedback;
  final List<PauseSegment> pauseSegments;
  
  const PauseAnalysis({
    required this.totalPauses,
    required this.averagePauseDuration,
    required this.pauseRate,
    required this.rhythmScore,
    required this.feedback,
    required this.pauseSegments,
  });
}

class PauseSegment {
  final double startTime;
  final double duration;
  final PauseType type;
  
  const PauseSegment({
    required this.startTime,
    required this.duration,
    required this.type,
  });
}

enum PauseType {
  natural,      // Pause naturelle
  hesitation,   // Pause d'hésitation
  breath,       // Pause respiratoire
  long,         // Pause longue
}

/// Analyse de l'énergie vocale
class EnergyAnalysis {
  final double averageEnergy;
  final double energyVariance;
  final double normalizedEnergyScore; // 0.0 à 1.0
  final String feedback;
  final EnergyProfile profile;
  
  const EnergyAnalysis({
    required this.averageEnergy,
    required this.energyVariance,
    required this.normalizedEnergyScore,
    required this.feedback,
    required this.profile,
  });
}

enum EnergyProfile {
  tooLow,       // Énergie insuffisante
  balanced,     // Énergie équilibrée
  tooHigh,      // Énergie excessive
  inconsistent, // Énergie incohérente
}

/// Analyse des disfluences
class DisfluencyAnalysis {
  final int hesitationCount;
  final int fillerWordsCount;    // "euh", "alors", etc.
  final int repetitionCount;
  final double severityScore;    // 0.0 à 1.0 (plus élevé = plus de problèmes)
  final String feedback;
  final List<DisfluencyEvent> events;
  
  const DisfluencyAnalysis({
    required this.hesitationCount,
    required this.fillerWordsCount,
    required this.repetitionCount,
    required this.severityScore,
    required this.feedback,
    required this.events,
  });
}

class DisfluencyEvent {
  final double timestamp;
  final DisfluencyType type;
  final String detectedText;
  
  const DisfluencyEvent({
    required this.timestamp,
    required this.type,
    required this.detectedText,
  });
}

enum DisfluencyType {
  hesitation,    // Hésitation
  fillerWord,    // Mot de remplissage
  repetition,    // Répétition
  restart,       // Reprise
  correction,    // Correction
}

/// Implémentation de fallback pour l'interface prosodique
/// Utilisée quand Kaldi n'est pas encore disponible
class FallbackProsodyAnalysis implements ProsodyAnalysisInterface {
  static const String _tag = 'FallbackProsodyAnalysis';
  static final Logger _logger = Logger();
  
  @override
  Future<ProsodyAnalysisResult?> analyzeProsody({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String language = 'fr',
  }) async {
    _logger.i('$_tag: Analyse prosodique fallback pour ${scenario.title}');
    
    try {
      // Analyse basique basée sur la durée et le contexte
      final duration = _estimateAudioDuration(audioData);
      
      return ProsodyAnalysisResult(
        overallProsodyScore: 75.0,
        speechRate: _createFallbackSpeechRate(duration),
        intonation: _createFallbackIntonation(),
        pauses: _createFallbackPauseAnalysis(duration),
        energy: _createFallbackEnergyAnalysis(),
        disfluency: _createFallbackDisfluencyAnalysis(),
        detailedFeedback: _createFallbackDetailedFeedback(scenario),
        analysisTimestamp: DateTime.now(),
      );
      
    } catch (e) {
      _logger.e('$_tag: Erreur analyse prosodique fallback: $e', error: e);
      return null;
    }
  }
  
  @override
  Future<SpeechRateAnalysis?> analyzeSpeechRate(Uint8List audioData) async {
    final duration = _estimateAudioDuration(audioData);
    return _createFallbackSpeechRate(duration);
  }
  
  @override
  Future<IntonationAnalysis?> analyzeIntonation(Uint8List audioData) async {
    return _createFallbackIntonation();
  }
  
  @override
  Future<PauseAnalysis?> analyzePauses(Uint8List audioData) async {
    final duration = _estimateAudioDuration(audioData);
    return _createFallbackPauseAnalysis(duration);
  }
  
  @override
  Future<EnergyAnalysis?> analyzeVocalEnergy(Uint8List audioData) async {
    return _createFallbackEnergyAnalysis();
  }
  
  @override
  Future<DisfluencyAnalysis?> analyzeDisfluencies(Uint8List audioData) async {
    return _createFallbackDisfluencyAnalysis();
  }
  
  @override
  Future<bool> isAvailable() async {
    _logger.i('$_tag: Service prosodique en mode fallback (Kaldi indisponible)');
    return true; // Fallback toujours disponible
  }
  
  @override
  void configure({
    required String kaldiServerUrl,
    Map<String, String>? modelPaths,
    Duration? timeout,
  }) {
    _logger.i('$_tag: Configuration prosodique en mode fallback');
    // Configuration ignorée en mode fallback
  }
  
  // Méthodes de fallback privées
  
  double _estimateAudioDuration(Uint8List audioData) {
    // Estimation basique : ~44100 samples/sec * 2 bytes/sample
    return audioData.length / (44100 * 2);
  }
  
  SpeechRateAnalysis _createFallbackSpeechRate(double duration) {
    final estimatedWords = (duration * 2.5).round(); // ~150 mots/min estimé
    final wpm = estimatedWords / (duration / 60);
    
    return SpeechRateAnalysis(
      wordsPerMinute: wpm,
      syllablesPerSecond: wpm * 1.5 / 60, // Estimation syllabique
      fluencyScore: _calculateFluidityScore(wpm),
      feedback: _getSpeechRateFeedback(wpm),
      category: _getSpeechRateCategory(wpm),
    );
  }
  
  IntonationAnalysis _createFallbackIntonation() {
    return const IntonationAnalysis(
      f0Mean: 150.0,
      f0Std: 25.0,
      f0Range: 100.0,
      clarityScore: 0.75,
      feedback: 'Intonation estimée normale. Analyse Kaldi requise pour détails.',
      pattern: IntonationPattern.natural,
    );
  }
  
  PauseAnalysis _createFallbackPauseAnalysis(double duration) {
    final estimatedPauses = (duration / 10).round(); // ~1 pause/10s
    
    return PauseAnalysis(
      totalPauses: estimatedPauses,
      averagePauseDuration: 0.8,
      pauseRate: estimatedPauses / (duration / 60),
      rhythmScore: 0.70,
      feedback: 'Rythme estimé correct. Analyse Kaldi requise pour précision.',
      pauseSegments: [],
    );
  }
  
  EnergyAnalysis _createFallbackEnergyAnalysis() {
    return const EnergyAnalysis(
      averageEnergy: 0.65,
      energyVariance: 0.15,
      normalizedEnergyScore: 0.75,
      feedback: 'Énergie vocale estimée équilibrée.',
      profile: EnergyProfile.balanced,
    );
  }
  
  DisfluencyAnalysis _createFallbackDisfluencyAnalysis() {
    return const DisfluencyAnalysis(
      hesitationCount: 2,
      fillerWordsCount: 1,
      repetitionCount: 0,
      severityScore: 0.20,
      feedback: 'Peu d\'hésitations détectées (estimation).',
      events: [],
    );
  }
  
  String _createFallbackDetailedFeedback(ConfidenceScenario scenario) {
    return '''
📊 **Analyse Prosodique Estimée**

Cette analyse utilise des estimations basiques en l'absence du système Kaldi complet.

🎯 **Pour ${scenario.title}** :
• Débit de parole dans la norme estimée
• Intonation probablement naturelle
• Rythme régulier présumé
• Énergie vocale équilibrée

⚡ **Prochaines améliorations** :
L'intégration de Kaldi permettra une analyse prosodique détaillée incluant :
• Analyse spectrale précise
• Détection fine des pauses
• Mesure exacte du débit
• Identification des patterns d'hésitation

💡 **Conseils généraux** :
${scenario.tips.take(2).join('\n• ')}
''';
  }
  
  double _calculateFluidityScore(double wpm) {
    if (wpm >= 120 && wpm <= 180) return 0.9;
    if (wpm >= 100 && wpm <= 200) return 0.75;
    if (wpm >= 80 && wpm <= 220) return 0.6;
    return 0.4;
  }
  
  String _getSpeechRateFeedback(double wpm) {
    if (wpm < 120) return 'Débit un peu lent, essayez d\'accélérer légèrement.';
    if (wpm > 180) return 'Débit rapide, prenez le temps de bien articuler.';
    return 'Débit optimal pour une communication claire.';
  }
  
  SpeechRateCategory _getSpeechRateCategory(double wpm) {
    if (wpm < 120) return SpeechRateCategory.tooSlow;
    if (wpm > 180) return SpeechRateCategory.tooFast;
    return SpeechRateCategory.optimal;
  }
}