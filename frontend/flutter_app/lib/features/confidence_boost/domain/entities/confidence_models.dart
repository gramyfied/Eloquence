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
}

// Modèle pour les résultats de l'analyse de la performance
class ConfidenceAnalysis {
  final double overallScore;
  final double confidenceScore;
  final double fluencyScore;
  final double clarityScore;
  final double energyScore;
  final String feedback;

  ConfidenceAnalysis({
    required this.overallScore,
    required this.confidenceScore,
    required this.fluencyScore,
    required this.clarityScore,
    required this.energyScore,
    required this.feedback,
  });
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