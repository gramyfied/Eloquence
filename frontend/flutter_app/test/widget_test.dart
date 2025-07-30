// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eloquence_2_0/presentation/app.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';

void main() {
  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Fournir les Mocks pour les providers globaux
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );

    // Vérifier qu'un widget de base (comme le splash screen ou le login) s'affiche.
    // Cette assertion dépend de votre widget initial.
    // Par exemple, si vous avez un CircularProgressIndicator sur le splash :
    expect(find.byType(App), findsOneWidget);
  });
}
