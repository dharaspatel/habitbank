import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

/// Lightweight shimmer placeholder — a soft gradient that slides across a
/// muted box. Use as a stand-in while remote images or content load.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    this.borderRadius,
    this.baseColor = AppTheme.subtle,
    this.highlightColor = const Color(0xFFEDEDED),
    this.duration = const Duration(milliseconds: 1200),
  });

  final BorderRadius? borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2 * t - 0.4, 0),
                end: Alignment(-1.0 + 2 * t + 0.4, 0),
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
