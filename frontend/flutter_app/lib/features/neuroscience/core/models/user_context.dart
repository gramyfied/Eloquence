import 'package:equatable/equatable.dart';
import 'user_profile.dart'; // Importe UserProfile

enum Goal {
  generalImprovement,
  professionalPresentation,
  interview,
  // Add more goals as needed
}

enum TimeConstraint {
  high, // e.g., preparing for an exam tomorrow
  medium,
  low, // e.g., casually learning over months
}

class UserContext extends Equatable {
  final UserProfile? userProfile;
  final double? stressLevel;
  final double? fatigueLevel;
  final Goal declaredGoal;
  final TimeConstraint timeConstraint;

  const UserContext({
    this.userProfile,
    this.stressLevel,
    this.fatigueLevel,
    this.declaredGoal = Goal.generalImprovement, // Valeur par défaut
    this.timeConstraint = TimeConstraint.medium, // Valeur par défaut
  });

  bool isAtRiskOfChurn() {
    // Logique de détection de risque d'abandon
    return false;
  }

  int sessionsSinceLastReward(String rewardLevel) {
    // Logique pour obtenir le nombre de sessions depuis la dernière récompense
    return 0;
  }

  @override
  List<Object?> get props => [userProfile, stressLevel, fatigueLevel, declaredGoal, timeConstraint];
}