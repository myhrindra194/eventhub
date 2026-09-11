import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_surface.dart';
import 'package:flutter/material.dart';

/// Shared layout for the three "there is nothing to show" states.
///
/// They are treated as first-class screens, not afterthoughts: an empty or
/// failing state is where a user decides whether the product is broken or
/// simply new. Each one gets an illustration-grade icon, a title that names
/// the situation, a sentence that explains it, and — crucially — an action
/// that gets the user out of the dead end.
class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.hero,
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
  });

  final Widget hero;
  final String title;
  final String message;
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            hero,
            const SizedBox(height: AppSpacing.xl),
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft radial glow behind the state icon — enough presence to anchor the
/// column without commissioning an illustration set.
class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.icon, required this.tone});

  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    return SizedBox.square(
      dimension: 128,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors.solid.withValues(alpha: 0.18),
              colors.solid.withValues(alpha: 0),
            ],
          ),
        ),
        child: Center(
          child: IconTile(
            icon: icon,
            size: 68,
            color: colors.fg,
            background: colors.bg,
          ),
        ),
      ),
    );
  }
}

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    return _StateLayout(
      hero: const SizedBox.square(
        dimension: 56,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      title: title!,
      message: message ?? AppStrings.loading,
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.message,
    super.key,
    this.icon = Icons.event_busy_rounded,
    this.title,
    this.action,
    this.secondaryAction,
    this.tone = AppTone.brand,
  });

  final String message;
  final IconData icon;
  final String? title;
  final Widget? action;
  final Widget? secondaryAction;
  final AppTone tone;

  @override
  Widget build(BuildContext context) => _StateLayout(
    hero: _GlowIcon(icon: icon, tone: tone),
    title: title ?? '',
    message: message,
    action: action,
    secondaryAction: secondaryAction,
  );
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    super.key,
    this.title,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _StateLayout(
    hero: _GlowIcon(icon: icon, tone: AppTone.danger),
    title: title ?? AppStrings.errorGeneric,
    message: message,
    action: onRetry == null
        ? null
        : AppButton.secondary(
            label: AppStrings.retry,
            icon: Icons.refresh_rounded,
            expand: false,
            size: AppButtonSize.medium,
            onPressed: onRetry,
          ),
  );
}
