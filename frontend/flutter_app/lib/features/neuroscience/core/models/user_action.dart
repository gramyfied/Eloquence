import 'package:equatable/equatable.dart';
import '../../core/models/user_performance.dart'; // Remarque: le chemin d'import, car c'est un niveau au-dessus de 'core/models'

class UserAction extends Equatable {
  final String type;
  final String? exerciseType; // Utilisé dans neuroscience_engine pour construire UserPerformance
  final int? expectedDuration; // Utilisé dans neuroscience_engine

  const UserAction({
    required this.type,
    this.exerciseType,
    this.expectedDuration,
  });

  factory UserAction.fromPerformance(UserPerformance performance) {
    // Un exemple simple, peut être beaucoup plus complexe
    return UserAction(
      type: 'completed_exercise',
      exerciseType: 'generic', // Placeholder
      expectedDuration: 0, // Placeholder
    );
  }

  @override
  List<Object?> get props => [type, exerciseType, expectedDuration];
}