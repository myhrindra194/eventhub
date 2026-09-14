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

  // Account & support — shared by both roles.
  static const editProfile = '/account/edit';
  static const help = '/help';
  static const privacyPolicy = '/privacy';
  static const about = '/about';
  static const notificationsCenter = '/notifications';
  static const notificationsCenterName = 'notifications';

  static const editProfileName = 'edit-profile';
  static const helpName = 'help';
  static const privacyPolicyName = 'privacy';
  static const aboutName = 'about';

  // Administration — any role, `admin` claim required (see RouteGuard).
  static const adminPrefix = '/admin';
  static const adminModeration = '/admin/moderation';
  static const adminModerationName = 'admin-moderation';
  static const adminModerationEntry = '/admin/moderation/:entryId';
  static const adminModerationEntryName = 'admin-moderation-entry';
  static const adminRoles = '/admin/roles';
  static const adminRolesName = 'admin-roles';
  static const entryIdParam = 'entryId';

  static String adminModerationEntryPath(String entryId) =>
      '/admin/moderation/${Uri.encodeComponent(entryId)}';

  static bool isAdminArea(String location) =>
      location == adminPrefix || location.startsWith('$adminPrefix/');

  // Public organizer profile and follows (F-10) — shared by both roles.
  static const organizerPublicProfile = '/organizers/:organizerId';
  static const organizerPublicProfileName = 'organizer-public-profile';
  static const following = '/following';
  static const followingName = 'following';

  /// Shared link `https://<host>/e/{id}`, opened by the app through App
  /// Links; redirects to the event detail.
  static const publicEventLink = '/e/:eventId';
  static const publicEventLinkName = 'public-event-link';

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
  static const ticket = '/reservations/:reservationId/ticket';
  static const favorites = '/favorites';
  static const favoritesName = 'favorites';

  static const eventsName = 'events';
  static const searchName = 'search';
  static const reservationsName = 'reservations';
  static const profileName = 'profile';
  static const settingsName = 'settings';
  static const changePasswordName = 'change-password';
  static const eventDetailName = 'event-detail';
  static const reservationConfirmationName = 'reservation-confirmation';
  static const ticketName = 'ticket';

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
  static const organizerEventCheckIn = '/organizer/events/:eventId/checkin';
  static const organizerEventCheckInName = 'organizer-event-checkin';
  static const organizerStats = '/organizer/stats';
  static const organizerAlerts = '/organizer/alerts';
  static const organizerStatsName = 'organizer-stats';
  static const organizerAlertsName = 'organizer-alerts';

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
  static const organizerIdParam = 'organizerId';

  /// Query parameter carrying a deep link across the splash and the login.
  static const fromParam = 'from';

  // -------------------------------------------------------------- builders
  static String eventDetailPath(String eventId) =>
      '/events/${Uri.encodeComponent(eventId)}';

  static String reservationConfirmationPath(String reservationId) =>
      '/reservations/${Uri.encodeComponent(reservationId)}/confirmation';

  static String organizerEventCheckInPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/checkin';

  static String ticketPath(String reservationId) =>
      '/reservations/${Uri.encodeComponent(reservationId)}/ticket';

  static String organizerEventEditPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/edit';

  static String organizerEventParticipantsPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/participants';

  static String organizerEventPublishedPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/published';

  static String organizerPublicProfilePath(String organizerId) =>
      '/organizers/${Uri.encodeComponent(organizerId)}';

  static String publicEventLinkPath(String eventId) =>
      '/e/${Uri.encodeComponent(eventId)}';

  /// [base] with the location to resume after it, e.g.
  /// `/login?from=%2Fevents%2Fabc`.
  static String withFrom(String base, String location) =>
      Uri(path: base, queryParameters: {fromParam: location}).toString();

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
  static const _roleAgnosticPaths = <String>{
    welcome,
    changePassword,
    editProfile,
    help,
    privacyPolicy,
    about,
    notificationsCenter,
    following,
  };

  static bool isRoleAgnostic(String location) =>
      _roleAgnosticPaths.contains(location) ||
      location.startsWith('/organizers/');

  /// Locations an external link may lead to (a shared event, an organizer
  /// profile). When one is requested before the session is ready, the guard
  /// remembers it in [fromParam] and resumes it after sign-in. Anything else
  /// in `from` is ignored — the parameter is user-controlled.
  static bool isDeepLinkTarget(String location) =>
      location.startsWith('/e/') ||
      location.startsWith('/events/') ||
      location.startsWith('/organizers/');

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

  static const organizerTabs = <String>[
    organizerEvents,
    organizerStats,
    organizerAlerts,
    organizerProfile,
  ];
}

/// Where a role lands once authenticated.
extension UserRoleRoutes on UserRole {
  String get homePath => switch (this) {
    UserRole.participant => AppRoutes.events,
    UserRole.organizer => AppRoutes.organizerEvents,
  };
}
