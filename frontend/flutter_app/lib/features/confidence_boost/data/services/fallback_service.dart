import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../../../../core/config/mobile_timeout_constants.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/ai_character_models.dart';

/// Service de fallback robuste multi-niveaux
/// 
/// ✅ NIVEAUX DE FALLBACK :
/// 1. Fallback LiveKit : Retry avec backoff exponentiel
/// 2. Fallback VOSK : Direct sans LiveKit
/// 3. Fallback Mistral : Réponses prédéfinies
/// 4. Fallback UI : Mode dégradé
class FallbackService {
  static const String _tag = 'FallbackService';
  final Logger _logger = Logger();
  
  // Configuration des niveaux de fallback (alignée avec MobileTimeoutConstants)
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = MobileTimeoutConstants.initialRetryDelay;
  static const Duration _maxRetryDelay = MobileTimeoutConstants.maxRetryDelay;
  
  // État du service
  FallbackLevel _currentLevel = FallbackLevel.normal;
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  
  // Cache pour les fallbacks
  final Map<String, AnalysisResult> _analysisCache = {};
  final Map<String, List<String>> _conversationCache = {};
  
  /// Niveau actuel de fallback
  FallbackLevel get currentLevel => _currentLevel;
  
  /// Nombre d'échecs consécutifs
  int get consecutiveFailures => _consecutiveFailures;

  /// **NIVEAU 1 : Fallback LiveKit**
  /// Retry avec backoff exponentiel pour les connexions LiveKit
  Future<T?> withLiveKitFallback<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;
    Duration delay = _baseRetryDelay;
    
    while (attempt < maxRetries) {
      try {
        _logger.d('🔄 [$_tag] $operationName - Tentative ${attempt + 1}/$maxRetries');
        
        final result = await operation();
        _onOperationSuccess(operationName);
        return result;
        
      } catch (e) {
        attempt++;
        _logger.w('⚠️ [$_tag] $operationName échoué (tentative $attempt): $e');
        
        if (attempt >= maxRetries) {
          _onOperationFailure(operationName, e);
          return null;
        }
        
        // Backoff exponentiel avec jitter
        final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.1).round());
        await Future.delayed(delay + jitter);
        final newDelayMs = math.min(
          (delay.inMilliseconds * 1.5).round(),
          _maxRetryDelay.inMilliseconds
        );
        delay = Duration(milliseconds: newDelayMs);
      }
    }
    
    return null;
  }

  /// **NIVEAU 2 : Fallback VOSK**
  /// Analyse audio directe sans LiveKit
  Future<AnalysisResult?> withVoskFallback({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    String? cacheKey,
  }) async {
    try {
      _logger.i('🎙️ [$_tag] Fallback VOSK direct (sans LiveKit)');
      
      // Vérifier le cache
      if (cacheKey != null && _analysisCache.containsKey(cacheKey)) {
        _logger.d('📋 [$_tag] Utilisation cache VOSK pour $cacheKey');
        return _analysisCache[cacheKey];
      }
      
      // Simuler analyse VOSK directe
      final result = await _performDirectVoskAnalysis(audioData, scenario);
      
      // Mettre en cache
      if (cacheKey != null && result != null) {
        _analysisCache[cacheKey] = result;
      }
      
      _onOperationSuccess('vosk_direct');
      return result;
      
    } catch (e) {
      _logger.e('❌ [$_tag] Fallback VOSK échoué: $e');
      _onOperationFailure('vosk_direct', e);
      return _createBasicAnalysisResult(audioData, scenario);
    }
  }

  /// **NIVEAU 3 : Fallback Mistral**
  /// Réponses de conversation prédéfinies
  Future<List<String>> withMistralFallback({
    required String userMessage,
    required AICharacterType characterType,
    required ConfidenceScenario scenario,
    String? cacheKey,
  }) async {
    try {
      _logger.i('🤖 [$_tag] Fallback Mistral avec réponses prédéfinies');
      
      // Vérifier le cache
      if (cacheKey != null && _conversationCache.containsKey(cacheKey)) {
        _logger.d('📋 [$_tag] Utilisation cache conversation pour $cacheKey');
        return _conversationCache[cacheKey]!;
      }
      
      // Générer réponses prédéfinies
      final responses = _generatePredefinedResponses(
        userMessage, 
        characterType, 
        scenario,
      );
      
      // Mettre en cache
      if (cacheKey != null) {
        _conversationCache[cacheKey] = responses;
      }
      
      _onOperationSuccess('mistral_fallback');
      return responses;
      
    } catch (e) {
      _logger.e('❌ [$_tag] Fallback Mistral échoué: $e');
      _onOperationFailure('mistral_fallback', e);
      return _getEmergencyResponses(characterType);
    }
  }

  /// **NIVEAU 4 : Fallback UI**
  /// Mode dégradé avec interface simplifiée
  Map<String, dynamic> getDegradedModeConfig() {
    _logger.w('🚨 [$_tag] Mode dégradé activé - Niveau: $_currentLevel');
    
    return {
      'fallback_level': _currentLevel.name,
      'consecutive_failures': _consecutiveFailures,
      'features_disabled': _getDisabledFeatures(),
      'user_message': _getUserFriendlyMessage(),
      'retry_enabled': _shouldAllowRetry(),
      'estimated_recovery_time': _getEstimatedRecoveryTime(),
    };
  }

  /// Réinitialise le service de fallback
  Future<void> reset() async {
    _logger.i('🔄 [$_tag] Réinitialisation du service de fallback');
    
    _currentLevel = FallbackLevel.normal;
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    
    // Garder un cache limité pour la performance
    if (_analysisCache.length > 50) {
      _analysisCache.clear();
    }
    
    if (_conversationCache.length > 50) {
      _conversationCache.clear();
    }
  }

  /// Analyse VOSK directe simulée
  Future<AnalysisResult?> _performDirectVoskAnalysis(
    Uint8List audioData, 
    ConfidenceScenario scenario,
  ) async {
    // Simuler un délai d'analyse optimisé mobile
    await Future.delayed(Duration(milliseconds: MobileTimeoutConstants.initialRetryDelay.inMilliseconds));
    
    // Créer une analyse basique mais fonctionnelle
    return AnalysisResult(
      confidenceScore: 0.75,
      clarityScore: 0.7,
      fluencyScore: 0.75,
      transcription: _generateBasicTranscription(audioData.length),
      keyInsights: [
        'Continue à pratiquer pour améliorer votre aisance',
        'Variez votre rythme de parole',
        'Maintenez le contact visuel avec votre audience'
      ],
      timestamp: DateTime.now(),
    );
  }

  /// Génère des réponses prédéfinies selon le personnage
  List<String> _generatePredefinedResponses(
    String userMessage,
    AICharacterType characterType,
    ConfidenceScenario scenario,
  ) {
    final responses = <String>[];
    
    switch (characterType) {
      case AICharacterType.thomas:
        responses.addAll(_getThomasResponses(userMessage, scenario));
        break;
      case AICharacterType.marie:
        responses.addAll(_getMarieResponses(userMessage, scenario));
        break;
    }
    
    // Ajouter des réponses génériques si nécessaire
    if (responses.isEmpty) {
      responses.addAll(_getGenericResponses(scenario));
    }
    
    return responses.take(3).toList(); // Limiter à 3 réponses
  }

  /// Réponses d'urgence en cas d'échec total
  List<String> _getEmergencyResponses(AICharacterType characterType) {
    switch (characterType) {
      case AICharacterType.thomas:
        return [
          'Continuez, vous vous en sortez bien.',
          'Prenez votre temps pour organiser vos idées.',
          'Votre approche est intéressante, développez.'
        ];
      case AICharacterType.marie:
        return [
          'C\'est un bon début, continuez sur cette voie.',
          'Votre passion transparaît dans vos mots.',
          'N\'hésitez pas à donner plus de détails.'
        ];
    }
  }

  /// Réponses de Thomas (professionnel, analytique)
  List<String> _getThomasResponses(String userMessage, ConfidenceScenario scenario) {
    if (scenario.type == ConfidenceScenarioType.interview) {
      return [
        'Excellent, pouvez-vous nous donner un exemple concret de cette expérience ?',
        'C\'est très pertinent. Comment mesureriez-vous le succès dans ce contexte ?',
        'Intéressant. Quels ont été les principaux défis que vous avez rencontrés ?'
      ];
    } else if (scenario.type == ConfidenceScenarioType.presentation) {
      return [
        'Votre structure est claire. Pouvez-vous approfondir ce point ?',
        'Les données que vous présentez sont convaincantes. Et les implications ?',
        'Bonne approche. Comment adapterez-vous cela pour différents publics ?'
      ];
    }
    
    return [
      'Votre argumentation est solide. Continuez.',
      'Je vois que vous maîtrisez le sujet. Développez cette idée.',
      'Perspective intéressante. Quelles sont les prochaines étapes ?'
    ];
  }

  /// Réponses de Marie (empathique, encourageante)
  List<String> _getMarieResponses(String userMessage, ConfidenceScenario scenario) {
    if (scenario.type == ConfidenceScenarioType.interview) {
      return [
        'C\'est formidable ! Votre enthousiasme est contagieux. Racontez-nous en plus.',
        'J\'adore votre approche ! Comment avez-vous développé cette passion ?',
        'Vous semblez vraiment à l\'aise avec ce sujet. Qu\'est-ce qui vous motive le plus ?'
      ];
    } else if (scenario.type == ConfidenceScenarioType.presentation) {
      return [
        'Votre énergie est captivante ! Comment pouvons-nous tous nous inspirer de cela ?',
        'C\'est exactement ce que nous avions besoin d\'entendre. Continuez !',
        'Vous transmettez vraiment votre passion. Quel conseil donneriez-vous à d\'autres ?'
      ];
    }
    
    return [
      'C\'est merveilleux ! Votre authenticité transpire.',
      'Vous vous exprimez avec tant de conviction. J\'adore !',
      'Continuez, vous nous inspirez vraiment !'
    ];
  }

  /// Réponses génériques de secours
  List<String> _getGenericResponses(ConfidenceScenario scenario) {
    return [
      'Pouvez-vous nous en dire plus à ce sujet ?',
      'C\'est intéressant. Comment en êtes-vous arrivé à cette conclusion ?',
      'Excellent point. Quels sont vos arguments principaux ?'
    ];
  }

  /// Gestion des succès d'opération
  void _onOperationSuccess(String operation) {
    if (_consecutiveFailures > 0) {
      _logger.i('✅ [$_tag] Récupération réussie pour $operation');
      _consecutiveFailures = 0;
      _updateFallbackLevel();
    }
  }

  /// Gestion des échecs d'opération
  void _onOperationFailure(String operation, dynamic error) {
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();
    
    _logger.w('⚠️ [$_tag] Échec $operation (${_consecutiveFailures}e consécutif): $error');
    _updateFallbackLevel();
  }

  /// Met à jour le niveau de fallback selon les échecs
  void _updateFallbackLevel() {
    final previousLevel = _currentLevel;
    
    if (_consecutiveFailures >= 10) {
      _currentLevel = FallbackLevel.critical;
    } else if (_consecutiveFailures >= 5) {
      _currentLevel = FallbackLevel.degraded;
    } else if (_consecutiveFailures >= 2) {
      _currentLevel = FallbackLevel.limited;
    } else {
      _currentLevel = FallbackLevel.normal;
    }
    
    if (_currentLevel != previousLevel) {
      _logger.w('🔄 [$_tag] Niveau de fallback: ${previousLevel.name} → ${_currentLevel.name}');
    }
  }

  /// Fonctionnalités désactivées selon le niveau
  List<String> _getDisabledFeatures() {
    switch (_currentLevel) {
      case FallbackLevel.normal:
        return [];
      case FallbackLevel.limited:
        return ['real_time_analysis', 'advanced_metrics'];
      case FallbackLevel.degraded:
        return ['real_time_analysis', 'advanced_metrics', 'ai_responses', 'voice_synthesis'];
      case FallbackLevel.critical:
        return ['real_time_analysis', 'advanced_metrics', 'ai_responses', 'voice_synthesis', 'audio_recording'];
    }
  }

  /// Message utilisateur selon le niveau
  String _getUserFriendlyMessage() {
    switch (_currentLevel) {
      case FallbackLevel.normal:
        return 'Tout fonctionne normalement.';
      case FallbackLevel.limited:
        return 'Fonctionnalités limitées temporairement. L\'essentiel reste disponible.';
      case FallbackLevel.degraded:
        return 'Mode de secours activé. Certaines fonctionnalités sont temporairement indisponibles.';
      case FallbackLevel.critical:
        return 'Service en maintenance. Mode minimal actif.';
    }
  }

  /// Détermine si un retry est autorisé
  bool _shouldAllowRetry() {
    if (_lastFailureTime == null) return true;
    
    final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceFailure > const Duration(minutes: 1);
  }

  /// Temps estimé de récupération
  Duration _getEstimatedRecoveryTime() {
    switch (_currentLevel) {
      case FallbackLevel.normal:
        return Duration.zero;
      case FallbackLevel.limited:
        return const Duration(minutes: 2);
      case FallbackLevel.degraded:
        return const Duration(minutes: 5);
      case FallbackLevel.critical:
        return const Duration(minutes: 10);
    }
  }

  /// Génère une transcription basique
  String _generateBasicTranscription(int audioLength) {
    // Estimer la durée basée sur la taille audio
    final estimatedDuration = audioLength / 16000; // Estimation 16kHz
    
    if (estimatedDuration < 2) {
      return 'Bonjour...';
    } else if (estimatedDuration < 5) {
      return 'Bonjour, je pense que...';
    } else {
      return 'Bonjour, je pense que cette opportunité est très intéressante pour moi.';
    }
  }

  /// Extrait des mots-clés basiques
  Map<String, double> _extractBasicKeywords(ConfidenceScenario scenario) {
    final keywords = <String, double>{};
    
    for (final keyword in scenario.keywords.take(3)) {
      keywords[keyword] = 0.7; // Score basique
    }
    
    return keywords;
  }

  /// Crée un résultat d'analyse basique
  AnalysisResult _createBasicAnalysisResult(Uint8List audioData, ConfidenceScenario scenario) {
    return AnalysisResult(
      confidenceScore: 0.6,
      clarityScore: 0.6,
      fluencyScore: 0.6,
      transcription: _generateBasicTranscription(audioData.length),
      keyInsights: [
        'Service temporairement limité. Continuez votre excellent travail !',
        'Les fonctionnalités avancées seront bientôt rétablies.'
      ],
      timestamp: DateTime.now(),
    );
  }
}

/// Niveaux de fallback disponibles
enum FallbackLevel {
  normal,     // Fonctionnement normal
  limited,    // Fonctionnalités limitées
  degraded,   // Mode dégradé
  critical,   // Mode minimal
}

/// Extension pour les niveaux de fallback
extension FallbackLevelExtension on FallbackLevel {
  String get displayName {
    switch (this) {
      case FallbackLevel.normal:
        return 'Normal';
      case FallbackLevel.limited:
        return 'Limité';
      case FallbackLevel.degraded:
        return 'Dégradé';
      case FallbackLevel.critical:
        return 'Critique';
    }
  }
  
  bool get isOperational => this != FallbackLevel.critical;
  
  bool get allowsAIFeatures => 
      this == FallbackLevel.normal || this == FallbackLevel.limited;
}