class Group {
  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final DateTime createdAt;

  /// Shareable invite URL. The receiver opens the app and pastes the code,
  /// or — when universal links are wired up — taps and joins directly.
  String get inviteUrl => 'https://habitbank.app/join/$inviteCode';

  factory Group.fromMap(Map<String, dynamic> map) => Group(
        id: map['id'] as String,
        name: map['name'] as String,
        ownerId: map['owner_id'] as String,
        inviteCode: map['invite_code'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
