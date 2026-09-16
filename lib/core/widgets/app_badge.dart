import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Le volume sonore d’un badge.
enum BadgeStyle {
  /// Fond teinté, texte coloré. Le défaut : lisible sans voler l’attention
  /// au contenu qu’il annote.
  soft,

  /// Pleinement saturé. Réservé aux états que l’utilisateur ne doit pas
  /// manquer (« Complet », « En direct »).
  solid,

  /// Transparent avec un filet coloré. Pour les badges posés sur une image.
  outline,
}

/// Étiquette de statut compacte.
///
/// Volontairement petite, en capitales et au tracking généreux : un badge
/// est une étiquette *machine*, pas de la prose, et le traitement
/// typographique le signale d’un coup d’œil.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.tone = AppTone.brand,
    this.style = BadgeStyle.soft,
    this.icon,
    this.dense = false,
  });

  final String label;
  final AppTone tone;
  final BadgeStyle style;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    final (bg, fg, border) = switch (style) {
      BadgeStyle.soft => (colors.bg, colors.fg, null),
      BadgeStyle.solid => (colors.solid, colors.onSolid, null),
      BadgeStyle.outline => (Colors.transparent, colors.fg, colors.border),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brButton,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontSize: dense ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un point pulsant plus un libellé, pour les états « en direct » que le
/// mouvement met en valeur.
class LiveBadge extends StatefulWidget {
  const LiveBadge({
    required this.label,
    super.key,
    this.tone = AppTone.success,
  });

  final String label;
  final AppTone tone;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(widget.tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.solid,
        borderRadius: AppRadius.brButton,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.onSolid,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSolid),
          ),
        ],
      ),
    );
  }
}

/// Pastille de date dépolie sur deux lignes, posée sur la couverture d’un
/// événement.
///
/// C’est la métaphore de la page de calendrier qu’emploie toute application
/// de billetterie, parce que la date est la première chose qu’un utilisateur
/// cherche du regard sur une carte d’événement.
class DateBadge extends StatelessWidget {
  const DateBadge({
    required this.month,
    required this.day,
    super.key,
    this.compact = false,
  });

  final String month;
  final String day;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? 5 : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                month.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: AppPalette.iris700,
                  fontSize: compact ? 9 : 10,
                ),
              ),
              Text(
                day,
                style: text.titleLarge?.copyWith(
                  color: AppPalette.neutral900,
                  fontSize: compact ? 16 : 19,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille compteur — notifications non lues, participants, filtres
/// appliqués. Utilise des chiffres tabulaires pour que la largeur ne danse
/// pas.
class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    super.key,
    this.tone = AppTone.brand,
    this.max = 99,
  });

  final int count;
  final AppTone tone;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.solid,
        borderRadius: AppRadius.brButton,
      ),
      child: Text(
        count > max ? '$max+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSolid,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
