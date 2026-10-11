import 'package:flutter/material.dart';

/// Clinical Theme System for Tabib Medical AI Doctor.
/// Features high-contrast, professional Material 3 styling with medical teal & emerald accents.
class AppTheme {
  // Medical Brand Color Palette
  static const Color primaryTeal = Color(0xFF00897B); // Deep clinical teal
  static const Color primaryTealDark = Color(0xFF00695C);
  static const Color primaryTealLight = Color(0xFF4DB6AC);
  static const Color accentEmerald = Color(0xFF10B981); // Verified status emerald
  static const Color emergencyRed = Color(0xFFEF4444); // Critical red flag alert
  static const Color warningAmber = Color(0xFFF59E0B);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Dark Clinical Palette
  static const Color darkBg = Color(0xFF0B111E);
  static const Color darkSurface = Color(0xFF131D31);
  static const Color darkSurfaceCard = Color(0xFF1A2640);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: primaryTeal,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE0F2F1),
      onPrimaryContainer: primaryTealDark,
      secondary: accentEmerald,
      onSecondary: Colors.white,
      error: emergencyRed,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: primaryTealLight,
      onPrimary: const Color(0xFF00332C),
      primaryContainer: const Color(0xFF004D40),
      onPrimaryContainer: const Color(0xFFA7FFEB),
      secondary: accentEmerald,
      onSecondary: Colors.black,
      error: emergencyRed,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF243350)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryTealLight, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTealLight,
          foregroundColor: const Color(0xFF042F2C),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
