import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_surface.dart';
import 'package:flutter/material.dart';

/// Opens a modal bottom sheet with the product's chrome already applied
/// (drag handle, rounded top, scrim, safe-area padding, scroll control).
///
/// Sheets are preferred to dialogs for anything with more than one line of
/// content: they stay within thumb reach, they can grow, and dismissing by
/// dragging is more forgiving than hunting for a small "cancel".
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useSafeArea: true,
    backgroundColor: context.tokens.surfaceOverlay,
    barrierColor: context.tokens.scrim,
    builder: builder,
  );
}

/// Standard layout inside a sheet: title, optional subtitle, content, and
/// an action area pinned at the bottom.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: text.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.xl),
              Flexible(child: child),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation sheet for an irreversible action.
///
/// Deliberately heavy: a large tinted icon, the consequence spelled out in
/// plain French, and the destructive button placed **above** "Annuler" so
/// the safe option is the one closest to the thumb. Returns `false` when
/// dismissed, never `null`.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  IconData icon = Icons.delete_outline_rounded,
  AppTone tone = AppTone.danger,
}) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (context) {
      final colors = context.tokens.resolve(tone);
      final text = Theme.of(context).textTheme;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: IconTile(
                  icon: icon,
                  size: 68,
                  color: colors.fg,
                  background: colors.bg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: confirmLabel,
                variant: tone == AppTone.danger
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
