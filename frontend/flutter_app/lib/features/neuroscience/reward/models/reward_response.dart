import 'package:equatable/equatable.dart';

import '../../core/models/user_context.dart';
import '../../core/models/user_performance.dart';
import 'reward.dart';

class RewardResponse extends Equatable {
  final Reward reward;
  final UserContext context;
  final UserPerformance performance;

  const RewardResponse({
    required this.reward,
    required this.context,
    required this.performance,
  });

  @override
  List<Object?> get props => [reward, context, performance];
}