import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// Central route registry.
///
/// Every location of the application is declared here — nowhere else. The
/// rest of the codebase never interpolates a path by hand: it calls one of
/// the `*Path()` builders, so a change of URL shape is a one-file change.
///
/// Naming convention
/// -----------------
/// * `xxx`          → the raw `go_router` pattern (may contain `:params`)
/// * `xxxName`      → the symbolic name used by `context.goNamed(...)`
/// * `xxxPath(...)` → a builder producing a concrete, encoded location
abstract final class AppRoutes {
  // ---------------------------------------------------------------- common
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const welcome = '/welcome';

  static const splashName = 'splash';
  static const onboardingName = 'onboarding';
  static const loginName = 'login';
  static const registerName = 'register';
  static const forgotPasswordName = 'forgot-password';
  static const completeProfileName = 'complete-profile';
  static const welcomeName = 'welcome';

  // ----------------------------------------------------------- participant
  static const events = '/events';
  static const search = '/search';
  static const reservations = '/reservations';
  static const profile = '/profile';
  static const settings = '/profile/settings';
  static const changePassword = '/change-password';
  static const eventDetail = '/events/:eventId';
  static const reservationConfirmation =
      '/reservations/:reservationId/confirmation';

  static const eventsName = 'events';
  static const searchName = 'search';
  static const reservationsName = 'reservations';
  static const profileName = 'profile';
  static const settingsName = 'settings';
  static const changePasswordName = 'change-password';
  static const eventDetailName = 'event-detail';
  static const reservationConfirmationName = 'reservation-confirmation';

  // ------------------------------------------------------------- organizer
  static const organizerPrefix = '/organizer';
  static const organizerEvents = '/organizer/events';
  static const organizerProfile = '/organizer/profile';
  static const organizerSettings = '/organizer/profile/settings';
  static const organizerEventNew = '/organizer/events/new';
  static const organizerEventEdit = '/organizer/events/:eventId/edit';
  static const organizerEventParticipants =
      '/organizer/events/:eventId/participants';
  static const organizerEventPublished = '/organizer/events/:eventId/published';

  static const organizerEventsName = 'organizer-events';
  static const organizerProfileName = 'organizer-profile';
  static const organizerSettingsName = 'organizer-settings';
  static const organizerEventNewName = 'organizer-event-new';
  static const organizerEventEditName = 'organizer-event-edit';
  static const organizerEventParticipantsName = 'organizer-event-participants';
  static const organizerEventPublishedName = 'organizer-event-published';

  // ---------------------------------------------------------------- params
  static const eventIdParam = 'eventId';
  static const reservationIdParam = 'reservationId';

  // -------------------------------------------------------------- builders
  static String eventDetailPath(String eventId) =>
      '/events/${Uri.encodeComponent(eventId)}';

  static String reservationConfirmationPath(String reservationId) =>
      '/reservations/${Uri.encodeComponent(reservationId)}/confirmation';

  static String organizerEventEditPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/edit';

  static String organizerEventParticipantsPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/participants';

  static String organizerEventPublishedPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/published';

  // ----------------------------------------------------------- classifiers
  /// Locations reachable without a session.
  static const _publicPaths = <String>{
    splash,
    onboarding,
    login,
    register,
    forgotPassword,
  };

  /// Authenticated locations that belong to **neither** role area: both a
  /// participant and an organizer must be able to open them. Without this
  /// set, the role-confinement rule would bounce an organizer out of
  /// `/change-password` simply because the path does not start with
  /// `/organizer`.
  static const _roleAgnosticPaths = <String>{welcome, changePassword};

  static bool isRoleAgnostic(String location) =>
      _roleAgnosticPaths.contains(location);

  /// Locations that belong to the organizer area of the product.
  static bool isPublic(String location) => _publicPaths.contains(location);

  static bool isOrganizerArea(String location) =>
      location == organizerPrefix || location.startsWith('$organizerPrefix/');

  /// Root tabs of each shell, in navigation-bar order. Used by the shells and
  /// by the guard to decide where a role "lands".
  static const participantTabs = <String>[
    events,
    search,
    reservations,
    profile,
  ];

  static const organizerTabs = <String>[organizerEvents, organizerProfile];
}

/// Where a role lands once authenticated.
extension UserRoleRoutes on UserRole {
  String get homePath => switch (this) {
    UserRole.participant => AppRoutes.events,
    UserRole.organizer => AppRoutes.organizerEvents,
  };
}
