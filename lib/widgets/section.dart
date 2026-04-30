import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.caption.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key, this.indent = 16});
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(height: 0.5, color: AppTheme.subtle),
    );
  }
}
