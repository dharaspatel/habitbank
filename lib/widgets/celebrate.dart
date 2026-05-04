import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Celebrate {
  static const _palette = <Color>[
    Color(0xFFFFD166),
    Color(0xFFEF476F),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFF8338EC),
  ];

  /// Plays a celebratory haptic and bursts confetti from the top-center of
  /// the root overlay. Safe to call right before popping the current route —
  /// the overlay lives on the parent navigator so the animation continues.
  static void fire(BuildContext context, {bool big = false}) {
    HapticFeedback.mediumImpact();
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    final controller =
        ConfettiController(duration: const Duration(milliseconds: 700));
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: controller,
            blastDirection: math.pi / 2, // downward
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: big ? 40 : 22,
            emissionFrequency: 0.04,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            shouldLoop: false,
            colors: _palette,
          ),
        ),
      );
    });
    overlayState.insert(entry);
    controller.play();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      controller.dispose();
      entry.remove();
    });
  }

  static void success() => HapticFeedback.mediumImpact();
  static void tap() => HapticFeedback.selectionClick();
}
