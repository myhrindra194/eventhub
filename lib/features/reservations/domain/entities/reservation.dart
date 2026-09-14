import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';

enum ReservationStatus {
  confirmed,

  /// A paid seat held while the buyer is on the Stripe page (F-11). Set and
  /// cleared by the payment functions only.
  pending,
  cancelled;

  String get label => switch (this) {
    ReservationStatus.confirmed => 'Confirmée',
    ReservationStatus.pending => 'Paiement en cours',
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

    /// Ticket type (F-12), copied at booking time.
    String? tierId,
    String? tierName,

    /// Amount actually paid, minor units; 0 for a free seat.
    @Default(0) int pricePaid,

    /// Price of a held seat, before payment.
    int? amountDue,
    String? currency,

    /// `pending`, `paid`, `refunded`, `expired`, `cancelled`, `refund_failed`.
    String? paymentStatus,

    /// Stripe Checkout page to resume a held purchase.
    String? checkoutUrl,
    DateTime? holdExpiresAt,
  }) = _Reservation;

  static String composeId({required String eventId, required String userId}) =>
      '${eventId}_$userId';

  /// Human-readable ticket code, e.g. `EH-7K2Q-M9XD`.
  ///
  /// Derived from the id rather than stored: the id is already unique and
  /// immutable, so the code needs no migration and cannot drift from it. The
  /// alphabet drops `0/O` and `1/I/L` — this is read aloud at a door, and
  /// those are exactly the characters people get wrong.
  String get ticketCode {
    const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    // FNV-1a, 32 bits, twice with different offsets: stable across runs and
    // platforms, unlike `String.hashCode`.
    int fnv(int seed) {
      var hash = seed;
      for (final unit in id.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      return hash;
    }

    String chunk(int value) {
      final buffer = StringBuffer();
      var v = value;
      for (var i = 0; i < 4; i++) {
        buffer.write(alphabet[v % alphabet.length]);
        v ~/= alphabet.length;
      }
      return buffer.toString();
    }

    return 'EH-${chunk(fnv(0x811C9DC5))}-${chunk(fnv(0x050C5D1F))}';
  }

  /// Payload encoded in the ticket's QR code.
  String get ticketPayload => 'eventhub://ticket/$id?code=$ticketCode';

  bool get isActive => status == ReservationStatus.confirmed;
  bool get isPending => status == ReservationStatus.pending;
  bool get isCancelled => status == ReservationStatus.cancelled;

  /// Paid ticket: cancelling it means a refund.
  bool get isPaid => pricePaid > 0;
  bool get isRefunded => paymentStatus == 'refunded';

  /// What the ticket gives access to, as printed on it.
  String get accessLabel =>
      (tierName?.isNotEmpty ?? false) ? tierName! : 'Accès général';
}
