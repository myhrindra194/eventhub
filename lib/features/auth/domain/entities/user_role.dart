/// Rôle choisi à l’inscription. Persisté sous la forme du `name` de l’enum
/// dans Firestore (`participant` / `organizer`) et imposé par les règles de
/// sécurité.
enum UserRole {
  participant,
  organizer;

  String get label => switch (this) {
    UserRole.participant => 'Participant',
    UserRole.organizer => 'Organisateur',
  };

  String get description => switch (this) {
    UserRole.participant => 'Je découvre et réserve des événements',
    UserRole.organizer => 'Je crée et gère mes événements',
  };

  static UserRole? tryParse(String? raw) {
    for (final role in values) {
      if (role.name == raw) return role;
    }
    return null;
  }
}
