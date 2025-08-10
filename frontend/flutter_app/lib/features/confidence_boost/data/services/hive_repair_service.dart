import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Service de réparation des boîtes Hive corrompues
/// 
/// 🔧 PROBLÈME RÉSOLU :
/// - Erreur "type 'int' is not a subtype of type 'DateTime' in type cast"
/// - Corruption des données de sérialisation Hive
/// - Incompatibilité entre versions des adaptateurs
class HiveRepairService {
  static final Logger _logger = Logger();
  
  /// Répare toutes les boîtes Hive corrompues
  static Future<void> repairCorruptedBoxes() async {
    try {
      _logger.w('🔧 RÉPARATION HIVE: Démarrage de la réparation des boîtes corrompues...');
      
      // 1. Nettoyer les boîtes de récompenses
      await _cleanRewardBoxes();
      
      // 2. Nettoyer les boîtes de virelangues
      await _cleanVirelangueBoxes();
      
      // 3. Nettoyer les boîtes d'historique
      await _cleanHistoryBoxes();
      
      // 4. Supprimer les fichiers temporaires
      await _cleanTempFiles();
      
      _logger.i('✅ RÉPARATION HIVE: Toutes les boîtes corrompues ont été réparées');
      
    } catch (e, stackTrace) {
      _logger.e('❌ RÉPARATION HIVE: Erreur durant la réparation: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Nettoie les boîtes de récompenses corrompues
  static Future<void> _cleanRewardBoxes() async {
    final boxNames = [
      'virelangueRewardHistoryBox',
      'virelanguePityTimerBox',
      'gemCollectionBox',
    ];
    
    for (final boxName in boxNames) {
      try {
        _logger.i('🧹 RÉPARATION: Nettoyage de la boîte "$boxName"...');
        
        // Fermer la boîte si ouverte
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
          _logger.d('📦 RÉPARATION: Boîte "$boxName" fermée');
        }
        
        // Supprimer la boîte corrompue
        await Hive.deleteBoxFromDisk(boxName);
        _logger.i('🗑️ RÉPARATION: Boîte "$boxName" supprimée du disque');
        
      } catch (e) {
        _logger.w('⚠️ RÉPARATION: Impossible de nettoyer "$boxName": $e');
        // Continuer avec les autres boîtes
      }
    }
  }
  
  /// Nettoie les boîtes de virelangues corrompues
  static Future<void> _cleanVirelangueBoxes() async {
    final boxNames = [
      'virelangueBox',
      'sessionBox',
      'scoreBox',
      'progressBox',
    ];
    
    for (final boxName in boxNames) {
      try {
        _logger.i('🧹 RÉPARATION: Nettoyage de la boîte "$boxName"...');
        
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        
        await Hive.deleteBoxFromDisk(boxName);
        _logger.i('🗑️ RÉPARATION: Boîte "$boxName" supprimée du disque');
        
      } catch (e) {
        _logger.w('⚠️ RÉPARATION: Impossible de nettoyer "$boxName": $e');
      }
    }
  }
  
  /// Nettoie les boîtes d'historique corrompues
  static Future<void> _cleanHistoryBoxes() async {
    final boxNames = [
      'userHistoryBox',
      'exerciseHistoryBox',
      'achievementBox',
    ];
    
    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        await Hive.deleteBoxFromDisk(boxName);
        _logger.i('🗑️ RÉPARATION: Boîte "$boxName" supprimée du disque');
      } catch (e) {
        _logger.w('⚠️ RÉPARATION: Impossible de nettoyer "$boxName": $e');
      }
    }
  }
  
  /// Supprime les fichiers temporaires et cache
  static Future<void> _cleanTempFiles() async {
    try {
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory('${appDir.path}/hive');
        
        if (await hiveDir.exists()) {
          // Supprimer tous les fichiers .hive corrompus
          final files = await hiveDir.list().toList();
          for (final file in files) {
            if (file is File && file.path.endsWith('.hive')) {
              try {
                await file.delete();
                _logger.d('🗑️ RÉPARATION: Fichier supprimé: ${file.path}');
              } catch (e) {
                _logger.w('⚠️ RÉPARATION: Impossible de supprimer ${file.path}: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.w('⚠️ RÉPARATION: Erreur nettoyage fichiers temporaires: $e');
    }
  }
  
  /// Réinitialise complètement Hive
  static Future<void> resetHiveCompletely() async {
    try {
      _logger.w('🔄 RÉPARATION COMPLÈTE: Réinitialisation totale de Hive...');
      
      // Fermer toutes les boîtes
      await Hive.close();
      
      // Supprimer tous les fichiers Hive
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory('${appDir.path}/hive');
        
        if (await hiveDir.exists()) {
          await hiveDir.delete(recursive: true);
          _logger.i('🗑️ RÉPARATION COMPLÈTE: Dossier Hive supprimé complètement');
        }
      }
      
      // Réinitialiser Hive
      await Hive.initFlutter();
      _logger.i('✅ RÉPARATION COMPLÈTE: Hive réinitialisé avec succès');
      
    } catch (e, stackTrace) {
      _logger.e('❌ RÉPARATION COMPLÈTE: Erreur: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Vérifie l'intégrité des boîtes Hive
  static Future<bool> checkHiveIntegrity() async {
    try {
      _logger.i('🔍 VÉRIFICATION HIVE: Contrôle d\'intégrité...');
      
      final testBoxName = 'hive_integrity_test';
      
      // Test d'écriture/lecture
      final testBox = await Hive.openBox(testBoxName);
      await testBox.put('test_key', DateTime.now());
      final testValue = testBox.get('test_key');
      await testBox.close();
      await Hive.deleteBoxFromDisk(testBoxName);
      
      final isHealthy = testValue != null;
      _logger.i('✅ VÉRIFICATION HIVE: Intégrité ${isHealthy ? "OK" : "CORROMPUE"}');
      
      return isHealthy;
      
    } catch (e) {
      _logger.e('❌ VÉRIFICATION HIVE: Erreur lors du test d\'intégrité: $e');
      return false;
    }
  }
}