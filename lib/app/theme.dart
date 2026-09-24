import 'package:flutter/cupertino.dart';

abstract final class TunlyTheme {
  static const background = Color(0xFF090A0C);
  static const surface = Color(0xFF17191D);
  static const elevated = Color(0xFF22252B);
  static const accent = Color(0xFFB8F36B);
  static const secondaryText = Color(0xFFA1A5AE);

  static const dark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: accent,
    scaffoldBackgroundColor: background,
    barBackgroundColor: Color(0xE6111215),
    textTheme: CupertinoTextThemeData(
      primaryColor: accent,
      textStyle:
          TextStyle(fontFamily: '.SF Pro Display', color: Color(0xFFF6F6F7)),
      navTitleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFF6F6F7)),
      navLargeTitleTextStyle: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFF6F6F7)),
    ),
  );
}
