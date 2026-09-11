import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/screens/change_password_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/login_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/profile_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/register_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/settings_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/splash_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/welcome_screen.dart';
import 'package:eventhub/features/events/presentation/screens/event_detail_screen.dart';
import 'package:eventhub/features/events/presentation/screens/event_form_screen.dart';
import 'package:eventhub/features/events/presentation/screens/event_list_screen.dart';
import 'package:eventhub/features/events/presentation/screens/event_search_screen.dart';
import 'package:eventhub/features/onboarding/application/onboarding_providers.dart';
import 'package:eventhub/features/onboarding/presentation/onboarding_screen.dart';
import 'package:eventhub/features/organizer/presentation/organizer_shell.dart';
import 'package:eventhub/features/organizer/presentation/screens/event_participants_screen.dart';
import 'package:eventhub/features/organizer/presentation/screens/event_published_screen.dart';
import 'package:eventhub/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:eventhub/features/participant/presentation/participant_shell.dart';
import 'package:eventhub/features/reservations/presentation/screens/my_reservations_screen.dart';
import 'package:eventhub/features/reservations/presentation/screens/reservation_confirmation_screen.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:eventhub/routes/route_guard.dart';
import 'package:eventhub/routes/route_observer.dart';
import 'package:eventhub/routes/route_transitions.dart';
import 'package:eventhub/routes/router_refresh.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Navigator keys. The root one is used by every route that must cover the
/// bottom navigation bar (details, forms, modals); each shell branch keeps
/// its own key so tab state survives switching.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _participantShellKey = GlobalKey<NavigatorState>(debugLabel: 'shell.p');
final _organizerShellKey = GlobalKey<NavigatorState>(debugLabel: 'shell.o');

/// The application router.
///
/// Composition:
///  * two [StatefulShellRoute]s — one per role — so each tab owns an
///    independent navigation stack;
///  * every "leaf" route (detail, form, participants) is attached to the
///    root navigator so it slides over the navigation bar;
///  * navigation policy lives in [RouteGuard], not here.
///
/// The router instance is `keepAlive`: rebuilding it would reset the whole
/// navigation state, so session changes are pushed through a
/// [RouterRefresh] listenable instead.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = RouterRefresh();
  ref
    ..listen(authSessionProvider, (_, __) => refresh.notify())
    ..listen(onboardingSeenProvider, (_, __) => refresh.notify())
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    observers: [AppRouteObserver()],
    redirect: (context, state) => RouteGuard.redirect(
      state: _guardState(ref),
      location: state.matchedLocation,
    ),
    routes: [
      ..._commonRoutes,
      _participantShell,
      ..._participantLeafRoutes,
      _organizerShell,
      ..._organizerLeafRoutes,
    ],
  );
}

/// Snapshot of everything the guard needs, read (never watched) so that the
/// router itself is never rebuilt.
RouteGuardState _guardState(Ref ref) {
  final session = ref.read(authSessionProvider);
  final onboarding = ref.read(onboardingSeenProvider);
  return RouteGuardState(
    session: session.value,
    onboardingSeen: onboarding.value,
    isBooting: (session.isLoading && !session.hasValue) || onboarding.isLoading,
  );
}

// ---------------------------------------------------------------- common --

final _commonRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.splash,
    name: AppRoutes.splashName,
    pageBuilder: (_, state) =>
        AppPage.of(state, const SplashScreen(), transition: AppTransition.none),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    name: AppRoutes.onboardingName,
    pageBuilder: (_, state) => AppPage.of(
      state,
      const OnboardingScreen(),
      transition: AppTransition.fadeThrough,
    ),
  ),
  GoRoute(
    path: AppRoutes.login,
    name: AppRoutes.loginName,
    pageBuilder: (_, state) => AppPage.of(
      state,
      const LoginScreen(),
      transition: AppTransition.fadeThrough,
    ),
  ),
  GoRoute(
    path: AppRoutes.register,
    name: AppRoutes.registerName,
    pageBuilder: (_, state) => AppPage.screen(state, const RegisterScreen()),
  ),
  // Reachable from Settings while signed in, hence a top-level route rather
  // than a child of either role's profile branch.
  GoRoute(
    path: AppRoutes.changePassword,
    name: AppRoutes.changePasswordName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) =>
        AppPage.screen(state, const ChangePasswordScreen()),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    name: AppRoutes.forgotPasswordName,
    pageBuilder: (_, state) =>
        AppPage.screen(state, const ForgotPasswordScreen()),
  ),
  GoRoute(
    path: AppRoutes.completeProfile,
    name: AppRoutes.completeProfileName,
    pageBuilder: (_, state) => AppPage.of(
      state,
      const CompleteProfileScreen(),
      transition: AppTransition.fadeThrough,
    ),
  ),
  GoRoute(
    path: AppRoutes.welcome,
    name: AppRoutes.welcomeName,
    pageBuilder: (_, state) => AppPage.of(
      state,
      const WelcomeScreen(),
      transition: AppTransition.fadeThrough,
    ),
  ),
];

// ----------------------------------------------------------- participant --

final _participantShell = StatefulShellRoute.indexedStack(
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, __, shell) => ParticipantShell(navigationShell: shell),
  branches: [
    StatefulShellBranch(
      navigatorKey: _participantShellKey,
      routes: [
        GoRoute(
          path: AppRoutes.events,
          name: AppRoutes.eventsName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const EventListScreen(),
            transition: AppTransition.none,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.search,
          name: AppRoutes.searchName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const EventSearchScreen(),
            transition: AppTransition.none,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.reservations,
          name: AppRoutes.reservationsName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const MyReservationsScreen(),
            transition: AppTransition.none,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const ProfileScreen(),
            transition: AppTransition.none,
          ),
          routes: [
            GoRoute(
              path: 'settings',
              name: AppRoutes.settingsName,
              parentNavigatorKey: rootNavigatorKey,
              pageBuilder: (_, state) =>
                  AppPage.screen(state, const SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);

final _participantLeafRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.eventDetail,
    name: AppRoutes.eventDetailName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.screen(
      state,
      EventDetailScreen(eventId: state.pathParameters[AppRoutes.eventIdParam]!),
    ),
  ),
  GoRoute(
    path: AppRoutes.reservationConfirmation,
    name: AppRoutes.reservationConfirmationName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.of(
      state,
      ReservationConfirmationScreen(
        reservationId: state.pathParameters[AppRoutes.reservationIdParam]!,
      ),
      transition: AppTransition.fadeThrough,
    ),
  ),
];

// ------------------------------------------------------------- organizer --

final _organizerShell = StatefulShellRoute.indexedStack(
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, __, shell) => OrganizerShell(navigationShell: shell),
  branches: [
    StatefulShellBranch(
      navigatorKey: _organizerShellKey,
      routes: [
        GoRoute(
          path: AppRoutes.organizerEvents,
          name: AppRoutes.organizerEventsName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const OrganizerDashboardScreen(),
            transition: AppTransition.none,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.organizerProfile,
          name: AppRoutes.organizerProfileName,
          pageBuilder: (_, state) => AppPage.of(
            state,
            const ProfileScreen(),
            transition: AppTransition.none,
          ),
          routes: [
            GoRoute(
              path: 'settings',
              name: AppRoutes.organizerSettingsName,
              parentNavigatorKey: rootNavigatorKey,
              pageBuilder: (_, state) =>
                  AppPage.screen(state, const SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);

final _organizerLeafRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.organizerEventNew,
    name: AppRoutes.organizerEventNewName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.modal(state, const EventFormScreen()),
  ),
  GoRoute(
    path: AppRoutes.organizerEventEdit,
    name: AppRoutes.organizerEventEditName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.modal(
      state,
      EventFormScreen(eventId: state.pathParameters[AppRoutes.eventIdParam]),
    ),
  ),
  GoRoute(
    path: AppRoutes.organizerEventParticipants,
    name: AppRoutes.organizerEventParticipantsName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.screen(
      state,
      EventParticipantsScreen(
        eventId: state.pathParameters[AppRoutes.eventIdParam]!,
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.organizerEventPublished,
    name: AppRoutes.organizerEventPublishedName,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (_, state) => AppPage.of(
      state,
      EventPublishedScreen(
        eventId: state.pathParameters[AppRoutes.eventIdParam]!,
      ),
      transition: AppTransition.fadeThrough,
    ),
  ),
];
