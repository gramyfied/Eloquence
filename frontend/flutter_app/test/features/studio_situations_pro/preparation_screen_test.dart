import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eloquence_2_0/features/studio_situations_pro/presentation/screens/preparation_screen.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_models.dart';

void main() {
  group('PreparationScreen wizard', () {
    testWidgets('flow enables/disables next button correctly and navigates steps', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PreparationScreen(simulationType: SimulationType.debatPlateau),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Objectif & Identité - saisir un nom pour garantir l'activation
      expect(find.text('Objectif & Identité'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Participant');
      await tester.pump();
      var nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Suivant'));
      expect(nextButton.onPressed != null, isTrue);

      // Go to Step 1
      await tester.tap(find.widgetWithText(ElevatedButton, 'Suivant'));
      await tester.pumpAndSettle();

      // Step 1: Sujet - no subject yet => next disabled
      expect(find.text('Sujet'), findsOneWidget);
      nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Suivant'));
      expect(nextButton.onPressed == null, isTrue);

      // Enter a subject
      await tester.enterText(find.byType(TextField).first, 'Intelligence artificielle et emploi');
      await tester.pump();
      nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Suivant'));
      expect(nextButton.onPressed != null, isTrue);

      // Go to Step 2 (Difficulté & Durée)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Difficulté & Durée'), findsOneWidget);

      // Next should be enabled by default on this step
      nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Suivant'));
      expect(nextButton.onPressed != null, isTrue);

      // Go to Step 3 (Récapitulatif)
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();
      expect(find.text('Récapitulatif'), findsOneWidget);

      // Final button should read "Commencer la simulation" and be enabled
      expect(find.text('Commencer la simulation'), findsOneWidget);
      final startButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(startButton.onPressed != null, isTrue);

      // Note: we do not tap the final button to avoid needing a GoRouter setup in this unit test.
    });
  });
}


