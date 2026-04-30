import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

/// Circular avatar with an optional colored ring. The ring color encodes
/// progress towards a goal: passing [progress] fills the ring proportionally.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.size,
    this.photoUrl,
    this.initial,
    this.ringColor,
    this.ringWidth = 2,
  });

  final double size;
  final String? photoUrl;
  final String? initial;

  /// If set, draws a solid ring of this color around the avatar.
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.subtle,
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: photoUrl == null
          ? Text(
              (initial?.isNotEmpty == true)
                  ? initial![0].toUpperCase()
                  : '',
              style: TextStyle(
                inherit: false,
                color: AppTheme.muted,
                fontSize: size * 0.45,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Display',
                decoration: TextDecoration.none,
              ),
            )
          : null,
    );
    if (ringColor == null) return inner;
    return Container(
      padding: EdgeInsets.all(ringWidth + 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: ringWidth),
      ),
      child: inner,
    );
  }
}

/// Row of overlapping avatars; [extraCount] renders a "+N" pill when the
/// caller has more members than [maxVisible].
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.avatars,
    this.size = 36,
    this.maxVisible = 5,
  });

  final List<AvatarCircle> avatars;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = avatars.take(maxVisible).toList();
    final overflow = avatars.length - visible.length;
    final overlap = size * 0.35;
    return SizedBox(
      height: size + 8,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: visible[i],
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.subtle,
                  border:
                      Border.all(color: AppTheme.background, width: 2),
                ),
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    inherit: false,
                    color: AppTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: '.SF Pro Text',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
