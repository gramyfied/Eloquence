import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mistral_api_service.dart';

/// Provider pour le service API Mistral
/// 
/// Ce provider fournit une instance du service Mistral pour la génération
/// de contenus IA personnalisés dans les exercices de confiance.
final mistralApiServiceProvider = Provider<IMistralApiService>((ref) {
  return MistralApiService();
});