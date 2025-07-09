import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../screens/home_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/exercise_active_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../features/confidence_boost/presentation/screens/confidence_boost_main_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/widgets/auth_wrapper.dart'; // Import AuthWrapper

class App extends StatelessWidget {
  static final _log = Logger('App');
  
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _log.info('🚀 Building Eloquence App with MaterialApp + AuthWrapper integration');
    
    return MaterialApp(
      title: 'Eloquence',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1F2E),
        fontFamily: 'Inter',
      ),
      home: const AuthWrapper(), // AuthWrapper décide d'afficher l'auth ou l'app principale
      routes: {
        // Routes d'authentification
        '/login': (context) {
          _log.info('🔐 Loading LoginScreen');
          return const LoginScreen();
        },
        '/signup': (context) {
          _log.info('📝 Loading SignUpScreen');
          return const SignUpScreen();
        },
        // Routes principales de l'application
        '/home': (context) {
          _log.info('🏠 Loading HomeScreen');
          return const HomeScreen();
        },
        '/exercises': (context) {
          _log.info('📋 Loading ExercisesScreen');
          return const ExercisesScreen();
        },
        '/scenarios': (context) {
          _log.info('🎭 Loading ScenariosScreen (redirect to ExercisesScreen)');
          return const ExercisesScreen(); // Temporairement, rediriger vers ExercisesScreen
        },
        '/profile': (context) {
          _log.info('👤 Loading ProfileScreen');
          return const ProfileScreen();
        },
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
          return MaterialPageRoute(
            builder: (context) {
              return const ConfidenceBoostMainScreen();
            },
          );
        }
        return null;
      },
    );
  }
}
