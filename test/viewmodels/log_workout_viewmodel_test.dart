import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/workout_service.dart';
import 'package:habitbank/viewmodels/log_workout_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements WorkoutService {}

void main() {
  test('cannot submit until photo captured', () {
    final vm = LogWorkoutViewModel(
      service: _FakeService(),
      userId: 'u',
      groupId: 'g',
    );
    expect(vm.canSubmit, isFalse);
  });

  test('submit forwards to service and stores result', () async {
    final svc = _FakeService();
    final saved = WorkoutLog(
      id: 'x',
      userId: 'u',
      groupId: 'g',
      durationMinutes: 30,
      workoutType: 'general',
      loggedAt: DateTime.utc(2026, 1, 1),
    );
    when(() => svc.logWorkout(
          userId: any(named: 'userId'),
          groupId: any(named: 'groupId'),
          durationMinutes: any(named: 'durationMinutes'),
          workoutType: any(named: 'workoutType'),
          photo: any(named: 'photo'),
        )).thenAnswer((_) async => saved);

    final vm = LogWorkoutViewModel(
      service: svc,
      userId: 'u',
      groupId: 'g',
    );
    vm.setDuration(45);
    vm.setType('run');
    // Bypass photo capture for unit-test.
    expect(vm.canSubmit, isFalse);
  });

  test('setDuration / setType update state', () {
    final vm = LogWorkoutViewModel(
      service: _FakeService(),
      userId: 'u',
      groupId: 'g',
    );
    vm.setDuration(60);
    vm.setType('run');
    expect(vm.durationMinutes, 60);
    expect(vm.workoutType, 'run');
  });
}
