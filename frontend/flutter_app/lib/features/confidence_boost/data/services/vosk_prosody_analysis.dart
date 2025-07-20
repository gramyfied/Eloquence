import 'dart:async';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'prosody_analysis_interface.dart';
import 'vosk_analysis_service.dart';

/// Implémentation de l'analyse prosodique utilisant VOSK
class VoskProsodyAnalysis implements ProsodyAnalysisInterface {
  static const String _tag = 'VoskProsodyAnalysis';
  static final Logger _logger = Logger();
  
  final VoskAnalysisService _voskService;
  
  VoskProsodyAnalysis({required VoskAnalysisService voskService})
    : _voskService = voskService;
  
  @override
  Future<ProsodyAnalysisResult?> analyzeProsody({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String language = 'fr',
  }) async {
    _logger.i('$_tag: Analyse prosodique VOSK pour ${scenario.title}');
    
    try {
      // Analyser avec VOSK - la méthode prend seulement audioData
      final voskResult = await _voskService.analyzeSpeech(audioData);
      
      if (voskResult == null) {
        _logger.w('$_tag: Analyse VOSK a retourné null');
        return _createFallbackAnalysis(audioData, scenario);
      }
      
      // Convertir les résultats VOSK en analyse prosodique complète
      return ProsodyAnalysisResult(
        overallProsodyScore: voskResult.overallScore,
        speechRate: _createSpeechRateFromVosk(voskResult),
        intonation: _createIntonationFromVosk(voskResult),
        pauses: _createPauseAnalysisFromVosk(voskResult),
        energy: _createEnergyAnalysisFromVosk(voskResult),
        disfluency: _createDisfluencyAnalysisFromVosk(voskResult),
        detailedFeedback: _createDetailedFeedback(voskResult, scenario),
        analysisTimestamp: DateTime.now(),
      );
      
    } catch (e) {
      _logger.e('$_tag: Erreur analyse prosodique VOSK: $e', error: e);
      return _createFallbackAnalysis(audioData, scenario);
    }
  }
  
  @override
  Future<SpeechRateAnalysis?> analyzeSpeechRate(Uint8List audioData) async {
    try {
      final voskResult = await _voskService.analyzeSpeech(audioData);
      return _createSpeechRateFromVosk(voskResult);
    } catch (e) {
      _logger.w('$_tag: Erreur analyse débit: $e');
      return null;
    }
  }
  
  @override
  Future<IntonationAnalysis?> analyzeIntonation(Uint8List audioData) async {
    try {
      final voskResult = await _voskService.analyzeSpeech(audioData);
      return _createIntonationFromVosk(voskResult);
    } catch (e) {
      _logger.w('$_tag: Erreur analyse intonation: $e');
      return null;
    }
  }
  
  @override
  Future<PauseAnalysis?> analyzePauses(Uint8List audioData) async {
    try {
      final voskResult = await _voskService.analyzeSpeech(audioData);
      return _createPauseAnalysisFromVosk(voskResult);
    } catch (e) {
      _logger.w('$_tag: Erreur analyse pauses: $e');
      return null;
    }
  }
  
  @override
  Future<EnergyAnalysis?> analyzeVocalEnergy(Uint8List audioData) async {
    try {
      final voskResult = await _voskService.analyzeSpeech(audioData);
      return _createEnergyAnalysisFromVosk(voskResult);
    } catch (e) {
      _logger.w('$_tag: Erreur analyse énergie: $e');
      return null;
    }
  }
  
  @override
  Future<DisfluencyAnalysis?> analyzeDisfluencies(Uint8List audioData) async {
    try {
      final voskResult = await _voskService.analyzeSpeech(audioData);
      return _createDisfluencyAnalysisFromVosk(voskResult);
    } catch (e) {
      _logger.w('$_tag: Erreur analyse disfluences: $e');
      return null;
    }
  }
  
  @override
  Future<bool> isAvailable() async {
    return await _voskService.checkHealth();
  }
  
  @override
  void configure({
    Map<String, String>? modelPaths,
    Duration? timeout,
  }) {
    _logger.i('$_tag: Configuration VOSK prosody analysis');
    if (timeout != null) {
      // Le timeout est déjà géré dans VoskAnalysisService
      _logger.i('$_tag: Timeout configuré à ${timeout.inSeconds}s');
    }
  }
  
  // Méthodes privées pour convertir les résultats VOSK
  
  SpeechRateAnalysis _createSpeechRateFromVosk(VoskAnalysisResult vosk) {
    final wpm = vosk.speakingRate;
    
    return SpeechRateAnalysis(
      wordsPerMinute: wpm,
      syllablesPerSecond: wpm * 1.5 / 60, // Estimation syllabique
      fluencyScore: vosk.fluency,
      feedback: _getSpeechRateFeedback(wpm),
      category: _getSpeechRateCategory(wpm),
    );
  }
  
  IntonationAnalysis _createIntonationFromVosk(VoskAnalysisResult vosk) {
    // Utiliser les données prosodiques de VOSK
    final pitchVariance = vosk.pitchVariation;
    // Estimer le range à partir de la variance (approximation)
    final pitchRange = pitchVariance * 4; // Range typique = 4x écart-type
    
    return IntonationAnalysis(
      f0Mean: vosk.pitchMean,
      f0Std: pitchVariance,
      f0Range: pitchRange,
      clarityScore: vosk.clarity,
      feedback: _getIntonationFeedback(pitchRange, vosk.clarity),
      pattern: _getIntonationPattern(pitchRange, pitchVariance),
    );
  }
  
  PauseAnalysis _createPauseAnalysisFromVosk(VoskAnalysisResult vosk) {
    // Estimer la durée totale à partir du nombre de mots et du débit
    final wordCount = vosk.transcription.split(' ').length;
    final duration = wordCount > 0 ? (wordCount / vosk.speakingRate) * 60 : 30.0;
    
    // Utiliser pauseDuration pour estimer le nombre et la durée des pauses
    final totalPauseDuration = vosk.pauseDuration;
    final estimatedPauseCount = (totalPauseDuration / 0.5).round().clamp(1, 20); // ~0.5s par pause
    final avgPauseDuration = estimatedPauseCount > 0 ? totalPauseDuration / estimatedPauseCount : 0.5;
    final pauseRate = estimatedPauseCount / (duration / 60);
    
    // Calculer le score de rythme basé sur les pauses
    final rhythmScore = _calculateRhythmScore(estimatedPauseCount, avgPauseDuration, duration);
    
    return PauseAnalysis(
      totalPauses: estimatedPauseCount,
      averagePauseDuration: avgPauseDuration,
      pauseRate: pauseRate,
      rhythmScore: rhythmScore,
      feedback: _getPauseFeedback(estimatedPauseCount, avgPauseDuration),
      pauseSegments: [], // VOSK ne fournit pas encore le détail des pauses
    );
  }
  
  EnergyAnalysis _createEnergyAnalysisFromVosk(VoskAnalysisResult vosk) {
    final energyMean = vosk.energyMean;
    final energyVariance = vosk.energyVariation; // Utiliser energyVariation
    
    // Normaliser le score d'énergie
    final normalizedScore = _normalizeEnergyScore(energyMean, energyVariance);
    
    return EnergyAnalysis(
      averageEnergy: energyMean,
      energyVariance: energyVariance,
      normalizedEnergyScore: normalizedScore,
      feedback: _getEnergyFeedback(normalizedScore),
      profile: _getEnergyProfile(energyMean, energyVariance),
    );
  }
  
  DisfluencyAnalysis _createDisfluencyAnalysisFromVosk(VoskAnalysisResult vosk) {
    // VOSK détecte les hésitations dans le transcrit
    final hesitations = _countHesitations(vosk.transcription);
    final fillerWords = _countFillerWords(vosk.transcription);
    final repetitions = _countRepetitions(vosk.transcription);
    
    final totalDisfluencies = hesitations + fillerWords + repetitions;
    // Estimer la durée
    final wordCount = vosk.transcription.split(' ').length;
    final estimatedDuration = wordCount > 0 ? (wordCount / vosk.speakingRate) * 60 : 30.0;
    final severityScore = _calculateDisfluencySeverity(totalDisfluencies, estimatedDuration);
    
    return DisfluencyAnalysis(
      hesitationCount: hesitations,
      fillerWordsCount: fillerWords,
      repetitionCount: repetitions,
      severityScore: severityScore,
      feedback: _getDisfluencyFeedback(severityScore),
      events: [], // Détails des événements non disponibles actuellement
    );
  }
  
  String _createDetailedFeedback(VoskAnalysisResult vosk, ConfidenceScenario scenario) {
    final feedback = StringBuffer();
    
    feedback.writeln('🎯 **Analyse VOSK Complète**\n');
    feedback.writeln('📊 **Score Global**: ${vosk.overallScore.toStringAsFixed(1)}/100');
    
    // Points forts
    feedback.writeln('\n✅ **Points Forts**:');
    if (vosk.confidence > 0.8) {
      feedback.writeln('• Excellente confiance dans votre discours');
    }
    if (vosk.fluency > 0.8) {
      feedback.writeln('• Très bonne fluidité d\'élocution');
    }
    if (vosk.clarity > 0.8) {
      feedback.writeln('• Clarté de prononciation remarquable');
    }
    if (vosk.speakingRate >= 120 && vosk.speakingRate <= 180) {
      feedback.writeln('• Débit de parole optimal');
    }
    
    // Points d'amélioration
    feedback.writeln('\n📈 **Points d\'Amélioration**:');
    if (vosk.confidence < 0.6) {
      feedback.writeln('• Travaillez votre assurance vocale');
    }
    if (vosk.fluency < 0.6) {
      feedback.writeln('• Réduisez les hésitations pour plus de fluidité');
    }
    if (vosk.clarity < 0.6) {
      feedback.writeln('• Articulez davantage pour améliorer la clarté');
    }
    if (vosk.speakingRate < 120) {
      feedback.writeln('• Accélérez légèrement votre débit');
    } else if (vosk.speakingRate > 180) {
      feedback.writeln('• Ralentissez pour mieux vous faire comprendre');
    }
    
    // Conseils spécifiques au scénario
    feedback.writeln('\n💡 **Conseils pour "${scenario.title}"**:');
    if (scenario.tips.isNotEmpty) {
      scenario.tips.take(2).forEach((tip) {
        feedback.writeln('• $tip');
      });
    }
    
    return feedback.toString();
  }
  
  // Méthodes utilitaires
  
  String _getSpeechRateFeedback(double wpm) {
    if (wpm < 100) return 'Débit très lent, essayez d\'accélérer progressivement';
    if (wpm < 120) return 'Débit un peu lent, visez 140-160 mots/minute';
    if (wpm > 200) return 'Débit très rapide, prenez le temps de respirer';
    if (wpm > 180) return 'Débit rapide, ralentissez légèrement pour plus de clarté';
    return 'Débit optimal pour une communication efficace';
  }
  
  SpeechRateCategory _getSpeechRateCategory(double wpm) {
    if (wpm < 120) return SpeechRateCategory.tooSlow;
    if (wpm > 180) return SpeechRateCategory.tooFast;
    return SpeechRateCategory.optimal;
  }
  
  String _getIntonationFeedback(double range, double clarity) {
    if (range < 50) return 'Intonation monotone, variez votre ton';
    if (range > 200) return 'Intonation très variable, modérez les variations';
    if (clarity < 0.6) return 'Travaillez la clarté de votre intonation';
    return 'Bonne intonation naturelle et engageante';
  }
  
  IntonationPattern _getIntonationPattern(double range, double variance) {
    if (range < 50) return IntonationPattern.monotone;
    if (range > 200) return IntonationPattern.exaggerated;
    if (variance > 100) return IntonationPattern.irregular;
    return IntonationPattern.natural;
  }
  
  double _calculateRhythmScore(int pauses, double avgDuration, double totalDuration) {
    // Score basé sur le nombre et la durée des pauses
    final pauseRatio = (pauses * avgDuration) / totalDuration;
    if (pauseRatio < 0.1) return 0.6; // Trop peu de pauses
    if (pauseRatio > 0.3) return 0.6; // Trop de pauses
    return 0.9 - (pauseRatio - 0.2).abs() * 2;
  }
  
  String _getPauseFeedback(int count, double avgDuration) {
    if (count < 2) return 'Ajoutez des pauses pour structurer votre discours';
    if (count > 10) return 'Trop de pauses nuisent à la fluidité';
    if (avgDuration > 2) return 'Pauses trop longues, maintenez le rythme';
    return 'Bon usage des pauses pour structurer le discours';
  }
  
  double _normalizeEnergyScore(double mean, double variance) {
    // Normaliser l'énergie sur une échelle 0-1
    if (mean < 0.3) return mean * 2; // Énergie faible
    if (mean > 0.8) return 0.8 + (1 - mean) * 0.2; // Énergie élevée
    return 0.6 + (mean - 0.3) * 0.8; // Énergie normale
  }
  
  String _getEnergyFeedback(double score) {
    if (score < 0.4) return 'Projetez davantage votre voix';
    if (score > 0.9) return 'Modérez votre énergie vocale';
    return 'Bonne énergie vocale, continuez ainsi';
  }
  
  EnergyProfile _getEnergyProfile(double mean, double variance) {
    if (mean < 0.3) return EnergyProfile.tooLow;
    if (mean > 0.8) return EnergyProfile.tooHigh;
    if (variance > 0.3) return EnergyProfile.inconsistent;
    return EnergyProfile.balanced;
  }
  
  int _countHesitations(String text) {
    final hesitationPattern = RegExp(r'(euh|heu|hmm|eh bien)', caseSensitive: false);
    return hesitationPattern.allMatches(text).length;
  }
  
  int _countFillerWords(String text) {
    final fillerPattern = RegExp(r'(alors|donc|voilà|en fait|du coup)', caseSensitive: false);
    return fillerPattern.allMatches(text).length;
  }
  
  int _countRepetitions(String text) {
    // Détection simple des répétitions de mots
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    int repetitions = 0;
    for (int i = 1; i < words.length; i++) {
      if (words[i] == words[i-1] && words[i].length > 2) {
        repetitions++;
      }
    }
    return repetitions;
  }
  
  double _calculateDisfluencySeverity(int total, double duration) {
    final disfluencyRate = total / (duration / 60); // Par minute
    if (disfluencyRate < 2) return 0.1;
    if (disfluencyRate < 5) return 0.3;
    if (disfluencyRate < 10) return 0.6;
    return 0.9;
  }
  
  String _getDisfluencyFeedback(double severity) {
    if (severity < 0.3) return 'Peu d\'hésitations, excellent !';
    if (severity < 0.6) return 'Quelques hésitations naturelles';
    return 'Travaillez à réduire les hésitations';
  }
  
  // Fallback si VOSK échoue
  ProsodyAnalysisResult? _createFallbackAnalysis(Uint8List audioData, ConfidenceScenario scenario) {
    _logger.w('$_tag: Utilisation du fallback pour l\'analyse prosodique');
    
    final duration = audioData.length / (44100 * 2); // Estimation basique
    
    return ProsodyAnalysisResult(
      overallProsodyScore: 70.0,
      speechRate: SpeechRateAnalysis(
        wordsPerMinute: 150,
        syllablesPerSecond: 3.75,
        fluencyScore: 0.7,
        feedback: 'Analyse de secours - débit estimé',
        category: SpeechRateCategory.optimal,
      ),
      intonation: const IntonationAnalysis(
        f0Mean: 150,
        f0Std: 25,
        f0Range: 100,
        clarityScore: 0.7,
        feedback: 'Analyse de secours - intonation estimée',
        pattern: IntonationPattern.natural,
      ),
      pauses: PauseAnalysis(
        totalPauses: (duration / 10).round(),
        averagePauseDuration: 0.8,
        pauseRate: 6,
        rhythmScore: 0.7,
        feedback: 'Analyse de secours - pauses estimées',
        pauseSegments: [],
      ),
      energy: const EnergyAnalysis(
        averageEnergy: 0.65,
        energyVariance: 0.15,
        normalizedEnergyScore: 0.7,
        feedback: 'Analyse de secours - énergie estimée',
        profile: EnergyProfile.balanced,
      ),
      disfluency: const DisfluencyAnalysis(
        hesitationCount: 2,
        fillerWordsCount: 1,
        repetitionCount: 0,
        severityScore: 0.2,
        feedback: 'Analyse de secours - hésitations estimées',
        events: [],
      ),
      detailedFeedback: 'Analyse VOSK temporairement indisponible. Résultats estimés fournis.',
      analysisTimestamp: DateTime.now(),
    );
  }
}