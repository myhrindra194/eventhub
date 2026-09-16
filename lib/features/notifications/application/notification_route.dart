import 'package:eventhub/routes/app_routes.dart';

/// Où mène l’appui sur une notification push.
///
/// Le contrat avec les Cloud Functions, c’est la map `data` de chaque
/// message : `type`, plus les identifiants nécessaires pour construire une
/// destination. Volontairement pur — pas de routeur, pas de plugin — pour que
/// chaque branche soit couverte par un test unitaire. Une charge utile
/// inconnue ou malformée n’ouvre rien plutôt qu’un écran cassé ; le garde du
/// routeur applique ensuite le confinement par rôle à ce qui est renvoyé.
abstract final class NotificationRoute {
  static const booking = 'booking';
  static const cancellation = 'cancellation';
  static const reminder = 'reminder';

  /// Une place s’est libérée sur un événement attendu : ouvrir l’événement
  /// pour réserver.
  static const waitlist = 'waitlist';

  /// Un organisateur suivi par l’utilisateur a publié un événement.
  static const newEvent = 'newEvent';

  /// La modération a supprimé un événement : les détenteurs voient leurs
  /// billets annulés (l’événement, lui, n’existe plus).
  static const eventRemoved = 'eventRemoved';

  /// L’avis de l’utilisateur a été masqué, ou masqué puis rétabli : ouvrir
  /// l’événement sur lequel il a été déposé.
  static const reviewHidden = 'reviewHidden';
  static const reviewRestored = 'reviewRestored';

  /// La modération a suspendu ou réintégré le compte : rien à ouvrir, la
  /// notification elle-même porte le motif.
  static const accountSuspended = 'accountSuspended';
  static const accountReinstated = 'accountReinstated';

  /// Co-organisateurs (F-16) : une invitation en attente de réponse, un membre
  /// qui a rejoint (ouvrir l’équipe), un retrait d’équipe (retour au tableau
  /// de bord).
  static const staffInvite = 'staffInvite';
  static const staffJoined = 'staffJoined';
  static const staffRemoved = 'staffRemoved';

  /// Paiements (F-11) : le billet est prêt ; un paiement tardif a été
  /// remboursé.
  static const paymentConfirmed = 'paymentConfirmed';
  static const paymentRefunded = 'paymentRefunded';

  /// Envoyée une seule fois, quand le compte enregistre son premier appareil
  /// (juste après la première connexion) : ouvre l’écran de bienvenue, qui
  /// mène à l’accueil correspondant au rôle du compte.
  static const welcome = 'welcome';

  static String? locationFor(Map<String, Object?> data) {
    final eventId = _nonEmpty(data['eventId']);
    final reservationId = _nonEmpty(data['reservationId']);

    return switch (data['type']) {
      booking || cancellation when eventId != null =>
        AppRoutes.organizerEventParticipantsPath(eventId),
      waitlist ||
      newEvent ||
      reviewHidden ||
      reviewRestored when eventId != null => AppRoutes.eventDetailPath(eventId),
      eventRemoved => AppRoutes.reservations,
      staffInvite => AppRoutes.organizerInvitations,
      staffJoined when eventId != null => AppRoutes.organizerEventTeamPath(
        eventId,
      ),
      staffRemoved => AppRoutes.organizerEvents,
      paymentConfirmed when reservationId != null => AppRoutes.ticketPath(
        reservationId,
      ),
      paymentRefunded => AppRoutes.reservations,
      reminder when reservationId != null => AppRoutes.ticketPath(
        reservationId,
      ),
      welcome => AppRoutes.welcome,
      _ => null,
    };
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
