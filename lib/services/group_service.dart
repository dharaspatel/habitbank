import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/balance.dart';
import '../models/challenge.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/user_profile.dart';
import '../models/weekly_result.dart';

class GroupService {
  GroupService(this._client);

  final SupabaseClient _client;

  Future<List<Group>> listMyGroups(String userId) async {
    final res = await _client
        .from('group_members')
        .select('group:groups(*)')
        .eq('user_id', userId);
    return (res as List)
        .map((row) => Group.fromMap(row['group'] as Map<String, dynamic>))
        .toList();
  }

  Future<Group> createGroup({
    required String name,
    required String ownerId,
    required GoalType goalType,
    required int goalTarget,
    required int stakeCents,
  }) async {
    final code = await _client.rpc('generate_invite_code') as String;
    final inserted = await _client
        .from('groups')
        .insert({
          'name': name,
          'owner_id': ownerId,
          'invite_code': code,
        })
        .select()
        .single();
    final group = Group.fromMap(inserted);
    await _client.from('group_members').insert({
      'group_id': group.id,
      'user_id': ownerId,
    });
    await _client.from('challenges').insert({
      'group_id': group.id,
      'goal_type': goalTypeToString(goalType),
      'goal_target': goalTarget,
      'stake_cents': stakeCents,
    });
    return group;
  }

  Future<Group> joinGroupByCode({
    required String code,
    required String userId,
  }) async {
    // Calls a SECURITY DEFINER RPC so we can look up a group we're not yet
    // a member of (RLS hides those from a regular select). The RPC also
    // inserts the membership atomically and rejects with `GROUP_FULL` once
    // the group has reached the 7-member cap.
    final List<dynamic> list;
    try {
      final res = await _client.rpc(
        'join_group_by_invite',
        params: {'p_code': code.trim().toUpperCase()},
      );
      list = (res as List?) ?? const [];
    } on PostgrestException catch (e) {
      if (e.message.contains('GROUP_FULL')) {
        throw const GroupFullException();
      }
      rethrow;
    }
    if (list.isEmpty) {
      throw const InvalidInviteCodeException();
    }
    return Group.fromMap(list.first as Map<String, dynamic>);
  }

  Future<List<GroupMember>> listMembers(String groupId) async {
    final rows = await _client
        .from('group_members')
        .select('group_id, user_id, profile:profiles(*)')
        .eq('group_id', groupId);
    return (rows as List).map((m) {
      final p = UserProfile.fromMap(m['profile'] as Map<String, dynamic>);
      return GroupMember(
        groupId: m['group_id'] as String,
        userId: m['user_id'] as String,
        profile: p,
      );
    }).toList();
  }

  Future<Challenge?> getChallenge(String groupId) async {
    final row = await _client
        .from('challenges')
        .select()
        .eq('group_id', groupId)
        .maybeSingle();
    return row == null ? null : Challenge.fromMap(row);
  }

  /// Owner-only on the server (RLS); UI should still gate this.
  Future<Challenge> updateChallenge({
    required String groupId,
    required GoalType goalType,
    required int goalTarget,
    required int stakeCents,
  }) async {
    final row = await _client
        .from('challenges')
        .update({
          'goal_type': goalTypeToString(goalType),
          'goal_target': goalTarget,
          'stake_cents': stakeCents,
        })
        .eq('group_id', groupId)
        .select()
        .single();
    return Challenge.fromMap(row);
  }

  Future<List<Balance>> listBalances(String groupId) async {
    final rows =
        await _client.from('balances').select().eq('group_id', groupId);
    return (rows as List)
        .map((r) => Balance.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<WeeklyResult>> listWeeklyResults(String groupId) async {
    final rows = await _client
        .from('weekly_results')
        .select()
        .eq('group_id', groupId)
        .order('week_start', ascending: false);
    return (rows as List)
        .map((r) => WeeklyResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

class GroupFullException implements Exception {
  const GroupFullException();
}

class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException();
  @override
  String toString() => 'No group with that code.';
}
