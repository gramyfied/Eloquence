import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/confidence_boost_provider.dart';
import 'confidence_boost_adaptive_screen.dart';

class ConfidenceBoostMainScreen extends ConsumerWidget {
  const ConfidenceBoostMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(confidenceScenariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Confidence - Scénarios'),
      ),
      body: scenariosAsync.when(
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
                      builder: (context) => ConfidenceBoostAdaptiveScreen(
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
      ),
    );
  }
}
