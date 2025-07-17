import 'package:mockito/mockito.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_api_service.dart';

class MockMistralApiService extends Mock implements MistralApiService {
  @override
  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double? temperature,
  }) async {
    // Retourner du contenu de test selon le type de prompt
    if (prompt.contains('TÂCHE: Génère un discours complet')) {
      return '''Mesdames et messieurs, je suis ravi de vous présenter aujourd'hui un projet innovant qui transformera notre approche. Cette initiative représente une opportunité unique de créer un impact positif et durable dans notre secteur d'activité.

Permettez-moi de vous expliquer les enjeux principaux et les bénéfices concrets de cette démarche révolutionnaire. Grâce à une méthodologie rigoureuse et à l'engagement de toute l'équipe, nous avons développé une solution qui répond parfaitement aux défis actuels du marché.

En conclusion, je suis convaincu que ce projet apportera une valeur ajoutée significative et contribuera à notre succès collectif à long terme.''';
    }
    
    if (prompt.contains('TÂCHE: Génère un texte à trous')) {
      return '''Bonjour à tous, je suis [BLANK] de vous présenter les résultats de notre [BLANK] trimestre. Malgré quelques [BLANK] rencontrés, nous avons atteint [BLANK]% de nos objectifs grâce à [BLANK] et à l'engagement remarquable de toute l'équipe. Ces [BLANK] nous permettent d'envisager l'avenir avec [BLANK].''';
    }
    
    if (prompt.contains('TÂCHE: Génère une structure guidée')) {
      return '''1. Introduction et contexte
   - Présentation personnelle et crédibilité
   - Annonce du plan de présentation
   - Transition: "Commençons par examiner..."

2. Développement des points clés
   - Analyse de la situation actuelle
   - Présentation des solutions
   - Transition: "Pour conclure..."

3. Conclusion et prochaines étapes
   - Synthèse des points essentiels
   - Appel à l'action''';
    }
    
    if (prompt.contains('TÂCHE: Sélectionne 6-8 mots-clés')) {
      return 'innovation, performance, collaboration, excellence, impact, transformation, stratégie, résultats';
    }
    
    if (prompt.contains('TÂCHE: Génère des conseils de coaching')) {
      return '''• Restez authentique et naturel dans votre expression
• Adaptez votre discours à votre audience en temps réel
• Utilisez des exemples concrets et des anecdotes personnelles
• Maintenez un contact visuel régulier avec l'audience
• Gérez votre respiration pour contrôler le stress''';
    }
    
    // Fallback par défaut
    return 'Contenu de test généré par le mock';
  }
}