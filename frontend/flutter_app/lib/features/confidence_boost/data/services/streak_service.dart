import '../../data/repositories/gamification_repository.dart';
import '../../domain/entities/gamification_models.dart';

class StreakService {
  final GamificationRepository _repository;

  StreakService(this._repository);

  Future<StreakInfo> updateStreak(String userId) async {
    final profile = await _repository.getUserProfile(userId);
    final now = DateTime.now();
    final lastSession = profile.lastSessionDate;

    final difference = now.difference(lastSession).inDays;
    bool streakBroken = false;
    bool newRecord = false;
    int newStreak = profile.currentStreak;

    if (difference == 1) {
      // Streak continue
      newStreak++;
    } else if (difference > 1) {
      // Streak brisé
      newStreak = 1;
      streakBroken = true;
    }
    // Si difference == 0, c'est le même jour, on ne fait rien.

    int newLongestStreak = profile.longestStreak;
    if (newStreak > profile.longestStreak) {
      newLongestStreak = newStreak;
      newRecord = true;
    }

    final updatedProfile = profile.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastSessionDate: now,
    );

    await _repository.updateUserProfile(updatedProfile);

    return StreakInfo(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      streakBroken: streakBroken,
      newRecord: newRecord,
    );
  }
}