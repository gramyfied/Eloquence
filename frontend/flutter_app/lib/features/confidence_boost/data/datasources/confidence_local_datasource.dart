import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';

abstract class ConfidenceLocalDataSource {
  Future<void> cacheScenarios(List<ConfidenceScenario> scenarios);
  Future<List<ConfidenceScenario>> getCachedScenarios();
  Future<void> saveSession(ConfidenceSession session);
  Future<void> updateSession(ConfidenceSession session);
  Future<ConfidenceSession?> getSession(String sessionId);
  Future<List<ConfidenceSession>> getUserSessions(String userId);
  Future<void> clearCache();
}

class ConfidenceLocalDataSourceImpl implements ConfidenceLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String SCENARIOS_KEY = 'confidence_scenarios';
  static const String SESSIONS_KEY_PREFIX = 'confidence_sessions_';
  static const String SESSION_KEY_PREFIX = 'confidence_session_';

  ConfidenceLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheScenarios(List<ConfidenceScenario> scenarios) async {
    final scenariosJson = scenarios.map((s) => _scenarioToJson(s)).toList();
    await sharedPreferences.setString(
      SCENARIOS_KEY,
      json.encode(scenariosJson),
    );
  }

  @override
  Future<List<ConfidenceScenario>> getCachedScenarios() async {
    final scenariosString = sharedPreferences.getString(SCENARIOS_KEY);
    if (scenariosString == null) {
      return _getDefaultScenarios();
    }
    
    try {
      final List<dynamic> scenariosJson = json.decode(scenariosString);
      return scenariosJson.map((json) => _scenarioFromJson(json)).toList();
    } catch (e) {
      return _getDefaultScenarios();
    }
  }

  @override
  Future<void> saveSession(ConfidenceSession session) async {
    // Sauvegarder la session individuelle
    await sharedPreferences.setString(
      '$SESSION_KEY_PREFIX${session.id}',
      json.encode(_sessionToJson(session)),
    );

    // Ajouter à la liste des sessions de l'utilisateur
    final userSessionsKey = '$SESSIONS_KEY_PREFIX${session.userId}';
    final existingSessions = await getUserSessions(session.userId);
    
    // Éviter les doublons
    existingSessions.removeWhere((s) => s.id == session.id);
    existingSessions.add(session);
    
    final sessionsJson = existingSessions.map((s) => _sessionToJson(s)).toList();
    await sharedPreferences.setString(
      userSessionsKey,
      json.encode(sessionsJson),
    );
  }

  @override
  Future<void> updateSession(ConfidenceSession session) async {
    await saveSession(session);
  }

  @override
  Future<ConfidenceSession?> getSession(String sessionId) async {
    final sessionString = sharedPreferences.getString('$SESSION_KEY_PREFIX$sessionId');
    if (sessionString == null) return null;
    
    try {
      final sessionJson = json.decode(sessionString);
      return _sessionFromJson(sessionJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ConfidenceSession>> getUserSessions(String userId) async {
    final sessionsString = sharedPreferences.getString('$SESSIONS_KEY_PREFIX$userId');
    if (sessionsString == null) return [];
    
    try {
      final List<dynamic> sessionsJson = json.decode(sessionsString);
      return sessionsJson.map((json) => _sessionFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith('confidence_')) {
        await sharedPreferences.remove(key);
      }
    }
  }

  // Méthodes de conversion JSON
  Map<String, dynamic> _scenarioToJson(ConfidenceScenario scenario) {
    return {
      'id': scenario.id,
      'title': scenario.title,
      'description': scenario.description,
      'prompt': scenario.prompt,
      'type': scenario.type.index,
      'durationSeconds': scenario.durationSeconds,
      'tips': scenario.tips,
      'keywords': scenario.keywords,
      'difficulty': scenario.difficulty,
      'icon': scenario.icon,
    };
  }

  ConfidenceScenario _scenarioFromJson(Map<String, dynamic> json) {
    return ConfidenceScenario(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      prompt: json['prompt'],
      type: ConfidenceScenarioTypeExtension.fromJson(json['type']),
      durationSeconds: json['durationSeconds'],
      tips: List<String>.from(json['tips']),
      keywords: List<String>.from(json['keywords']),
      difficulty: json['difficulty'] ?? 'intermediate',
      icon: json['icon'] ?? '🎯',
    );
  }

  Map<String, dynamic> _sessionToJson(ConfidenceSession session) {
    return {
      'id': session.id,
      'userId': session.userId,
      'scenario': _scenarioToJson(session.scenario),
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'recordingDurationSeconds': session.recordingDurationSeconds,
      'audioFilePath': session.audioFilePath,
      'analysis': session.analysis != null ? _analysisToJson(session.analysis!) : null,
      'achievedBadges': session.achievedBadges,
      'isCompleted': session.isCompleted,
    };
  }

  ConfidenceSession _sessionFromJson(Map<String, dynamic> json) {
    return ConfidenceSession(
      id: json['id'],
      userId: json['userId'],
      scenario: _scenarioFromJson(json['scenario']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      recordingDurationSeconds: json['recordingDurationSeconds'],
      audioFilePath: json['audioFilePath'],
      analysis: json['analysis'] != null ? _analysisFromJson(json['analysis']) : null,
      achievedBadges: List<String>.from(json['achievedBadges']),
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> _analysisToJson(ConfidenceAnalysis analysis) {
    return {
      'overallScore': analysis.overallScore,
      'confidenceScore': analysis.confidenceScore,
      'fluencyScore': analysis.fluencyScore,
      'clarityScore': analysis.clarityScore,
      'energyScore': analysis.energyScore,
      'wordCount': analysis.wordCount,
      'speakingRate': analysis.speakingRate,
      'keywordsUsed': analysis.keywordsUsed,
      'transcription': analysis.transcription,
      'feedback': analysis.feedback,
      'strengths': analysis.strengths,
      'improvements': analysis.improvements,
    };
  }

  ConfidenceAnalysis _analysisFromJson(Map<String, dynamic> json) {
    return ConfidenceAnalysis(
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      fluencyScore: (json['fluencyScore'] ?? 0.0).toDouble(),
      clarityScore: (json['clarityScore'] ?? 0.0).toDouble(),
      energyScore: (json['energyScore'] ?? 0.0).toDouble(),
      wordCount: json['wordCount'] ?? 0,
      speakingRate: (json['speakingRate'] ?? 0.0).toDouble(),
      keywordsUsed: List<String>.from(json['keywordsUsed'] ?? []),
      transcription: json['transcription'] ?? '',
      feedback: json['feedback'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
    );
  }

  // Scénarios par défaut CONFORMES AUX SPÉCIFICATIONS
  List<ConfidenceScenario> _getDefaultScenarios() {
    return ConfidenceScenario.getDefaultScenarios();
  }
}