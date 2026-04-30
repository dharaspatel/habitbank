class WeeklyResult {
  WeeklyResult({
    required this.id,
    required this.groupId,
    required this.weekStart,
    required this.weekEnd,
    required this.winners,
    required this.losers,
    required this.poolAmount,
    required this.perWinner,
  });

  final String id;
  final String groupId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<String> winners;
  final List<String> losers;
  final int poolAmount;
  final int perWinner;

  factory WeeklyResult.fromMap(Map<String, dynamic> map) => WeeklyResult(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        weekStart: DateTime.parse(map['week_start'] as String),
        weekEnd: DateTime.parse(map['week_end'] as String),
        winners: List<String>.from((map['winners'] as List?) ?? const []),
        losers: List<String>.from((map['losers'] as List?) ?? const []),
        poolAmount: (map['pool_amount'] as num?)?.toInt() ?? 0,
        perWinner: (map['per_winner'] as num?)?.toInt() ?? 0,
      );
}
