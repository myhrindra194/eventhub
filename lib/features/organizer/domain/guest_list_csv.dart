import 'dart:convert';

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

  /// File contents: UTF-8 **with a byte-order mark**. Without it, Excel on
  /// Windows decodes the file as ANSI and "Réservé" becomes "RÃ©servÃ©".
  /// The clipboard path keeps [build] as is — a BOM pasted into a cell is an
  /// invisible stray character.
  static List<int> fileBytes(List<Reservation> guests) =>
      utf8.encode('\uFEFF${build(guests)}');

  /// `participants-flutter-meetup-tana.csv`: lowercase ASCII, accents
  /// folded, anything else collapsed to single dashes, at most 60 characters
  /// of title. Falls back to `participants.csv`.
  static String fileNameFor(String eventTitle) {
    const folded = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'õ': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ÿ': 'y',
      'ñ': 'n',
      'œ': 'oe',
      'æ': 'ae',
    };
    final ascii = eventTitle
        .toLowerCase()
        .split('')
        .map((c) => folded[c] ?? c)
        .join();
    var slug = ascii
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.length > 60) {
      slug = slug.substring(0, 60).replaceAll(RegExp(r'-+$'), '');
    }
    return slug.isEmpty ? 'participants.csv' : 'participants-$slug.csv';
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
