import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/challenge.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/settlement_engine.dart';

Challenge challenge({
  required String userId,
  GoalType type = GoalType.workouts,
  int target = 3,
  int deduction = 10,
}) {
  return Challenge(
    id: 'c-$userId',
    groupId: 'g',
    userId: userId,
    goalType: type,
    goalTarget: target,
    deductionX: deduction,
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
  group('SettlementEngine.settle', () {
    test('winners split loser pool equally', () {
      final input = SettlementInput(
        challenges: [
          challenge(userId: 'a', target: 3),
          challenge(userId: 'b', target: 3),
          challenge(userId: 'c', target: 3),
        ],
        logs: [
          log(userId: 'a'),
          log(userId: 'a'),
          log(userId: 'a'),
          log(userId: 'b'),
          log(userId: 'b'),
          log(userId: 'b'),
          log(userId: 'c'),
        ],
      );
      final out = SettlementEngine.settle(input);
      expect(out.winners, ['a', 'b']);
      expect(out.losers, ['c']);
      expect(out.pool, 10);
      expect(out.perWinner, 5);
      expect(out.deltas, {'a': 5, 'b': 5, 'c': -10});
    });

    test('no winners => pool burns, only losers see deductions', () {
      final input = SettlementInput(
        challenges: [
          challenge(userId: 'a', target: 5),
          challenge(userId: 'b', target: 5, deduction: 20),
        ],
        logs: [log(userId: 'a'), log(userId: 'b')],
      );
      final out = SettlementEngine.settle(input);
      expect(out.winners, isEmpty);
      expect(out.losers, ['a', 'b']);
      expect(out.pool, 30);
      expect(out.perWinner, 0);
      expect(out.deltas, {'a': -10, 'b': -20});
    });

    test('all winners => zero pool, zero deltas', () {
      final input = SettlementInput(
        challenges: [
          challenge(userId: 'a', target: 1),
          challenge(userId: 'b', target: 1),
        ],
        logs: [log(userId: 'a'), log(userId: 'b')],
      );
      final out = SettlementEngine.settle(input);
      expect(out.winners, ['a', 'b']);
      expect(out.losers, isEmpty);
      expect(out.pool, 0);
      expect(out.perWinner, 0);
      expect(out.deltas, isEmpty);
    });

    test('minutes goal sums durations', () {
      final input = SettlementInput(
        challenges: [
          challenge(userId: 'a', type: GoalType.minutes, target: 60),
          challenge(userId: 'b', type: GoalType.minutes, target: 60),
        ],
        logs: [
          log(userId: 'a', minutes: 30),
          log(userId: 'a', minutes: 35),
          log(userId: 'b', minutes: 30),
        ],
      );
      final out = SettlementEngine.settle(input);
      expect(out.winners, ['a']);
      expect(out.losers, ['b']);
      expect(out.deltas, {'b': -10, 'a': 10});
    });

    test('tie split: integer floor; remainder burns', () {
      // pool=10, 3 winners => perWinner=3, 1 unit burns
      final input = SettlementInput(
        challenges: [
          challenge(userId: 'a', target: 1),
          challenge(userId: 'b', target: 1),
          challenge(userId: 'c', target: 1),
          challenge(userId: 'd', target: 1),
        ],
        logs: [log(userId: 'a'), log(userId: 'b'), log(userId: 'c')],
      );
      final out = SettlementEngine.settle(input);
      expect(out.pool, 10);
      expect(out.winners.length, 3);
      expect(out.losers, ['d']);
      expect(out.perWinner, 3);
      expect(out.deltas['a'], 3);
      expect(out.deltas['b'], 3);
      expect(out.deltas['c'], 3);
      expect(out.deltas['d'], -10);
    });

    test('user without challenge is ignored entirely', () {
      final input = SettlementInput(
        challenges: [challenge(userId: 'a', target: 1)],
        logs: [log(userId: 'b'), log(userId: 'a')],
      );
      final out = SettlementEngine.settle(input);
      expect(out.winners, ['a']);
      expect(out.losers, isEmpty);
      expect(out.deltas, isEmpty);
    });
  });

  group('currentIsoWeekUtc', () {
    test('returns Monday-aligned UTC week containing the timestamp', () {
      // 2026-01-07 is a Wednesday
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
