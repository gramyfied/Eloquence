import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/repositories/confidence_repository.dart';
import '../datasources/confidence_local_datasource.dart';
import '../datasources/confidence_remote_datasource.dart';

class ConfidenceRepositoryImpl implements ConfidenceRepository {
  final ConfidenceLocalDataSource localDataSource;
  final ConfidenceRemoteDataSource remoteDataSource;

  ConfidenceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<ConfidenceScenario>> getScenarios() async {
    try {
      final scenarios = await remoteDataSource.getScenarios();
      if (scenarios.isNotEmpty) {
        await localDataSource.cacheScenarios(scenarios);
        return scenarios;
      }
      return await localDataSource.getCachedScenarios();
    } catch (e) {
      return await localDataSource.getCachedScenarios();
    }
  }

  @override
  Future<ConfidenceScenario?> getScenarioById(String id) async {
    final scenarios = await getScenarios();
    try {
      return scenarios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ConfidenceScenario> getRandomScenario() async {
    final scenarios = await getScenarios();
    if (scenarios.isEmpty) {
      throw Exception('Aucun scénario disponible');
    }
    final random = Random();
    return scenarios[random.nextInt(scenarios.length)];
  }

  @override
  Future<ConfidenceAnalysis> analyzePerformance({
    required String audioFilePath,
    required ConfidenceScenario scenario,
    required Duration recordingDuration,
  }) async {
    // La logique d'analyse est maintenant déléguée à la source de données distante.
    // Le repository agit comme un simple proxy.
    return await remoteDataSource.analyzeAudio(
      audioFilePath: audioFilePath,
      scenario: scenario,
    );
  }
}