import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/challenge.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/settlement_engine.dart';

Challenge groupChallenge({
  GoalType type = GoalType.workouts,
  int target = 3,
  int stake = 100,
}) {
  return Challenge(
    id: 'c',
    groupId: 'g',
    goalType: type,
    goalTarget: target,
    stakeCents: stake,
  );
}

WorkoutLog log({
  required String userId,
  int minutes = 30,
  DateTime? at,
}) {
  return WorkoutLog(
    id: 'l-${DateTime.now().microsecondsSinceEpoch}-$userId',
    userId: userId,
    groupId: 'g',
    durationMinutes: minutes,
    workoutType: 'general',
    loggedAt: at ?? DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('SettlementEngine.settle (pool model: hitters split the pot)', () {
    test('hitters split pool evenly, losers get nothing', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 3, stake: 100),
        memberIds: ['a', 'b', 'c'],
        logs: [
          log(userId: 'a'), log(userId: 'a'), log(userId: 'a'),
          log(userId: 'b'), log(userId: 'b'), log(userId: 'b'),
          log(userId: 'c'),
        ],
      ));
      expect(out.winners, ['a', 'b']);
      expect(out.losers, ['c']);
      expect(out.pool, 300); // 3 × 100
      expect(out.perWinner, 150); // 300 ~/ 2
      expect(out.deltas, {'a': 150, 'b': 150, 'c': 0});
    });

    test('all hit => pool split evenly, each gets their own stake back', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, ['a', 'b']);
      expect(out.losers, isEmpty);
      expect(out.pool, 200);
      expect(out.perWinner, 100);
      expect(out.deltas, {'a': 100, 'b': 100});
    });

    test('only one hitter takes the whole pool', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a')],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['b']);
      expect(out.deltas, {'a': 200, 'b': 0});
    });

    test('all miss => closest to goal wins the whole pool', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 5, stake: 100),
        memberIds: ['a', 'b', 'c'],
        logs: [
          log(userId: 'a'),
          log(userId: 'b'), log(userId: 'b'), log(userId: 'b'),
          log(userId: 'c'), log(userId: 'c'),
        ],
      ));
      expect(out.winners, ['b']);
      expect(out.losers, ['a', 'c']);
      expect(out.deltas, {'a': 0, 'b': 300, 'c': 0});
    });

    test('all miss with a tie => earliest member in order wins', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 5, stake: 100),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['b']);
      expect(out.deltas, {'a': 200, 'b': 0});
    });

    test('odd cents in the pool floor to the winners (remainder burns)', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'b', 'c'],
        logs: [log(userId: 'a'), log(userId: 'b'), log(userId: 'c')],
      ));
      expect(out.pool, 300);
      expect(out.perWinner, 100); // 300 ~/ 3
      expect(out.deltas.values.fold<int>(0, (a, b) => a + b), 300);
    });

    test('minutes goal sums durations across the week', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(
            type: GoalType.minutes, target: 60, stake: 250),
        memberIds: ['a', 'b'],
        logs: [
          log(userId: 'a', minutes: 30),
          log(userId: 'a', minutes: 35),
          log(userId: 'b', minutes: 30),
        ],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['b']);
      expect(out.deltas, {'a': 500, 'b': 0});
    });

    test('member with no logs gets nothing', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'silent'],
        logs: [log(userId: 'a')],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['silent']);
      expect(out.deltas, {'a': 200, 'silent': 0});
    });
  });

  group('currentIsoWeekUtc', () {
    test('Monday-aligned UTC week containing the timestamp', () {
      final week = currentIsoWeekUtc(DateTime.utc(2026, 1, 7, 15));
      expect(week.start, DateTime.utc(2026, 1, 5));
      expect(week.end, DateTime.utc(2026, 1, 12));
    });

    test('Sunday belongs to the just-ending week', () {
      final week = currentIsoWeekUtc(DateTime.utc(2026, 1, 11, 23, 59));
      expect(week.start, DateTime.utc(2026, 1, 5));
      expect(week.end, DateTime.utc(2026, 1, 12));
    });

    test('Monday 00:00 starts a new week', () {
      final week = currentIsoWeekUtc(DateTime.utc(2026, 1, 12));
      expect(week.start, DateTime.utc(2026, 1, 12));
      expect(week.end, DateTime.utc(2026, 1, 19));
    });
  });
}
