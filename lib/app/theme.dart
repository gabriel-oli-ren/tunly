import 'package:flutter/cupertino.dart';

abstract final class TunlyTheme {
  static const background = Color(0xFF050A17);
  static const surface = Color(0xFF0C1630);
  static const elevated = Color(0xFF15234A);
  static const accent = Color(0xFF465BFF);
  static const secondaryText = Color(0xFFA5ACC0);

  static const dark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: accent,
    scaffoldBackgroundColor: background,
    barBackgroundColor: Color(0xF2050A17),
    textTheme: CupertinoTextThemeData(
      primaryColor: accent,
      textStyle: TextStyle(color: Color(0xFFF7F8FC)),
      navTitleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFF7F8FC)),
      navLargeTitleTextStyle: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFF7F8FC)),
    ),
  );
}
