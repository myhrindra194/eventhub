import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:flutter/material.dart';

/// Ergonomics on [BuildContext]: theme access and the two feedback helpers
/// every screen needs. Keeping snack bars here guarantees one visual
/// treatment for success/error messages across the whole product.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  /// Screen metrics, read without rebuilding on unrelated MediaQuery changes.
  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.paddingOf(this);
  bool get isCompact => AppBreakpoints.isCompact(screenSize.width);

  void showToast(
    String message, {
    AppTone tone = AppTone.neutral,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final t = tokens;
    final resolved = tone == AppTone.neutral ? null : t.resolve(tone);
    final foreground =
        resolved?.onSolid ?? (t.isDark ? t.textPrimary : Colors.white);

    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
          backgroundColor: resolved?.solid,
          action: action,
        ),
      );
  }

  void showSuccess(String message) => showToast(
    message,
    tone: AppTone.success,
    icon: Icons.check_circle_rounded,
  );

  void showFailure(Failure failure) => showToast(
    failure.message,
    tone: AppTone.danger,
    icon: Icons.error_outline_rounded,
  );
}
