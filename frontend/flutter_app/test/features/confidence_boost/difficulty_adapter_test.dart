import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/difficulty_adapter.dart';
import 'package:eloquence_2_0/domain/entities/exercise.dart';

void main() {
  group('DifficultyAdapter Tests', () {
    late DifficultyAdapter difficultyAdapter;

    setUp(() {
      difficultyAdapter = DifficultyAdapter();
    });

    group('Adaptation dynamique de difficulté', () {
      test('devrait adapter la difficulté selon le profil utilisateur', () async {
        // Arrange
        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'pronunciation': 0.7, 'fluency': 0.6},
          totalSessions: 10,
          overallConfidence: 75.0,
          lastSessionDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final context = DifficultyContext(
          objective: LearningObjective.rapidProgress,
          timeConstraint: TimeConstraint.medium,
          fatigueLevel: 0.2,
        );

        // Act
        final result = await difficultyAdapter.adaptDifficultyDynamically(
          userProfile: userProfile,
          targetSkill: 'pronunciation',
          context: context,
        );

        // Assert
        expect(result.numericLevel, greaterThan(0.0));
        expect(result.numericLevel, lessThanOrEqualTo(1.0));
        expect(result.stringLevel, isNotEmpty);
        expect(result.recommendations, isNotEmpty);
        expect(result.confidence, greaterThan(0.0));
      });

      test('devrait détecter un plateau de performance', () async {
        // Arrange
        final performances = List.generate(5, (index) => 
          PerformanceMetrics(
            overallScore: 0.75, // Score constant = plateau
            skillScores: {'pronunciation': 0.75},
            timestamp: DateTime.now().subtract(Duration(days: index)),
            sessionDuration: const Duration(minutes: 5),
            exerciseType: 'pronunciation',
          ),
        );

        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'pronunciation': 0.75},
          totalSessions: 10,
          overallConfidence: 75.0,
          lastSessionDate: DateTime.now(),
        );

        final context = DifficultyContext(
          objective: LearningObjective.mastery,
          timeConstraint: TimeConstraint.low,
        );

        // Act
        final result = await difficultyAdapter.adaptDifficultyDynamically(
          userProfile: userProfile,
          targetSkill: 'pronunciation',
          context: context,
          recentPerformances: performances,
        );

        // Assert
        expect(result.adaptationReason, contains('plateau'));
        expect(result.numericLevel, greaterThan(0.75)); // Augmentation pour sortir du plateau
      });

      test('devrait réduire la difficulté si utilisateur en difficulté', () async {
        // Arrange
        final performances = List.generate(3, (index) => 
          PerformanceMetrics(
            overallScore: 0.4, // Score faible = difficulté
            skillScores: {'pronunciation': 0.4},
            timestamp: DateTime.now().subtract(Duration(days: index)),
            sessionDuration: const Duration(minutes: 5),
            exerciseType: 'pronunciation',
          ),
        );

        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'pronunciation': 0.6},
          totalSessions: 5,
          overallConfidence: 50.0,
          lastSessionDate: DateTime.now(),
        );

        final context = DifficultyContext(
          objective: LearningObjective.confidence,
          timeConstraint: TimeConstraint.high,
        );

        // Act
        final result = await difficultyAdapter.adaptDifficultyDynamically(
          userProfile: userProfile,
          targetSkill: 'pronunciation',
          context: context,
          recentPerformances: performances,
        );

        // Assert
        expect(result.adaptationReason, contains('Réduction'));
        expect(result.numericLevel, lessThan(0.6)); // Réduction de difficulté
      });

      test('devrait ajuster selon la contrainte de temps', () async {
        // Arrange
        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'pronunciation': 0.5},
          totalSessions: 15,
          overallConfidence: 70.0,
          lastSessionDate: DateTime.now(),
        );

        final contextHighTime = DifficultyContext(
          objective: LearningObjective.rapidProgress,
          timeConstraint: TimeConstraint.high,
          fatigueLevel: 0.8, // Très fatigué
        );

        // Act
        final result = await difficultyAdapter.adaptDifficultyDynamically(
          userProfile: userProfile,
          targetSkill: 'pronunciation',
          context: contextHighTime,
        );

        // Assert
        expect(result.suggestedDuration.inMinutes, lessThanOrEqualTo(8)); // Max pour contrainte haute
        expect(result.recommendations.any((r) => r.contains('fatigué')), isTrue);
      });
    });

    group('Conversions de types de difficulté', () {
      test('devrait convertir string vers numérique correctement', () {
        expect(DifficultyAdapter.stringToNumericDifficulty('débutant'), equals(0.2));
        expect(DifficultyAdapter.stringToNumericDifficulty('intermédiaire'), equals(0.5));
        expect(DifficultyAdapter.stringToNumericDifficulty('avancé'), equals(0.8));
        expect(DifficultyAdapter.stringToNumericDifficulty('expert'), equals(1.0));
        expect(DifficultyAdapter.stringToNumericDifficulty('invalid'), equals(0.5)); // Fallback
      });

      test('devrait convertir numérique vers ExerciseDifficulty', () async {
        final result = await _getAdaptationResult(0.3);
        expect(result.exerciseDifficulty, equals(ExerciseDifficulty.beginner));

        final result2 = await _getAdaptationResult(0.5);
        expect(result2.exerciseDifficulty, equals(ExerciseDifficulty.intermediate));

        final result3 = await _getAdaptationResult(0.8);
        expect(result3.exerciseDifficulty, equals(ExerciseDifficulty.advanced));

        final result4 = await _getAdaptationResult(0.9);
        expect(result4.exerciseDifficulty, equals(ExerciseDifficulty.expert));
      });
    });

    group('Utilités publiques', () {
      test('devrait évaluer si utilisateur prêt pour difficulté', () async {
        // Arrange
        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'pronunciation': 0.7},
          totalSessions: 20,
          overallConfidence: 80.0,
          lastSessionDate: DateTime.now(),
        );

        // Act & Assert
        final readyForHigher = await difficultyAdapter.isUserReadyForDifficulty(
          userProfile: userProfile,
          targetDifficulty: 0.8, // +0.1 seulement
          skill: 'pronunciation',
        );
        expect(readyForHigher, isTrue);

        final notReadyForMuchHigher = await difficultyAdapter.isUserReadyForDifficulty(
          userProfile: userProfile,
          targetDifficulty: 0.95, // +0.25 trop élevé
          skill: 'pronunciation',
        );
        expect(notReadyForMuchHigher, isFalse);
      });

      test('devrait retourner niveau recommandé suivant', () async {
        // Arrange
        final userProfile = UserPerformanceProfile(
          userId: 'test_user',
          skillLevels: {'fluency': 0.6},
          totalSessions: 8,
          overallConfidence: 65.0,
          lastSessionDate: DateTime.now(),
        );

        final context = DifficultyContext(
          objective: LearningObjective.mastery,
          timeConstraint: TimeConstraint.medium,
        );

        // Act
        final nextLevel = await difficultyAdapter.getNextRecommendedLevel(
          userProfile: userProfile,
          skill: 'fluency',
          context: context,
        );

        // Assert
        expect(nextLevel, greaterThan(0.0));
        expect(nextLevel, lessThanOrEqualTo(1.0));
      });
    });

    group('Gestion des erreurs et fallback', () {
      test('devrait retourner fallback en cas d\'erreur', () async {
        // Arrange - profil avec des données incorrectes
        final invalidProfile = UserPerformanceProfile(
          userId: '',
          skillLevels: {},
          totalSessions: -1,
          overallConfidence: -10.0,
          lastSessionDate: DateTime.now(),
        );

        final context = DifficultyContext(
          objective: LearningObjective.rapidProgress,
          timeConstraint: TimeConstraint.medium,
        );

        // Act
        final result = await difficultyAdapter.adaptDifficultyDynamically(
          userProfile: invalidProfile,
          targetSkill: 'invalid_skill',
          context: context,
        );

        // Assert
        expect(result.numericLevel, equals(0.5)); // Fallback niveau
        expect(result.stringLevel, equals('intermédiaire'));
        expect(result.adaptationReason, contains('défaut'));
        expect(result.confidence, lessThan(0.5)); // Faible confiance
      });
    });
  });
}

// Helper pour créer un résultat d'adaptation avec niveau spécifique
Future<AdaptedDifficultyResult> _getAdaptationResult(double targetLevel) async {
  final adapter = DifficultyAdapter();
  final userProfile = UserPerformanceProfile(
    userId: 'test',
    skillLevels: {'test': targetLevel},
    totalSessions: 10,
    overallConfidence: targetLevel * 100,
    lastSessionDate: DateTime.now(),
  );
  final context = DifficultyContext(
    objective: LearningObjective.mastery,
    timeConstraint: TimeConstraint.medium,
  );
  
  return await adapter.adaptDifficultyDynamically(
    userProfile: userProfile,
    targetSkill: 'test',
    context: context,
  );
}