import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';

enum ReservationStatus {
  confirmed,
  cancelled;

  String get label => switch (this) {
    ReservationStatus.confirmed => 'Confirmée',
    ReservationStatus.cancelled => 'Annulée',
  };
}

/// A participant's seat on an event.
///
/// Event and user fields are denormalised so that "Mes réservations" and the
/// organizer's participant list render without N+1 reads, and keep working
/// if the event is later deleted.
///
/// The document id is deterministic (`<eventId>_<userId>`, see
/// [Reservation.composeId]) which makes the "one reservation per participant
/// per event" rule enforceable both in the transaction and in security rules.
@freezed
abstract class Reservation with _$Reservation {
  const Reservation._();

  const factory Reservation({
    required String id,
    required String eventId,
    required String userId,
    required String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    required DateTime eventStartsAt,
    required String eventLocation,
    required ReservationStatus status,
    required DateTime reservedAt,
    DateTime? cancelledAt,
  }) = _Reservation;

  static String composeId({required String eventId, required String userId}) =>
      '${eventId}_$userId';

  bool get isActive => status == ReservationStatus.confirmed;
  bool get isCancelled => status == ReservationStatus.cancelled;
}
