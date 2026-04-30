class Balance {
  Balance({
    required this.groupId,
    required this.userId,
    required this.balance,
  });

  final String groupId;
  final String userId;
  final int balance;

  factory Balance.fromMap(Map<String, dynamic> map) => Balance(
        groupId: map['group_id'] as String,
        userId: map['user_id'] as String,
        balance: (map['balance'] as num?)?.toInt() ?? 0,
      );
}
