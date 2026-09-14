/// What a user agreed to be notified about.
///
/// Stored in `users/{uid}/private/notifications` and read by the Cloud
/// Functions before every send, so switching a toggle off takes effect on the
/// very next push — nothing is cached server-side.
///
/// Defaults are "on": both kinds are transactional (a reminder for a seat
/// you booked, a booking on your own event), not marketing. A missing or
/// malformed document therefore behaves like a fresh account.
class NotificationPreferences {
  const NotificationPreferences({
    this.eventReminders = true,
    this.bookingAlerts = true,
  });

  factory NotificationPreferences.fromMap(Map<String, Object?>? map) {
    bool read(String key) => switch (map?[key]) {
      final bool value => value,
      _ => true,
    };
    return NotificationPreferences(
      eventReminders: read(eventRemindersKey),
      bookingAlerts: read(bookingAlertsKey),
    );
  }

  static const eventRemindersKey = 'eventReminders';
  static const bookingAlertsKey = 'bookingAlerts';

  /// Participant: a push the day before an event they hold a ticket for.
  final bool eventReminders;

  /// Organizer: a push for every booking or cancellation on their events.
  final bool bookingAlerts;

  Map<String, Object> toMap() => {
    eventRemindersKey: eventReminders,
    bookingAlertsKey: bookingAlerts,
  };

  NotificationPreferences copyWith({
    bool? eventReminders,
    bool? bookingAlerts,
  }) => NotificationPreferences(
    eventReminders: eventReminders ?? this.eventReminders,
    bookingAlerts: bookingAlerts ?? this.bookingAlerts,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.eventReminders == eventReminders &&
      other.bookingAlerts == bookingAlerts;

  @override
  int get hashCode => Object.hash(eventReminders, bookingAlerts);
}
