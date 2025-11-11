import 'package:flutter/material.dart';

/// Color palette extracted from your screenshot
class AppColors {
  static const Color orange = Color(0xFFFE7508); // Accent Orange
  static const Color lavender = Color(0xFFD1C9E9); // Soft Lavender
  static const Color deepPurple = Color(0xFF3D26CD); // Deep Blue-Purple
  static const Color white = Color(0xFFFFFFFF); // Pure White
  static const Color offWhite = Color(0xFFF8F8FD); // Slight Off-White
  static const Color darkIndigo = Color(0xFF3820CC); // Dark Indigo
  static const Color mediumPurple = Color(0xFF6857D8); // Medium Purple
  static const Color royalPurple = Color(0xFF5743D4); // Royal Purple
}

/// Application theme definitions
class AppTheme {
  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.deepPurple,
    scaffoldBackgroundColor: AppColors.offWhite,
    colorScheme: ColorScheme.light(
      primary: AppColors.deepPurple,
      secondary: AppColors.orange,
      background: AppColors.offWhite,
      surface: AppColors.lavender,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepPurple,
      foregroundColor: AppColors.white,
      elevation: 4,
      shadowColor: Colors.black26,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 4,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.deepPurple,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    ),
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.royalPurple,
    scaffoldBackgroundColor: AppColors.darkIndigo,
    colorScheme: ColorScheme.dark(
      primary: AppColors.royalPurple,
      secondary: AppColors.orange,
      background: AppColors.darkIndigo,
      surface: AppColors.deepPurple,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.royalPurple,
      foregroundColor: AppColors.white,
      elevation: 4,
      shadowColor: Colors.black54,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 4,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
    ),
  );
}
