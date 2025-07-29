import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/confidence_boost_provider.dart';
import 'confidence_boost_rest_screen.dart';

class ConfidenceBoostMainScreen extends ConsumerWidget {
  const ConfidenceBoostMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(confidenceScenariosProvider);
    final gamificationInit = ref.watch(gamificationInitializationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Confidence - Scénarios'),
      ),
      body: gamificationInit.when(
        data: (isInitialized) {
          if (!isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text('Système de gamification indisponible'),
                  Text('L\'application fonctionne en mode dégradé'),
                ],
              ),
            );
          }
          
          return scenariosAsync.when(
            data: (scenarios) {
              return ListView.builder(
                itemCount: scenarios.length,
                itemBuilder: (context, index) {
                  final scenario = scenarios[index];
                  return ListTile(
                    title: Text(scenario.title),
                    subtitle: Text(scenario.description),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ConfidenceBoostRestScreen(
                            scenario: scenario,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation du système de gamification...'),
            ],
          ),
        ),
        error: (err, stack) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Erreur d\'initialisation'),
              Text('Redémarrez l\'application'),
            ],
          ),
        ),
      ),
    );
  }
}
