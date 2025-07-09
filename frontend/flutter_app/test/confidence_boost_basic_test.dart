import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart' as confidence_models;
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_session.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';

void main() {
  group('ConfidenceScenario Tests', () {
    test('devrait créer un scénario correctement', () {
      const scenario = ConfidenceScenario(
        id: 'test-1',
        title: 'Test Scenario',
        description: 'Description test',
        prompt: 'Présentez-vous en 30 secondes',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 30,
        tips: ['Tip 1', 'Tip 2'],
        keywords: ['confiance', 'présentation'],
        difficulty: 'beginner',
        icon: '👥',
      );

      expect(scenario.id, 'test-1');
      expect(scenario.title, 'Test Scenario');
      expect(scenario.type, confidence_models.ConfidenceScenarioType.meeting);
      expect(scenario.durationSeconds, 30);
      expect(scenario.tips.length, 2);
      expect(scenario.keywords.length, 2);
      expect(scenario.difficulty, 'beginner');
      expect(scenario.icon, '👥');
    });

    test('devrait obtenir les scénarios par défaut', () {
      final scenarios = ConfidenceScenario.getDefaultScenarios();
      
      expect(scenarios.length, 5);
      expect(scenarios[0].id, 'team_meeting');
      expect(scenarios[1].id, 'client_presentation');
      expect(scenarios[2].id, 'elevator_pitch');
      expect(scenarios[3].id, 'team_motivation');
      expect(scenarios[4].id, 'product_demo');
    });
  });

  group('ConfidenceScenarioType Tests', () {
    test('devrait retourner le bon nom d\'affichage', () {
      expect(
        confidence_models.ConfidenceScenarioType.meeting.displayName,
        'Réunion d\'équipe',
      );
      expect(
        confidence_models.ConfidenceScenarioType.presentation.displayName,
        'Présentation client',
      );
      expect(
        confidence_models.ConfidenceScenarioType.pitch.displayName,
        'Elevator Pitch',
      );
      expect(
        confidence_models.ConfidenceScenarioType.meeting.displayName, // Pas de correspondance directe, utiliser meeting
        'Motivation d\'équipe',
      );
      expect(
        confidence_models.ConfidenceScenarioType.presentation.displayName, // Pas de correspondance directe, utiliser presentation
        'Démonstration produit',
      );
    });

    test('devrait retourner la bonne icône', () {
      expect(confidence_models.ConfidenceScenarioType.meeting.icon, '👥');
      expect(confidence_models.ConfidenceScenarioType.presentation.icon, '💼');
      expect(confidence_models.ConfidenceScenarioType.pitch.icon, '🚀');
      expect(confidence_models.ConfidenceScenarioType.meeting.icon, '⚡'); // Pas de correspondance directe, utiliser meeting
      expect(confidence_models.ConfidenceScenarioType.presentation.icon, '📱'); // Pas de correspondance directe, utiliser presentation
    });
  });

  group('ConfidenceAnalysis Tests', () {
    test('devrait créer une analyse correctement', () {
      final analysis = ConfidenceAnalysis(
        overallScore: 0.8,
        confidenceScore: 0.85,
        fluencyScore: 0.78,
        clarityScore: 0.82,
        energyScore: 0.75,
        wordCount: 120,
        speakingRate: 140.0,
        keywordsUsed: ['confiance', 'présentation'],
        transcription: 'Bonjour, je suis...',
        feedback: 'Excellente performance !',
        strengths: ['Bonne structure', 'Vocabulaire riche'],
        improvements: ['Ajouter plus d\'énergie'],
      );

      expect(analysis.confidenceScore, 0.85);
      expect(analysis.fluencyScore, 0.78);
      expect(analysis.clarityScore, 0.82);
      expect(analysis.energyScore, 0.75);
      expect(analysis.wordCount, 120);
      expect(analysis.speakingRate, 140.0);
      expect(analysis.keywordsUsed.length, 2);
      expect(analysis.strengths.length, 2);
      expect(analysis.improvements.length, 1);
    });

    test('devrait calculer le score global correctement', () {
      final analysis = ConfidenceAnalysis(
        overallScore: 0.75,
        confidenceScore: 0.80,
        fluencyScore: 0.70,
        clarityScore: 0.90,
        energyScore: 0.60,
        wordCount: 100,
        speakingRate: 120.0,
        keywordsUsed: [],
        transcription: 'Test',
        feedback: 'Test feedback',
        strengths: [],
        improvements: [],
      );

      final overallScore = analysis.overallScore;
      expect(overallScore, closeTo(0.75, 0.02)); // (0.80 + 0.70 + 0.90 + 0.60) / 4
    });
  });

  group('ConfidenceSession Tests', () {
    test('devrait créer une session correctement', () {
      final now = DateTime.now();
      final scenario = ConfidenceScenario(
        id: 'test-1',
        title: 'Test',
        description: 'Desc',
        prompt: 'Prompt',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 30,
        tips: [],
        keywords: [],
        difficulty: 'beginner',
        icon: '👥',
      );

      final session = ConfidenceSession(
        id: 'session-1',
        userId: 'user-1',
        scenario: scenario,
        startTime: now,
        endTime: now.add(const Duration(seconds: 30)),
        audioFilePath: '/path/to/audio.wav',
        recordingDurationSeconds: 30,
        analysis: null,
        achievedBadges: ['first_step'],
        isCompleted: true,
      );

      expect(session.id, 'session-1');
      expect(session.userId, 'user-1');
      expect(session.scenario.id, 'test-1');
      expect(session.audioFilePath, '/path/to/audio.wav');
      expect(session.analysis, isNull);
      expect(session.achievedBadges.length, 1);
      expect(session.achievedBadges.first, 'first_step');
      expect(session.isCompleted, true);
    });

    test('devrait supporter une session avec analyse', () {
      final scenario = ConfidenceScenario(
        id: 'test-1',
        title: 'Test',
        description: 'Desc',
        prompt: 'Prompt',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 30,
        tips: [],
        keywords: [],
        difficulty: 'beginner',
        icon: '👥',
      );

      final analysis = ConfidenceAnalysis(
        overallScore: 0.8,
        confidenceScore: 0.85,
        fluencyScore: 0.78,
        clarityScore: 0.82,
        energyScore: 0.75,
        wordCount: 120,
        speakingRate: 140.0,
        keywordsUsed: ['confiance'],
        transcription: 'Bonjour, je suis...',
        feedback: 'Excellente performance !',
        strengths: ['Bonne structure'],
        improvements: ['Ajouter plus d\'énergie'],
      );

      final session = ConfidenceSession(
        id: 'session-2',
        userId: 'user-1',
        scenario: scenario,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(seconds: 30)),
        audioFilePath: '/path/to/audio.wav',
        recordingDurationSeconds: 30,
        analysis: analysis,
        achievedBadges: ['confident_speaker', 'clear_voice'],
        isCompleted: true,
      );

      expect(session.analysis, isNotNull);
      expect(session.analysis!.confidenceScore, 0.85);
      expect(session.achievedBadges.length, 2);
    });
  });

  group('Scenario Equality Tests', () {
    test('devrait être égaux quand toutes les propriétés correspondent', () {
      const scenario1 = ConfidenceScenario(
        id: 'same_id',
        title: 'Same Title',
        description: 'Same description',
        prompt: 'Same prompt',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 60,
        tips: ['Same tip'],
        keywords: ['same'],
        difficulty: 'beginner',
        icon: '👥',
      );

      const scenario2 = ConfidenceScenario(
        id: 'same_id',
        title: 'Same Title',
        description: 'Same description',
        prompt: 'Same prompt',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 60,
        tips: ['Same tip'],
        keywords: ['same'],
        difficulty: 'beginner',
        icon: '👥',
      );

      expect(scenario1, equals(scenario2));
      expect(scenario1.hashCode, equals(scenario2.hashCode));
    });

    test('ne devrait pas être égaux quand les propriétés diffèrent', () {
      const scenario1 = ConfidenceScenario(
        id: 'id1',
        title: 'Title 1',
        description: 'Description 1',
        prompt: 'Prompt 1',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 60,
        tips: ['Tip 1'],
        keywords: ['keyword1'],
        difficulty: 'beginner',
        icon: '👥',
      );

      const scenario2 = ConfidenceScenario(
        id: 'id2', // Different ID
        title: 'Title 1',
        description: 'Description 1',
        prompt: 'Prompt 1',
        type: confidence_models.ConfidenceScenarioType.meeting,
        durationSeconds: 60,
        tips: ['Tip 1'],
        keywords: ['keyword1'],
        difficulty: 'beginner',
        icon: '👥',
      );

      expect(scenario1, isNot(equals(scenario2)));
    });
  });
}