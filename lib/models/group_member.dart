import 'user_profile.dart';

class GroupMember {
  GroupMember({
    required this.groupId,
    required this.userId,
    required this.profile,
  });

  final String groupId;
  final String userId;
  final UserProfile profile;
}
