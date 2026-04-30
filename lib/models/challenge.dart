enum GoalType { workouts, minutes }

GoalType goalTypeFrom(String s) =>
    s == 'minutes' ? GoalType.minutes : GoalType.workouts;

String goalTypeToString(GoalType g) =>
    g == GoalType.minutes ? 'minutes' : 'workouts';

/// One challenge per group. Every member shares the same goal target and
/// the same per-week stake.
class Challenge {
  Challenge({
    required this.id,
    required this.groupId,
    required this.goalType,
    required this.goalTarget,
    required this.deductionX,
  });

  final String id;
  final String groupId;
  final GoalType goalType;
  final int goalTarget;
  final int deductionX;

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        goalType: goalTypeFrom(map['goal_type'] as String),
        goalTarget: map['goal_target'] as int,
        deductionX: map['deduction_x'] as int,
      );
}
