import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/weekly_result.dart';
import '../widgets/section.dart';

/// Per-user ledger derived from weekly results. Pure presentation; the data
/// flows from [WeeklyResultsViewModel] in the parent route.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({
    super.key,
    required this.userId,
    required this.results,
  });

  final String userId;
  final List<WeeklyResult> results;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.MMMd();
    final entries = <_Entry>[];
    var running = 0;
    for (final r in results.reversed) {
      var delta = 0;
      if (r.winners.contains(userId)) delta += r.perWinner;
      if (r.losers.contains(userId)) {
        // We don't store the per-user deduction here; estimate with pool/loser count.
        final perLoser =
            r.losers.isEmpty ? 0 : (r.poolAmount ~/ r.losers.length);
        delta -= perLoser;
      }
      running += delta;
      entries.insert(0, _Entry(
        label: '${df.format(r.weekStart)} – ${df.format(r.weekEnd)}',
        delta: delta,
        running: running,
      ));
    }
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Ledger'),
      ),
      child: SafeArea(
        child: entries.isEmpty
            ? Center(
                child: Text('No history yet.',
                    style: AppTheme.body.copyWith(color: AppTheme.muted)))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const ThinDivider(),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final sign = e.delta >= 0 ? '+' : '−';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.label, style: AppTheme.body)),
                        Text('$sign${e.delta.abs()}',
                            style: AppTheme.headline),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _Entry {
  _Entry({required this.label, required this.delta, required this.running});
  final String label;
  final int delta;
  final int running;
}
