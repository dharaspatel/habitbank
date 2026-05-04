import 'package:flutter/cupertino.dart';

/// Hard cap on members per group — matches the 7-color avatar palette so
/// every member gets a distinct color. Enforced server-side in the
/// `join_group_by_invite` RPC and surfaced client-side as
/// [GroupFullException].
const int kMaxGroupSize = 7;

/// Stable per-user color used for avatar rings and the pool-share bar.
/// Hashing the userId keeps the same person's color consistent across
/// rebuilds and group screens without needing a server-assigned color.
// Fixed 7-color set for member avatars. Greens are reserved for the
// workout progress ring, so they are intentionally absent.
const List<Color> kMemberPalette = [
  Color(0xFFFFD60A), // yellow
  Color(0xFFE63946), // red
  Color(0xFF9D00FF), // purple
  Color(0xFF118AB2), // blue
  Color(0xFFCC5500), // orange
  Color(0xFFFF4FA3), // pink
  Color(0xFF3D5AFE), // indigo
];

Color colorForUserId(String userId) {
  if (userId.isEmpty) return kMemberPalette[0];
  var hash = 0;
  for (final code in userId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return kMemberPalette[hash % kMemberPalette.length];
}
