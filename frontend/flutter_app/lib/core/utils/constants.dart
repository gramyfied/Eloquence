/// Constantes globales pour l'application Eloquence
class AppConstants {
  // URLs des services backend
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String defaultVoskUrl = 'http://localhost:2700';
  static const String defaultMistralUrl = 'http://localhost:8001';
  static const String defaultLivekitUrl = 'ws://localhost:7880';
  static const String defaultEloquenceConversationUrl = 'http://localhost:8003';
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 45);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration shortTimeout = Duration(seconds: 10);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Constantes pour le système de cache
class CacheConstants {
  // Durées d'expiration
  static const Duration memoryExpiration = Duration(minutes: 30);
  static const Duration diskExpiration = Duration(hours: 24);
  
  // Tailles de cache
  static const int maxMemoryCacheSize = 100;
  static const int maxDiskCacheSize = 500;
  
  // Préfixes et clés
  static const String cachePrefix = 'mistral_cache_';
  static const String userPrefsPrefix = 'user_prefs_';
  
  // Configuration cache
  static const bool enableDiskCache = true;
  static const bool enableMemoryCache = true;
}

/// Constantes pour l'interface utilisateur
class UIConstants {
  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Espacements
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  
  // Rayons de bordure
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
}

/// Constantes pour l'analyse vocale
class SpeechConstants {
  // Paramètres d'enregistrement
  static const int sampleRate = 16000;
  static const int channels = 1;
  static const int bitDepth = 16;
  
  // Durées
  static const Duration minRecordingDuration = Duration(seconds: 1);
  static const Duration maxRecordingDuration = Duration(minutes: 5);
  static const Duration silenceThreshold = Duration(milliseconds: 500);
  
  // Seuils d'analyse
  static const double confidenceThreshold = 0.7;
  static const double volumeThreshold = 0.1;
}

/// Constantes pour la gamification
class GamificationConstants {
  // Points et scores
  static const int basePoints = 10;
  static const int bonusPoints = 25;
  static const int perfectScorePoints = 100;
  
  // Niveaux
  static const int pointsPerLevel = 500;
  static const int maxLevel = 50;
  
  // Badges
  static const List<String> availableBadges = [
    'first_conversation',
    'confident_speaker',
    'pronunciation_master',
    'fluency_expert',
    'vocabulary_champion',
  ];
}

/// Constantes pour les exercices de confiance
class ConfidenceBoostConstants {
  // Durées d'exercice
  static const Duration minExerciseDuration = Duration(minutes: 2);
  static const Duration maxExerciseDuration = Duration(minutes: 15);
  static const Duration defaultExerciseDuration = Duration(minutes: 5);
  
  // Niveaux de difficulté
  static const List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'expert',
  ];
  
  // Types de scénarios
  static const List<String> scenarioTypes = [
    'job_interview',
    'presentation',
    'casual_conversation',
    'phone_call',
    'meeting',
  ];
}

/// Constantes pour la connectivité réseau
class NetworkConstants {
  // Timeouts spécifiques
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration sendTimeout = Duration(seconds: 20);
  
  // Retry configuration
  static const int maxNetworkRetries = 3;
  static const Duration networkRetryDelay = Duration(seconds: 1);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// Constantes pour les logs
class LogConstants {
  static const String appTag = 'Eloquence';
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
  static const int maxLogEntries = 1000;
}
