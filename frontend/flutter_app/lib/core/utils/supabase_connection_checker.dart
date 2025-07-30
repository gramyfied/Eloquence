import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../config/supabase_config.dart';

/// Utilitaire pour vérifier la connexion à Supabase
class SupabaseConnectionChecker {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Vérifie la connexion à Supabase et affiche le résultat
  static Future<bool> checkConnection() async {
    _logger.i('Vérification de la connexion à Supabase...');
    
    try {
      final isConnected = await SupabaseConfig.testConnection();
      
      if (isConnected) {
        _logger.i('✅ Connexion à Supabase établie avec succès');
        _logger.d('URL: ${SupabaseConfig.supabaseUrl}');
      } else {
        _logger.e('❌ Échec de la connexion à Supabase');
      }
      
      return isConnected;
    } catch (e) {
      _logger.e('❌ Erreur lors de la vérification de la connexion à Supabase: $e');
      
      return false;
    }
  }
  
  /// Affiche les informations de connexion à Supabase
  static void printConnectionInfo() {
    if (kDebugMode) {
      _logger.i('====================================');
      _logger.i('INFORMATIONS DE CONNEXION SUPABASE');
      _logger.i('====================================');
      _logger.i('URL: ${SupabaseConfig.supabaseUrl}');
      _logger.i('Projet: zjhzwzgslkrociuootph');
      _logger.i('Région: eu-west-3 (Paris)');
      _logger.i('====================================');
    }
  }
}
