import 'package:flutter/foundation.dart';

import '../models/weekly_result.dart';
import '../services/group_service.dart';

class WeeklyResultsViewModel extends ChangeNotifier {
  WeeklyResultsViewModel(this._service, this.groupId);

  final GroupService _service;
  final String groupId;

  bool _loading = false;
  String? _error;
  List<WeeklyResult> _results = const [];

  bool get loading => _loading;
  String? get error => _error;
  List<WeeklyResult> get results => _results;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _results = await _service.listWeeklyResults(groupId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
