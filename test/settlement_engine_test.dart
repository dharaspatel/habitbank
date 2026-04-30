import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/challenge.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/settlement_engine.dart';

Challenge groupChallenge({
  GoalType type = GoalType.workouts,
  int target = 3,
  int stake = 10,
}) {
  return Challenge(
    id: 'c',
    groupId: 'g',
    goalType: type,
    goalTarget: target,
    deductionX: stake,
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
  group('SettlementEngine.settle (one challenge per group)', () {
    test('winners split loser pool equally', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 3, stake: 10),
        memberIds: ['a', 'b', 'c'],
        logs: [
          log(userId: 'a'), log(userId: 'a'), log(userId: 'a'),
          log(userId: 'b'), log(userId: 'b'), log(userId: 'b'),
          log(userId: 'c'),
        ],
      ));
      expect(out.winners, ['a', 'b']);
      expect(out.losers, ['c']);
      expect(out.pool, 10);
      expect(out.perWinner, 5);
      expect(out.deltas, {'a': 5, 'b': 5, 'c': -10});
    });

    test('no winners => pool burns', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 5, stake: 10),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, isEmpty);
      expect(out.losers, ['a', 'b']);
      expect(out.pool, 20);
      expect(out.perWinner, 0);
      expect(out.deltas, {'a': -10, 'b': -10});
    });

    test('all winners => zero pool, zero deltas', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, ['a', 'b']);
      expect(out.losers, isEmpty);
      expect(out.pool, 0);
      expect(out.perWinner, 0);
      expect(out.deltas, {'a': 0, 'b': 0});
    });

    test('minutes goal sums durations', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(type: GoalType.minutes, target: 60, stake: 10),
        memberIds: ['a', 'b'],
        logs: [
          log(userId: 'a', minutes: 30),
          log(userId: 'a', minutes: 35),
          log(userId: 'b', minutes: 30),
        ],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['b']);
      expect(out.deltas, {'b': -10, 'a': 10});
    });

    test('tie split: integer floor; remainder burns', () {
      // pool=10, 3 winners => perWinner=3, 1 unit burns
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 10),
        memberIds: ['a', 'b', 'c', 'd'],
        logs: [log(userId: 'a'), log(userId: 'b'), log(userId: 'c')],
      ));
      expect(out.pool, 10);
      expect(out.winners, ['a', 'b', 'c']);
      expect(out.losers, ['d']);
      expect(out.perWinner, 3);
      expect(out.deltas['a'], 3);
      expect(out.deltas['b'], 3);
      expect(out.deltas['c'], 3);
      expect(out.deltas['d'], -10);
    });

    test('member with no logs is treated as a loser', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 5),
        memberIds: ['a', 'silent'],
        logs: [log(userId: 'a')],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['silent']);
      expect(out.deltas, {'silent': -5, 'a': 5});
    });
  });

  group('currentIsoWeekUtc', () {
    test('returns Monday-aligned UTC week containing the timestamp', () {
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
