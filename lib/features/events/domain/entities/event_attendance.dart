import 'dart:math' as math;

/// « Qui y va » — la phrase de preuve sociale du détail d’un événement
/// (F-07).
///
/// Le décompte vient de l’événement lui-même (`capacity - availablePlaces`,
/// transactionnel et exact) ; les noms viennent de la fonction de base de
/// données `event_attendance`, au format « Prénom I. » — jamais un nom
/// complet, jamais un e-mail.
abstract final class Attendance {
  /// Noms cités dans la phrase ; les avatars peuvent en montrer
  /// quelques-uns de plus.
  static const namesInSentence = 2;

  /// `null` quand personne n’a réservé : un bandeau vide est pire qu’un
  /// bandeau absent.
  ///
  /// * 1, no names → « 1 personne y va »
  /// * 12, no names → « 12 personnes y vont »
  /// * 1, [Soa] → « Soa y va »
  /// * 2, [Soa, Hery R.] → « Soa et Hery R. y vont »
  /// * 3, [Soa] → « Soa et 2 autres y vont »
  /// * 42, [Soa, Hery R.] → « Soa, Hery R. et 40 autres y vont »
  static String? sentence({required int going, required List<String> names}) {
    if (going <= 0) return null;
    final shown = names
        .where((n) => n.trim().isNotEmpty)
        .take(math.min(namesInSentence, going))
        .toList();
    final others = going - shown.length;

    if (shown.isEmpty) {
      return going > 1 ? '$going personnes y vont' : '1 personne y va';
    }
    if (others <= 0) {
      return shown.length == 1
          ? '${shown.first} y va'
          : '${shown.join(' et ')} y vont';
    }
    final rest = others > 1 ? '$others autres' : '1 autre personne';
    return '${shown.join(', ')} et $rest y vont';
  }
}
