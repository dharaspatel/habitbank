import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

/// Circular progress ring with the current value rendered in the middle and
/// an optional caption below. Used for the "this week" card on the group
/// detail screen ("0/4 complete").
class WeekProgressRing extends StatelessWidget {
  const WeekProgressRing({
    super.key,
    required this.value,
    required this.target,
    this.size = 160,
    this.caption,
  });

  final int value;
  final int target;
  final double size;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final pct = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: pct),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value/$target',
                style: TextStyle(
                  inherit: false,
                  color: AppTheme.foreground,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  fontFamily: '.SF Pro Display',
                  letterSpacing: -1,
                  decoration: TextDecoration.none,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(caption!, style: AppTheme.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = AppTheme.subtle;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.foreground;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}
