import 'package:equatable/equatable.dart';
import 'confidence_models.dart';

/// Représente un scénario de confiance pour l'exercice Confidence Boost Express
/// CONFORME AUX SPÉCIFICATIONS EXACTES DU PROMPT
class ConfidenceScenario extends Equatable {
  final String id;
  final String title;
  final String description;
  final String prompt;
  final ConfidenceScenarioType type;
  final int durationSeconds;
  final List<String> tips;
  final List<String> keywords;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String icon;

  const ConfidenceScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.type,
    required this.durationSeconds,
    required this.tips,
    required this.keywords,
    required this.difficulty,
    required this.icon,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        prompt,
        type,
        durationSeconds,
        tips,
        keywords,
        difficulty,
        icon,
      ];

  /// Factory pour créer les scénarios exacts spécifiés dans le prompt
  static ConfidenceScenario professional() {
    return const ConfidenceScenario(
        id: 'professional_presentation',
        title: 'Présentation Professionnelle',
        description: 'Présentez votre projet avec assurance',
        prompt: 'Présentez votre projet à des collègues ou à des supérieurs hiérarchiques.',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 180,
        tips: ['Structurez votre discours', 'Soyez clair et concis', 'Utilisez des visuels'],
        keywords: ['projet', 'résultats', 'stratégie'],
        difficulty: 'Débutant',
        icon: 'business_center',
    );
  }

  static ConfidenceScenario interview() {
    return const ConfidenceScenario(
        id: 'job_interview',
        title: 'Entretien d\'Embauche',
        description: 'Brillez lors de votre prochain entretien',
        prompt: 'Répondez à la question "Parlez-moi de vous" de manière percutante.',
        type: ConfidenceScenarioType.pitch,
        durationSeconds: 120,
        tips: ['Mettez en avant vos forces', 'Soyez authentique', 'Préparez des questions'],
        keywords: ['compétences', 'expérience', 'motivation'],
        difficulty: 'Intermédiaire',
        icon: 'work',
    );
  }

  static ConfidenceScenario publicSpeaking() {
    return const ConfidenceScenario(
        id: 'public_speaking',
        title: 'Prise de Parole Publique',
        description: 'Captivez votre audience avec confiance',
        prompt: 'Donnez un discours inspirant sur un sujet qui vous passionne.',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 300,
        tips: ['Utilisez le storytelling', 'Modulez votre voix', 'Interagissez avec le public'],
        keywords: ['passion', 'message', 'audience'],
        difficulty: 'Avancé',
        icon: 'mic',
    );
  }

  static List<ConfidenceScenario> getDefaultScenarios() {
    return [
      const ConfidenceScenario(
        id: 'team_meeting',
        title: 'Réunion d\'équipe',
        description: 'Pratiquez votre discours pour une réunion avec vos collègues.',
        prompt: 'Présentez brièvement un projet sur lequel vous travaillez actuellement à votre équipe. Expliquez les objectifs principaux, les défis rencontrés et les prochaines étapes prévues. Vous avez 3 minutes.',
        type: ConfidenceScenarioType.meeting,
        durationSeconds: 180,
        difficulty: 'beginner',
        icon: '👥',
        tips: [
          'Structurez votre présentation en 3 parties',
          'Utilisez des exemples concrets',
          'Maintenez un contact visuel',
          'Parlez avec assurance'
        ],
        keywords: ['projet', 'objectifs', 'défis', 'étapes', 'équipe'],
      ),
      
      const ConfidenceScenario(
        id: 'client_presentation',
        title: 'Présentation client',
        description: 'Présentez une solution à un client potentiel.',
        prompt: 'Vous présentez une solution innovante à un client potentiel. Expliquez clairement le problème que vous résolvez, votre solution unique et les bénéfices concrets pour leur entreprise. Soyez persuasif et professionnel.',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 240,
        difficulty: 'intermediate',
        icon: '💼',
        tips: [
          'Identifiez clairement le problème',
          'Présentez votre solution unique',
          'Quantifiez les bénéfices',
          'Soyez persuasif mais authentique'
        ],
        keywords: ['solution', 'problème', 'bénéfices', 'innovation', 'entreprise'],
      ),
      
      const ConfidenceScenario(
        id: 'elevator_pitch',
        title: 'Elevator Pitch',
        description: 'Présentez votre startup en 90 secondes.',
        prompt: 'Vous êtes dans un ascenseur avec un investisseur potentiel. Présentez votre startup de manière concise : votre vision, le problème que vous résolvez, votre solution, le marché et pourquoi ils devraient investir. Vous avez 90 secondes maximum.',
        type: ConfidenceScenarioType.pitch,
        durationSeconds: 90,
        difficulty: 'advanced',
        icon: '🚀',
        tips: [
          'Soyez concis et impactant',
          'Commencez par le problème',
          'Présentez votre solution unique',
          'Terminez par un appel à l\'action'
        ],
        keywords: ['startup', 'vision', 'marché', 'investissement', 'solution'],
      ),
      
      const ConfidenceScenario(
        id: 'team_motivation',
        title: 'Motivation d\'équipe',
        description: 'Motivez votre équipe avant un projet important.',
        prompt: 'Votre équipe commence un projet crucial pour l\'entreprise. Motivez-les en expliquant l\'importance du projet, les objectifs à atteindre et pourquoi vous avez confiance en leur capacité à réussir. Inspirez-les !',
        type: ConfidenceScenarioType.meeting,
        durationSeconds: 150,
        difficulty: 'intermediate',
        icon: '⚡',
        tips: [
          'Exprimez votre confiance en l\'équipe',
          'Expliquez l\'importance du projet',
          'Fixez des objectifs clairs',
          'Inspirez par votre énergie'
        ],
        keywords: ['motivation', 'projet', 'objectifs', 'confiance', 'réussir'],
      ),
      
      const ConfidenceScenario(
        id: 'product_demo',
        title: 'Démonstration produit',
        description: 'Présentez les fonctionnalités de votre produit.',
        prompt: 'Présentez votre produit à des prospects. Expliquez ses fonctionnalités principales, ses avantages uniques et comment il peut résoudre leurs problèmes spécifiques. Rendez votre présentation engageante et mémorable.',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 200,
        difficulty: 'intermediate',
        icon: '📱',
        tips: [
          'Montrez les fonctionnalités clés',
          'Mettez en avant les avantages',
          'Utilisez des cas d\'usage concrets',
          'Rendez la démo interactive'
        ],
        keywords: ['produit', 'fonctionnalités', 'avantages', 'problèmes', 'solution'],
      ),
    ];
  }
}
