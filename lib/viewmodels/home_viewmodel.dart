import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/group.dart';
import '../models/weekly_result.dart';
import '../services/group_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._service);

  final GroupService _service;

  bool _loading = false;
  String? _error;
  List<Group> _groups = const [];
  Map<String, int> _balanceByGroup = const {};
  Map<String, List<WeeklyResult>> _resultsByGroup = const {};

  bool get loading => _loading;
  String? get error => _error;
  List<Group> get groups => _groups;
  Map<String, List<WeeklyResult>> get resultsByGroup => _resultsByGroup;

  int balanceForGroup(String groupId) => _balanceByGroup[groupId] ?? 0;

  int get totalBalance =>
      _balanceByGroup.values.fold<int>(0, (a, b) => a + b);

  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _service.listMyGroups(userId);
      final balances = <String, int>{};
      final results = <String, List<WeeklyResult>>{};
      for (final g in _groups) {
        final list = await _service.listBalances(g.id);
        final mine = list.firstWhere(
          (b) => b.userId == userId,
          orElse: () => Balance(groupId: g.id, userId: userId, balance: 0),
        );
        balances[g.id] = mine.balance;
        results[g.id] = await _service.listWeeklyResults(g.id);
      }
      _balanceByGroup = balances;
      _resultsByGroup = results;
      _userId = userId;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String? _userId;

  /// Longest current streak across groups: count consecutive most-recent
  /// weekly_results where the user appears in `winners`. The streak is
  /// computed per group; the maximum is reported.
  int get currentStreakWeeks {
    if (_userId == null) return 0;
    var best = 0;
    for (final results in _resultsByGroup.values) {
      // weekly_results are returned newest-first by GroupService.
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
}
