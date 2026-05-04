import '../models/challenge.dart';
import '../models/workout_log.dart';

/// Pure settlement function. Mirrors the edge function — used for previews
/// in-app and for unit tests that don't need a database.
class SettlementInput {
  SettlementInput({
    required this.challenge,
    required this.memberIds,
    required this.logs,
  });

  /// The single goal applied to every member of the group.
  final Challenge challenge;

  /// All members of the group at the moment of settlement.
  final List<String> memberIds;

  /// Workout logs from the settled week, scoped to the group.
  final List<WorkoutLog> logs;
}

class SettlementOutcome {
  SettlementOutcome({
    required this.winners,
    required this.losers,
    required this.pool,
    required this.perWinner,
    required this.deltas,
  });

  final List<String> winners;
  final List<String> losers;
  final int pool;
  final int perWinner;
  final Map<String, int> deltas;
}

class SettlementEngine {
  /// Pool model: every member notionally puts `stake` into the pot
  /// (`pool = stake * memberCount`) and the hitters split the entire pot
  /// evenly — losers' delta is 0 (their stake funded the pot but balances
  /// only track winnings, never go negative). If *every* member misses,
  /// the member with the highest score (ties broken by member order) wins
  /// the whole pool so the money never disappears.
  /// `perWinner = pool ~/ winnersCount` (any cent remainder is dropped).
  static SettlementOutcome settle(SettlementInput input) {
    final totals = <String, _Totals>{};
    for (final log in input.logs) {
      final t = totals.putIfAbsent(log.userId, _Totals.new);
      t.workouts += 1;
      t.minutes += log.durationMinutes;
    }

    final winners = <String>[];
    final losers = <String>[];
    final scores = <String, int>{};
    final stake = input.challenge.stakeCents;
    final pool = stake * input.memberIds.length;

    for (final userId in input.memberIds) {
      final t = totals[userId] ?? _Totals();
      final score = input.challenge.goalType == GoalType.workouts
          ? t.workouts
          : t.minutes;
      scores[userId] = score;
      if (score >= input.challenge.goalTarget) {
        winners.add(userId);
      } else {
        losers.add(userId);
      }
    }

    if (winners.isEmpty && losers.isNotEmpty) {
      String closest = losers.first;
      for (final userId in losers) {
        if (scores[userId]! > scores[closest]!) closest = userId;
      }
      losers.remove(closest);
      winners.add(closest);
    }

    final perWinner = winners.isEmpty ? 0 : pool ~/ winners.length;
    final deltas = <String, int>{
      for (final userId in input.memberIds)
        userId: winners.contains(userId) ? perWinner : 0,
    };

    return SettlementOutcome(
      winners: winners,
      losers: losers,
      pool: pool,
      perWinner: perWinner,
      deltas: deltas,
    );
  }
}

class _Totals {
  int workouts = 0;
  int minutes = 0;
}

/// Returns [Mon 00:00 UTC, next Mon 00:00 UTC) containing [now].
({DateTime start, DateTime end}) currentIsoWeekUtc(DateTime now) {
  final utc =
      DateTime.utc(now.toUtc().year, now.toUtc().month, now.toUtc().day);
  final dayOfWeek = (utc.weekday + 6) % 7; // Mon=0..Sun=6
  final start = utc.subtract(Duration(days: dayOfWeek));
  final end = start.add(const Duration(days: 7));
  return (start: start, end: end);
}
