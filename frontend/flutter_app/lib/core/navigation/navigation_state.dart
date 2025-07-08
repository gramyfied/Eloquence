import 'package:flutter/material.dart';
import '../../models/orator_model.dart';
import '../../services/orator_service.dart';

enum CarouselVisibilityState {
  full(1.0),        // Navigation libre - 100% visible
  medium(0.5),      // Liste exercices - 50% visible
  subtle(0.3),      // Exercice sélectionné - 30% visible
  minimal(0.1);     // Exercice actif - 10% visible

  const CarouselVisibilityState(this.opacity);
  final double opacity;
}

class NavigationState extends ChangeNotifier {
  CarouselVisibilityState _carouselState = CarouselVisibilityState.full;
  String _currentRoute = '/home';
  Orator _currentOrator = orators.first;

  CarouselVisibilityState get carouselState => _carouselState;
  String get currentRoute => _currentRoute;
  Orator get currentOrator => _currentOrator;

  void updateCarouselState(CarouselVisibilityState newState) {
    if (_carouselState != newState) {
      _carouselState = newState;
      notifyListeners();
    }
  }

  void navigateTo(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;

      // Mettre à jour l'état du carrousel selon la route
      CarouselVisibilityState newCarouselState;
      switch (route) {
        case '/home':
          newCarouselState = CarouselVisibilityState.full;
          break;
        case '/exercises':
          newCarouselState = CarouselVisibilityState.medium;
          break;
        case '/exercise_detail':
          newCarouselState = CarouselVisibilityState.subtle;
          break;
        case '/exercise_active':
          newCarouselState = CarouselVisibilityState.minimal;
          break;
        default:
          newCarouselState = CarouselVisibilityState.full;
      }

      updateCarouselState(newCarouselState);
      // notifyListeners() is called by updateCarouselState
    }
  }

  void updateCurrentOrator(Orator orator) {
    if (_currentOrator.id != orator.id) {
      _currentOrator = orator;
      notifyListeners();
    }
  }

  void startExercise(String exerciseId) {
    navigateTo('/exercise_active');
    // Logique spécifique au démarrage d'exercice
  }

  void endExercise() {
    navigateTo('/exercises');
    // Logique spécifique à la fin d'exercice
  }
}