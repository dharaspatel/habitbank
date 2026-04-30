enum GoalType { workouts, minutes }

GoalType goalTypeFrom(String s) =>
    s == 'minutes' ? GoalType.minutes : GoalType.workouts;

String goalTypeToString(GoalType g) =>
    g == GoalType.minutes ? 'minutes' : 'workouts';

/// One challenge per group. Every member shares the same goal target and
/// the same per-week stake (stored in cents, e.g. 100 = $1.00).
class Challenge {
  Challenge({
    required this.id,
    required this.groupId,
    required this.goalType,
    required this.goalTarget,
    required this.stakeCents,
  });

  final String id;
  final String groupId;
  final GoalType goalType;
  final int goalTarget;
  final int stakeCents;

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        goalType: goalTypeFrom(map['goal_type'] as String),
        goalTarget: map['goal_target'] as int,
        stakeCents: (map['stake_cents'] as num?)?.toInt() ?? 0,
      );
}
