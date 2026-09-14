import 'package:eventhub/routes/app_routes.dart';

/// Where tapping a push takes the user.
///
/// The contract with the Cloud Functions is the `data` map of each message:
/// `type` plus the ids needed to build a location. Kept pure — no router, no
/// plugin — so every branch is unit-tested. An unknown or malformed payload
/// opens nothing rather than a broken screen; the router guard still applies
/// role confinement to whatever is returned.
abstract final class NotificationRoute {
  static const booking = 'booking';
  static const cancellation = 'cancellation';
  static const reminder = 'reminder';

  /// A seat opened on an event the user waits for: open the event to book.
  static const waitlist = 'waitlist';

  /// An organizer the user follows published an event.
  static const newEvent = 'newEvent';

  /// Moderation removed an event: holders see their cancelled tickets
  /// (the event itself no longer exists).
  static const eventRemoved = 'eventRemoved';

  /// The user's review was hidden: open the event it was left on.
  static const reviewHidden = 'reviewHidden';

  /// Co-organizers (F-16): an invitation to answer, a member who joined
  /// (open the team), removal from a team (back to the dashboard).
  static const staffInvite = 'staffInvite';
  static const staffJoined = 'staffJoined';
  static const staffRemoved = 'staffRemoved';

  /// Payments (F-11): the ticket is ready; a late payment was refunded.
  static const paymentConfirmed = 'paymentConfirmed';
  static const paymentRefunded = 'paymentRefunded';

  static String? locationFor(Map<String, Object?> data) {
    final eventId = _nonEmpty(data['eventId']);
    final reservationId = _nonEmpty(data['reservationId']);

    return switch (data['type']) {
      booking || cancellation when eventId != null =>
        AppRoutes.organizerEventParticipantsPath(eventId),
      waitlist ||
      newEvent ||
      reviewHidden when eventId != null => AppRoutes.eventDetailPath(eventId),
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
      _ => null,
    };
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
