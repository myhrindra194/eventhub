import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Serialises a guest list to CSV.
///
/// Choices, each for the tool the file actually ends up in:
///  * `;` as separator — a French-locale Excel opens a comma-separated file
///    as a single column, and `;` is what it expects;
///  * `\r\n` line endings and double-quote escaping, per RFC 4180;
///  * dates as `yyyy-MM-dd HH:mm` — sortable as text, unambiguous across
///    locales, unlike `03/04`.
///
/// Pure and locale-free so it is unit-testable without a widget tree.
abstract final class GuestListCsv {
  static const separator = ';';
  static const header = ['N°', 'Nom', 'Email', 'Réservé le', 'Code billet'];

  static String build(List<Reservation> guests) {
    final rows = <List<String>>[
      header,
      for (var i = 0; i < guests.length; i++)
        [
          '${i + 1}',
          guests[i].userName,
          guests[i].userEmail,
          _timestamp(guests[i].reservedAt),
          guests[i].ticketCode,
        ],
    ];
    return rows.map((row) => row.map(_escape).join(separator)).join('\r\n');
  }

  static String _timestamp(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  static String _escape(String value) {
    final needsQuotes =
        value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
  }
}
