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

  static String? locationFor(Map<String, Object?> data) {
    final eventId = _nonEmpty(data['eventId']);
    final reservationId = _nonEmpty(data['reservationId']);

    return switch (data['type']) {
      booking || cancellation when eventId != null =>
        AppRoutes.organizerEventParticipantsPath(eventId),
      waitlist when eventId != null => AppRoutes.eventDetailPath(eventId),
      reminder when reservationId != null => AppRoutes.ticketPath(
        reservationId,
      ),
      _ => null,
    };
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
