import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4A90D9),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1E1E1E),
      onPrimary: Color(0xFFFFFFFF),
    ),
    dividerColor: const Color(0xFFE0E0E0),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4A90D9),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFD4D4D4),
      onPrimary: Color(0xFFFFFFFF),
    ),
    dividerColor: const Color(0xFF333333),
  );
}
