import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppTheme.foreground,
      borderRadius: BorderRadius.circular(12),
      onPressed: busy ? null : onPressed,
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(color: AppTheme.background),
                const SizedBox(width: 12),
                Text(
                  busyLabel ?? label,
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: const TextStyle(
                color: AppTheme.background,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
