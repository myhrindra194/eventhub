import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Écran d'accueil temporaire — à remplacer par le vrai écran
/// de découverte des événements ("Explore Events").
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Text(
          'Home Screen — à construire',
          style: AppTypography.heading2(isDark),
        ),
      ),
    );
  }
}