/// Une ligne de `public.notifications`, écrite par la base de données chaque
/// fois qu’un push est dû (purgée 30 jours plus tard, sur `expires_at`).
///
/// L’historique existe parce qu’un push est éphémère : balayé du centre de
/// notifications, il a disparu. La liste in-app est l’endroit où l’on répond
/// après coup à « qui a réservé hier ? » et « c’est quand, déjà, cet
/// événement ? ».
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.eventId,
    this.reservationId,
    this.readAt,
  });

  final String id;

  /// `booking`, `cancellation`, `reminder`, `waitlist` — voir
  /// `NotificationRoute` pour savoir ce que chacun ouvre.
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? eventId;
  final String? reservationId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// La même forme que la map `data` d’un push, pour qu’un appui dans la liste
  /// et un appui sur la notification système passent par une seule fonction de
  /// routage.
  Map<String, Object?> get routeData => {
    'type': type,
    'eventId': eventId,
    'reservationId': reservationId,
  };
}
