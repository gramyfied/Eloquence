import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/widgets/confidence_results_view.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_session.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/datasources/confidence_remote_datasource.dart';

// Mock complet pour les dépendances
class MockConfidenceRemoteDataSource implements ConfidenceRemoteDataSource {
  @override
  Future<List<ConfidenceScenario>> getScenarios() async {
    return [
      const ConfidenceScenario(
        id: 'test_scenario',
        title: 'Test Scenario',
        description: 'A test scenario',
        prompt: 'Parlez avec confiance de votre projet',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 300,
        tips: ['Stay calm'],
        keywords: ['confiance', 'test', 'projet'],
        difficulty: 'moyen',
        icon: '🎯',
      ),
    ];
  }

  @override
  Future<ConfidenceAnalysis> analyzeAudio({
    required String audioFilePath,
    required ConfidenceScenario scenario,
  }) async {
    // Mock implementation pour analyzeAudio
    return ConfidenceAnalysis(
      overallScore: 85.0,
      confidenceScore: 0.85,
      fluencyScore: 0.8,
      clarityScore: 0.85,
      energyScore: 0.9,
      feedback: 'Test feedback excellent pour validation interface',
      improvements: ['Continuez ainsi', 'Parfait timing'],
    );
  }
}

void main() {
  group('🎮 Gamification Interface Validation Tests', () {
    late ProviderContainer container;
    late ConfidenceBoostProvider confidenceProvider;

    setUp(() async {
      // Initialisation des SharedPreferences pour les tests
      SharedPreferences.setMockInitialValues({});
      final mockSharedPrefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          // Override avec mock pour éviter l'erreur Supabase
          confidenceRemoteDataSourceProvider.overrideWithValue(
            MockConfidenceRemoteDataSource(),
          ),
          // Override pour SharedPreferences avec mock initialisé
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
        ],
      );
      confidenceProvider = container.read(confidenceBoostProvider);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('🎯 Test 1: Validation gamification de base avec affichage XP/badges',
        (WidgetTester tester) async {
      debugPrint('\n🚀 [TEST 1] Démarrage du test de gamification de base...');
      
      // 1. Créer des données de gamification de démonstration
      await confidenceProvider.createDemoGamificationData();
      
      // 2. Vérifier l'état après création
      var state = container.read(confidenceBoostProvider);
      debugPrint('🔍 État gamification après création: ${state.lastGamificationResult != null ? "PRÉSENT" : "NULL"}');
      
      if (state.lastGamificationResult != null) {
        final result = state.lastGamificationResult!;
        debugPrint('   📈 XP gagné: ${result.earnedXP}');
        debugPrint('   🏆 Nouveaux badges: ${result.newBadges.length}');
        debugPrint('   📊 Niveau actuel: ${result.newLevel}');
        debugPrint('   🔥 Streak: ${result.streakInfo.currentStreak}');
        
        // 3. Test d'affichage dans le widget
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              confidenceRemoteDataSourceProvider.overrideWithValue(
                MockConfidenceRemoteDataSource(),
              ),
              sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final provider = ref.watch(confidenceBoostProvider);
                    
                    if (provider.lastGamificationResult == null) {
                      return const Text('🔄 Chargement gamification...');
                    }
                    
                    // Créer un SessionRecord complet pour le widget
                    final testSession = SessionRecord(
                      userId: 'test_user',
                      analysis: ConfidenceAnalysis(
                        overallScore: 85.0,
                        confidenceScore: 0.85,
                        fluencyScore: 0.8,
                        clarityScore: 0.85,
                        energyScore: 0.9,
                        feedback: 'Test feedback excellent pour validation interface',
                        improvements: ['Continuez ainsi', 'Parfait timing'],
                      ),
                      scenario: const ConfidenceScenario(
                        id: 'test_scenario',
                        title: 'Test Présentation',
                        description: 'Scénario de test',
                        prompt: 'Présentez votre projet avec assurance',
                        type: ConfidenceScenarioType.presentation,
                        durationSeconds: 300,
                        tips: ['Respirez calmement'],
                        keywords: ['projet', 'confiance', 'test'],
                        difficulty: 'moyen',
                        icon: '🎯',
                      ),
                      textSupport: TextSupport(
                        type: SupportType.fullText,
                        content: 'Support de test',
                      ),
                      earnedXP: result.earnedXP,
                      newBadges: result.newBadges,
                      timestamp: DateTime.now(),
                      sessionDuration: const Duration(minutes: 3),
                    );
                    
                    return ConfidenceResultsView(
                      session: testSession,
                      onRetry: () {
                        debugPrint('🔄 Retry button pressed');
                      },
                      onComplete: () {
                        debugPrint('✅ Complete button pressed');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // 4. Vérifications d'affichage
        expect(find.text('Score global'), findsOneWidget);
        expect(find.text('Analyse détaillée'), findsOneWidget);
        
        debugPrint('✅ [TEST 1] Interface gamification affichée avec succès!');
      } else {
        fail('❌ [TEST 1] Échec: Aucune donnée de gamification créée');
      }
    });

    testWidgets('🆙 Test 2: Validation interface avec level up et badges épiques',
        (WidgetTester tester) async {
      debugPrint('\n🚀 [TEST 2] Démarrage du test de level up...');
      
      // 1. Créer des données de level up
      await confidenceProvider.createDemoGamificationDataWithLevelUp();
      
      // 2. Vérifier l'état
      var state = container.read(confidenceBoostProvider);
      debugPrint('🔍 État gamification après level up: ${state.lastGamificationResult != null ? "PRÉSENT" : "NULL"}');
      
      if (state.lastGamificationResult != null) {
        final result = state.lastGamificationResult!;
        debugPrint('   📈 XP massif: ${result.earnedXP}');
        debugPrint('   🏆 Badges épiques: ${result.newBadges.length}');
        debugPrint('   🆙 Niveau élevé: ${result.newLevel}');
        debugPrint('   🔥 Streak record: ${result.streakInfo.currentStreak}');
        debugPrint('   🎊 Level up: ${result.levelUp}');
        
        // 3. Test d'affichage avec level up
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              confidenceRemoteDataSourceProvider.overrideWithValue(
                MockConfidenceRemoteDataSource(),
              ),
              sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final provider = ref.watch(confidenceBoostProvider);
                    
                    if (provider.lastGamificationResult == null) {
                      return const Text('🔄 Chargement level up...');
                    }
                    
                    // SessionRecord pour le test avec level up
                    final testSessionLevelUp = SessionRecord(
                      userId: 'test_user',
                      analysis: ConfidenceAnalysis(
                        overallScore: 95.0,
                        confidenceScore: 0.95,
                        fluencyScore: 0.95,
                        clarityScore: 0.9,
                        energyScore: 0.92,
                        feedback: 'Performance exceptionnelle avec level up!',
                        improvements: ['Niveau supérieur atteint!'],
                      ),
                      scenario: const ConfidenceScenario(
                        id: 'levelup_scenario',
                        title: 'Défi Level Up',
                        description: 'Scénario difficile réussi',
                        prompt: 'Présentez un projet innovant avec excellence',
                        type: ConfidenceScenarioType.pitch,
                        durationSeconds: 600,
                        tips: ['Excellence requise'],
                        keywords: ['innovation', 'excellence', 'défi'],
                        difficulty: 'difficile',
                        icon: '🚀',
                      ),
                      textSupport: TextSupport(
                        type: SupportType.freeImprovisation,
                        content: 'Support avancé',
                      ),
                      earnedXP: result.earnedXP,
                      newBadges: result.newBadges,
                      timestamp: DateTime.now(),
                      sessionDuration: const Duration(minutes: 8),
                    );
                    
                    return ConfidenceResultsView(
                      session: testSessionLevelUp,
                      onRetry: () {
                        debugPrint('🔄 Retry level up test');
                      },
                      onComplete: () {
                        debugPrint('🎉 Level up completed');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // 4. Vérifications spéciales pour level up
        expect(find.text('Score global'), findsOneWidget);
        expect(find.text('Badges débloqués'), findsWidgets);
        
        debugPrint('🎉 [TEST 2] Interface level up validée avec succès!');
      } else {
        fail('❌ [TEST 2] Échec: Aucune donnée de level up créée');
      }
    });

    test('🧹 Test 3: Validation effacement des données de gamification', () async {
      debugPrint('\n🚀 [TEST 3] Test d\'effacement des données...');
      
      // 1. Créer des données
      await confidenceProvider.createDemoGamificationData();
      var state = container.read(confidenceBoostProvider);
      debugPrint('🎮 Données créées: ${state.lastGamificationResult != null ? "OUI" : "NON"}');
      
      // Vérifier que les données existent
      expect(state.lastGamificationResult, isNotNull);
      
      // 2. Test d'effacement (méthode synchrone)
      confidenceProvider.clearDemoGamificationData();
      state = container.read(confidenceBoostProvider);
      debugPrint('🧹 Effacement effectué - état: ${state.lastGamificationResult == null ? "NULL (OK)" : "ENCORE PRÉSENT (ERREUR)"}');
      
      // 3. Vérifier que les données ont été effacées
      expect(state.lastGamificationResult, isNull);
      
      debugPrint('✅ [TEST 3] Effacement des données validé avec succès!');
    });
  });
}