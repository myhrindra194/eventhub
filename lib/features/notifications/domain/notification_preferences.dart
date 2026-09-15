/// What a user agreed to be notified about.
///
/// Stored in `public.notification_preferences` and read by `private.notify`
/// before every notification, so switching a toggle off takes effect on the
/// very next push — nothing is cached server-side.
///
/// Defaults are "on": reminders and booking alerts are transactional (a seat
/// you booked, a booking on your own event), and following an organizer is an
/// explicit request to hear from them. A missing or malformed document
/// therefore behaves like a fresh account.
class NotificationPreferences {
  const NotificationPreferences({
    this.eventReminders = true,
    this.bookingAlerts = true,
    this.followedOrganizers = true,
  });

  factory NotificationPreferences.fromMap(Map<String, Object?>? map) {
    bool read(String key) => switch (map?[key]) {
      final bool value => value,
      _ => true,
    };
    return NotificationPreferences(
      eventReminders: read(eventRemindersKey),
      bookingAlerts: read(bookingAlertsKey),
      followedOrganizers: read(followedOrganizersKey),
    );
  }

  static const eventRemindersKey = 'eventReminders';
  static const bookingAlertsKey = 'bookingAlerts';
  static const followedOrganizersKey = 'followedOrganizers';

  /// Participant: a push the day before an event they hold a ticket for, and
  /// when a seat opens on an event they wait for.
  final bool eventReminders;

  /// Organizer: a push for every booking or cancellation on their events.
  final bool bookingAlerts;

  /// Anyone: a push when an organizer they follow publishes an event.
  final bool followedOrganizers;

  Map<String, Object> toMap() => {
    eventRemindersKey: eventReminders,
    bookingAlertsKey: bookingAlerts,
    followedOrganizersKey: followedOrganizers,
  };

  NotificationPreferences copyWith({
    bool? eventReminders,
    bool? bookingAlerts,
    bool? followedOrganizers,
  }) => NotificationPreferences(
    eventReminders: eventReminders ?? this.eventReminders,
    bookingAlerts: bookingAlerts ?? this.bookingAlerts,
    followedOrganizers: followedOrganizers ?? this.followedOrganizers,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.eventReminders == eventReminders &&
      other.bookingAlerts == bookingAlerts &&
      other.followedOrganizers == followedOrganizers;

  @override
  int get hashCode =>
      Object.hash(eventReminders, bookingAlerts, followedOrganizers);
}
