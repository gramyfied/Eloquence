import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../models/orator_model.dart';
import '../../services/orator_service.dart';

final navigationStateProvider = ChangeNotifierProvider<NavigationState>((ref) {
  return NavigationState();
});

enum CarouselVisibilityState {
  full(1.0),        // Navigation libre - 100% visible
  medium(0.5),      // Liste exercices - 50% visible
  subtle(0.3),      // Exercice sélectionné - 30% visible
  minimal(0.1);     // Exercice actif - 10% visible

  const CarouselVisibilityState(this.opacity);
  final double opacity;
}

class NavigationState extends ChangeNotifier {
  static final _log = Logger('NavigationState');
  
  CarouselVisibilityState _carouselState = CarouselVisibilityState.full;
  String _currentRoute = '/home';
  Orator _currentOrator = orators.first;
  bool _isAuthRoute = false;

  CarouselVisibilityState get carouselState => _carouselState;
  String get currentRoute => _currentRoute;
  Orator get currentOrator => _currentOrator;
  bool get isAuthRoute => _isAuthRoute;

  void updateCarouselState(CarouselVisibilityState newState) {
    if (_carouselState != newState) {
      _carouselState = newState;
      notifyListeners();
    }
  }

  void navigateTo(String route, [BuildContext? context, Object? arguments]) {
    _log.info('🧭 NavigationState.navigateTo called with route: $route');
    
    if (_currentRoute != route) {
      final previousRoute = _currentRoute;
      _currentRoute = route;
      
      // Déterminer si c'est une route d'authentification
      _isAuthRoute = _isAuthenticationRoute(route);
      _log.info('📍 Route transition: $previousRoute → $route (isAuthRoute: $_isAuthRoute)');

      // Mettre à jour l'état du carrousel selon la route
      CarouselVisibilityState newCarouselState;
      switch (route) {
        case '/login':
        case '/signup':
          // Routes d'authentification - masquer complètement le carrousel
          newCarouselState = CarouselVisibilityState.minimal;
          _log.info('🔐 Auth route detected - setting carousel to minimal');
          break;
        case '/home':
          newCarouselState = CarouselVisibilityState.full;
          _log.info('🏠 Home route - setting carousel to full');
          break;
        case '/exercises':
          newCarouselState = CarouselVisibilityState.medium;
          _log.info('📋 Exercises route - setting carousel to medium');
          break;
        case '/exercise_detail':
          newCarouselState = CarouselVisibilityState.subtle;
          _log.info('📖 Exercise detail route - setting carousel to subtle');
          break;
        case '/exercise_active':
          newCarouselState = CarouselVisibilityState.minimal;
          _log.info('🎯 Exercise active route - setting carousel to minimal');
          break;
        default:
          newCarouselState = CarouselVisibilityState.full;
          _log.warning('⚠️ Unknown route: $route - defaulting carousel to full');
      }

      updateCarouselState(newCarouselState);
      
      // Navigation réelle si context fourni
      if (context != null) {
        _log.info('🚀 Performing Flutter navigation to: $route');
        try {
          Navigator.pushNamed(context, route, arguments: arguments);
          _log.info('✅ Navigation successful to: $route');
        } catch (e) {
          _log.severe('❌ Navigation failed to: $route - Error: $e');
        }
      } else {
        _log.info('⏸️ Navigation state updated but no context provided for Flutter navigation');
      }
      
      notifyListeners();
    } else {
      _log.info('⚡ Same route requested: $route - skipping navigation');
    }
  }

  void updateCurrentOrator(Orator orator) {
    if (_currentOrator.id != orator.id) {
      _currentOrator = orator;
      notifyListeners();
    }
  }

  void startExercise(String exerciseId, [BuildContext? context]) {
    navigateTo('/exercise_active', context);
    // Logique spécifique au démarrage d'exercice
  }

  void endExercise([BuildContext? context]) {
    navigateTo('/exercises', context);
    // Logique spécifique à la fin d'exercice
  }

  // ======== MÉTHODES D'AUTHENTIFICATION ========
  
  /// Détermine si une route donnée est une route d'authentification
  bool _isAuthenticationRoute(String route) {
    const authRoutes = ['/login', '/signup'];
    return authRoutes.contains(route);
  }
  
  /// Navigation vers l'écran de connexion
  void navigateToLogin([BuildContext? context]) {
    _log.info('🔐 Navigating to login screen');
    navigateTo('/login', context);
  }
  
  /// Navigation vers l'écran d'inscription
  void navigateToSignup([BuildContext? context]) {
    _log.info('📝 Navigating to signup screen');
    navigateTo('/signup', context);
  }
  
  /// Navigation vers l'écran principal après authentification
  void navigateToMainApp([BuildContext? context]) {
    _log.info('🚀 Navigating to main app after authentication');
    navigateTo('/home', context);
  }
  
  /// Déconnexion et retour à l'écran de connexion
  void logout([BuildContext? context]) {
    _log.info('👋 User logout - navigating to login');
    navigateTo('/login', context);
  }
  
  /// Reset complet de l'état de navigation (utile pour la déconnexion)
  void resetNavigationState() {
    _log.info('🔄 Resetting navigation state');
    _currentRoute = '/login';
    _isAuthRoute = true;
    _carouselState = CarouselVisibilityState.minimal;
    notifyListeners();
  }
}