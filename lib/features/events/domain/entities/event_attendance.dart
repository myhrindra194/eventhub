import 'dart:math' as math;

/// "Who's going" — the social-proof sentence on the event detail (F-07).
///
/// The head count comes from the event itself (`capacity - availablePlaces`,
/// transactional and exact); the names come from
/// `aggregates/event_{id}.recentAttendees`, maintained by the
/// `aggregateAttendance` Cloud Function as "Prénom I." — never a full name,
/// never an email.
abstract final class Attendance {
  /// Names spelled out in the sentence; the avatars may show a few more.
  static const namesInSentence = 2;

  /// `null` when nobody booked: an empty strip is worse than no strip.
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
