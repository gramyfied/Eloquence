/// Modèles pour les métriques et états de conversation

/// Métriques de conversation en temps réel
class ConversationMetrics {
  final double confidenceScore;
  final double speechRate;
  final double volumeLevel;
  final int pauseCount;
  final double averagePauseLength;
  final Map<String, dynamic> prosodyMetrics;
  final DateTime timestamp;

  const ConversationMetrics({
    required this.confidenceScore,
    required this.speechRate,
    required this.volumeLevel,
    required this.pauseCount,
    required this.averagePauseLength,
    required this.prosodyMetrics,
    required this.timestamp,
  });

  factory ConversationMetrics.empty() {
    return ConversationMetrics(
      confidenceScore: 0.0,
      speechRate: 0.0,
      volumeLevel: 0.0,
      pauseCount: 0,
      averagePauseLength: 0.0,
      prosodyMetrics: {},
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confidenceScore': confidenceScore,
      'speechRate': speechRate,
      'volumeLevel': volumeLevel,
      'pauseCount': pauseCount,
      'averagePauseLength': averagePauseLength,
      'prosodyMetrics': prosodyMetrics,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversationMetrics.fromJson(Map<String, dynamic> json) {
    return ConversationMetrics(
      confidenceScore: json['confidenceScore']?.toDouble() ?? 0.0,
      speechRate: json['speechRate']?.toDouble() ?? 0.0,
      volumeLevel: json['volumeLevel']?.toDouble() ?? 0.0,
      pauseCount: json['pauseCount'] ?? 0,
      averagePauseLength: json['averagePauseLength']?.toDouble() ?? 0.0,
      prosodyMetrics: Map<String, dynamic>.from(json['prosodyMetrics'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// États possibles de la conversation
enum ConversationState {
  idle,
  listening,
  processing,
  responding,
  paused,
  completed,
  error;

  String get displayName {
    switch (this) {
      case ConversationState.idle:
        return 'En attente';
      case ConversationState.listening:
        return 'Écoute';
      case ConversationState.processing:
        return 'Traitement';
      case ConversationState.responding:
        return 'Réponse';
      case ConversationState.paused:
        return 'En pause';
      case ConversationState.completed:
        return 'Terminé';
      case ConversationState.error:
        return 'Erreur';
    }
  }

  bool get isActive {
    return this == ConversationState.listening || 
           this == ConversationState.processing || 
           this == ConversationState.responding;
  }
}
