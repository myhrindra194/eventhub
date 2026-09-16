import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/widgets.dart';

/// Les bandes de largeur auxquelles le produit s'adapte réellement.
///
/// Trois, pas sept. Chaque bande supplémentaire est une mise en page que
/// personne ne teste : le design doit seulement tenir sur un téléphone
/// d'entrée de gamme de 320 dp, sur les 360–430 dp du courant, et au-delà, là
/// où une colonne unique paraîtrait étirée.
enum ScreenSize {
  /// < 360 dp — petits téléphones, ou écran partagé.
  small,

  /// 360–599 dp — le téléphone pour lequel le design est dessiné.
  medium,

  /// >= 600 dp — tablettes, pliables, fenêtres de bureau.
  expanded;

  static ScreenSize of(double width) {
    if (width < 360) return ScreenSize.small;
    if (width < AppBreakpoints.compact) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

extension ResponsiveX on BuildContext {
  ScreenSize get screenSize => ScreenSize.of(MediaQuery.sizeOf(this).width);

  bool get isSmallScreen => screenSize == ScreenSize.small;
  bool get isExpandedScreen => screenSize == ScreenSize.expanded;

  /// Choisit une valeur par bande. [medium] est la référence ; les deux
  /// autres s'y rabattent, de sorte qu'un appelant ne redéfinit que ce qui
  /// doit vraiment changer.
  ///
  /// ```dart
  /// final hero = context.responsive(medium: 148.0, small: 116.0);
  /// ```
  T responsive<T>({required T medium, T? small, T? expanded}) =>
      switch (screenSize) {
        ScreenSize.small => small ?? medium,
        ScreenSize.medium => medium,
        ScreenSize.expanded => expanded ?? medium,
      };

  /// Gouttière horizontale, resserrée sur les écrans étroits où 20 dp de
  /// chaque côté mangent une part notable d'une ligne de 320 dp.
  double get gutter => responsive(medium: AppSpacing.gutter, small: 16.0);
}

/// Centre une colonne de contenu et plafonne sa largeur.
///
/// Au-delà d'environ 480 dp, une colonne de formulaire cesse d'être lisible
/// et commence à paraître abandonnée au milieu de la page. C'est ce plafond
/// qui rend le même écran utilisable sur un téléphone, un pliable et une
/// fenêtre de bureau, sans écrire une seconde mise en page.
class ResponsiveColumn extends StatelessWidget {
  const ResponsiveColumn({required this.child, super.key, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
