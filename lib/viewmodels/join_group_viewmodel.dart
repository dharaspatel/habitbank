import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../services/group_service.dart';

class JoinGroupViewModel extends ChangeNotifier {
  JoinGroupViewModel(this._service, this.userId);

  final GroupService _service;
  final String userId;
  bool _busy = false;
  String? _error;
  Group? _joined;

  bool get busy => _busy;
  String? get error => _error;
  Group? get joined => _joined;

  Future<void> join(String code) async {
    if (code.trim().length < 4) {
      _error = 'Invalid code';
      notifyListeners();
      return;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _joined = await _service.joinGroupByCode(
          code: code.trim(), userId: userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
