import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// Registre central des routes.
///
/// Chaque destination de l’application est déclarée ici — et nulle part
/// ailleurs. Le reste du code n’interpole jamais un chemin à la main : il
/// appelle l’un des builders `*Path()`, si bien qu’un changement de forme
/// d’URL se joue dans un seul fichier.
///
/// Convention de nommage
/// ---------------------
/// * `xxx`          → le motif `go_router` brut (peut contenir des `:params`)
/// * `xxxName`      → le nom symbolique utilisé par `context.goNamed(...)`
/// * `xxxPath(...)` → un builder produisant une destination concrète, encodée
abstract final class AppRoutes {
  // ---------------------------------------------------------------- commun
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const welcome = '/welcome';

  // Compte et support — partagés par les deux rôles.
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

  // Administration — tous rôles, claim `admin` requis (voir RouteGuard).
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

  // Profil public d’organisateur et abonnements (F-10) — partagés par les
  // deux rôles.
  static const organizerPublicProfile = '/organizers/:organizerId';
  static const organizerPublicProfileName = 'organizer-public-profile';
  static const following = '/following';
  static const followingName = 'following';

  /// Lien partagé `https://<host>/e/{id}`, ouvert par l’application via les
  /// App Links ; redirige vers le détail de l’événement.
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
  static const payment = '/reservations/:reservationId/payment';
  static const paymentName = 'payment';

  /// URL de retour de Stripe Checkout (pages Hosting + App Links).
  static const paySuccess = '/pay/success';
  static const paySuccessName = 'pay-success';
  static const payCancel = '/pay/cancel';
  static const payCancelName = 'pay-cancel';
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

  // ---------------------------------------------------------- organisateur
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
  static const organizerEventTeam = '/organizer/events/:eventId/team';
  static const organizerEventTeamName = 'organizer-event-team';
  static const organizerInvitations = '/organizer/invitations';
  static const organizerInvitationsName = 'organizer-invitations';
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

  // ------------------------------------------------------------ paramètres
  static const eventIdParam = 'eventId';
  static const reservationIdParam = 'reservationId';
  static const organizerIdParam = 'organizerId';

  /// Paramètre de requête qui transporte un lien profond à travers le splash
  /// et la connexion.
  static const fromParam = 'from';

  // -------------------------------------------------------------- builders
  static String eventDetailPath(String eventId) =>
      '/events/${Uri.encodeComponent(eventId)}';

  static String reservationConfirmationPath(String reservationId) =>
      '/reservations/${Uri.encodeComponent(reservationId)}/confirmation';

  static String organizerEventTeamPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/team';

  static String organizerEventCheckInPath(String eventId) =>
      '/organizer/events/${Uri.encodeComponent(eventId)}/checkin';

  static String paymentPath(String reservationId) =>
      '/reservations/${Uri.encodeComponent(reservationId)}/payment';

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

  /// [base] assortie de la destination à reprendre ensuite, p. ex.
  /// `/login?from=%2Fevents%2Fabc`.
  static String withFrom(String base, String location) =>
      Uri(path: base, queryParameters: {fromParam: location}).toString();

  // ------------------------------------------------------- classificateurs
  /// Destinations accessibles sans session.
  static const _publicPaths = <String>{
    splash,
    onboarding,
    login,
    register,
    forgotPassword,
  };

  /// Destinations authentifiées qui n’appartiennent à **aucun** des deux
  /// espaces de rôle : un participant comme un organisateur doit pouvoir les
  /// ouvrir. Sans cet ensemble, la règle de confinement par rôle éjecterait
  /// un organisateur de `/change-password` au seul motif que le chemin ne
  /// commence pas par `/organizer`.
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

  /// Destinations vers lesquelles un lien externe peut mener (un événement
  /// partagé, un profil d’organisateur). Lorsque l’une d’elles est demandée
  /// avant que la session ne soit prête, le guard la mémorise dans
  /// [fromParam] et la reprend après la connexion. Tout autre contenu de
  /// `from` est ignoré — ce paramètre est sous le contrôle de l’utilisateur.
  static bool isDeepLinkTarget(String location) =>
      location.startsWith('/e/') ||
      location.startsWith('/events/') ||
      location.startsWith('/organizers/') ||
      location.startsWith('/pay/');

  /// Destinations qui appartiennent à l’espace organisateur du produit.
  static bool isPublic(String location) => _publicPaths.contains(location);

  static bool isOrganizerArea(String location) =>
      location == organizerPrefix || location.startsWith('$organizerPrefix/');

  /// Onglets racines de chaque shell, dans l’ordre de la barre de
  /// navigation. Utilisés par les shells et par le guard pour décider où un
  /// rôle « atterrit ».
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

/// Là où atterrit un rôle une fois authentifié.
extension UserRoleRoutes on UserRole {
  String get homePath => switch (this) {
    UserRole.participant => AppRoutes.events,
    UserRole.organizer => AppRoutes.organizerEvents,
  };
}
