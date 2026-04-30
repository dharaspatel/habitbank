import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

/// Rounded, hairline-bordered surface used for every card-shaped block in
/// the app: group tiles on home, member tiles, the "you could lose" pill,
/// the workout-photo card. White on white with a subtle 1-px border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.subtle, width: 1),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return inner;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: inner,
    );
  }
}
