import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';
import '../../domain/repositories/confidence_repository.dart';
import '../datasources/confidence_local_datasource.dart';
import '../datasources/confidence_remote_datasource.dart';

class ConfidenceRepositoryImpl implements ConfidenceRepository {
  final ConfidenceLocalDataSource localDataSource;
  final ConfidenceRemoteDataSource remoteDataSource;
  final _uuid = const Uuid();

  ConfidenceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<ConfidenceScenario>> getScenarios() async {
    try {
      // Essayer d'abord de récupérer depuis le remote
      final scenarios = await remoteDataSource.getScenarios();
      // Mettre en cache localement
      await localDataSource.cacheScenarios(scenarios);
      return scenarios;
    } catch (e) {
      // En cas d'erreur, utiliser le cache local
      return await localDataSource.getCachedScenarios();
    }
  }

  @override
  Future<ConfidenceScenario?> getScenarioById(String id) async {
    final scenarios = await getScenarios();
    try {
      return scenarios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ConfidenceScenario> getRandomScenario() async {
    final scenarios = await getScenarios();
    if (scenarios.isEmpty) {
      throw Exception('Aucun scénario disponible');
    }
    final random = Random();
    return scenarios[random.nextInt(scenarios.length)];
  }

  @override
  Future<ConfidenceSession> startSession({
    required String userId,
    required ConfidenceScenario scenario,
  }) async {
    final session = ConfidenceSession(
      id: _uuid.v4(),
      userId: userId,
      scenario: scenario,
      startTime: DateTime.now(),
      recordingDurationSeconds: 0,
    );

    // Sauvegarder localement
    await localDataSource.saveSession(session);
    
    return session;
  }

  @override
  Future<void> updateSession(ConfidenceSession session) async {
    await localDataSource.updateSession(session);
  }

  @override
  Future<ConfidenceSession> completeSession({
    required String sessionId,
    required String audioFilePath,
    required int recordingDurationSeconds,
    required ConfidenceAnalysis analysis,
  }) async {
    final session = await localDataSource.getSession(sessionId);
    if (session == null) {
      throw Exception('Session non trouvée');
    }

    final updatedSession = session.copyWith(
      endTime: DateTime.now(),
      audioFilePath: audioFilePath,
      recordingDurationSeconds: recordingDurationSeconds,
      analysis: analysis,
      isCompleted: true,
    );

    // Vérifier et attribuer les badges
    final badges = await checkAndAwardBadges(
      userId: session.userId,
      session: updatedSession,
    );

    final sessionWithBadges = updatedSession.copyWith(
      achievedBadges: badges,
    );

    // Sauvegarder localement et à distance
    await localDataSource.updateSession(sessionWithBadges);
    await remoteDataSource.saveSession(sessionWithBadges);

    return sessionWithBadges;
  }

  @override
  Future<List<ConfidenceSession>> getUserSessions(String userId) async {
    try {
      // Essayer de récupérer depuis le remote
      final sessions = await remoteDataSource.getUserSessions(userId);
      // Mettre en cache localement
      for (final session in sessions) {
        await localDataSource.saveSession(session);
      }
      return sessions;
    } catch (e) {
      // En cas d'erreur, utiliser le cache local
      return await localDataSource.getUserSessions(userId);
    }
  }

  @override
  Future<ConfidenceStats> getUserStats(String userId) async {
    final sessions = await getUserSessions(userId);
    
    if (sessions.isEmpty) {
      return ConfidenceStats(
        totalSessions: 0,
        consecutiveDays: 0,
        averageConfidenceScore: 0,
        averageFluencyScore: 0,
        averageClarityScore: 0,
        averageEnergyScore: 0,
        totalRecordingSeconds: 0,
        unlockedBadges: [],
        scenarioTypeCount: {},
      );
    }

    // Calculer les statistiques
    final completedSessions = sessions.where((s) => s.isCompleted).toList();
    final sessionsWithAnalysis = completedSessions.where((s) => s.analysis != null).toList();

    // Calcul des moyennes
    double avgConfidence = 0, avgFluency = 0, avgClarity = 0, avgEnergy = 0;
    if (sessionsWithAnalysis.isNotEmpty) {
      avgConfidence = sessionsWithAnalysis
          .map((s) => s.analysis!.confidenceScore)
          .reduce((a, b) => a + b) / sessionsWithAnalysis.length;
      avgFluency = sessionsWithAnalysis
          .map((s) => s.analysis!.fluencyScore)
          .reduce((a, b) => a + b) / sessionsWithAnalysis.length;
      avgClarity = sessionsWithAnalysis
          .map((s) => s.analysis!.clarityScore)
          .reduce((a, b) => a + b) / sessionsWithAnalysis.length;
      avgEnergy = sessionsWithAnalysis
          .map((s) => s.analysis!.energyScore)
          .reduce((a, b) => a + b) / sessionsWithAnalysis.length;
    }

    // Calcul du temps total
    final totalSeconds = completedSessions
        .map((s) => s.recordingDurationSeconds)
        .fold(0, (a, b) => a + b);

    // Calcul des jours consécutifs
    final consecutiveDays = _calculateConsecutiveDays(completedSessions);

    // Compter les types de scénarios
    final scenarioTypeCount = <ConfidenceScenarioType, int>{};
    for (final session in completedSessions) {
      scenarioTypeCount[session.scenario.type] = 
          (scenarioTypeCount[session.scenario.type] ?? 0) + 1;
    }

    // Collecter tous les badges uniques
    final allBadges = <String>{};
    for (final session in completedSessions) {
      allBadges.addAll(session.achievedBadges);
    }

    return ConfidenceStats(
      totalSessions: completedSessions.length,
      consecutiveDays: consecutiveDays,
      averageConfidenceScore: avgConfidence,
      averageFluencyScore: avgFluency,
      averageClarityScore: avgClarity,
      averageEnergyScore: avgEnergy,
      totalRecordingSeconds: totalSeconds,
      unlockedBadges: allBadges.toList(),
      scenarioTypeCount: scenarioTypeCount,
      lastSessionDate: completedSessions.isNotEmpty 
          ? completedSessions.last.endTime 
          : null,
    );
  }

  @override
  Future<List<String>> checkAndAwardBadges({
    required String userId,
    required ConfidenceSession session,
  }) async {
    final badges = <String>[];
    final stats = await getUserStats(userId);

    // Badge "Première Victoire" - Première session complétée
    if (stats.totalSessions == 0) {
      badges.add('first_victory');
    }

    // Badge "Orateur Régulier" - 7 jours consécutifs
    if (stats.consecutiveDays >= 7) {
      badges.add('regular_speaker');
    }

    // Badge "Maître de la Confiance" - Score de confiance > 90%
    if (session.analysis != null && session.analysis!.confidenceScore >= 0.9) {
      badges.add('confidence_master');
    }

    // Badge "Voix Claire" - Score de clarté > 85%
    if (session.analysis != null && session.analysis!.clarityScore >= 0.85) {
      badges.add('clear_voice');
    }

    // Badge "Énergie Contagieuse" - Score d'énergie > 85%
    if (session.analysis != null && session.analysis!.energyScore >= 0.85) {
      badges.add('contagious_energy');
    }

    // Badge "Marathonien" - 30 sessions complétées
    if (stats.totalSessions >= 29) { // 29 + cette session = 30
      badges.add('marathon_speaker');
    }

    // Badge "Polyvalent" - Avoir essayé tous les types de scénarios
    if (stats.scenarioTypeCount.length == ConfidenceScenarioType.values.length - 1) {
      // -1 car on n'a pas encore compté la session actuelle
      badges.add('versatile_speaker');
    }

    // Badge "Perfectionniste" - Score global > 95%
    if (session.analysis != null && session.analysis!.overallScore >= 0.95) {
      badges.add('perfectionist');
    }

    return badges;
  }

  int _calculateConsecutiveDays(List<ConfidenceSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Trier les sessions par date
    final sortedSessions = List<ConfidenceSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    int consecutiveDays = 1;
    DateTime? lastDate = sortedSessions.first.startTime;

    for (int i = 1; i < sortedSessions.length; i++) {
      final currentDate = sortedSessions[i].startTime;
      final dayDifference = currentDate.difference(lastDate!).inDays;

      if (dayDifference == 1) {
        consecutiveDays++;
      } else if (dayDifference > 1) {
        consecutiveDays = 1; // Réinitialiser si la séquence est brisée
      }
      // Si dayDifference == 0, c'est le même jour, on ne change rien

      lastDate = currentDate;
    }

    // Vérifier si la dernière session est d'aujourd'hui ou d'hier
    final now = DateTime.now();
    final lastSessionDate = sortedSessions.last.startTime;
    final daysSinceLastSession = now.difference(lastSessionDate).inDays;

    if (daysSinceLastSession > 1) {
      return 0; // La séquence est brisée
    }

    return consecutiveDays;
  }
}