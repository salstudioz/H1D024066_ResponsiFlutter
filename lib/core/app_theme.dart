import 'package:flutter/material.dart';

/// Pengaturan Theme (Material 3) modern untuk Light Mode dan Dark Mode.
/// Terinspirasi dari desain cuaca kontemporer (pastel hero card, dark obsidian cards,
/// tipografi modern, dan kontras tajam).
class AppTheme {
  const AppTheme._();

  // ----- Warna Light Mode -----
  static const Color lightBg = Color(0xFFF7F9FD);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFFFF753E);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ----- Warna Dark Mode -----
  static const Color darkBg = Color(0xFF0C101B);
  static const Color darkSurface = Color(0xFF151C2C);
  static const Color darkCardHover = Color(0xFF1E273D);
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkSecondary = Color(0xFFFFD600);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: lightPrimary,
          secondary: lightSecondary,
          surface: lightSurface,
          onSurface: lightTextPrimary,
          onSurfaceVariant: lightTextSecondary,
        ),
        cardColor: lightSurface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        dividerColor: const Color(0xFFE2E8F0),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 68,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: lightTextPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: lightTextPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: lightTextPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: lightTextPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: lightTextSecondary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: lightTextSecondary,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: darkPrimary,
          secondary: darkSecondary,
          surface: darkSurface,
          onSurface: darkTextPrimary,
          onSurfaceVariant: darkTextSecondary,
        ),
        cardColor: darkSurface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        dividerColor: const Color(0xFF1E293B),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 68,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: darkTextPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: darkTextPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: darkTextPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: darkTextSecondary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: darkTextSecondary,
          ),
        ),
      );
}
