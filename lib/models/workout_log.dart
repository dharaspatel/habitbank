class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.durationMinutes,
    required this.workoutType,
    required this.loggedAt,
    this.photoUrl,
  });

  final String id;
  final String userId;
  final String groupId;
  final int durationMinutes;
  final String workoutType;
  final DateTime loggedAt;
  final String? photoUrl;

  factory WorkoutLog.fromMap(Map<String, dynamic> map) => WorkoutLog(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        groupId: map['group_id'] as String,
        durationMinutes: map['duration_minutes'] as int,
        workoutType: (map['workout_type'] as String?) ?? 'general',
        loggedAt: DateTime.parse(map['logged_at'] as String),
        photoUrl: map['photo_url'] as String?,
      );
}
