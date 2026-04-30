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
    ImagePicker? picker,
  })  : _service = service,
        _picker = picker ?? ImagePicker();

  final WorkoutService _service;
  final ImagePicker _picker;
  final String userId;
  final String groupId;

  File? _photo;
  int _durationMinutes = 30;
  String _workoutType = 'general';
  bool _busy = false;
  String? _error;
  WorkoutLog? _saved;

  File? get photo => _photo;
  int get durationMinutes => _durationMinutes;
  String get workoutType => _workoutType;
  bool get busy => _busy;
  String? get error => _error;
  bool get canSubmit => _photo != null && _durationMinutes > 0 && !_busy;
  WorkoutLog? get saved => _saved;

  void setDuration(int minutes) {
    _durationMinutes = minutes;
    notifyListeners();
  }

  void setType(String type) {
    _workoutType = type;
    notifyListeners();
  }

  Future<void> capturePhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (x != null) {
      _photo = File(x.path);
      notifyListeners();
    }
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
        workoutType: _workoutType,
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
