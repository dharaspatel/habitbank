import 'package:flutter/cupertino.dart';

import '../config/member_palette.dart';
import '../config/theme.dart';
import '../models/balance.dart';
import '../models/group_member.dart';
import 'money_field.dart';

/// Horizontal stacked bar showing each member's share of the cumulative
/// pool of money. Segment widths are proportional to that member's
/// (non-negative) balance; segment colors come from [colorForUserId] so
/// they line up with each member's avatar ring.
class PoolBar extends StatelessWidget {
  const PoolBar({
    super.key,
    required this.members,
    required this.balances,
    this.projectedDeltas = const {},
    this.height = 14,
  });

  final List<GroupMember> members;
  final List<Balance> balances;

  /// Per-member projection of *this* week's pool share if the week ended
  /// now. Rendered as a translucent extension of each member's segment so
  /// you can see who's winning the in-flight pool.
  final Map<String, int> projectedDeltas;
  final double height;

  @override
  Widget build(BuildContext context) {
    final byUser = {for (final b in balances) b.userId: b.balance};
    final shares = <({
      String userId,
      String name,
      int balance,
      int projected,
    })>[
      for (final m in members)
        (
          userId: m.userId,
          name: m.profile.name.isEmpty ? 'Member' : m.profile.name,
          balance: (byUser[m.userId] ?? 0).clamp(0, 1 << 31),
          projected:
              (projectedDeltas[m.userId] ?? 0).clamp(0, 1 << 31),
        ),
    ];
    final total = shares.fold<int>(0, (a, s) => a + s.balance);
    final totalProjected = shares.fold<int>(0, (a, s) => a + s.projected);
    final hasProjection = totalProjected > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pool split', style: AppTheme.caption),
              Text(
                total > 0 || hasProjection
                    ? '${formatCents(total)}'
                        '${hasProjection ? ' + ${formatCents(totalProjected)} this week' : ''}'
                    : '—',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: height,
              child: (total == 0 && !hasProjection)
                  ? Container(color: AppTheme.subtle)
                  : Row(
                      children: [
                        for (final s in shares) ...[
                          if (s.balance > 0)
                            Expanded(
                              flex: s.balance,
                              child: Container(
                                color: colorForUserId(s.userId),
                              ),
                            ),
                          if (s.projected > 0)
                            Expanded(
                              flex: s.projected,
                              child: Container(
                                color: colorForUserId(s.userId)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final s in shares)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorForUserId(s.userId),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total == 0
                          ? s.name
                          : '${s.name} · ${formatCents(s.balance)}',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
