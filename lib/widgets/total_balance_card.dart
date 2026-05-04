import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../config/theme.dart';
import 'money_field.dart';

/// Frosted-glass green card showing the user's total balance and the
/// week-over-week trend. Drop-in for the top of the home screen.
class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({
    super.key,
    required this.balanceCents,
    required this.weekOverWeekChange,
  });

  final int balanceCents;
  final double? weekOverWeekChange;

  static const Color _green = Color(0xFF0F9D58);
  static const Color _greenDeep = Color(0xFF0B7A45);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _green.withValues(alpha: 0.18),
                _green.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: _green.withValues(alpha: 0.35),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total balance',
                style: AppTheme.caption.copyWith(
                  color: _greenDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatSignedMoney(balanceCents),
                style: AppTheme.balanceLarge.copyWith(color: _greenDeep),
              ),
              const SizedBox(height: 8),
              _Trend(change: weekOverWeekChange, color: _greenDeep),
            ],
          ),
        ),
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.change, required this.color});
  final double? change;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = change;
    final IconData icon;
    final String label;
    if (c == null) {
      icon = CupertinoIcons.minus;
      label = 'no data yet';
    } else if (c > 0) {
      icon = CupertinoIcons.arrow_up_right;
      label = '${(c * 100).round()}% vs last week';
    } else if (c < 0) {
      icon = CupertinoIcons.arrow_down_right;
      label = '${(c * 100).abs().round()}% vs last week';
    } else {
      icon = CupertinoIcons.minus;
      label = 'flat vs last week';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatSignedMoney(int cents) {
  final abs = formatCents(cents.abs());
  return cents < 0 ? '−$abs' : abs;
}
