import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._service);

  final GroupService _service;

  bool _loading = false;
  String? _error;
  List<Group> _groups = const [];
  Map<String, int> _balanceByGroup = const {};

  bool get loading => _loading;
  String? get error => _error;
  List<Group> get groups => _groups;

  int balanceForGroup(String groupId) => _balanceByGroup[groupId] ?? 0;

  int get totalBalance =>
      _balanceByGroup.values.fold<int>(0, (a, b) => a + b);

  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _service.listMyGroups(userId);
      final m = <String, int>{};
      for (final g in _groups) {
        final balances = await _service.listBalances(g.id);
        final mine = balances.firstWhere(
          (b) => b.userId == userId,
          orElse: () => Balance(groupId: g.id, userId: userId, balance: 0),
        );
        m[g.id] = mine.balance;
      }
      _balanceByGroup = m;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
