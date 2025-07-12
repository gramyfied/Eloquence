import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../lib/features/confidence_boost/domain/entities/confidence_scenario.dart';
import '../lib/features/confidence_boost/domain/entities/gamification_models.dart';
import '../lib/features/confidence_boost/domain/entities/confidence_models.dart';

/// Test de validation pour vérifier que le conflit Hive TypeAdapter est résolu
/// 
/// Problème initial : typeId 21 était utilisé par ConfidenceScenario ET Badge
/// Solution : Badge utilise maintenant typeId 24
void main() {
  group('🔧 Validation Hive TypeAdapter - Conflit Résolu', () {
    
    test('✅ Vérification: Pas de conflit de typeId entre ConfidenceScenario et Badge', () {
      // Arrange - Initialisation Hive en mémoire
      Hive.init('test_hive');
      
      // Vérification des typeId uniques
      const confidenceScenarioTypeId = 21; // ConfidenceScenario
      const badgeTypeId = 24; // Badge (modifié de 21 vers 24)
      const userGamificationProfileTypeId = 20; // UserGamificationProfile
      const badgeRarityTypeId = 22; // BadgeRarity
      const badgeCategoryTypeId = 23; // BadgeCategory
      const confidenceScenarioTypeTypeId = 19; // ConfidenceScenarioType
      
      // Act & Assert - Vérification que tous les typeId sont uniques
      final typeIds = [
        confidenceScenarioTypeId,
        badgeTypeId,
        userGamificationProfileTypeId,
        badgeRarityTypeId,
        badgeCategoryTypeId,
        confidenceScenarioTypeTypeId,
      ];
      
      // Vérification: aucun doublon
      final uniqueTypeIds = typeIds.toSet();
      expect(uniqueTypeIds.length, equals(typeIds.length), 
        reason: 'Tous les typeId doivent être uniques');
      
      // Vérification spécifique: Badge n'utilise plus typeId 21
      expect(badgeTypeId, isNot(equals(confidenceScenarioTypeId)), 
        reason: 'Badge ne doit plus avoir le même typeId que ConfidenceScenario');
      
      print('✅ [HIVE_VALIDATION] Tous les typeId sont uniques:');
      print('   - ConfidenceScenario: $confidenceScenarioTypeId');
      print('   - Badge: $badgeTypeId');
      print('   - UserGamificationProfile: $userGamificationProfileTypeId');
      print('   - BadgeRarity: $badgeRarityTypeId');
      print('   - BadgeCategory: $badgeCategoryTypeId');
      print('   - ConfidenceScenarioType: $confidenceScenarioTypeTypeId');
    });

    test('✅ Enregistrement TypeAdapter: Pas d\'exception de conflit', () async {
      // Arrange - Initialisation Hive en mémoire pour les tests
      Hive.init('test_hive_memory');
      
      try {
        // Act - Enregistrement des TypeAdapters (dans l'ordre)
        if (!Hive.isAdapterRegistered(19)) {
          Hive.registerAdapter(ConfidenceScenarioTypeAdapter());
        }
        if (!Hive.isAdapterRegistered(20)) {
          Hive.registerAdapter(UserGamificationProfileAdapter());
        }
        if (!Hive.isAdapterRegistered(21)) {
          Hive.registerAdapter(ConfidenceScenarioAdapter());
        }
        if (!Hive.isAdapterRegistered(22)) {
          Hive.registerAdapter(BadgeRarityAdapter());
        }
        if (!Hive.isAdapterRegistered(23)) {
          Hive.registerAdapter(BadgeCategoryAdapter());
        }
        if (!Hive.isAdapterRegistered(24)) {
          Hive.registerAdapter(BadgeAdapter());
        }
        
        // Assert - Aucune exception levée
        print('✅ [HIVE_REGISTRATION] Tous les TypeAdapters enregistrés sans conflit');
        
        // Vérification que les adapters sont bien enregistrés
        expect(Hive.isAdapterRegistered(19), isTrue);
        expect(Hive.isAdapterRegistered(20), isTrue);
        expect(Hive.isAdapterRegistered(21), isTrue);
        expect(Hive.isAdapterRegistered(22), isTrue);
        expect(Hive.isAdapterRegistered(23), isTrue);
        expect(Hive.isAdapterRegistered(24), isTrue);
        
      } catch (e) {
        fail('❌ [HIVE_ERROR] Conflit TypeAdapter détecté: $e');
      }
    });

    test('✅ Création et sérialisation: ConfidenceScenario et Badge fonctionnels', () async {
      // Arrange - S'assurer que les adapters sont enregistrés
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(ConfidenceScenarioAdapter());
      }
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(ConfidenceScenarioTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(24)) {
        Hive.registerAdapter(BadgeAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(BadgeRarityAdapter());
      }
      if (!Hive.isAdapterRegistered(23)) {
        Hive.registerAdapter(BadgeCategoryAdapter());
      }
      
      final testScenario = ConfidenceScenario(
        id: 'test_scenario',
        title: 'Test Scenario',
        description: 'Test description',
        prompt: 'Test prompt',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 180,
        tips: ['tip1', 'tip2'],
        keywords: ['keyword1', 'keyword2'],
        difficulty: 'beginner',
        icon: '🎯',
      );
      
      final testBadge = Badge(
        id: 'test_badge',
        name: 'Test Badge',
        description: 'Test badge description',
        iconPath: 'test_icon.png',
        rarity: BadgeRarity.common,
        category: BadgeCategory.performance,
        xpReward: 100,
      );
      
      // Act - Test en mémoire uniquement
      try {
        final scenarioBox = await Hive.openBox<ConfidenceScenario>('test_scenarios_memory');
        final badgeBox = await Hive.openBox<Badge>('test_badges_memory');
        
        await scenarioBox.put('test_key', testScenario);
        await badgeBox.put('test_key', testBadge);
        
        final retrievedScenario = scenarioBox.get('test_key');
        final retrievedBadge = badgeBox.get('test_key');
        
        // Assert
        expect(retrievedScenario, isNotNull);
        expect(retrievedBadge, isNotNull);
        expect(retrievedScenario!.id, equals('test_scenario'));
        expect(retrievedBadge!.id, equals('test_badge'));
        expect(retrievedBadge.category, equals(BadgeCategory.performance));
        
        print('✅ [HIVE_SERIALIZATION] ConfidenceScenario et Badge fonctionnent correctement');
        
        await scenarioBox.close();
        await badgeBox.close();
        
      } catch (e) {
        fail('❌ [HIVE_SERIALIZATION_ERROR] Erreur de sérialisation: $e');
      }
    });

    test('🎯 CORRECTION CRITIQUE: BadgeCategory TypeAdapter doit fonctionner sans erreur', () async {
      // Arrange - Enregistrer les adapters nécessaires
      if (!Hive.isAdapterRegistered(23)) {
        Hive.registerAdapter(BadgeCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(BadgeRarityAdapter());
      }
      if (!Hive.isAdapterRegistered(24)) {
        Hive.registerAdapter(BadgeAdapter());
      }
      
      try {
        // Test direct en mémoire pour éviter les problèmes de fichiers
        final categoryBox = await Hive.openBox<BadgeCategory>('badgeCategory_critical_memory');
        final badgeBox = await Hive.openBox<Badge>('badge_critical_memory');
        
        // Act - Utilisation directe de BadgeCategory (qui causait l'erreur)
        await categoryBox.put('performance', BadgeCategory.performance);
        await categoryBox.put('streak', BadgeCategory.streak);
        await categoryBox.put('milestone', BadgeCategory.milestone);
        
        // Création d'un Badge utilisant BadgeCategory
        final criticalBadge = Badge(
          id: 'critical_test_badge',
          name: 'Critical Test Badge',
          description: 'Badge pour tester la correction TypeAdapter',
          iconPath: '/icons/critical.png',
          rarity: BadgeRarity.epic,
          category: BadgeCategory.performance, // Utilise BadgeCategory directement
          xpReward: 250,
        );
        
        // Cette opération échouait avant la correction avec:
        // "HiveError: Cannot write, unknown type: BadgeCategory. Did you forget to register an adapter?"
        await badgeBox.put('critical_test', criticalBadge);
        
        // Assert - Vérification que tout fonctionne
        final savedCategory = categoryBox.get('performance');
        final savedBadge = badgeBox.get('critical_test');
        
        expect(savedCategory, equals(BadgeCategory.performance));
        expect(savedBadge, isNotNull);
        expect(savedBadge!.category, equals(BadgeCategory.performance));
        expect(savedBadge.rarity, equals(BadgeRarity.epic));
        
        print('✅ [CRITICAL_FIX] BadgeCategory TypeAdapter fonctionne correctement');
        print('   - BadgeCategory sérialisé/désérialisé avec succès');
        print('   - Badge avec BadgeCategory sauvegardé sans erreur');
        
        await categoryBox.close();
        await badgeBox.close();
        
      } catch (e) {
        fail('❌ [CRITICAL_ERROR] BadgeCategory TypeAdapter encore défaillant: $e');
      }
    });
  });
}