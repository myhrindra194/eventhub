import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter/foundation.dart';

/// Outcome of the boot sequence, as far as navigation is concerned.
///
/// Modelled explicitly (rather than juggling two `AsyncValue`s inside the
/// redirect callback) so the whole navigation policy becomes a pure function
/// of a value object — and therefore unit-testable without a widget tree.
@immutable
class RouteGuardState {
  const RouteGuardState({
    required this.session,
    required this.onboardingSeen,
    required this.isBooting,
  });

  /// `null` while the session stream has not emitted yet.
  final AuthSession? session;

  /// `null` while the preference has not been read yet.
  final bool? onboardingSeen;

  /// True while either of the two above is still unknown on a cold start.
  final bool isBooting;

  @override
  bool operator ==(Object other) =>
      other is RouteGuardState &&
      other.session == session &&
      other.onboardingSeen == onboardingSeen &&
      other.isBooting == isBooting;

  @override
  int get hashCode => Object.hash(session, onboardingSeen, isBooting);
}

/// The single place where "who may see what" is decided.
///
/// Rules, in priority order:
///  1. **Booting** — hold everyone on the splash until the session and the
///     onboarding flag are known. Prevents the login screen from flashing
///     for an already-authenticated user.
///  2. **First launch** — an install that has never seen the onboarding is
///     routed to it before anything else.
///  3. **Signed out** — only public locations are reachable; everything else
///     falls back to `/login`.
///  4. **Profile missing** — a Firebase account without a Firestore profile
///     is pinned to `/complete-profile` (no escape, no dead end).
///  5. **Signed in** — public locations bounce to the role's home, and each
///     role is confined to its own area (`/organizer/**` vs the rest).
///
/// Returning `null` means "the requested location is fine, let it through".
abstract final class RouteGuard {
  static String? redirect({
    required RouteGuardState state,
    required String location,
  }) {
    // 1. Cold start: nothing is known yet.
    if (state.isBooting) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    return switch (state.session) {
      null || SignedOut() => _signedOut(state, location),
      ProfileMissing() =>
        location == AppRoutes.completeProfile
            ? null
            : AppRoutes.completeProfile,
      SignedIn(:final user) => _signedIn(
        location: location,
        home: user.role.homePath,
        isOrganizer: user.isOrganizer,
      ),
    };
  }

  static String? _signedOut(RouteGuardState state, String location) {
    // 2. First launch on this install.
    if (!(state.onboardingSeen ?? true)) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }
    // Onboarding already consumed: it is no longer a valid destination.
    if (location == AppRoutes.onboarding) return AppRoutes.login;

    // 3. Public locations stay reachable; the splash is transient.
    final isReachable =
        AppRoutes.isPublic(location) && location != AppRoutes.splash;
    return isReachable ? null : AppRoutes.login;
  }

  static String? _signedIn({
    required String location,
    required String home,
    required bool isOrganizer,
  }) {
    // Screens both roles share (the post-sign-up celebration, the password
    // change) bypass the confinement rule below.
    if (AppRoutes.isRoleAgnostic(location)) return null;

    // The account exists: the sign-up funnel is over.
    if (location == AppRoutes.register ||
        location == AppRoutes.completeProfile) {
      return AppRoutes.welcome;
    }

    // 5. No going back to the public funnel once authenticated.
    if (AppRoutes.isPublic(location)) return home;

    // Role confinement: an organizer never lands in the participant area
    // (and vice versa), whatever the deep link says.
    final inOrganizerArea = AppRoutes.isOrganizerArea(location);
    if (isOrganizer != inOrganizerArea) return home;

    return null;
  }
}
