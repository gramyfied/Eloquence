import 'package:flutter/material.dart';
import 'simulation_models.dart';

class SimulationConfigs {
  static const List<SimulationConfig> all = [
    // Simulations simples (1 agent)
    SimulationConfig(
      type: SimulationType.publicSpeaking,
      title: 'Présentation Publique',
      description: 'Maîtrise de la scène et persuasion',
      icon: Icons.mic_rounded,
      accentColor: Color(0xFF00D4FF), // EloquenceTheme.cyan
      participants: ['Public Interactif', 'Modérateur'],
      estimatedDuration: Duration(minutes: 15),
    ),
    SimulationConfig(
      type: SimulationType.jobInterview,
      title: 'Entretien d\'embauche',
      description: 'Recrutement avec RH et manager',
      icon: Icons.work_rounded,
      accentColor: Color(0xFF8B5CF6), // EloquenceTheme.violet
      participants: ['RH Recruiter', 'Manager Technique'],
      estimatedDuration: Duration(minutes: 30),
    ),
    SimulationConfig(
      type: SimulationType.salesPitch,
      title: 'Argumentaire de Vente',
      description: 'Pitch commercial avec prospects',
      icon: Icons.trending_up_rounded,
      accentColor: Color(0xFF4ECDC4), // EloquenceTheme.successGreen
      participants: ['Prospect Décideur', 'Prospect Technique'],
      estimatedDuration: Duration(minutes: 20),
    ),
    SimulationConfig(
      type: SimulationType.difficultConversation,
      title: 'Conversation Difficile',
      description: 'Gestion de conflit ou de feedback délicat',
      icon: Icons.speaker_notes_off_rounded,
      accentColor: Color(0xFFFF5252), // EloquenceTheme.errorRed
      participants: ['Collaborateur', 'Manager Senior'],
      estimatedDuration: Duration(minutes: 25),
    ),
    SimulationConfig(
      type: SimulationType.negotiation,
      title: 'Négociation Complexe',
      description: 'Atteindre un accord mutuellement bénéfique',
      icon: Icons.gavel_rounded,
      accentColor: Color(0xFFFFB347), // EloquenceTheme.warningOrange
      participants: ['Partie Opposée', 'Médiateur'],
      estimatedDuration: Duration(minutes: 20),
    ),
    
    // Simulations multi-agents (plusieurs agents)
    SimulationConfig(
      type: SimulationType.debatPlateau,
      title: 'Débat en Plateau TV',
      description: 'Défendre ses idées face à plusieurs interlocuteurs',
      icon: Icons.tv_rounded,
      accentColor: Color(0xFFE91E63), // EloquenceTheme.pink
      participants: ['Animateur', 'Journaliste', 'Expert'],
      estimatedDuration: Duration(minutes: 25),
    ),
    SimulationConfig(
      type: SimulationType.entretienEmbauche,
      title: 'Entretien d\'Embauche Pro',
      description: 'Entretien approfondi avec plusieurs recruteurs',
      icon: Icons.badge_rounded,
      accentColor: Color(0xFF6366F1), // EloquenceTheme.indigo
      participants: ['Manager RH', 'Expert Technique'],
      estimatedDuration: Duration(minutes: 35),
    ),
    SimulationConfig(
      type: SimulationType.reunionDirection,
      title: 'Réunion de Direction',
      description: 'Présenter un projet stratégique au comité',
      icon: Icons.meeting_room_rounded,
      accentColor: Color(0xFF14B8A6), // EloquenceTheme.teal
      participants: ['PDG', 'Directeur Financier'],
      estimatedDuration: Duration(minutes: 30),
    ),
    SimulationConfig(
      type: SimulationType.conferenceVente,
      title: 'Conférence de Vente',
      description: 'Présentation commerciale devant plusieurs décideurs',
      icon: Icons.storefront_rounded,
      accentColor: Color(0xFF10B981), // EloquenceTheme.emerald
      participants: ['Client Senior', 'Acheteur', 'Partenaire'],
      estimatedDuration: Duration(minutes: 25),
    ),
    SimulationConfig(
      type: SimulationType.conferencePublique,
      title: 'Conférence Publique',
      description: 'Intervention devant un large public avec Q&A',
      icon: Icons.campaign_rounded,
      accentColor: Color(0xFFF59E0B), // EloquenceTheme.amber
      participants: ['Modératrice', 'Expert du domaine'],
      estimatedDuration: Duration(minutes: 20),
    ),
  ];
}