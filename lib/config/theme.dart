import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color background = CupertinoColors.white;
  static const Color foreground = CupertinoColors.black;
  static const Color subtle = Color(0xFFE5E5E5);
  static const Color muted = Color(0xFF8E8E93);

  static const CupertinoThemeData theme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: foreground,
    scaffoldBackgroundColor: background,
    barBackgroundColor: background,
    textTheme: CupertinoTextThemeData(
      primaryColor: foreground,
      textStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Text',
        color: foreground,
        fontSize: 16,
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Display',
        color: foreground,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Display',
        color: foreground,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        decoration: TextDecoration.none,
      ),
    ),
  );

  static const TextStyle balanceLarge = TextStyle(
    fontFamily: '.SF Pro Display',
    color: foreground,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: '.SF Pro Display',
    color: foreground,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: '.SF Pro Text',
    color: foreground,
    fontSize: 16,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: '.SF Pro Text',
    color: muted,
    fontSize: 13,
  );
}
