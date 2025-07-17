import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'confidence_models.g.dart';

// Enum pour les différents types de support texte
@HiveType(typeId: 10)
enum SupportType {
  @HiveField(0)
  fullText,
  @HiveField(1)
  fillInBlanks,
  @HiveField(2)
  guidedStructure,
  @HiveField(3)
  keywordChallenge,
  @HiveField(4)
  freeImprovisation,
}

// Modèle pour le support texte fourni à l'utilisateur
@HiveType(typeId: 11)
class TextSupport extends HiveObject {
  @HiveField(0)
  final SupportType type;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final List<String> suggestedWords; // Pour le type 'fillInBlanks'

  TextSupport({
    required this.type,
    required this.content,
    this.suggestedWords = const [],
  });
}

// Enum pour les différents types de scénarios de confiance
@HiveType(typeId: 12)
enum ConfidenceScenarioType {
  @HiveField(0)
  presentation,
  @HiveField(1)
  meeting,
  @HiveField(2)
  interview,
  @HiveField(3)
  networking,
  @HiveField(4)
  pitch,
}


extension ConfidenceScenarioTypeExtension on ConfidenceScenarioType {
  String toJson() {
    return name;
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
@HiveType(typeId: 13)
class ConfidenceAnalysis extends HiveObject {
  @HiveField(0)
  final double overallScore;
  @HiveField(1)
  final double confidenceScore;
  @HiveField(2)
  final double fluencyScore;
  @HiveField(3)
  final double clarityScore;
  @HiveField(4)
  final double energyScore;
  @HiveField(5)
  final String feedback;
  @HiveField(6)
  final int wordCount;
  @HiveField(7)
  final double speakingRate;
  @HiveField(8)
  final List<String> keywordsUsed;
  @HiveField(9)
  final String transcription;
  @HiveField(10)
  final List<String> strengths;
  @HiveField(11)
  final List<String> improvements;
  
  // Métriques spécifiques à Vosk pour exercices de confiance
  @HiveField(12)
  final double hesitationControl;
  @HiveField(13)
  final double assertiveness;
  @HiveField(14)
  final double keywordRelevance;
  @HiveField(15)
  final double speechConfidence;

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
    // Métriques Vosk avec valeurs par défaut
    this.hesitationControl = 0.0,
    this.assertiveness = 0.0,
    this.keywordRelevance = 0.0,
    this.speechConfidence = 0.0,
  });
}

// Classe pour les particules de confettis - non persistée dans Hive
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