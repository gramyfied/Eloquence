import 'package:hive/hive.dart';
import 'confidence_models.dart';
import 'confidence_scenario.dart';
import 'gamification_models.dart';

part 'confidence_session.g.dart';

@HiveType(typeId: 15)
class SessionRecord extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final ConfidenceAnalysis analysis;
  @HiveField(2)
  final ConfidenceScenario scenario;
  @HiveField(3)
  final TextSupport textSupport;
  @HiveField(4)
  final int earnedXP;
  @HiveField(5)
  final List<Badge> newBadges;
  @HiveField(6)
  final DateTime timestamp;
  @HiveField(7)
  final Duration sessionDuration;

  SessionRecord({
    required this.userId,
    required this.analysis,
    required this.scenario,
    required this.textSupport,
    required this.earnedXP,
    required this.newBadges,
    required this.timestamp,
    required this.sessionDuration,
  });
}
