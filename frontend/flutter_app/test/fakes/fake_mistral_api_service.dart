import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_api_service.dart';

class FakeMistralApiService implements IMistralApiService {
  bool shouldFail = false;
  String? customResponse;

  @override
  Future<String> generateText({
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
  }) async {
    // TODO: implement generateText
    if (shouldFail) {
      throw Exception('Fake API Error');
    }

    if (customResponse != null) {
      return customResponse!;
    }

    // Retourner du contenu selon le type de prompt
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
    return 'Contenu de test généré par le fake service';
  }

  @override
  Future<Map<String, dynamic>> analyzeContent({
    required String prompt,
    int maxTokens = 800,
  }) async {
    // TODO: implement analyzeContent
    if (shouldFail) {
      throw Exception('Fake API Error');
    }
    return {
      'content_score': 0.8,
      'feedback': 'Analyse simulée: Excellente présentation ! Votre ton était confiant et votre message était clair.',
      'strengths': ['Clarté du message', 'Confiance dans le ton', 'Structure cohérente'],
      'improvements': ['Continuer la pratique régulière', 'Explorer de nouveaux sujets'],
    };
  }
  
  @override
  Map<String, dynamic> getCacheStatistics() {
    // TODO: implement getCacheStatistics
    throw UnimplementedError();
  }
  
  @override
  Future<void> preloadCommonPrompts() {
    // TODO: implement preloadCommonPrompts
    throw UnimplementedError();
  }
  
  @override
  void dispose() {
    // TODO: implement dispose
  }
  
  @override
  Future<void> clearCache() {
    // TODO: implement clearCache
    throw UnimplementedError();
  }
}