/// What a ticket QR code carries: `eventhub://ticket/<reservationId>?code=<code>`
/// (see `Reservation.ticketPayload`).
///
/// The QR is not signed, and does not need to be: the scanner never trusts
/// it. It only says *which* reservation to look up; admission is decided from
/// the reservation document read server-side, and the short code must match
/// the one derived from that document's id. A forged QR can at best point at
/// someone else's real booking — which the check-in record then burns.
class TicketPayload {
  const TicketPayload({required this.reservationId, required this.code});

  final String reservationId;
  final String code;

  /// `null` for anything that is not an EventHub ticket (a URL, a Wi-Fi QR…).
  static TicketPayload? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'eventhub' || uri.host != 'ticket') {
      return null;
    }
    final segments = uri.pathSegments;
    final code = uri.queryParameters['code'];
    if (segments.length != 1 || segments.single.isEmpty) return null;
    if (code == null || code.isEmpty) return null;
    return TicketPayload(reservationId: segments.single, code: code);
  }

  /// Codes are read aloud and typed by hand at the door: case and spaces
  /// must not matter.
  static String normalizeCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'\s'), '');
}
