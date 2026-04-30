enum GoalType { workouts, minutes }

GoalType goalTypeFrom(String s) =>
    s == 'minutes' ? GoalType.minutes : GoalType.workouts;

String goalTypeToString(GoalType g) =>
    g == GoalType.minutes ? 'minutes' : 'workouts';

class Challenge {
  Challenge({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.goalType,
    required this.goalTarget,
    required this.deductionX,
  });

  final String id;
  final String groupId;
  final String userId;
  final GoalType goalType;
  final int goalTarget;
  final int deductionX;

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        userId: map['user_id'] as String,
        goalType: goalTypeFrom(map['goal_type'] as String),
        goalTarget: map['goal_target'] as int,
        deductionX: map['deduction_x'] as int,
      );
}
