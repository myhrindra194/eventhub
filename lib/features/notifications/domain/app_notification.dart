/// One row of `public.notifications`, written by the database each time a
/// push is due (purged 30 days later, on `expires_at`).
///
/// The history exists because a push is ephemeral: dismissed from the system
/// tray, it is gone. The in-app list is where "who booked yesterday?" and
/// "when is that event again?" are answered afterwards.
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

  /// `booking`, `cancellation`, `reminder`, `waitlist` — see
  /// `NotificationRoute` for what each opens.
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? eventId;
  final String? reservationId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// The same shape as the push `data` map, so a tap in the list and a tap
  /// on the system notification go through one routing function.
  Map<String, Object?> get routeData => {
    'type': type,
    'eventId': eventId,
    'reservationId': reservationId,
  };
}
