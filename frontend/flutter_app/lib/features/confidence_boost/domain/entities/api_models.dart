import 'package:equatable/equatable.dart';

/// Résultat de l'analyse audio par l'API backend
class ConfidenceAnalysisResult extends Equatable {
  final String transcription;
  final String aiResponse;
  final double confidenceScore;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;
  
  const ConfidenceAnalysisResult({
    required this.transcription,
    required this.aiResponse,
    required this.confidenceScore,
    required this.metrics,
    required this.timestamp,
  });
  
  factory ConfidenceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ConfidenceAnalysisResult(
      transcription: json['transcription'] ?? '',
      aiResponse: json['ai_response'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      metrics: json['metrics'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transcription': transcription,
      'ai_response': aiResponse,
      'confidence_score': confidenceScore,
      'metrics': metrics,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [transcription, aiResponse, confidenceScore, metrics, timestamp];
}

/// Session d'exercice Boost Confidence
class ConfidenceSession extends Equatable {
  final String sessionId;
  final String userId;
  final String scenarioId;
  final String language;
  final String roomName;
  final String livekitUrl;
  final String livekitToken;
  final String participantIdentity;
  final ConfidenceInitialMessage? initialMessage;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  const ConfidenceSession({
    required this.sessionId,
    required this.userId,
    required this.scenarioId,
    required this.language,
    required this.roomName,
    required this.livekitUrl,
    required this.livekitToken,
    required this.participantIdentity,
    this.initialMessage,
    required this.status,
    required this.createdAt,
    this.metadata = const {},
  });
  
  factory ConfidenceSession.fromJson(Map<String, dynamic> json) {
    return ConfidenceSession(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      language: json['language'] ?? 'fr',
      roomName: json['room_name'] ?? '',
      livekitUrl: json['livekit_url'] ?? '',
      livekitToken: json['livekit_token'] ?? '',
      participantIdentity: json['participant_identity'] ?? '',
      initialMessage: json['initial_message'] != null 
          ? ConfidenceInitialMessage.fromJson(json['initial_message'])
          : null,
      status: json['status'] ?? 'created',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'scenario_id': scenarioId,
      'language': language,
      'room_name': roomName,
      'livekit_url': livekitUrl,
      'livekit_token': livekitToken,
      'participant_identity': participantIdentity,
      'initial_message': initialMessage?.toJson(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    sessionId, userId, scenarioId, language, roomName, 
    livekitUrl, livekitToken, participantIdentity, initialMessage, 
    status, createdAt, metadata
  ];
}

/// Message initial de la session
class ConfidenceInitialMessage extends Equatable {
  final String text;
  final int timestamp;
  
  const ConfidenceInitialMessage({
    required this.text,
    required this.timestamp,
  });
  
  factory ConfidenceInitialMessage.fromJson(Map<String, dynamic> json) {
    return ConfidenceInitialMessage(
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [text, timestamp];
}

/// Scénario API depuis le backend
class ApiScenario extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final String language;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const ApiScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.language,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ApiScenario.fromJson(Map<String, dynamic> json) {
    return ApiScenario(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      durationMinutes: json['duration_minutes'] ?? 10,
      language: json['language'] ?? 'fr',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'language': language,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, title, description, category, difficulty, 
    durationMinutes, language, tags, createdAt, updatedAt
  ];
}

/// Réponse de la liste des scénarios
class ScenariosResponse extends Equatable {
  final List<ApiScenario> scenarios;
  final int total;
  final String language;
  final DateTime timestamp;
  
  const ScenariosResponse({
    required this.scenarios,
    required this.total,
    required this.language,
    required this.timestamp,
  });
  
  factory ScenariosResponse.fromJson(Map<String, dynamic> json) {
    return ScenariosResponse(
      scenarios: (json['scenarios'] as List<dynamic>? ?? [])
          .map((item) => ApiScenario.fromJson(item))
          .toList(),
      total: json['total'] ?? 0,
      language: json['language'] ?? 'fr',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarios': scenarios.map((s) => s.toJson()).toList(),
      'total': total,
      'language': language,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [scenarios, total, language, timestamp];
}

/// Rapport final de l'exercice (à implémenter côté backend)
class ConfidenceReport extends Equatable {
  final String sessionId;
  final double finalScore;
  final int totalInteractions;
  final Duration totalDuration;
  final List<String> recommendations;
  final Map<String, dynamic> detailedMetrics;
  final DateTime timestamp;
  
  const ConfidenceReport({
    required this.sessionId,
    required this.finalScore,
    required this.totalInteractions,
    required this.totalDuration,
    required this.recommendations,
    required this.detailedMetrics,
    required this.timestamp,
  });
  
  factory ConfidenceReport.fromJson(Map<String, dynamic> json) {
    return ConfidenceReport(
      sessionId: json['session_id'] ?? '',
      finalScore: (json['final_confidence_score'] ?? 0.0).toDouble(),
      totalInteractions: json['interactions'] ?? 0,
      totalDuration: Duration(seconds: (json['duration'] ?? 0).toInt()),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      detailedMetrics: json['detailed_metrics'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'final_confidence_score': finalScore,
      'interactions': totalInteractions,
      'duration': totalDuration.inSeconds,
      'recommendations': recommendations,
      'detailed_metrics': detailedMetrics,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    sessionId, finalScore, totalInteractions, totalDuration,
    recommendations, detailedMetrics, timestamp
  ];
}

/// Message de conversation pour l'interface
class ConversationMessage extends Equatable {
  final String text;
  final ConversationRole role;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  const ConversationMessage({
    required this.text,
    required this.role,
    this.metadata,
    required this.timestamp,
  });
  
  ConversationMessage.now({
    required this.text,
    required this.role,
    this.metadata,
  }) : timestamp = DateTime.now();
  
  factory ConversationMessage.fromAnalysisResult(ConfidenceAnalysisResult result) {
    return ConversationMessage(
      text: result.aiResponse,
      role: ConversationRole.assistant,
      metadata: {
        'transcription': result.transcription,
        'confidence_score': result.confidenceScore,
        'metrics': result.metrics,
      },
      timestamp: result.timestamp,
    );
  }

  @override
  List<Object?> get props => [text, role, metadata, timestamp];
}

/// Rôle dans la conversation
enum ConversationRole {
  user,
  assistant,
}

/// Statut de santé de l'API
class ApiHealthStatus extends Equatable {
  final String status;
  final String service;
  final DateTime timestamp;
  
  const ApiHealthStatus({
    required this.status,
    required this.service,
    required this.timestamp,
  });
  
  factory ApiHealthStatus.fromJson(Map<String, dynamic> json) {
    return ApiHealthStatus(
      status: json['status'] ?? 'unknown',
      service: json['service'] ?? 'eloquence-api',
      timestamp: DateTime.now(),
    );
  }

  bool get isHealthy => status == 'healthy';

  @override
  List<Object?> get props => [status, service, timestamp];
}