import 'package:flutter/material.dart';

enum SimulationType {
  // Simulations originales
  jobInterview,
  salesPitch,
  publicSpeaking,
  difficultConversation,
  negotiation,
  
  // Nouvelles simulations multi-agents
  debatPlateau,
  entretienEmbauche,
  reunionDirection,
  conferenceVente,
  conferencePublique,
}

extension SimulationTypeExtension on SimulationType {
  String toDisplayString() {
    switch (this) {
      case SimulationType.jobInterview:
        return 'Entretien d\'embauche';
      case SimulationType.salesPitch:
        return 'Argumentaire de vente';
      case SimulationType.publicSpeaking:
        return 'Prise de parole en public';
      case SimulationType.difficultConversation:
        return 'Conversation difficile';
      case SimulationType.negotiation:
        return 'Négociation';
      
      // Nouvelles simulations multi-agents
      case SimulationType.debatPlateau:
        return 'Débat en Plateau TV';
      case SimulationType.entretienEmbauche:
        return 'Entretien d\'Embauche Pro';
      case SimulationType.reunionDirection:
        return 'Réunion de Direction';
      case SimulationType.conferenceVente:
        return 'Conférence de Vente';
      case SimulationType.conferencePublique:
        return 'Conférence Publique';
    }
  }

  String toRouteString() {
    return name; // Utilise le nom de l'enum ('jobInterview' etc.)
  }

  static SimulationType fromRouteString(String routeString) {
    return SimulationType.values.firstWhere(
      (e) => e.name == routeString,
      orElse: () => SimulationType.jobInterview, // Fallback
    );
  }
  
  bool get isMultiAgent {
    return [
      SimulationType.debatPlateau,
      SimulationType.entretienEmbauche,
      SimulationType.reunionDirection,
      SimulationType.conferenceVente,
      SimulationType.conferencePublique,
    ].contains(this);
  }
  
  IconData get icon {
    switch (this) {
      case SimulationType.jobInterview:
      case SimulationType.entretienEmbauche:
        return Icons.work_outline;
      case SimulationType.salesPitch:
      case SimulationType.conferenceVente:
        return Icons.sell_outlined;
      case SimulationType.publicSpeaking:
      case SimulationType.conferencePublique:
        return Icons.campaign_outlined;
      case SimulationType.difficultConversation:
        return Icons.psychology_outlined;
      case SimulationType.negotiation:
        return Icons.handshake_outlined;
      case SimulationType.debatPlateau:
        return Icons.tv_outlined;
      case SimulationType.reunionDirection:
        return Icons.meeting_room_outlined;
    }
  }
  
  Color get accentColor {
    switch (this) {
      case SimulationType.jobInterview:
      case SimulationType.entretienEmbauche:
        return Colors.blue;
      case SimulationType.salesPitch:
      case SimulationType.conferenceVente:
        return Colors.green;
      case SimulationType.publicSpeaking:
      case SimulationType.conferencePublique:
        return Colors.purple;
      case SimulationType.difficultConversation:
        return Colors.orange;
      case SimulationType.negotiation:
        return Colors.teal;
      case SimulationType.debatPlateau:
        return Colors.red;
      case SimulationType.reunionDirection:
        return Colors.indigo;
    }
  }
}

class SimulationConfig {
  final SimulationType type;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> participants;
  final Duration estimatedDuration;
  final bool isMultiAgent;

  const SimulationConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.participants,
    required this.estimatedDuration,
    this.isMultiAgent = false,
  });
}

class SimulationMetrics {
  final double confidence;
  final int speechPace; // mots par minute
  final double voiceEnergy;
  final double clarity;
  final DateTime timestamp;

  const SimulationMetrics({
    required this.confidence,
    required this.speechPace,
    required this.voiceEnergy,
    required this.clarity,
    required this.timestamp,
  });
}