import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTypography {
  static TextStyle display(bool isDark) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle heading1(bool isDark) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle heading2(bool isDark) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle heading3(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle bodyLarge(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle body(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle caption(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        letterSpacing: 0.5,
      );
}