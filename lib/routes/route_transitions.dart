import 'package:eventhub/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Vocabulaire de mouvement de la navigation.
///
/// Material 3 définit trois motifs de transition ; on les expose comme des
/// page builders de premier ordre pour qu’une route déclare une *intention*
/// (« ceci est un pas en avant », « ceci est une modale ») au lieu de
/// bricoler une animation à la main.
///
///  * [AppTransition.sharedAxisX] — navigation latérale au sein d’un flux
///    (liste → détail, étape 1 → étape 2). Glissement + fondu sur l’axe X.
///  * [AppTransition.fadeThrough] — remplacement de contenus sans lien entre
///    eux (branches d’onglets, splash → accueil). Fondu sortant, mise à
///    l’échelle entrante.
///  * [AppTransition.modal] — une page façon feuille qui monte depuis le bas.
///  * [AppTransition.none] — instantané, pour le splash et les redirections
///    du guard.
enum AppTransition { sharedAxisX, fadeThrough, modal, none }

/// Une [Page] qui porte une [AppTransition]. À utiliser comme `pageBuilder`
/// d’une `GoRoute` :
///
/// ```dart
/// GoRoute(
///   path: AppRoutes.eventDetail,
///   pageBuilder: (context, state) => AppPage.of(
///     state,
///     const EventDetailScreen(),
///     transition: AppTransition.sharedAxisX,
///   ),
/// )
/// ```
abstract final class AppPage {
  static Page<void> of(
    GoRouterState state,
    Widget child, {
    AppTransition transition = AppTransition.sharedAxisX,
    bool fullscreenDialog = false,
  }) {
    if (transition == AppTransition.none) {
      return NoTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: child,
      );
    }

    return CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      fullscreenDialog: fullscreenDialog,
      opaque: transition != AppTransition.modal,
      barrierColor: transition == AppTransition.modal ? Colors.black54 : null,
      transitionDuration: switch (transition) {
        AppTransition.modal => AppMotion.slow,
        _ => AppMotion.medium,
      },
      reverseTransitionDuration: AppMotion.short,
      transitionsBuilder: switch (transition) {
        AppTransition.sharedAxisX => _sharedAxisX,
        AppTransition.fadeThrough => _fadeThrough,
        AppTransition.modal => _modal,
        AppTransition.none => _none,
      },
      child: child,
    );
  }

  /// Raccourci pour le cas très courant « écran simple, mouvement latéral ».
  static Page<void> screen(GoRouterState state, Widget child) =>
      of(state, child);

  /// Raccourci pour un formulaire plein écran présenté en modale.
  static Page<void> modal(GoRouterState state, Widget child) =>
      of(state, child, transition: AppTransition.modal, fullscreenDialog: true);
}

Widget _none(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) => child;

/// La page entrante glisse depuis la droite pendant que la sortante dérive
/// vers la gauche ; les deux se croisent en fondu. 30 px de course seulement
/// — les longs glissements font bon marché.
Widget _sharedAxisX(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  final enter = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
  final exit = CurvedAnimation(parent: secondary, curve: AppMotion.emphasized);

  return FadeTransition(
    opacity: enter,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(enter),
      child: SlideTransition(
        position: Tween(
          begin: Offset.zero,
          end: const Offset(-0.04, 0),
        ).animate(exit),
        child: child,
      ),
    ),
  );
}

/// Fondu + léger agrandissement. Utilisé quand les deux pages n’ont aucun
/// lien entre elles.
Widget _fadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  final enter = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.35, 1, curve: AppMotion.decelerate),
  );
  return FadeTransition(
    opacity: enter,
    child: ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(enter),
      child: child,
    ),
  );
}

/// Monte depuis le bas avec une courbe arrondie et décélérante.
Widget _modal(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  final enter = CurvedAnimation(
    parent: animation,
    curve: AppMotion.emphasized,
    reverseCurve: AppMotion.accelerate,
  );
  return SlideTransition(
    position: Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(enter),
    child: FadeTransition(opacity: enter, child: child),
  );
}
