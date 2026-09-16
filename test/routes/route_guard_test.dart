import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:eventhub/routes/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// La politique de navigation est une fonction pure : elle est donc testée
/// comme telle — sans arbre de widgets, sans router, sans pump. Chaque règle
/// de `RouteGuard` a son cas explicite, et c'est précisément ce qui rendra
/// son évolution sans danger plus tard.
void main() {
  const participant = AppUser(
    id: 'u1',
    name: 'Elie',
    email: 'elie@example.com',
    role: UserRole.participant,
  );
  const organizer = AppUser(
    id: 'u2',
    name: 'Hasina',
    email: 'hasina@example.com',
    role: UserRole.organizer,
  );

  RouteGuardState booting() => const RouteGuardState(
    session: null,
    onboardingSeen: null,
    isBooting: true,
  );

  RouteGuardState signedOut({bool onboardingSeen = true}) => RouteGuardState(
    session: const SignedOut(),
    onboardingSeen: onboardingSeen,
    isBooting: false,
  );

  RouteGuardState signedIn(AppUser user) => RouteGuardState(
    session: SignedIn(user),
    onboardingSeen: true,
    isBooting: false,
  );

  String? redirect(RouteGuardState state, String location) =>
      RouteGuard.redirect(state: state, location: location);

  group('booting', () {
    test('holds every location on the splash', () {
      expect(redirect(booting(), AppRoutes.events), AppRoutes.splash);
      expect(redirect(booting(), AppRoutes.login), AppRoutes.splash);
    });

    test('lets the splash itself through', () {
      expect(redirect(booting(), AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    test('sends a first launch to the onboarding', () {
      final state = signedOut(onboardingSeen: false);
      expect(redirect(state, AppRoutes.login), AppRoutes.onboarding);
      expect(redirect(state, AppRoutes.onboarding), isNull);
    });

    test('closes the onboarding once it has been seen', () {
      expect(redirect(signedOut(), AppRoutes.onboarding), AppRoutes.login);
    });

    test('allows public routes and blocks private ones', () {
      expect(redirect(signedOut(), AppRoutes.login), isNull);
      expect(redirect(signedOut(), AppRoutes.register), isNull);
      expect(redirect(signedOut(), AppRoutes.forgotPassword), isNull);
      expect(redirect(signedOut(), AppRoutes.events), AppRoutes.login);
      expect(redirect(signedOut(), AppRoutes.organizerEvents), AppRoutes.login);
    });
  });

  group('profile missing', () {
    const state = RouteGuardState(
      session: ProfileMissing(uid: 'u1', email: 'e@x.com'),
      onboardingSeen: true,
      isBooting: false,
    );

    test('pins the user on the completion screen', () {
      expect(redirect(state, AppRoutes.events), AppRoutes.completeProfile);
      expect(redirect(state, AppRoutes.login), AppRoutes.completeProfile);
      expect(redirect(state, AppRoutes.completeProfile), isNull);
    });
  });

  group('signed in', () {
    test('bounces public routes to the role home', () {
      expect(
        redirect(signedIn(participant), AppRoutes.login),
        AppRoutes.events,
      );
      expect(
        redirect(signedIn(organizer), AppRoutes.login),
        AppRoutes.organizerEvents,
      );
    });

    // Deux rôles exclusifs, fixés à l'inscription : le verrou joue dans les
    // deux sens. Un participant n'entre pas dans l'espace organisateur, et
    // un organisateur — qui ne réserve pas — reste dans le sien.
    test('confines each role to its own area', () {
      expect(
        redirect(signedIn(participant), AppRoutes.organizerEvents),
        AppRoutes.events,
      );
      expect(
        redirect(signedIn(organizer), AppRoutes.events),
        AppRoutes.organizerEvents,
      );
      expect(
        redirect(signedIn(organizer), AppRoutes.reservations),
        AppRoutes.organizerEvents,
      );
    });

    // « Tous les événements » appartient à l'espace participant : la route
    // vit dans la branche Explorer du shell, et ne doit pas devenir une
    // porte dérobée pour un organisateur.
    test('confines the all-events catalogue to participants', () {
      expect(redirect(signedIn(participant), AppRoutes.allEvents), isNull);
      expect(
        redirect(signedIn(organizer), AppRoutes.allEvents),
        AppRoutes.organizerEvents,
      );
      expect(AppRoutes.isRoleAgnostic(AppRoutes.allEvents), isFalse);
      expect(AppRoutes.isOrganizerArea(AppRoutes.allEvents), isFalse);
    });

    test('lets a role browse its own area', () {
      expect(redirect(signedIn(participant), AppRoutes.events), isNull);
      expect(redirect(signedIn(participant), AppRoutes.reservations), isNull);
      expect(
        redirect(signedIn(organizer), AppRoutes.organizerEventNew),
        isNull,
      );
    });

    test('opens account and support pages to both roles', () {
      for (final path in [
        AppRoutes.editProfile,
        AppRoutes.help,
        AppRoutes.privacyPolicy,
        AppRoutes.about,
        AppRoutes.notificationsCenter,
        AppRoutes.changePassword,
      ]) {
        expect(redirect(signedIn(participant), path), isNull, reason: path);
        expect(redirect(signedIn(organizer), path), isNull, reason: path);
      }
    });

    test('keeps statistics and alerts inside the organizer area', () {
      for (final path in [
        AppRoutes.organizerStats,
        AppRoutes.organizerAlerts,
      ]) {
        expect(redirect(signedIn(organizer), path), isNull, reason: path);
        expect(
          redirect(signedIn(participant), path),
          AppRoutes.events,
          reason: path,
        );
      }
    });

    test(
      'the door check-in is the organizer’s; favourites the participant’s',
      () {
        expect(redirect(signedIn(participant), AppRoutes.favorites), isNull);
        expect(
          redirect(signedIn(organizer), AppRoutes.favorites),
          AppRoutes.organizerEvents,
        );
        final checkIn = AppRoutes.organizerEventCheckInPath('e1');
        expect(checkIn, '/organizer/events/e1/checkin');
        expect(redirect(signedIn(organizer), checkIn), isNull);
        expect(redirect(signedIn(participant), checkIn), AppRoutes.events);
      },
    );

    test('a ticket belongs to the participant space', () {
      final ticket = AppRoutes.ticketPath('evt_u1');
      expect(ticket, '/reservations/evt_u1/ticket');
      expect(redirect(signedIn(participant), ticket), isNull);
      expect(redirect(signedIn(organizer), ticket), AppRoutes.organizerEvents);
    });

    test('routes the end of the sign-up funnel to the welcome screen', () {
      expect(
        redirect(signedIn(participant), AppRoutes.register),
        AppRoutes.welcome,
      );
      expect(
        redirect(signedIn(participant), AppRoutes.completeProfile),
        AppRoutes.welcome,
      );
      expect(redirect(signedIn(participant), AppRoutes.welcome), isNull);
    });
  });

  group('public organizer profiles and deep links', () {
    test('opens organizer profiles and the following list to both roles', () {
      final profile = AppRoutes.organizerPublicProfilePath('o1');
      expect(profile, '/organizers/o1');
      for (final path in [profile, AppRoutes.following]) {
        expect(redirect(signedIn(participant), path), isNull, reason: path);
        expect(redirect(signedIn(organizer), path), isNull, reason: path);
      }
      expect(redirect(signedOut(), profile), '/login?from=%2Forganizers%2Fo1');
    });

    test('carries a shared link through the splash and the login', () {
      final link = AppRoutes.publicEventLinkPath('e1');
      expect(link, '/e/e1');
      expect(redirect(booting(), link), '/splash?from=%2Fe%2Fe1');
      expect(
        RouteGuard.redirect(
          state: signedOut(),
          location: AppRoutes.splash,
          from: link,
        ),
        '/login?from=%2Fe%2Fe1',
      );
      expect(
        redirect(signedOut(), AppRoutes.eventDetailPath('e1')),
        '/login?from=%2Fevents%2Fe1',
      );
      expect(
        RouteGuard.redirect(
          state: signedOut(),
          location: AppRoutes.login,
          from: link,
        ),
        isNull,
      );
    });

    test('resumes the link once signed in, whichever space the user is in', () {
      final link = AppRoutes.publicEventLinkPath('e1');
      expect(
        RouteGuard.redirect(
          state: signedIn(participant),
          location: AppRoutes.login,
          from: link,
        ),
        link,
      );
      // Un événement partagé est un écran participant, et un organisateur
      // réserve comme les autres : le lien s'ouvre donc pour les deux, au lieu
      // de renvoyer au tableau de bord — c'est bien ce qui faisait l'intérêt
      // de partager ce lien.
      expect(redirect(signedIn(participant), link), isNull);
      expect(redirect(signedIn(organizer), link), isNull);
    });

    test('ignores a from parameter that is not a deep-link target', () {
      expect(
        RouteGuard.redirect(
          state: signedIn(participant),
          location: AppRoutes.login,
          from: '/organizer/events',
        ),
        AppRoutes.events,
      );
      expect(
        RouteGuard.redirect(
          state: signedOut(),
          location: AppRoutes.splash,
          from: 'https://evil.example/e/1',
        ),
        AppRoutes.login,
      );
    });
  });

  group('payments', () {
    // Seul un participant réserve, donc seul un participant paie : un
    // organisateur qui suivrait le lien de retour reste dans son espace.
    test('the Stripe return link belongs to the participant space', () {
      expect(AppRoutes.paymentPath('e1_u1'), '/reservations/e1_u1/payment');
      expect(redirect(signedIn(participant), AppRoutes.paySuccess), isNull);
      expect(
        redirect(signedIn(organizer), AppRoutes.paySuccess),
        AppRoutes.organizerEvents,
      );
      expect(
        redirect(signedIn(participant), AppRoutes.paymentPath('e1_u1')),
        isNull,
      );
    });
  });

  group('administration', () {
    test('opens the moderation area to admins of either role only', () {
      final entry = AppRoutes.adminModerationEntryPath('review_e1_p9');
      expect(entry, '/admin/moderation/review_e1_p9');
      for (final path in [
        AppRoutes.adminModeration,
        entry,
        AppRoutes.adminRoles,
      ]) {
        expect(
          redirect(signedIn(participant.copyWith(isAdmin: true)), path),
          isNull,
          reason: path,
        );
        expect(
          redirect(signedIn(organizer.copyWith(isAdmin: true)), path),
          isNull,
          reason: path,
        );
        expect(redirect(signedIn(participant), path), AppRoutes.events);
        expect(redirect(signedIn(organizer), path), AppRoutes.organizerEvents);
        expect(redirect(signedOut(), path), AppRoutes.login);
      }
    });
  });

  group('route classification', () {
    test('recognises the organizer area without prefix collisions', () {
      expect(AppRoutes.isOrganizerArea('/organizer/events'), isTrue);
      expect(AppRoutes.isOrganizerArea('/organizer'), isTrue);
      expect(AppRoutes.isOrganizerArea('/organizers-club'), isFalse);
      expect(AppRoutes.isOrganizerArea('/events'), isFalse);
    });

    test('builds parameterised paths with encoding', () {
      expect(AppRoutes.eventDetailPath('abc'), '/events/abc');
      expect(
        AppRoutes.organizerEventEditPath('a b'),
        '/organizer/events/a%20b/edit',
      );
    });
  });
}
