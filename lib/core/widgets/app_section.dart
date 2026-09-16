import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Petite légende en capitales qui introduit un groupe de contenu.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
  );
}

/// Titre de section, avec un « tout voir » facultatif.
///
/// Le fil d'accueil est bâti avec ceux-là : c'est une hiérarchie de sections
/// nommées, que l'œil parcourt, qui transforme une liste plate en quelque
/// chose qui paraît éditorialisé — le motif vers lequel toutes les grandes
/// places de marché ont convergé.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      0,
      AppSpacing.gutter,
      AppSpacing.md,
    ),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: t.brand,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                visualDensity: VisualDensity.compact,
              ),
              // Libellé seul : les boutons du produit ne portent pas
              // d'icône. La flèche doublait le sens de « Tout voir » sans
              // rien ajouter, et c'était le dernier bouton à en garder une.
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// L'en-tête par lequel s'ouvre un écran de premier niveau : une ligne de
/// surtitre, un grand titre, et une action facultative à droite — avatar,
/// bouton.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      AppSpacing.lg,
      AppSpacing.gutter,
      AppSpacing.lg,
    ),
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(title, style: text.displaySmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle!, style: text.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }
}

/// Barre en sliver dont le fond flouté apparaît en fondu au défilement : elle
/// garde un titre compact accessible sans voler de hauteur au repos. Utilisée
/// par les écrans de détail.
class FrostedSliverAppBar extends StatelessWidget {
  const FrostedSliverAppBar({
    required this.title,
    super.key,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Même surface opaque et même filet que AppTopBar et la barre
      // d'onglets. Opaque sur l'AppBar elle-même : un fond transparent est
      // composé en noir par certains GPU Android (voir AppTopBar).
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: t.border, width: 0.5)),
      leading: leading,
      actions: actions,
      title: Text(title, overflow: TextOverflow.ellipsis),
    );
  }
}
