import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';

enum ReservationStatus {
  confirmed,

  /// A paid seat held while the buyer pays (F-11). Kept in the domain for
  /// the day a payment server exists; on the Spark plan it is never written
  /// (the security rules accept `confirmed` and `cancelled` only).
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
/// The id is deterministic: `DocIds.reservation(eventId, userId)`, i.e.
/// `<eventId>_<userId>`. That is how "one seat per person per event" holds
/// without a unique index — there is only one document to write — and how
/// the security rules find the caller's own seat to prove a booking, a
/// cancellation or an attendance. A re-booking after a cancellation rewrites
/// the same document, hence keeps the same ticket code.
@freezed
abstract class Reservation with _$Reservation {
  const Reservation._();

  const factory Reservation({
    required String id,

    /// Empty once the event is deleted: the reservation stays as history,
    /// with its snapshot of title, date and place.
    required String eventId,

    /// Empty once the participant's account is deleted (the row is
    /// anonymised and kept for the organizer's statistics).
    required String userId,

    /// Empty once the organizer's account is deleted.
    required String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    required DateTime eventStartsAt,
    required String eventLocation,
    required ReservationStatus status,
    required DateTime reservedAt,
    DateTime? cancelledAt,

    /// Who cancelled: the holder's uid, or `moderation` when an administrator
    /// removed the event.
    String? cancelledBy,

    /// Ticket type (F-12), copied at booking time.
    String? tierId,
    String? tierName,

    /// Amount actually paid, minor units. Always 0 without a payment server:
    /// the rules refuse anything else.
    @Default(0) int pricePaid,

    // Payment fields (F-11). Never stored on the Spark plan — no server can
    // take a payment — so they stay null; the payment screens keep reading
    // them for the day a payment backend is added.
    int? amountDue,
    String? currency,
    String? paymentStatus,
    String? checkoutUrl,
    DateTime? holdExpiresAt,
  }) = _Reservation;

  /// Human-readable ticket code, e.g. `EH-7K2Q-M9XD`.
  ///
  /// Derived from the id rather than stored: the id is already unique and
  /// immutable, so the code needs no migration and cannot drift from it. The
  /// alphabet drops `0/O` and `1/I/L` — this is read aloud at a door, and
  /// those are exactly the characters people get wrong.
  String get ticketCode => ticketCodeFor(id);

  /// [ticketCode] of the reservation [id], without the reservation itself:
  /// the door checks a scanned code against the id it came with before
  /// asking the server anything.
  static String ticketCodeFor(String id) {
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
