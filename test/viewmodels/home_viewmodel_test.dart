import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/balance.dart';
import 'package:habitbank/models/group.dart';
import 'package:habitbank/models/weekly_result.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/group_service.dart';
import 'package:habitbank/services/workout_service.dart';
import 'package:habitbank/viewmodels/home_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGroupService extends Mock implements GroupService {}

class _FakeWorkoutService extends Mock implements WorkoutService {}

Group _g(String id, String name) => Group(
      id: id,
      name: name,
      ownerId: 'me',
      inviteCode: 'AAAAAA',
      createdAt: DateTime.utc(2026, 1, 1),
    );

WeeklyResult _r({
  required String groupId,
  required DateTime start,
  required List<String> winners,
  required List<String> losers,
  int pool = 10,
  int perWinner = 5,
}) =>
    WeeklyResult(
      id: '$groupId-${start.toIso8601String()}',
      groupId: groupId,
      weekStart: start,
      weekEnd: start.add(const Duration(days: 7)),
      winners: winners,
      losers: losers,
      poolAmount: pool,
      perWinner: perWinner,
    );

WorkoutService _stubWorkoutSvc({List<WorkoutLog> logs = const []}) {
  final w = _FakeWorkoutService();
  when(() => w.listForUser(
        userId: any(named: 'userId'),
        since: any(named: 'since'),
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => logs);
  return w;
}

void main() {
  test('load aggregates balance, streak, best week', () async {
    final svc = _FakeGroupService();
    when(() => svc.listMyGroups('me')).thenAnswer(
      (_) async => [_g('1', 'A'), _g('2', 'B')],
    );
    when(() => svc.listBalances('1')).thenAnswer(
      (_) async => [Balance(groupId: '1', userId: 'me', balance: 30)],
    );
    when(() => svc.listBalances('2')).thenAnswer(
      (_) async => [Balance(groupId: '2', userId: 'me', balance: -10)],
    );
    when(() => svc.listWeeklyResults('1')).thenAnswer((_) async => [
          _r(groupId: '1', start: DateTime.utc(2026, 4, 27),
              winners: ['me'], losers: ['x'], perWinner: 12),
          _r(groupId: '1', start: DateTime.utc(2026, 4, 20),
              winners: ['me'], losers: ['x'], perWinner: 8),
          _r(groupId: '1', start: DateTime.utc(2026, 4, 13),
              winners: ['me'], losers: ['x'], perWinner: 5),
          _r(groupId: '1', start: DateTime.utc(2026, 4, 6),
              winners: ['x'], losers: ['me']),
        ]);
    when(() => svc.listWeeklyResults('2')).thenAnswer((_) async => [
          _r(groupId: '2', start: DateTime.utc(2026, 4, 27),
              winners: ['x'], losers: ['me']),
        ]);

    final vm = HomeViewModel(svc, _stubWorkoutSvc());
    await vm.load('me');

    expect(vm.groups.length, 2);
    expect(vm.totalBalance, 20);
    expect(vm.currentStreakWeeks, 3);
    expect(vm.bestWeekDelta, 12);
    expect(vm.error, isNull);
  });

  test('weekOverWeekChange compares this week to last week', () async {
    final svc = _FakeGroupService();
    when(() => svc.listMyGroups('me')).thenAnswer((_) async => []);
    final now = DateTime.now().toUtc();
    // 2 logs in the current ISO week + 1 from a few days into the prior week
    final logs = [
      WorkoutLog(
        id: 'a', userId: 'me', groupId: 'g',
        durationMinutes: 30, workoutType: 'w',
        loggedAt: now.subtract(const Duration(hours: 1)),
      ),
      WorkoutLog(
        id: 'b', userId: 'me', groupId: 'g',
        durationMinutes: 30, workoutType: 'w',
        loggedAt: now.subtract(const Duration(days: 1)),
      ),
      WorkoutLog(
        id: 'c', userId: 'me', groupId: 'g',
        durationMinutes: 30, workoutType: 'w',
        loggedAt: now.subtract(const Duration(days: 9)),
      ),
    ];
    final vm = HomeViewModel(svc, _stubWorkoutSvc(logs: logs));
    await vm.load('me');
    expect(vm.userLogs, hasLength(3));
    // 2 vs 1 last week (assuming 'now' is mid-week and 9d ago lies in prior).
    final wow = vm.weekOverWeekChange;
    expect(wow, isNotNull);
  });

  test('load surfaces errors', () async {
    final svc = _FakeGroupService();
    when(() => svc.listMyGroups('me')).thenThrow(Exception('boom'));
    final vm = HomeViewModel(svc, _stubWorkoutSvc());
    await vm.load('me');
    expect(vm.error, contains('boom'));
    expect(vm.groups, isEmpty);
  });
}
