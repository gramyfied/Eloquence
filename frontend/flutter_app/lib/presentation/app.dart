import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../screens/home_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/exercise_active_screen.dart';
import '../presentation/screens/scenario/scenario_screen.dart';
import '../screens/profile_screen.dart';
import '../features/confidence_boost/presentation/screens/confidence_boost_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NavigationState(),
      child: MaterialApp(
        title: 'Eloquence',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1A1F2E),
          fontFamily: 'Inter',
        ),
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/exercises': (context) => const ExercisesScreen(),
          '/scenarios': (context) => const ScenarioScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/exercise_detail') {
            final args = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) {
                return ExerciseDetailScreen(exerciseId: args);
              },
            );
          }
          if (settings.name == '/exercise_active') {
            final args = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) {
                return ExerciseActiveScreen(exerciseId: args);
              },
            );
          }
          if (settings.name == '/confidence_boost') {
            final args = settings.arguments as String; // userId
            return MaterialPageRoute(
              builder: (context) {
                return ConfidenceBoostScreen(userId: args);
              },
            );
          }
          return null;
        },
      ),
    );
  }
}
