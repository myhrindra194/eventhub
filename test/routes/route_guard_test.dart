import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:eventhub/routes/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// The navigation policy is a pure function, so it is tested as one — no
/// widget tree, no router, no pumping. Every rule of `RouteGuard` gets an
/// explicit case, which is what makes it safe to change later.
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

    test('keeps each role inside its own area', () {
      expect(
        redirect(signedIn(participant), AppRoutes.organizerEvents),
        AppRoutes.events,
      );
      expect(
        redirect(signedIn(organizer), AppRoutes.events),
        AppRoutes.organizerEvents,
      );
    });

    test('lets a role browse its own area', () {
      expect(redirect(signedIn(participant), AppRoutes.events), isNull);
      expect(redirect(signedIn(participant), AppRoutes.reservations), isNull);
      expect(
        redirect(signedIn(organizer), AppRoutes.organizerEventNew),
        isNull,
      );
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
