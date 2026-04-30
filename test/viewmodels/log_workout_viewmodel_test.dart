import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/workout_service.dart';
import 'package:habitbank/viewmodels/log_workout_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements WorkoutService {}

void main() {
  setUpAll(() {
    registerFallbackValue(File('placeholder'));
  });

  LogWorkoutViewModel build({WorkoutService? svc}) => LogWorkoutViewModel(
        service: svc ?? _FakeService(),
        userId: 'u',
        groupId: 'g',
        photo: File('/tmp/fake.jpg'),
      );

  test('starts ready to submit with sensible defaults', () {
    final vm = build();
    expect(vm.canSubmit, isTrue);
    expect(vm.durationMinutes, 30);
  });

  test('cycleDuration walks the presets and wraps', () {
    final vm = build();
    expect(vm.durationMinutes, 30);
    vm.cycleDuration();
    expect(vm.durationMinutes, 45);
    vm.cycleDuration();
    expect(vm.durationMinutes, 60);
    vm.cycleDuration();
    expect(vm.durationMinutes, 90);
    vm.cycleDuration();
    expect(vm.durationMinutes, 15);
    vm.cycleDuration();
    expect(vm.durationMinutes, 30);
  });

  test('submit forwards photo + duration to the service', () async {
    final svc = _FakeService();
    when(() => svc.logWorkout(
          userId: any(named: 'userId'),
          groupId: any(named: 'groupId'),
          durationMinutes: any(named: 'durationMinutes'),
          workoutType: any(named: 'workoutType'),
          photo: any(named: 'photo'),
        )).thenAnswer((_) async => WorkoutLog(
          id: 'x',
          userId: 'u',
          groupId: 'g',
          durationMinutes: 45,
          workoutType: 'workout',
          loggedAt: DateTime.utc(2026, 1, 1),
        ));

    final vm = build(svc: svc);
    vm.cycleDuration(); // 30 -> 45
    await vm.submit();

    verify(() => svc.logWorkout(
          userId: 'u',
          groupId: 'g',
          durationMinutes: 45,
          workoutType: 'workout',
          photo: any(named: 'photo'),
        )).called(1);
    expect(vm.saved, isNotNull);
    expect(vm.error, isNull);
  });
}
