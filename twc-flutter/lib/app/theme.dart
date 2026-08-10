import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF00A86B),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF111111),
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF00A86B),
      unselectedItemColor: Color(0xFF888888),
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00A86B),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00A86B),
      secondary: Color(0xFF00A86B),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111111),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00A86B),
    scaffoldBackgroundColor: const Color(0xFF0B0B0B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF00A86B),
      unselectedItemColor: Color(0xFF888888),
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00A86B),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00A86B),
      secondary: Color(0xFF00A86B),
      surface: Color(0xFF1E1E1E),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFFFFF),
    ),
  );
}
