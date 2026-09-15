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

  /// A paid seat still on hold: the payment never went through (F-11).
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
/// The holder fields come from the `check_in_ticket` function, which only
/// returns them once the ticket is known to belong to this event.
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

/// What the scanner decides on its own, before asking the server.
///
/// Pure. Admission itself — status, payment, first scan — is decided and
/// recorded atomically by the `check_in_ticket` database function, so two
/// doors scanning one ticket at the same instant never both admit it.
abstract final class CheckInPolicy {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// A verdict the scanner can give without the server, or `null` when the
  /// ticket must be checked there.
  ///
  /// The short code is derived from the reservation id, so a QR whose code
  /// does not match its own id is forged — no need to reveal whether that
  /// id exists. An id that is not a uuid cannot be a reservation.
  static CheckInVerdict? precheck({
    required String reservationId,
    required String code,
  }) {
    if (!_uuid.hasMatch(reservationId)) {
      return const CheckInVerdict(CheckInStatus.notFound);
    }
    if (TicketPayload.normalizeCode(code) !=
        TicketPayload.normalizeCode(Reservation.ticketCodeFor(reservationId))) {
      return CheckInVerdict(
        CheckInStatus.invalidCode,
        reservationId: reservationId,
      );
    }
    return null;
  }
}
