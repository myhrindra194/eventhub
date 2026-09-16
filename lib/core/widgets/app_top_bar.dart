import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// L'unique barre supérieure du produit.
///
/// Deux formes, et seulement deux, parce qu'il n'existe que deux situations :
///
///  * [AppTopBar.root] — une des destinations de la navigation. Pas de
///    retour : on ne « revient » pas d'un onglet, on en change. Le titre est
///    celui de l'onglet, et les actions (cloche, avatar) vivent à droite.
///  * [AppTopBar.subPage] — un écran empilé par-dessus. Il porte toujours le
///    même retour : le disque accentué de [CircleBackButton], celui de
///    « Modifier mon profil ». Une flèche nue selon l'écran et un disque
///    selon un autre, c'est exactement ce qui fait qu'une application paraît
///    assemblée par morceaux.
///
/// Le fond est **exactement** celui de la barre d'onglets ([AppNavBar]) : la
/// surface opaque `surface`, avec un filet d'un demi-point côté contenu. Les
/// deux barres encadrent ainsi le contenu d'une seule couleur, identique
/// quel que soit ce qui défile dessous. Ni ombre ni élévation : c'est le
/// filet qui sépare.
///
/// **Pourquoi plus de flou.** La barre du haut ne recouvre rien au repos : le
/// corps de l'écran commence *sous* elle. Un `BackdropFilter` sans rien à
/// flouter est rendu en noir par le moteur Impeller d'Android — c'est ce qui
/// peignait la barre en noir sur un téléphone, avec un titre illisible.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Barre d'une destination de premier niveau.
  const AppTopBar.root({
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
  }) : onBack = null;

  /// Barre d'un écran empilé, avec le retour standard.
  const AppTopBar.subPage({
    required this.title,
    required this.onBack,
    super.key,
    this.subtitle,
    this.actions = const [],
  });

  final String title;

  /// Ligne de contexte sous le titre : la date d'un événement, le nom d'un
  /// compte. Facultative — elle ne doit jamais répéter le titre.
  final String? subtitle;
  final List<Widget> actions;

  /// `null` sur une destination de premier niveau.
  final VoidCallback? onBack;

  /// Diamètre du disque de retour, repris de [CircleBackButton].
  static const _backSize = 44.0;

  /// Hauteur de base ; une ligne de contexte ajoute sa hauteur de texte.
  static const _baseHeight = 68.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? _baseHeight : _baseHeight + 20);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final hasBack = onBack != null;

    return AppBar(
      automaticallyImplyLeading: false,
      // Couleur opaque portée par l'AppBar elle-même, et non un fond
      // transparent recouvert d'un décor : sur certains GPU Android (Mali /
      // MediaTek sous Impeller), le `Material` transparent d'une AppBar est
      // composé en noir, quel que soit ce qu'on peint dessous.
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      shape: Border(bottom: BorderSide(color: t.border, width: 0.5)),
      // Sans retour, le titre s'aligne sur la gouttière de l'écran ; avec
      // retour, il se cale à droite du disque, à la même distance.
      titleSpacing: hasBack ? AppSpacing.md : AppSpacing.gutter,
      leadingWidth: hasBack ? AppSpacing.gutter + _backSize : 0,
      leading: hasBack
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpacing.gutter),
              child: Center(child: CircleBackButton(onPressed: onBack!)),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: text.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: text.bodySmall?.copyWith(color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        ...actions,
        // La dernière action s'arrête sur la gouttière, comme le titre en
        // face : une icône collée au bord casse l'alignement de l'écran.
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}
