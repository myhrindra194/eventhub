import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Couleurs selon la maquette
    Color backgroundColor;
    Color textColor;

    if (variant == AppButtonVariant.primary) {
      backgroundColor = const Color(0xFF6B65F6);
      textColor = Colors.white;
    } else {
      backgroundColor = isDark
          ? const Color(0xFF1E222B)
          : const Color(0xFFEFEFF4);
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: isDark
              ? const Color(0xFF16181D).withValues(alpha: 0.5)
              : Colors.grey.shade300,
          foregroundColor: textColor,
          disabledForegroundColor: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black26,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onPressed == null ? null : textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
