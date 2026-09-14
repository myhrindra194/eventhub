import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Outcome of scanning one ticket at the door, most severe first.
enum CheckInStatus {
  /// No reservation behind this QR, or not readable by this organizer.
  notFound,

  /// A real ticket, for another event.
  wrongEvent,

  /// The reservation exists but the short code does not match it: the QR
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

class CheckInVerdict {
  const CheckInVerdict(this.status, {this.reservation, this.checkedInAt});

  final CheckInStatus status;
  final Reservation? reservation;

  /// When the ticket was first scanned, for [CheckInStatus.alreadyCheckedIn].
  final DateTime? checkedInAt;

  bool get isAdmitted => status == CheckInStatus.admitted;
}

/// Decides admission. Pure: the data source reads the reservation and any
/// existing check-in, this function only judges, so every branch is tested.
abstract final class CheckInPolicy {
  static CheckInVerdict evaluate({
    required String eventId,
    required String code,
    required Reservation? reservation,
    required DateTime? checkedInAt,
  }) {
    if (reservation == null) {
      return const CheckInVerdict(CheckInStatus.notFound);
    }
    if (reservation.eventId != eventId) {
      return CheckInVerdict(CheckInStatus.wrongEvent, reservation: reservation);
    }
    if (TicketPayload.normalizeCode(code) !=
        TicketPayload.normalizeCode(reservation.ticketCode)) {
      return CheckInVerdict(
        CheckInStatus.invalidCode,
        reservation: reservation,
      );
    }
    if (reservation.isPending) {
      return CheckInVerdict(CheckInStatus.unpaid, reservation: reservation);
    }
    if (reservation.isCancelled) {
      return CheckInVerdict(CheckInStatus.cancelled, reservation: reservation);
    }
    if (checkedInAt != null) {
      return CheckInVerdict(
        CheckInStatus.alreadyCheckedIn,
        reservation: reservation,
        checkedInAt: checkedInAt,
      );
    }
    return CheckInVerdict(CheckInStatus.admitted, reservation: reservation);
  }
}
