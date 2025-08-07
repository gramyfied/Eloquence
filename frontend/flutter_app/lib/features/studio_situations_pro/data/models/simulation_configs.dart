import 'package:flutter/material.dart';
import 'simulation_models.dart';

class SimulationConfigs {
  static const List<SimulationConfig> all = [
    SimulationConfig(
      type: SimulationType.publicSpeaking, // Remplacé tvDebate
      title: 'Présentation Publique', // Titre ajusté
      description: 'Maîtrise de la scène et persuasion', // Description ajustée
      icon: Icons.mic_rounded, // Icône ajustée
      accentColor: Color(0xFF00D4FF), // EloquenceTheme.cyan
      participants: ['Public Interactif', 'Modérateur'], // Participants ajustés
      estimatedDuration: Duration(minutes: 15),
    ),
    SimulationConfig(
      type: SimulationType.jobInterview,
      title: 'Entretien d\'embauche', // Titre ajusté
      description: 'Recrutement avec RH et manager',
      icon: Icons.work_rounded, // Icône ajustée
      accentColor: Color(0xFF8B5CF6), // EloquenceTheme.violet
      participants: ['RH Recruiter', 'Manager Technique'], // Participants ajustés
      estimatedDuration: Duration(minutes: 30),
    ),
    SimulationConfig(
      type: SimulationType.salesPitch, // Remplacé salesConference
      title: 'Argumentaire de Vente', // Titre ajusté
      description: 'Pitch commercial avec prospects',
      icon: Icons.trending_up_rounded, // Icône ajustée
      accentColor: Color(0xFF4ECDC4), // EloquenceTheme.successGreen
      participants: ['Prospect Décideur', 'Prospect Technique'], // Participants ajustés
      estimatedDuration: Duration(minutes: 20),
    ),
    SimulationConfig(
      type: SimulationType.difficultConversation, // Remplacé boardMeeting
      title: 'Conversation Difficile', // Titre ajusté
      description: 'Gestion de conflit ou de feedback délicat', // Description ajustée
      icon: Icons.speaker_notes_off_rounded, // Icône ajustée
      accentColor: Color(0xFFFF5252), // EloquenceTheme.errorRed
      participants: ['Collaborateur', 'Manager Senior'], // Participants ajustés
      estimatedDuration: Duration(minutes: 25),
    ),
    SimulationConfig(
      type: SimulationType.negotiation, // Nouvelle valeur
      title: 'Négociation Complexe', // Titre ajusté
      description: 'Atteindre un accord mutuellement bénéfique', // Description ajustée
      icon: Icons.gavel_rounded, // Icône ajustée
      accentColor: Color(0xFFFFB347), // EloquenceTheme.warningOrange
      participants: ['Partie Opposée', 'Médiateur'], // Participants ajustés
      estimatedDuration: Duration(minutes: 20),
    ),
  ];
}