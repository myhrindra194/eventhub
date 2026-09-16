/// Ce que porte le QR code d’un billet :
/// `eventhub://ticket/<reservationId>?code=<code>` (voir
/// `Reservation.ticketPayload`).
///
/// Le QR n’est pas signé, et n’a pas à l’être : le scanner ne lui fait
/// jamais confiance. Il dit seulement *quelle* réservation aller chercher ;
/// le code court doit correspondre à celui dérivé de cet id, et l’admission
/// est tranchée par la base de données à partir de la ligne de réservation.
/// Un QR forgé peut au mieux désigner la vraie réservation de quelqu’un
/// d’autre — que l’enregistrement de check-in brûle alors.
class TicketPayload {
  const TicketPayload({required this.reservationId, required this.code});

  final String reservationId;
  final String code;

  /// `null` pour tout ce qui n’est pas un billet EventHub (une URL, un QR
  /// Wi-Fi…).
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

  /// Les codes sont lus à voix haute et saisis à la main à l’entrée : la
  /// casse et les espaces ne doivent pas compter.
  static String normalizeCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'\s'), '');
}
