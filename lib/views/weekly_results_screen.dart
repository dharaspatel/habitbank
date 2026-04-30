import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/weekly_results_viewmodel.dart';
import '../widgets/money_field.dart';
import '../widgets/section.dart';

class WeeklyResultsScreen extends StatelessWidget {
  const WeeklyResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeeklyResultsViewModel>();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        middle: Text('Weekly results'),
      ),
      child: SafeArea(
        child: vm.loading
            ? const Center(child: CupertinoActivityIndicator())
            : vm.results.isEmpty
                ? Center(
                    child: Text('No results yet.',
                        style: AppTheme.body.copyWith(color: AppTheme.muted)),
                  )
                : ListView.separated(
                    itemCount: vm.results.length,
                    separatorBuilder: (_, __) => const ThinDivider(),
                    itemBuilder: (_, i) {
                      final r = vm.results[i];
                      final df = DateFormat.MMMd();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${df.format(r.weekStart)} – ${df.format(r.weekEnd)}',
                              style: AppTheme.headline,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pool ${formatCents(r.poolAmount)} • '
                              '${r.winners.length} winners (${formatCents(r.perWinner)} each) • '
                              '${r.losers.length} losers',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
