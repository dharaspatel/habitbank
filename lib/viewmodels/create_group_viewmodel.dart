import 'package:flutter/foundation.dart';

import '../models/challenge.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class CreateGroupViewModel extends ChangeNotifier {
  CreateGroupViewModel(this._service, this.userId);

  final GroupService _service;
  final String userId;
  bool _busy = false;
  String? _error;
  Group? _created;

  bool get busy => _busy;
  String? get error => _error;
  Group? get created => _created;

  Future<void> create({
    required String name,
    required GoalType goalType,
    required int goalTarget,
    required int stakeCents,
  }) async {
    if (name.trim().isEmpty) {
      _error = 'Name required';
      notifyListeners();
      return;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _created = await _service.createGroup(
        name: name.trim(),
        ownerId: userId,
        goalType: goalType,
        goalTarget: goalTarget,
        stakeCents: stakeCents,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
