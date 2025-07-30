import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'confidence_models.dart';

part 'confidence_scenario.g.dart';

/// Représente un scénario de confiance pour l'exercice Confidence Boost Express
/// CONFORME AUX SPÉCIFICATIONS EXACTES DU PROMPT
@HiveType(typeId: 21)
class ConfidenceScenario extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String prompt;
  @HiveField(4)
  final ConfidenceScenarioType type;
  @HiveField(5)
  final int durationSeconds;
  @HiveField(6)
  final List<String> tips;
  @HiveField(7)
  final List<String> keywords;
  @HiveField(8)
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  @HiveField(9)
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
  List<Object?> get props => [id, title, description, prompt, type, durationSeconds, tips, keywords, difficulty, icon];

  // Ajout du constructeur const
  const ConfidenceScenario.professional()
      : id = 'professional_presentation',
        title = 'Présentation Professionnelle',
        description = 'Présentez votre projet avec assurance',
        prompt =
            'Présentez votre projet à des collègues ou à des supérieurs hiérarchiques.',
        type = ConfidenceScenarioType.presentation,
        durationSeconds = 180,
        tips = const [
          'Structurez votre discours',
          'Soyez clair et concis',
          'Utilisez des visuels'
        ],
        keywords = const ['projet', 'résultats', 'stratégie'],
        difficulty = 'Débutant',
        icon = 'business_center';

  const ConfidenceScenario.interview()
      : id = 'job_interview',
        title = 'Entretien d\'Embauche',
        description = 'Brillez lors de votre prochain entretien',
        prompt = 'Répondez à la question "Parlez-moi de vous" de manière percutante.',
        type = ConfidenceScenarioType.pitch,
        durationSeconds = 120,
        tips = const [
          'Mettez en avant vos forces',
          'Soyez authentique',
          'Préparez des questions'
        ],
        keywords = const ['compétences', 'expérience', 'motivation'],
        difficulty = 'Intermédiaire',
        icon = 'work';

  const ConfidenceScenario.publicSpeaking()
      : id = 'public_speaking',
        title = 'Prise de Parole Publique',
        description = 'Captivez votre audience avec confiance',
        prompt = 'Donnez un discours inspirant sur un sujet qui vous passionne.',
        type = ConfidenceScenarioType.presentation,
        durationSeconds = 300,
        tips = const [
          'Utilisez le storytelling',
          'Modulez votre voix',
          'Interagissez avec le public'
        ],
        keywords = const ['passion', 'message', 'audience'],
        difficulty = 'Avancé',
        icon = 'mic';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prompt': prompt,
      'type': type.name,
      'durationSeconds': durationSeconds,
      'tips': tips,
      'keywords': keywords,
      'difficulty': difficulty,
      'icon': icon,
    };
  }

  factory ConfidenceScenario.fromJson(Map<String, dynamic> json) {
    return ConfidenceScenario(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      prompt: json['prompt'] ?? '',
      type: ConfidenceScenarioType.values.firstWhere((e) => e.name == json['type'], orElse: () => ConfidenceScenarioType.presentation),
      durationSeconds: json['durationSeconds'] ?? 180,
      tips: List<String>.from(json['tips'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      difficulty: json['difficulty'] ?? 'beginner',
      icon: json['icon'] ?? '👥',
    );
  }


  static List<ConfidenceScenario> getDefaultScenarios() {
    return const [
      ConfidenceScenario(
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
      ConfidenceScenario(
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
      ConfidenceScenario(
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
      ConfidenceScenario(
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
      ConfidenceScenario(
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
