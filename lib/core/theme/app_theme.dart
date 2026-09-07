import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract class AppTheme {
  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentIndigo,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.display(true),
        headlineLarge: AppTypography.heading1(true),
        headlineMedium: AppTypography.heading2(true),
        titleMedium: AppTypography.heading3(true),
        bodyLarge: AppTypography.bodyLarge(true),
        bodyMedium: AppTypography.body(true),
        bodySmall: AppTypography.caption(true),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        prefixIconColor: AppColors.darkTextSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentIndigo,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: AppColors.accentIndigo,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.display(false),
        headlineLarge: AppTypography.heading1(false),
        headlineMedium: AppTypography.heading2(false),
        titleMedium: AppTypography.heading3(false),
        bodyLarge: AppTypography.bodyLarge(false),
        bodyMedium: AppTypography.body(false),
        bodySmall: AppTypography.caption(false),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
        prefixIconColor: AppColors.lightTextSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
    );
  }
}