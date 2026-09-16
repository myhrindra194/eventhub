/// Ce pour quoi un utilisateur a accepté d’être notifié.
///
/// Stockées dans `public.notification_preferences` et lues par
/// `private.notify` avant chaque notification, si bien que désactiver un
/// interrupteur prend effet dès le push suivant — rien n’est mis en cache côté
/// serveur.
///
/// Les valeurs par défaut sont « activé » : les rappels et les alertes de
/// réservation sont transactionnels (une place que l’on a réservée, une
/// réservation sur son propre événement), et suivre un organisateur est une
/// demande explicite d’avoir de ses nouvelles. Un document absent ou malformé
/// se comporte donc comme un compte tout neuf.
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

  /// Participant : un push la veille d’un événement pour lequel il détient un
  /// billet, et quand une place se libère sur un événement qu’il attend.
  final bool eventReminders;

  /// Organisateur : un push à chaque réservation ou annulation sur ses
  /// événements.
  final bool bookingAlerts;

  /// Tout le monde : un push quand un organisateur suivi publie un événement.
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
