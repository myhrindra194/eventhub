/// Le nom court sous lequel un participant apparaît dans la preuve sociale
/// d’un événement (« Soa, Hery R. et 40 autres y vont »).
///
/// `events/{id}/attendees` est lisible par tout compte connecté : il
/// contient donc le strict minimum, le prénom et l’initiale du mot suivant,
/// jamais le nom complet, l’e-mail ni l’uid (la clé du document est un
/// hachage de l’uid). Les règles plafonnent le nom à 40 caractères.
abstract final class AttendeeName {
  static const maxLength = 40;

  /// Affiché quand le nom d’un profil est vide (ce qui ne devrait jamais
  /// arriver : les règles imposent deux caractères).
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
    // Points de code, et non unités UTF-16 : un emoji ou une lettre
    // accentuée écrite sur deux unités ne doit pas être coupé en deux.
    final first = words.first.runes.toList(growable: false);
    final room = maxLength - initial.length;
    final kept = first.length > room ? first.sublist(0, room) : first;
    return '${String.fromCharCodes(kept)}$initial';
  }
}
