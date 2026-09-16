import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_surface.dart';
import 'package:flutter/material.dart';

/// La mise en page partagée des trois états « il n'y a rien à montrer ».
///
/// Ils sont traités comme des écrans à part entière, jamais comme un
/// après-coup : c'est devant un état vide ou en échec que l'utilisateur
/// décide si le produit est cassé ou simplement neuf. Chacun reçoit donc une
/// icône de qualité d'illustration, un titre qui nomme la situation, une
/// phrase qui l'explique et — surtout — une action qui sort de l'impasse.
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
            // Centrage explicite de l'icône : selon le parent (sliver, liste,
            // colonne étirée), elle se retrouvait calée à gauche alors que le
            // texte, lui, restait centré.
            Center(child: hero),
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

/// Halo radial doux derrière l'icône d'état — assez de présence pour ancrer
/// la colonne, sans commander toute une série d'illustrations.
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
            expand: false,
            size: AppButtonSize.medium,
            onPressed: onRetry,
          ),
  );
}
