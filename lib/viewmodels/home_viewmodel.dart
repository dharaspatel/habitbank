import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/group.dart';
import '../models/weekly_result.dart';
import '../models/workout_log.dart';
import '../services/group_service.dart';
import '../services/settlement_engine.dart';
import '../services/workout_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._groupService, this._workoutService);

  final GroupService _groupService;
  final WorkoutService _workoutService;

  bool _loading = false;
  String? _error;
  List<Group> _groups = const [];
  Map<String, int> _balanceByGroup = const {};
  Map<String, List<WeeklyResult>> _resultsByGroup = const {};
  List<WorkoutLog> _userLogs = const [];
  String? _userId;

  bool get loading => _loading;
  String? get error => _error;
  List<Group> get groups => _groups;
  Map<String, List<WeeklyResult>> get resultsByGroup => _resultsByGroup;

  /// All of the current user's workout logs from the last [_lookbackDays]
  /// (across every group they belong to) — used to render the home heatmap.
  List<WorkoutLog> get userLogs => _userLogs;

  static const _lookbackDays = 84; // 12 weeks

  int balanceForGroup(String groupId) => _balanceByGroup[groupId] ?? 0;

  int get totalBalance =>
      _balanceByGroup.values.fold<int>(0, (a, b) => a + b);

  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _groupService.listMyGroups(userId);
      final balances = <String, int>{};
      final results = <String, List<WeeklyResult>>{};
      for (final g in _groups) {
        final list = await _groupService.listBalances(g.id);
        final mine = list.firstWhere(
          (b) => b.userId == userId,
          orElse: () => Balance(groupId: g.id, userId: userId, balance: 0),
        );
        balances[g.id] = mine.balance;
        results[g.id] = await _groupService.listWeeklyResults(g.id);
      }
      _balanceByGroup = balances;
      _resultsByGroup = results;
      _userLogs = await _workoutService.listForUser(
        userId: userId,
        since: DateTime.now()
            .toUtc()
            .subtract(const Duration(days: _lookbackDays)),
      );
      _userId = userId;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Longest current streak across groups: count consecutive most-recent
  /// weekly_results where the user appears in `winners`. Maximum is reported.
  int get currentStreakWeeks {
    if (_userId == null) return 0;
    var best = 0;
    for (final results in _resultsByGroup.values) {
      var streak = 0;
      for (final r in results) {
        if (r.winners.contains(_userId)) {
          streak += 1;
        } else {
          break;
        }
      }
      if (streak > best) best = streak;
    }
    return best;
  }

  /// Largest single-week delta (positive or negative) the user has seen.
  int get bestWeekDelta {
    if (_userId == null) return 0;
    var best = 0;
    for (final results in _resultsByGroup.values) {
      for (final r in results) {
        if (r.winners.contains(_userId) && r.perWinner > best) {
          best = r.perWinner;
        }
      }
    }
    return best;
  }

  /// This-week vs. last-week change in workout count, expressed as a fraction
  /// (e.g. 0.10 = +10%). Returns null when there's not enough data to be
  /// meaningful (no logs in either window).
  double? get weekOverWeekChange {
    final week = currentIsoWeekUtc(DateTime.now().toUtc());
    final lastStart = week.start.subtract(const Duration(days: 7));
    final thisCount = _userLogs.where((l) {
      final t = l.loggedAt.toUtc();
      return !t.isBefore(week.start) && t.isBefore(week.end);
    }).length;
    final lastCount = _userLogs.where((l) {
      final t = l.loggedAt.toUtc();
      return !t.isBefore(lastStart) && t.isBefore(week.start);
    }).length;
    if (thisCount == 0 && lastCount == 0) return null;
    if (lastCount == 0) return 1.0; // brand-new activity
    return (thisCount - lastCount) / lastCount;
  }
}
