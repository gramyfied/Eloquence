import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/unified_logger_service.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zjhzwzgslkrociuootph.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqaHp3emdzbGtyb2NpdW9vdHBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0MzU5NTIsImV4cCI6MjA2MTAxMTk1Mn0.7_yHEtb8keFsYpiR1Z9pZvH4x_8IqLMpguy0gfg38O8';
  
  static Future<void> initialize() async {
    try {
      UnifiedLoggerService.info('Initialisation de Supabase...');
      UnifiedLoggerService.debug('URL: $supabaseUrl');
      
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode, // Active les logs de debug en mode développement
      );
      
      UnifiedLoggerService.info('Supabase initialisé avec succès');
      
      // Vérifier la connexion
      try {
        await client.from('exercises').select('id').limit(1);
        UnifiedLoggerService.info('Connexion à Supabase établie avec succès');
      } catch (e) {
        UnifiedLoggerService.error('Erreur de connexion à Supabase: $e');
      }
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors de l\'initialisation de Supabase: $e');
      rethrow;
    }
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Méthode pour tester la connexion à Supabase
  static Future<bool> testConnection() async {
    try {
      await client.from('exercises').select('id').limit(1);
      return true;
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors du test de connexion à Supabase: $e');
      return false;
    }
  }
}
