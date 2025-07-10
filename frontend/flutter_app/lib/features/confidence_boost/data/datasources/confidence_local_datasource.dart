import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
abstract class ConfidenceLocalDataSource {
  Future<void> cacheScenarios(List<ConfidenceScenario> scenarios);
  Future<List<ConfidenceScenario>> getCachedScenarios();
  Future<void> clearScenariosCache();
}

class ConfidenceLocalDataSourceImpl implements ConfidenceLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String SCENARIOS_KEY = 'confidence_scenarios';

  ConfidenceLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheScenarios(List<ConfidenceScenario> scenarios) async {
    // Cette méthode de sérialisation manuelle sera remplacée par Hive pour les objets complexes.
    // Pour les scénarios, qui sont moins dynamiques, SharedPreferences reste acceptable.
    final scenariosJson = scenarios.map((s) => _scenarioToJson(s)).toList();
    await sharedPreferences.setString(
      SCENARIOS_KEY,
      json.encode(scenariosJson),
    );
  }

  @override
  Future<List<ConfidenceScenario>> getCachedScenarios() async {
    final scenariosString = sharedPreferences.getString(SCENARIOS_KEY);
    if (scenariosString == null) {
      return _getDefaultScenarios();
    }
    
    try {
      final List<dynamic> scenariosJson = json.decode(scenariosString);
      return scenariosJson.map((json) => _scenarioFromJson(json)).toList();
    } catch (e) {
      return _getDefaultScenarios();
    }
  }

  @override
  Future<void> clearScenariosCache() async {
    await sharedPreferences.remove(SCENARIOS_KEY);
  }

  // Méthodes de conversion JSON pour ConfidenceScenario
  Map<String, dynamic> _scenarioToJson(ConfidenceScenario scenario) {
    return {
      'id': scenario.id,
      'title': scenario.title,
      'description': scenario.description,
      'type': scenario.type.toString(), // Utiliser toString pour l'enum
      'difficulty': scenario.difficulty,
      'keywords': scenario.keywords,
      'tips': scenario.tips,
      'icon': scenario.icon,
    };
  }

  ConfidenceScenario _scenarioFromJson(Map<String, dynamic> json) {
    return ConfidenceScenario(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      prompt: json['prompt'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 60,
      type: ConfidenceScenarioType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ConfidenceScenarioType.presentation,
      ),
      difficulty: json['difficulty'] ?? 'intermediate',
      keywords: List<String>.from(json['keywords']),
      tips: List<String>.from(json['tips']),
      icon: json['icon'] ?? '🎯',
    );
  }

  List<ConfidenceScenario> _getDefaultScenarios() {
    // Re-création de la liste par défaut pour maintenir la fonctionnalité
    return [
      ConfidenceScenario(
        id: '1',
        title: 'Présentation d\'équipe',
        description: 'Présentez les résultats de votre dernier projet à votre équipe.',
        prompt: 'Commencez par résumer l\'objectif du projet. Présentez ensuite les 3 résultats clés que vous avez obtenus. Terminez en proposant les prochaines étapes.',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 180,
        difficulty: 'intermediate',
        keywords: ['résultats', 'projet', 'équipe', 'prochaines étapes'],
        tips: ['Parlez lentement', 'Regardez vos interlocuteurs', 'Utilisez des gestes'],
        icon: '🗣️',
      ),
    ];
  }
}