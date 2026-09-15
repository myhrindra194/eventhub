import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Outcome of scanning one ticket at the door, most severe first.
enum CheckInStatus {
  /// No reservation behind this QR.
  notFound,

  /// A real ticket, for another event.
  wrongEvent,

  /// The short code does not match the reservation id it came with: the QR
  /// was tampered with.
  invalidCode,

  /// A paid seat still on hold (F-11). Never produced without a payment
  /// server, kept so the door is ready for it.
  unpaid,

  /// The participant cancelled: the seat was released.
  cancelled,

  /// Valid ticket, already used — the most likely fraud at a door (a
  /// screenshot shared with a friend).
  alreadyCheckedIn,

  /// Let them in.
  admitted,
}

/// The door's answer, and what it can say about the ticket holder.
///
/// The holder fields are only filled once the ticket is known to belong to
/// the scanned event: a volunteer never learns anything about another
/// event's guests.
class CheckInVerdict {
  const CheckInVerdict(
    this.status, {
    this.reservationId,
    this.holderName,
    this.tierName,
    this.checkedInAt,
  });

  final CheckInStatus status;
  final String? reservationId;
  final String? holderName;
  final String? tierName;

  /// When the ticket was scanned: now for [CheckInStatus.admitted], the
  /// first time for [CheckInStatus.alreadyCheckedIn].
  final DateTime? checkedInAt;

  bool get isAdmitted => status == CheckInStatus.admitted;

  /// What the ticket gives access to, as printed on it.
  String get accessLabel =>
      (tierName?.isNotEmpty ?? false) ? tierName! : 'Accès général';
}

/// What the door decides, in two pure steps.
///
/// Admission itself is recorded by a Firestore transaction that reads the
/// reservation and `events/{id}/checkins/{reservationId}` and creates the
/// latter only if it is absent. The check-in document is append-only in the
/// rules, so two doors scanning one ticket at the same instant never both
/// admit it: the second transaction retries, finds the entry and answers
/// [CheckInStatus.alreadyCheckedIn].
abstract final class CheckInPolicy {
  /// `<eventId>_<userId>` (see `DocIds.reservation`): Firestore auto ids and
  /// Firebase Auth uids are both `[A-Za-z0-9]`.
  static final _reservationId = RegExp(r'^[A-Za-z0-9]+_[A-Za-z0-9]+$');

  /// A verdict the scanner can give without the server, or `null` when the
  /// ticket must be checked there.
  ///
  /// * an id that cannot be a reservation id is no ticket;
  /// * the short code is derived from the id, so a QR whose code does not
  ///   match its own id is forged — no need to reveal whether the id exists;
  /// * the id names its event: a ticket for another event is refused here,
  ///   which also matters because the rules would not even let this team
  ///   read another event's reservation.
  static CheckInVerdict? precheck({
    required String eventId,
    required String reservationId,
    required String code,
  }) {
    if (!_reservationId.hasMatch(reservationId)) {
      return const CheckInVerdict(CheckInStatus.notFound);
    }
    if (TicketPayload.normalizeCode(code) !=
        TicketPayload.normalizeCode(Reservation.ticketCodeFor(reservationId))) {
      return CheckInVerdict(
        CheckInStatus.invalidCode,
        reservationId: reservationId,
      );
    }
    final ticketEvent = reservationId.substring(
      0,
      reservationId.lastIndexOf('_'),
    );
    if (ticketEvent != eventId) {
      return CheckInVerdict(
        CheckInStatus.wrongEvent,
        reservationId: reservationId,
      );
    }
    return null;
  }

  /// The verdict on what the check-in transaction read: the [reservation]
  /// (`null` when it does not exist) and whether a check-in entry already
  /// exists ([alreadyScanned], first scanned at [scannedAt]).
  static CheckInVerdict judge({
    required String eventId,
    required String reservationId,
    required Reservation? reservation,
    required bool alreadyScanned,
    required DateTime now,
    DateTime? scannedAt,
  }) {
    if (reservation == null) {
      return CheckInVerdict(
        CheckInStatus.notFound,
        reservationId: reservationId,
      );
    }
    if (reservation.eventId != eventId) {
      return CheckInVerdict(
        CheckInStatus.wrongEvent,
        reservationId: reservationId,
      );
    }
    CheckInVerdict verdict(CheckInStatus status, [DateTime? at]) =>
        CheckInVerdict(
          status,
          reservationId: reservationId,
          holderName: reservation.userName,
          tierName: reservation.tierName,
          checkedInAt: at,
        );
    if (reservation.isPending) return verdict(CheckInStatus.unpaid);
    if (!reservation.isActive) return verdict(CheckInStatus.cancelled);
    if (alreadyScanned) {
      return verdict(CheckInStatus.alreadyCheckedIn, scannedAt);
    }
    return verdict(CheckInStatus.admitted, now);
  }
}
