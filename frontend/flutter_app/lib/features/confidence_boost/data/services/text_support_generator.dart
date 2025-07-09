import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';

class TextSupportGenerator {
  Future<TextSupport> generateSupport({
    required ConfidenceScenario scenario,
    required SupportType type,
    required String difficulty,
  }) async {
    // Logique de génération de texte factice pour l'instant
    await Future.delayed(const Duration(milliseconds: 500));
    return TextSupport(
      type: type,
      content: 'Voici un texte généré pour le scénario "${scenario.title}".',
      suggestedWords: ['confiance', 'impact', 'présentation'],
    );
  }
}