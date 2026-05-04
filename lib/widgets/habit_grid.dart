import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

/// GitHub-style heatmap. Renders [weeks] columns × 7 rows (Mon..Sun); cell
/// intensity is determined by how many [loggedAt] timestamps fall on each
/// day, bucketed in the user's local timezone.
///
/// Designed to live below the groups list on the home screen.
class HabitGrid extends StatelessWidget {
  const HabitGrid({
    super.key,
    required this.loggedAt,
    this.weeks = 12,
    this.gap = 4,
  });

  final List<DateTime> loggedAt;
  final int weeks;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toLocal();
    final endDay = DateTime(today.year, today.month, today.day);
    // Anchor the rightmost column on the most recent Sunday (so the most
    // recent week is on the right and rows are Mon..Sun top-to-bottom).
    final daysSinceMonday = (endDay.weekday + 6) % 7;
    final lastMonday = endDay.subtract(Duration(days: daysSinceMonday));
    final firstMonday = lastMonday.subtract(Duration(days: 7 * (weeks - 1)));

    // Bucket logs by date.
    final counts = <String, int>{};
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    for (final ts in loggedAt) {
      final local = ts.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(firstMonday) || day.isAfter(endDay)) continue;
      counts.update(key(day), (v) => v + 1, ifAbsent: () => 1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 7 * 16.0 + 6 * gap;
        final cell = ((width - (weeks - 1) * gap) / weeks).clamp(2.0, 64.0);

        Widget cellFor(DateTime day) {
          final inFuture = day.isAfter(endDay);
          final c = inFuture ? -1 : (counts[key(day)] ?? 0);
          return Container(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: _shade(c),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row == 6 ? 0 : gap),
              child: Row(
                children: List.generate(weeks, (col) {
                  final day = firstMonday.add(Duration(days: col * 7 + row));
                  return Padding(
                    padding:
                        EdgeInsets.only(right: col == weeks - 1 ? 0 : gap),
                    child: cellFor(day),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  static Color _shade(int count) {
    if (count < 0) return AppTheme.background; // future day
    if (count == 0) return AppTheme.subtle;
    if (count == 1) return const Color(0xFFB7EDDB); // green-100
    if (count == 2) return const Color(0xFF4FCFA6); // green-300
    return const Color(0xFF06D6A0); // green-500 (matches progress ring)
  }
}
