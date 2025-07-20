/// Configuration centralisée des timeouts optimisés pour mobile
/// 
/// Basé sur les meilleures pratiques mobiles :
/// - Connexions rapides : 2-3s
/// - Analyses légères : 4-6s  
/// - Analyses complètes : 6-8s
/// - Upload/Download : 8-12s
/// - Health checks : 1-2s
class MobileTimeoutConstants {
  // === TIMEOUTS RÉSEAU CRITIQUES ===
  
  /// Timeout pour établir une connexion réseau (très critique)
  static const Duration connectionTimeout = Duration(seconds: 3);
  
  /// Timeout pour les health checks et ping
  static const Duration healthCheckTimeout = Duration(seconds: 2);
  
  /// Timeout pour les requêtes légères (GET simples)
  static const Duration lightRequestTimeout = Duration(seconds: 4);
  
  /// Timeout pour les requêtes moyennes (POST avec peu de données)
  static const Duration mediumRequestTimeout = Duration(seconds: 6);
  
  /// Timeout pour les requêtes lourdes (POST avec beaucoup de données)
  static const Duration heavyRequestTimeout = Duration(seconds: 8);
  
  /// Timeout pour les uploads de fichiers
  static const Duration fileUploadTimeout = Duration(seconds: 12);
  
  // === TIMEOUTS ANALYSE VOCALE ===
  
  /// Timeout pour l'analyse VOSK (optimisé mobile)
  static const Duration voskAnalysisTimeout = Duration(seconds: 6);
  
  /// Timeout pour l'analyse Mistral (IA conversationnelle)
  static const Duration mistralAnalysisTimeout = Duration(seconds: 8);
  
  /// Timeout pour l'analyse complète (pipeline complet)
  static const Duration fullPipelineTimeout = Duration(seconds: 8);
  
  /// Timeout pour l'analyse de confiance
  static const Duration confidenceAnalysisTimeout = Duration(seconds: 6);
  
  // === TIMEOUTS LIVEKIT ===
  
  /// Timeout pour la connexion LiveKit
  static const Duration livekitConnectionTimeout = Duration(seconds: 3);
  
  /// Timeout pour les opérations LiveKit courtes
  static const Duration livekitOperationTimeout = Duration(seconds: 4);
  
  /// Timeout pour les requêtes d'analyse LiveKit
  static const Duration livekitAnalysisTimeout = Duration(seconds: 6);
  
  // === TIMEOUTS FALLBACK ===
  
  /// Timeout pour les tentatives de retry
  static const Duration retryTimeout = Duration(seconds: 4);
  
  /// Timeout pour les services de fallback
  static const Duration fallbackTimeout = Duration(seconds: 3);
  
  /// Timeout pour les opérations d'urgence
  static const Duration emergencyTimeout = Duration(seconds: 2);
  
  // === TIMEOUTS DIAGNOSTICS ===
  
  /// Timeout pour les tests de connectivité
  static const Duration networkDiagnosticsTimeout = Duration(seconds: 3);
  
  /// Timeout pour les tests de latence
  static const Duration latencyTestTimeout = Duration(seconds: 2);
  
  // === DÉLAIS DE RETRY ===
  
  /// Délai initial entre les tentatives de retry
  static const Duration initialRetryDelay = Duration(milliseconds: 300);
  
  /// Délai maximum entre les tentatives de retry
  static const Duration maxRetryDelay = Duration(seconds: 2);
  
  /// Délai de cooldown après échec d'un service
  static const Duration serviceCooldown = Duration(minutes: 2);
  
  // === UTILITAIRES ===
  
  /// Retourne un timeout adapté selon le type d'opération
  static Duration getTimeoutForOperation(OperationType type) {
    switch (type) {
      case OperationType.healthCheck:
        return healthCheckTimeout;
      case OperationType.lightRequest:
        return lightRequestTimeout;
      case OperationType.mediumRequest:
        return mediumRequestTimeout;
      case OperationType.heavyRequest:
        return heavyRequestTimeout;
      case OperationType.fileUpload:
        return fileUploadTimeout;
      case OperationType.voskAnalysis:
        return voskAnalysisTimeout;
      case OperationType.mistralAnalysis:
        return mistralAnalysisTimeout;
      case OperationType.confidenceAnalysis:
        return confidenceAnalysisTimeout;
      case OperationType.livekitConnection:
        return livekitConnectionTimeout;
      case OperationType.livekitOperation:
        return livekitOperationTimeout;
      case OperationType.networkDiagnostics:
        return networkDiagnosticsTimeout;
    }
  }
  
  /// Calcule un délai de retry avec backoff exponentiel
  static Duration calculateRetryDelay(int attemptNumber) {
    final delay = initialRetryDelay * (attemptNumber * attemptNumber);
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }
  
  /// Retourne un timeout réduit pour mobile avec connectivité faible
  static Duration getMobileOptimizedTimeout(Duration baseTimeout) {
    // Réduction de 25% pour mobile avec connectivité potentiellement faible
    final optimized = Duration(
      milliseconds: (baseTimeout.inMilliseconds * 0.75).round(),
    );
    
    // Minimum de 2 secondes pour éviter les timeouts trop agressifs
    const minimumTimeout = Duration(seconds: 2);
    return optimized < minimumTimeout ? minimumTimeout : optimized;
  }
  
  /// Retourne des statistiques sur les timeouts configurés
  static Map<String, Duration> getTimeoutStats() {
    return {
      'connection': connectionTimeout,
      'healthCheck': healthCheckTimeout,
      'lightRequest': lightRequestTimeout,
      'mediumRequest': mediumRequestTimeout,
      'heavyRequest': heavyRequestTimeout,
      'voskAnalysis': voskAnalysisTimeout,
      'mistralAnalysis': mistralAnalysisTimeout,
      'fullPipeline': fullPipelineTimeout,
      'confidenceAnalysis': confidenceAnalysisTimeout,
      'livekitConnection': livekitConnectionTimeout,
      'networkDiagnostics': networkDiagnosticsTimeout,
    };
  }
}

/// Types d'opérations pour sélection automatique du timeout
enum OperationType {
  healthCheck,
  lightRequest,
  mediumRequest,
  heavyRequest,
  fileUpload,
  voskAnalysis,
  mistralAnalysis,
  confidenceAnalysis,
  livekitConnection,
  livekitOperation,
  networkDiagnostics,
}

/// Configuration adaptative selon les conditions réseau
class AdaptiveTimeoutConfig {
  final bool isSlowNetwork;
  final bool isMobileData;
  final bool isLowBattery;
  
  const AdaptiveTimeoutConfig({
    this.isSlowNetwork = false,
    this.isMobileData = false,
    this.isLowBattery = false,
  });
  
  /// Adapte un timeout selon les conditions actuelles
  Duration adaptTimeout(Duration baseTimeout) {
    var multiplier = 1.0;
    
    // Ajustements selon les conditions
    if (isSlowNetwork) multiplier *= 1.5;
    if (isMobileData) multiplier *= 1.2;
    if (isLowBattery) multiplier *= 0.8; // Plus agressif pour économiser batterie
    
    final adapted = Duration(
      milliseconds: (baseTimeout.inMilliseconds * multiplier).round(),
    );
    
    // Limites de sécurité
    const minTimeout = Duration(seconds: 1);
    const maxTimeout = Duration(seconds: 15);
    
    if (adapted < minTimeout) return minTimeout;
    if (adapted > maxTimeout) return maxTimeout;
    return adapted;
  }
}