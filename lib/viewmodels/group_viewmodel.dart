import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/challenge.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/weekly_result.dart';
import '../models/workout_log.dart';
import '../services/group_service.dart';
import '../services/settlement_engine.dart';
import '../services/workout_service.dart';

class GroupViewModel extends ChangeNotifier {
  GroupViewModel({
    required GroupService groupService,
    required WorkoutService workoutService,
    required this.group,
    required this.currentUserId,
  })  : _groupService = groupService,
        _workoutService = workoutService;

  final GroupService _groupService;
  final WorkoutService _workoutService;
  final Group group;
  final String currentUserId;

  bool _loading = false;
  String? _error;
  List<GroupMember> _members = const [];
  List<WorkoutLog> _logs = const [];
  List<Balance> _balances = const [];
  List<WeeklyResult> _weeklyResults = const [];
  Challenge? _challenge;

  bool get loading => _loading;
  String? get error => _error;
  List<GroupMember> get members => _members;
  List<WorkoutLog> get logs => _logs;
  List<Balance> get balances => _balances;
  List<WeeklyResult> get weeklyResults => _weeklyResults;
  Challenge? get challenge => _challenge;
  bool get isOwner => group.ownerId == currentUserId;

  /// What this week's settlement would award each member if the week ended
  /// right now. Mirrors [SettlementEngine.settle] on the in-progress logs so
  /// the UI can preview projected pool shares.
  Map<String, int> get projectedDeltas {
    final c = _challenge;
    if (c == null || _members.isEmpty) return const {};
    final week = currentIsoWeekUtc(DateTime.now().toUtc());
    final thisWeek = _logs
        .where((l) =>
            l.loggedAt.toUtc().isAfter(week.start) &&
            l.loggedAt.toUtc().isBefore(week.end))
        .toList();
    final out = SettlementEngine.settle(SettlementInput(
      challenge: c,
      memberIds: _members.map((m) => m.userId).toList(),
      logs: thisWeek,
    ));
    return out.deltas;
  }

  int progressForUser(String userId) {
    final c = _challenge;
    if (c == null) return 0;
    final week = currentIsoWeekUtc(DateTime.now().toUtc());
    final mine = _logs.where((l) =>
        l.userId == userId &&
        l.loggedAt.toUtc().isAfter(week.start) &&
        l.loggedAt.toUtc().isBefore(week.end));
    if (c.goalType == GoalType.workouts) {
      return mine.length;
    }
    return mine.fold<int>(0, (a, l) => a + l.durationMinutes);
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _members = await _groupService.listMembers(group.id);
      _logs = await _workoutService.listForGroup(group.id);
      _balances = await _groupService.listBalances(group.id);
      _weeklyResults = await _groupService.listWeeklyResults(group.id);
      _challenge = await _groupService.getChallenge(group.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Owner-only. RLS rejects writes from non-owners.
  Future<void> updateChallenge({
    required GoalType type,
    required int target,
    required int stakeCents,
  }) async {
    if (!isOwner) return;
    _challenge = await _groupService.updateChallenge(
      groupId: group.id,
      goalType: type,
      goalTarget: target,
      stakeCents: stakeCents,
    );
    notifyListeners();
  }
}
