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
  static SettlementOutcome settle(SettlementInput input) {
    final totals = <String, _Totals>{};
    for (final log in input.logs) {
      final t = totals.putIfAbsent(log.userId, _Totals.new);
      t.workouts += 1;
      t.minutes += log.durationMinutes;
    }

    final winners = <String>[];
    final losers = <String>[];
    var pool = 0;
    final deltas = <String, int>{};
    final stake = input.challenge.stakeCents;

    for (final userId in input.memberIds) {
      final t = totals[userId] ?? _Totals();
      final score = input.challenge.goalType == GoalType.workouts
          ? t.workouts
          : t.minutes;
      if (score >= input.challenge.goalTarget) {
        winners.add(userId);
      } else {
        losers.add(userId);
        pool += stake;
        deltas[userId] = -stake;
      }
    }

    final perWinner = winners.isEmpty ? 0 : pool ~/ winners.length;
    for (final w in winners) {
      deltas[w] = perWinner;
    }

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
