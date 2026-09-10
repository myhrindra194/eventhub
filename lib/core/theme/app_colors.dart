import 'package:flutter/material.dart';

abstract class AppColors {
  // Dark Mode
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF14171C);
  static const Color darkSurfaceLight = Color(0xFF1E2229);

  // Light Mode
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF3F4F6);

  // Accent and state colors.
  static const Color accentIndigo = Color.fromRGBO(103, 58, 183, 1.0);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Dark mode text colors.
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Light mode text colors.
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
}
