import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/gamification_models.dart' as gamification;
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart' as confidence_models;
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart' as confidence_scenarios;
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_analysis_backend_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/prosody_analysis_interface.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/repositories/gamification_repository.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/xp_calculator_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/badge_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/streak_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/gamification_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/datasources/confidence_remote_datasource.dart';
import '../../fakes/fake_clean_livekit_service.dart';
import '../../fakes/fake_api_service.dart';

// Mock classes simples pour les tests
class MockConfidenceRemoteDataSource implements ConfidenceRemoteDataSource {
  @override
  Future<List<confidence_scenarios.ConfidenceScenario>> getScenarios() async {
    debugPrint('🔧 MockConfidenceRemoteDataSource.getScenarios() appelé');
    return [
      const confidence_scenarios.ConfidenceScenario(
        id: 'test-scenario',
        title: 'Test Scenario',
        description: 'Scenario de test',
        prompt: 'Test prompt',
        type: confidence_models.ConfidenceScenarioType.presentation,
        durationSeconds: 60,
        tips: ['Test tip'],
        keywords: ['test', 'scenario'],
        difficulty: 'intermediate',
        icon: '🎯',
      ),
    ];
  }

  @override
  Future<confidence_models.ConfidenceAnalysis> analyzeAudio({
    required String audioFilePath,
    required confidence_scenarios.ConfidenceScenario scenario,
  }) async {
    debugPrint('🔧 MockConfidenceRemoteDataSource.analyzeAudio() appelé');
    return confidence_models.ConfidenceAnalysis(
      overallScore: 0.85,
      confidenceScore: 0.85,
      fluencyScore: 0.82,
      clarityScore: 0.88,
      energyScore: 0.80,
      wordCount: 120,
      speakingRate: 150.0,
      keywordsUsed: ['test'],
      transcription: 'Mock transcription',
      feedback: 'Mock feedback',
      strengths: ['Mock strength'],
      improvements: ['Mock improvement'],
    );
  }
}

class MockConfidenceAnalysisBackendService extends ConfidenceAnalysisBackendService {
  @override
  Future<bool> isServiceAvailable() async => false;
}

class MockProsodyAnalysisInterface extends FallbackProsodyAnalysis {}

class MockGamificationRepository extends HiveGamificationRepository {
  @override
  Future<void> initialize() async {}
}

class MockXPCalculatorService extends XPCalculatorService {}

class MockBadgeService extends BadgeService {
  MockBadgeService() : super(MockGamificationRepository());
}

class MockStreakService extends StreakService {
  MockStreakService() : super(MockGamificationRepository());
}

class MockGamificationService extends GamificationService {
  MockGamificationService() : super(
    MockGamificationRepository(),
    MockBadgeService(),
    MockXPCalculatorService(),
    MockStreakService()
  );
}

void main() {
  group('Validation de la Correction Structurelle - Méthodes de Démonstration Gamification', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialiser SharedPreferences pour les tests
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // Créer le container avec tous les providers mockés
      container = ProviderContainer(
        overrides: [
          // Override SharedPreferences provider
          sharedPreferencesProvider.overrideWithValue(prefs),
          
          // Override ApiService provider avec fake
          apiServiceProvider.overrideWithValue(FakeApiService()),
          
          // Override LiveKit service avec fake
          livekitServiceProvider.overrideWithValue(FakeCleanLiveKitService()),
          
          // Override Mistral API service avec fake
// import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
          // TODO: Ajouter l'override du provider correctement ici si nécessaire
          
          // Override autres services avec mocks simples
          confidenceAnalysisBackendServiceProvider.overrideWithValue(MockConfidenceAnalysisBackendService()),
          prosodyAnalysisInterfaceProvider.overrideWithValue(MockProsodyAnalysisInterface()),
          
          // 🔧 CORRECTION CRITIQUE: Override confidenceRemoteDataSourceProvider pour éviter l'appel à Supabase
          confidenceRemoteDataSourceProvider.overrideWithValue(MockConfidenceRemoteDataSource()),
          
          // Correction pour FutureProvider: utiliser overrideWith pour retourner une Future
          gamificationRepositoryProvider.overrideWith((ref) async => MockGamificationRepository()),
          xpCalculatorServiceProvider.overrideWithValue(MockXPCalculatorService()),
          badgeServiceProvider.overrideWithValue(MockBadgeService()),
          streakServiceProvider.overrideWithValue(MockStreakService()),
          gamificationServiceProvider.overrideWithValue(MockGamificationService()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('VALIDATION DIRECTE: Méthodes de démonstration sont accessibles et fonctionnelles', (WidgetTester tester) async {
      debugPrint('\n🔧 === TEST DIRECT DES MÉTHODES DÉPLACÉES ===');
      
      final notifier = container.read(confidenceBoostProvider.notifier);
      
      // Test 1: createDemoGamificationData
      debugPrint('📝 Test de createDemoGamificationData()...');
      await notifier.createDemoGamificationData();
      
      // Vérifier l'état après l'appel
      container.read(confidenceBoostProvider);
      final demoResult = notifier.lastGamificationResult;
      
      expect(demoResult, isNotNull, reason: 'createDemoGamificationData doit générer un résultat');
      expect(demoResult!.earnedXP, greaterThan(0), reason: 'XP doit être positif');
      expect(demoResult.newBadges, isNotEmpty, reason: 'Des badges doivent être présents');
      expect(demoResult.streakInfo, isNotNull, reason: 'StreakInfo doit être présent');
      expect(demoResult.bonusMultiplier, isNotNull, reason: 'BonusMultiplier doit être présent');
      debugPrint('✅ createDemoGamificationData fonctionne: XP=${demoResult.earnedXP}, Badges=${demoResult.newBadges.length}');
      
      // Test 2: createDemoGamificationDataWithLevelUp
      debugPrint('📝 Test de createDemoGamificationDataWithLevelUp()...');
      await notifier.createDemoGamificationDataWithLevelUp();
      
      final levelUpResult = notifier.lastGamificationResult;
      expect(levelUpResult, isNotNull, reason: 'createDemoGamificationDataWithLevelUp doit générer un résultat');
      expect(levelUpResult!.earnedXP, greaterThan(demoResult.earnedXP), reason: 'Level up doit donner plus d\'XP');
      expect(levelUpResult.newBadges.any((b) => b.rarity == gamification.BadgeRarity.epic), isTrue,
        reason: 'Level up doit inclure des badges épiques');
      expect(levelUpResult.levelUp, isTrue, reason: 'Level up doit être activé');
      debugPrint('✅ createDemoGamificationDataWithLevelUp fonctionne: XP=${levelUpResult.earnedXP}, Level=${levelUpResult.newLevel}, Badges épiques=${levelUpResult.newBadges.where((b) => b.rarity == gamification.BadgeRarity.epic).length}');
      
      // Test 3: clearDemoGamificationData
      debugPrint('📝 Test de clearDemoGamificationData()...');
      notifier.clearDemoGamificationData();
      
      final clearedResult = notifier.lastGamificationResult;
      expect(clearedResult, isNull, reason: 'clearDemoGamificationData doit effacer les données');
      debugPrint('✅ clearDemoGamificationData fonctionne: État effacé correctement');
      
      debugPrint('🎉 TOUTES LES MÉTHODES DÉPLACÉES FONCTIONNENT CORRECTEMENT!');
    });

    testWidgets('VALIDATION STRUCTURELLE: Vérification que les méthodes ne sont plus dans le scope invalide', (WidgetTester tester) async {
      debugPrint('\n🔍 === VALIDATION DE LA CORRECTION STRUCTURELLE ===');
      
      final notifier = container.read(confidenceBoostProvider.notifier);
      
      // Tester que les méthodes sont maintenant accessibles comme méthodes de classe
      debugPrint('📝 Vérification de l\'accessibilité des méthodes comme membres de ConfidenceBoostProvider...');
      
      // Test que la méthode createDemoGamificationData est accessible
      final hasCreateDemo = notifier.createDemoGamificationData;
      expect(hasCreateDemo, isNotNull, reason: 'createDemoGamificationData doit être accessible');
      
      // Test que la méthode createDemoGamificationDataWithLevelUp est accessible
      final hasCreateDemoLevelUp = notifier.createDemoGamificationDataWithLevelUp;
      expect(hasCreateDemoLevelUp, isNotNull, reason: 'createDemoGamificationDataWithLevelUp doit être accessible');
      
      // Test que la méthode clearDemoGamificationData est accessible
      final hasClearDemo = notifier.clearDemoGamificationData;
      expect(hasClearDemo, isNotNull, reason: 'clearDemoGamificationData doit être accessible');
      
      debugPrint('✅ SUCCÈS: Toutes les méthodes de démonstration sont maintenant accessibles comme méthodes de classe');
      debugPrint('🎯 CORRECTION STRUCTURELLE VALIDÉE: Les méthodes ne sont plus piégées dans le scope du try-catch');
    });

    testWidgets('VALIDATION INTÉGRATION: Test du fallback d\'urgence avec démonstration', (WidgetTester tester) async {
      debugPrint('\n🚨 === TEST DU FALLBACK D\'URGENCE AVEC DÉMONSTRATION ===');
      
      final notifier = container.read(confidenceBoostProvider.notifier);
      
      // Simuler un appel direct au fallback (comme dans analyzePerformance)
      debugPrint('📝 Test direct de la génération de données de démonstration...');
      await notifier.createDemoGamificationData();
      
      // Récupérer les données générées depuis l'état du provider
      final demoData = notifier.lastGamificationResult;
      expect(demoData, isNotNull, reason: 'Les données de démonstration doivent être générées');
      
      // Vérifications complètes des données générées
      expect(demoData!.earnedXP, inInclusiveRange(30, 300), reason: 'XP doit être dans la plage réaliste');
      expect(demoData.newBadges.length, inInclusiveRange(1, 3), reason: 'Nombre de badges réaliste');
      expect(demoData.streakInfo.currentStreak, greaterThan(0), reason: 'Streak doit être positif');
      expect(demoData.bonusMultiplier, isNotNull, reason: 'BonusMultiplier doit être présent');
      
      // Test des types de badges générés
      final badgeCategories = demoData.newBadges.map((b) => b.category.name).toSet();
      debugPrint('🏆 Catégories de badges générées: ${badgeCategories.join(', ')}');
      
      // Test des raretés de badges
      final badgeRarities = demoData.newBadges.map((b) => b.rarity.name).toSet();
      debugPrint('💎 Raretés de badges: ${badgeRarities.join(', ')}');
      
      // Validation des multiplicateurs
      final multiplier = demoData.bonusMultiplier;
      expect(multiplier.performanceMultiplier, greaterThanOrEqualTo(1.0), reason: 'Performance multiplier doit être >= 1.0');
      expect(multiplier.streakMultiplier, greaterThanOrEqualTo(1.0), reason: 'Streak multiplier doit être >= 1.0');
      expect(multiplier.difficultyMultiplier, greaterThanOrEqualTo(1.0), reason: 'Difficulty multiplier doit être >= 1.0');
      
      debugPrint('✅ SUCCÈS: Le fallback d\'urgence génère des données de gamification complètes et réalistes');
      debugPrint('🎉 CORRECTION STRUCTURELLE COMPLÈTEMENT VALIDÉE!');
    });
  });
}