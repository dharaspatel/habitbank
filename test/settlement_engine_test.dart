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
  group('SettlementEngine.settle (binary +stake / -stake per member)', () {
    test('hitters gain stake, missers lose stake', () {
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
      expect(out.deltas, {'a': 100, 'b': 100, 'c': -100});
      expect(out.perWinner, 100);
      expect(out.pool, 300); // 3 members × 100c at risk
    });

    test('all miss => everyone -stake', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 5, stake: 100),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, isEmpty);
      expect(out.losers, ['a', 'b']);
      expect(out.deltas, {'a': -100, 'b': -100});
    });

    test('all hit => everyone +stake', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'b'],
        logs: [log(userId: 'a'), log(userId: 'b')],
      ));
      expect(out.winners, ['a', 'b']);
      expect(out.losers, isEmpty);
      expect(out.deltas, {'a': 100, 'b': 100});
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
      expect(out.deltas, {'a': 250, 'b': -250});
    });

    test('member with no logs is treated as a loser', () {
      final out = SettlementEngine.settle(SettlementInput(
        challenge: groupChallenge(target: 1, stake: 100),
        memberIds: ['a', 'silent'],
        logs: [log(userId: 'a')],
      ));
      expect(out.winners, ['a']);
      expect(out.losers, ['silent']);
      expect(out.deltas, {'a': 100, 'silent': -100});
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
