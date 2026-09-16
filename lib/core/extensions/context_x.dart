import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:flutter/material.dart';

/// Ergonomie sur [BuildContext] : accès au thème et les deux helpers de
/// retour visuel dont tout écran a besoin. Centraliser ici les snack bars
/// garantit un traitement visuel unique des messages de succès et d’erreur
/// dans tout le produit.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  /// Métriques de l’écran, lues sans reconstruire sur les changements de
  /// MediaQuery sans rapport.
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
