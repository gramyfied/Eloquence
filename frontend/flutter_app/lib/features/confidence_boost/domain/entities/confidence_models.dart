import 'package:flutter/material.dart';

// Enum pour les différents types de support texte
enum SupportType {
  fullText,
  fillInBlanks,
  guidedStructure,
  keywordChallenge,
  freeImprovisation,
}

// Modèle pour le support texte fourni à l'utilisateur
class TextSupport {
  final SupportType type;
  final String content;
  final List<String> suggestedWords; // Pour le type 'fillInBlanks'

  TextSupport({
    required this.type,
    required this.content,
    this.suggestedWords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'content': content,
      'suggestedWords': suggestedWords,
    };
  }

  factory TextSupport.fromJson(Map<String, dynamic> json) {
    return TextSupport(
      type: SupportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SupportType.fullText,
      ),
      content: json['content'] ?? '',
      suggestedWords: List<String>.from(json['suggestedWords'] ?? []),
    );
  }
}

// Enum pour les différents types de scénarios de confiance
enum ConfidenceScenarioType {
  presentation,
  meeting,
  interview,
  networking,
  pitch,
  // Ajoutez d'autres types si nécessaire
}


extension ConfidenceScenarioTypeExtension on ConfidenceScenarioType {
  String toJson() {
    switch (this) {
      case ConfidenceScenarioType.presentation:
        return 'presentation';
      case ConfidenceScenarioType.meeting:
        return 'meeting';
      case ConfidenceScenarioType.interview:
        return 'interview';
      case ConfidenceScenarioType.networking:
        return 'networking';
      case ConfidenceScenarioType.pitch:
        return 'pitch';
      default:
        return 'presentation';
    }
  }

  static ConfidenceScenarioType fromJson(String json) {
    switch (json) {
      case 'presentation':
        return ConfidenceScenarioType.presentation;
      case 'meeting':
        return ConfidenceScenarioType.meeting;
      case 'interview':
        return ConfidenceScenarioType.interview;
      case 'networking':
        return ConfidenceScenarioType.networking;
      case 'pitch':
        return ConfidenceScenarioType.pitch;
      default:
        return ConfidenceScenarioType.presentation;
    }
  }

  String get displayName {
    switch (this) {
      case ConfidenceScenarioType.presentation:
        return 'Présentation';
      case ConfidenceScenarioType.meeting:
        return 'Réunion';
      case ConfidenceScenarioType.interview:
        return 'Entretien';
      case ConfidenceScenarioType.networking:
        return 'Réseautage';
      case ConfidenceScenarioType.pitch:
        return 'Pitch';
    }
  }

  String get icon {
    switch (this) {
      case ConfidenceScenarioType.presentation:
        return '🗣️';
      case ConfidenceScenarioType.meeting:
        return '👥';
      case ConfidenceScenarioType.interview:
        return '💼';
      case ConfidenceScenarioType.networking:
        return '🤝';
      case ConfidenceScenarioType.pitch:
        return '🚀';
    }
  }
}

// Modèle pour les résultats de l'analyse de la performance
class ConfidenceAnalysis {
  final double overallScore;
  final double confidenceScore;
  final double fluencyScore;
  final double clarityScore;
  final double energyScore;
  final String feedback;
  final int wordCount;
  final double speakingRate;
  final List<String> keywordsUsed;
  final String transcription;
  final List<String> strengths;
  final List<String> improvements;

  ConfidenceAnalysis({
    required this.overallScore,
    required this.confidenceScore,
    required this.fluencyScore,
    required this.clarityScore,
    required this.energyScore,
    required this.feedback,
    this.wordCount = 0,
    this.speakingRate = 0.0,
    this.keywordsUsed = const [],
    this.transcription = '',
    this.strengths = const [],
    this.improvements = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'confidenceScore': confidenceScore,
      'fluencyScore': fluencyScore,
      'clarityScore': clarityScore,
      'energyScore': energyScore,
      'feedback': feedback,
      'wordCount': wordCount,
      'speakingRate': speakingRate,
      'keywordsUsed': keywordsUsed,
      'transcription': transcription,
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  factory ConfidenceAnalysis.fromJson(Map<String, dynamic> json) {
    return ConfidenceAnalysis(
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      fluencyScore: (json['fluencyScore'] ?? 0.0).toDouble(),
      clarityScore: (json['clarityScore'] ?? 0.0).toDouble(),
      energyScore: (json['energyScore'] ?? 0.0).toDouble(),
      feedback: json['feedback'] ?? '',
      wordCount: json['wordCount'] ?? 0,
      speakingRate: (json['speakingRate'] ?? 0.0).toDouble(),
      keywordsUsed: List<String>.from(json['keywordsUsed'] ?? []),
      transcription: json['transcription'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
    );
  }
}

// Classe pour les particules de confettis
class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocity;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double deltaTime) {
    y += velocity * deltaTime;
    rotation += rotationSpeed * deltaTime;
  }
}