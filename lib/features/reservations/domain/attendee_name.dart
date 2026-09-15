/// The short name an attendee is listed under on an event's social proof
/// ("Soa, Hery R. et 40 autres y vont").
///
/// `events/{id}/attendees` is readable by every signed-in account, so it
/// holds as little as possible: the first name and the initial of the next
/// word, never the full name, the e-mail or the uid (the document key is a
/// hash of the uid). The rules cap the name at 40 characters.
abstract final class AttendeeName {
  static const maxLength = 40;

  /// Shown when a profile name is blank (it never should be: the rules
  /// require two characters).
  static const fallback = 'Participant';

  /// `Jean-Marc Rakotomalala` → `Jean-Marc R.`; `Soa` → `Soa`.
  static String of(String fullName) {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return fallback;

    final initial = words.length > 1
        ? ' ${String.fromCharCode(words[1].runes.first).toUpperCase()}.'
        : '';
    // Code points, not UTF-16 units: an emoji or an accented letter written
    // as two units must not be cut in half.
    final first = words.first.runes.toList(growable: false);
    final room = maxLength - initial.length;
    final kept = first.length > room ? first.sublist(0, room) : first;
    return '${String.fromCharCodes(kept)}$initial';
  }
}
