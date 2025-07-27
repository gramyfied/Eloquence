import 'package:logger/logger.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Service de logging unifié pour l'application Eloquence
/// Combine les meilleures fonctionnalités d'AppLogger et LoggerService
class UnifiedLoggerService {
  // Singleton pattern
  static final UnifiedLoggerService _instance = UnifiedLoggerService._internal();
  factory UnifiedLoggerService() => _instance;
  UnifiedLoggerService._internal();

  // Logger principal avec configuration optimisée
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Niveaux de log
  static const int _levelVerbose = 0;
  static const int _levelDebug = 1;
  static const int _levelInfo = 2;
  static const int _levelWarning = 3;
  static const int _levelError = 4;

  // Niveau de log actuel
  int _currentLevel = _levelVerbose;

  // Timestamps pour mesurer la latence
  final Map<String, DateTime> _timestamps = {};

  // Formatteur de date
  final DateFormat _dateFormat = DateFormat('HH:mm:ss.SSS');

  /// Définit le niveau de log
  void setLogLevel(int level) {
    _currentLevel = level;
  }

  /// Log debug (informations de débogage)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
    _logToConsole('DEBUG', message);
  }

  /// Log info (informations générales)
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    _logToConsole('INFO', message);
  }

  /// Log warning (avertissements)
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _logToConsole('WARNING', message);
  }

  /// Log error (erreurs)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _logToConsole('ERROR', message);
    if (error != null) {
      _logToConsole('ERROR', 'Exception: $error');
    }
    if (stackTrace != null) {
      _logToConsole('ERROR', 'StackTrace: $stackTrace');
    }
  }

  /// Log fatal (erreurs critiques)
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    _logToConsole('FATAL', message);
  }

  /// Log de performance (mesure du temps entre deux points)
  void performance(String tag, String operation, {bool start = false, bool end = false}) {
    if (_currentLevel <= _levelDebug) {
      if (start) {
        _timestamps['$tag-$operation'] = DateTime.now();
        _logToConsole('PERF', '⏱️ Début: $operation');
      } else if (end && _timestamps.containsKey('$tag-$operation')) {
        final startTime = _timestamps['$tag-$operation']!;
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        _logToConsole('PERF', '⏱️ Fin: $operation - Durée: $duration ms');
        _timestamps.remove('$tag-$operation');
      }
    }
  }

  /// Log de latence réseau
  void networkLatency(String tag, String operation, int latencyMs) {
    if (_currentLevel <= _levelDebug) {
      String indicator;
      if (latencyMs < 100) {
        indicator = '🟢'; // Bonne latence
      } else if (latencyMs < 300) {
        indicator = '🟡'; // Latence moyenne
      } else {
        indicator = '🔴'; // Latence élevée
      }
      _logToConsole('NETWORK', '$indicator $operation - Latence: $latencyMs ms');
    }
  }

  /// Log WebSocket
  void webSocket(String tag, String event, {String? data, bool isIncoming = true}) {
    if (_currentLevel <= _levelDebug) {
      final direction = isIncoming ? '⬇️ REÇU' : '⬆️ ENVOYÉ';
      _logToConsole('WEBSOCKET', '$direction $event${data != null ? ' - $data' : ''}');
    }
  }

  /// Méthode interne pour formater et afficher les logs
  static void _logToConsole(String level, String message) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] [$level] $message';
    
    // Afficher dans la console de débogage
    debugPrint(logMessage);
    
    // Afficher dans la console du développeur (visible dans DevTools)
    developer.log(message, name: level, time: DateTime.now());
  }
}

// Instance globale pour un accès facile
final unifiedLogger = UnifiedLoggerService();
