import 'package:flutter/widgets.dart';

/// Échelle d’espacement — une grille stricte de 4 pt.
///
/// Ne jamais coder un padding en dur : prendre le pas le plus proche. Une
/// mise en page construite sur une échelle finie se lit comme un choix ;
/// une mise en page faite de nombres arbitraires se lit comme un accident,
/// et cet écart constitue l’essentiel de ce qu’on appelle un « design
/// mature ».
abstract final class AppSpacing {
  static const none = 0.0;
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 56.0;

  /// Gouttière horizontale de tous les écrans. Source de vérité unique :
  /// changez-la ici et toute l’app se réaligne.
  static const gutter = 20.0;

  static const screen = EdgeInsets.symmetric(horizontal: gutter);
}

/// Rayons d’angle.
///
/// L’échelle est **volontairement plate à 6 px**. Tout rectangle arrondi —
/// bouton, champ, carte, chip, badge, sheet, dialogue, snack bar, image,
/// piste — reçoit la même arête dessinée. Les paliers nommés (`xs` … `xxxl`)
/// sont conservés pour que les appels disent encore *quel* rôle joue un
/// angle, mais ils résolvent tous vers la même valeur : une arête franche,
/// répétée, se lit comme une décision ; une échelle de rayons voisins se lit
/// comme un template par défaut.
///
/// Un cercle est une autre forme, pas un rayon plus grand : avatars, points
/// de statut, points de pagination et boutons ronds à icône seule utilisent
/// `BoxShape.circle` / `CircleBorder`, jamais un rayon.
abstract final class AppRadius {
  /// 6 px, ce n’est pas un rectangle arrondi qui se prend pour une pilule :
  /// ça se lit comme une arête dessinée. Les grands rayons sont le signe le
  /// plus flagrant d’un template par défaut, et l’identité du produit tient
  /// à sa photographie et à sa typographie, pas à des angles mous.
  static const button = 6.0;

  /// Les champs partagent le rayon des boutons.
  static const input = button;

  static const xs = button;
  static const sm = button;
  static const md = button;
  static const lg = button;
  static const xl = button;
  static const xxl = button;
  static const xxxl = button;

  /// Extrémités totalement arrondies. Réservé aux points de pagination et
  /// aux indicateurs filaires dont la hauteur *est* le diamètre — jamais
  /// pour une forme qui contient du texte.
  static const pill = 999.0;

  static const brButton = BorderRadius.all(Radius.circular(button));
  static const brInput = BorderRadius.all(Radius.circular(input));
  static const brXs = BorderRadius.all(Radius.circular(xs));
  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
  static const brXxl = BorderRadius.all(Radius.circular(xxl));
  static const brPill = BorderRadius.all(Radius.circular(pill));

  /// Arrondi du haut uniquement, pour la feuille de contenu qui chevauche
  /// une image hero. Les mêmes 6 px que partout ailleurs.
  static const brSheet = BorderRadius.vertical(top: Radius.circular(xxxl));

  /// Les bottom sheets modales utilisent le rayon des contrôles, et non
  /// [brSheet] : une sheet est un panneau dans lequel l’utilisateur agit,
  /// elle reprend donc la même arête dessinée à 6 px que les boutons et les
  /// champs qu’elle contient.
  static const brModalSheet = BorderRadius.vertical(
    top: Radius.circular(button),
  );
}

/// Dimensions des cibles tactiles et des contrôles.
abstract final class AppSizes {
  /// Cible tactile minimale imposée par WCAG / Material.
  static const minTouch = 48.0;

  static const buttonSm = 40.0;
  static const buttonMd = 48.0;
  static const buttonLg = 56.0;

  static const inputHeight = 56.0;

  /// Hauteur utile de la barre d'onglets, hors zone du geste d'accueil :
  /// 49 points sur iOS, arrondis à 52 pour la cible tactile d'Android.
  static const navBarHeight = 52.0;

  /// Espace qu’une zone scrollable doit réserver pour que son dernier
  /// élément passe au-dessus de la barre d'onglets : sa hauteur, la zone du
  /// geste d'accueil la plus haute (34 points) et une respiration.
  static const navBarInset = 104.0;

  /// Largeur de contenu maximale — au-delà, une colonne unique paraît
  /// étirée sur tablettes et pliables ; le contenu est donc centré.
  static const maxContentWidth = 560.0;
}

/// Points de rupture de mise en page (window size classes de Material 3,
/// réduites à ce à quoi le produit s’adapte réellement).
abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;

  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= medium;
}
