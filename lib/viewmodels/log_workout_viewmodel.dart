import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/workout_log.dart';
import '../services/workout_service.dart';

class LogWorkoutViewModel extends ChangeNotifier {
  LogWorkoutViewModel({
    required WorkoutService service,
    required this.userId,
    required this.groupId,
    required File photo,
    ImagePicker? picker,
  })  : _service = service,
        _picker = picker ?? ImagePicker(),
        _photo = photo;

  static const List<int> durationPresets = [15, 30, 45, 60, 90];

  final WorkoutService _service;
  final ImagePicker _picker;
  final String userId;
  final String groupId;

  File _photo;
  int _durationMinutes = 30;
  bool _busy = false;
  String? _error;
  WorkoutLog? _saved;

  File get photo => _photo;
  int get durationMinutes => _durationMinutes;
  bool get busy => _busy;
  String? get error => _error;
  WorkoutLog? get saved => _saved;
  bool get canSubmit => !_busy;

  void cycleDuration() {
    final i = durationPresets.indexOf(_durationMinutes);
    _durationMinutes = durationPresets[(i + 1) % durationPresets.length];
    notifyListeners();
  }

  Future<bool> retake() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (x == null) return false;
    _photo = File(x.path);
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    if (!canSubmit) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _saved = await _service.logWorkout(
        userId: userId,
        groupId: groupId,
        durationMinutes: _durationMinutes,
        workoutType: 'workout',
        photo: _photo,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
