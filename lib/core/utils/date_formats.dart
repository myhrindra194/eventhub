import 'package:intl/intl.dart';

/// Formatage centralisé des dates et des heures en français.
abstract final class AppDateFormats {
  static const locale = 'fr_FR';

  static final _date = DateFormat('EEEE d MMMM yyyy', locale);
  static final _shortDate = DateFormat('d MMM yyyy', locale);
  static final _time = DateFormat('HH:mm', locale);
  static final _dateTime = DateFormat('d MMM yyyy, HH:mm', locale);
  static final _month = DateFormat('MMM', locale);
  static final _dayMonth = DateFormat('d MMM', locale);
  static final _weekdayDate = DateFormat('EEEE d MMM yyyy', locale);

  static String date(DateTime d) => _capitalize(_date.format(d));
  static String shortDate(DateTime d) => _shortDate.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// « OCT » — mois abrégé pour les badges de date.
  static String monthAbbr(DateTime d) =>
      _month.format(d).replaceAll('.', '').toUpperCase();

  /// « 24 oct. » — libellés des axes de graphiques.
  static String dayMonth(DateTime d) => _dayMonth.format(d);

  /// « 24 oct. • 20:00 » — ligne méta d’une carte.
  static String dayMonthTime(DateTime d) =>
      '${_dayMonth.format(d)} • ${_time.format(d)}';

  /// « Vendredi 24 oct. 2026 » — titre d’une ligne de détail.
  static String weekdayDate(DateTime d) => _capitalize(_weekdayDate.format(d));

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime withTime(int hour, int minute) =>
      DateTime(year, month, day, hour, minute);
}
