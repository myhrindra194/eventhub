import 'dart:convert';

import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Sérialise une liste d’invités en CSV.
///
/// Les choix faits, chacun pour l’outil dans lequel le fichier finit
/// réellement :
///  * `;` comme séparateur — un Excel en locale française ouvre un fichier
///    séparé par des virgules sur une seule colonne, et c’est `;` qu’il
///    attend ;
///  * des fins de ligne `\r\n` et un échappement par guillemets doubles,
///    conformément à la RFC 4180 ;
///  * des dates en `yyyy-MM-dd HH:mm` — triables comme du texte et non
///    ambiguës d’une locale à l’autre, contrairement à `03/04` ;
///  * le type de billet et le montant payé (F-12, F-11), tels que l’entrée et
///    la comptabilité les lisent.
///
/// Pur et indépendant de la locale, donc testable unitairement sans arbre de
/// widgets.
abstract final class GuestListCsv {
  static const separator = ';';
  static const header = [
    'N°',
    'Nom',
    'Email',
    'Réservé le',
    'Billet',
    'Montant payé',
    'Code billet',
  ];

  static String build(List<Reservation> guests) {
    final rows = <List<String>>[
      header,
      for (var i = 0; i < guests.length; i++)
        [
          '${i + 1}',
          guests[i].userName,
          guests[i].userEmail,
          _timestamp(guests[i].reservedAt),
          guests[i].accessLabel,
          if (guests[i].isPaid)
            Money.format(guests[i].pricePaid, guests[i].currency ?? 'EUR')
          else
            'Gratuit',
          guests[i].ticketCode,
        ],
    ];
    return rows.map((row) => row.map(_escape).join(separator)).join('\r\n');
  }

  /// Contenu du fichier : UTF-8 **avec marque d’ordre des octets**. Sans elle,
  /// Excel sous Windows décode le fichier en ANSI et « Réservé » devient
  /// « RÃ©servÃ© ». Le chemin presse-papiers, lui, garde [build] tel quel — un
  /// BOM collé dans une cellule est un caractère parasite invisible.
  static List<int> fileBytes(List<Reservation> guests) =>
      utf8.encode('\uFEFF${build(guests)}');

  /// `participants-flutter-meetup-tana.csv` : ASCII en minuscules, accents
  /// dépliés, tout le reste réduit à des tirets simples, avec au plus 60
  /// caractères de titre. Se rabat sur `participants.csv`.
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
