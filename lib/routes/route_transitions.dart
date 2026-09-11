import 'package:eventhub/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation motion vocabulary.
///
/// Material 3 defines three transition patterns; we expose them as first
/// class page builders so a route declares *intent* ("this is a forward
/// step", "this is a modal") instead of hand-rolling an animation.
///
///  * [AppTransition.sharedAxisX] — lateral navigation inside a flow
///    (list → detail, step 1 → step 2). Slides + fades along the X axis.
///  * [AppTransition.fadeThrough] — swapping unrelated content (tab
///    branches, splash → home). Fade out, scale in.
///  * [AppTransition.modal] — a sheet-like page rising from the bottom.
///  * [AppTransition.none] — instant, for the splash and guarded redirects.
enum AppTransition { sharedAxisX, fadeThrough, modal, none }

/// A [Page] that carries an [AppTransition]. Use it as the `pageBuilder` of
/// a `GoRoute`:
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

  /// Convenience for the very common "plain screen, lateral motion" case.
  static Page<void> screen(GoRouterState state, Widget child) =>
      of(state, child);

  /// Convenience for a full-screen form presented as a modal.
  static Page<void> modal(GoRouterState state, Widget child) =>
      of(state, child, transition: AppTransition.modal, fullscreenDialog: true);
}

Widget _none(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) => child;

/// Incoming page slides in from the right while the outgoing one drifts
/// left; both cross-fade. 30 px of travel only — long slides feel cheap.
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

/// Fade + subtle scale-up. Used when the two pages are unrelated.
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

/// Rises from the bottom with a rounded, decelerating curve.
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
