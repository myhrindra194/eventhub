import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Opens a modal bottom sheet with the product's chrome already applied
/// (6 px top corners, scrim, safe-area padding, scroll control).
///
/// Sheets are preferred to dialogs for anything with more than one line of
/// content: they stay within thumb reach, they can grow, and dismissing by
/// dragging is more forgiving than hunting for a small "cancel".
///
/// There is deliberately **no drag handle**. The grabber pill is an iOS
/// convention that reads as template chrome; every sheet carries an explicit
/// close button instead, and drag-to-dismiss still works.
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
    // Set here as well as in the theme, so a sheet looks right even under a
    // theme that does not come from `AppTheme`.
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brModalSheet),
    backgroundColor: context.tokens.surfaceOverlay,
    barrierColor: context.tokens.scrim,
    builder: builder,
  );
}

/// Standard layout inside a sheet.
///
/// Three bands separated by hairlines — header, content, actions — rather
/// than one centred column: the header states what the sheet is and how to
/// leave it, the content scrolls on its own, and the actions stay anchored
/// at the bottom however long the content gets.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// Padding of the content band.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.headlineSmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(subtitle!, style: text.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const SheetCloseButton(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: t.borderSubtle),
            Flexible(
              child: Padding(padding: padding, child: child),
            ),
            if (actions.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: t.borderSubtle),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Square ✕ with the 6 px control radius — the explicit way out that
/// replaces the drag handle.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, this.onPressed});

  /// Defaults to popping the sheet with no result.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      tooltip: 'Fermer',
      icon: const Icon(Icons.close_rounded, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: t.textSecondary,
        backgroundColor: t.surfaceSunken,
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brButton,
          side: BorderSide(color: t.border),
        ),
      ),
    );
  }
}

/// Confirmation sheet for an irreversible action.
///
/// Left-aligned, like a letter rather than a pop-up: a tinted 6 px square
/// carrying the subject, the consequence spelled out in plain French, then
/// the two choices. The destructive button sits **above** "Annuler" so the
/// safe option is the one closest to the thumb. Returns `false` when
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
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.brButton,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(icon, size: 22, color: colors.fg),
                  ),
                  const Spacer(),
                  SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              // The content keeps the xl gutter on the right even though the
              // header row hugs the close button closer to the edge.
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: text.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      style: text.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: confirmLabel,
                      variant: tone == AppTone.danger
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      elevated: false,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.secondary(
                      label: cancelLabel,
                      elevated: false,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
