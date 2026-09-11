/// Role chosen at sign-up. Persisted as the enum `name` in Firestore
/// (`participant` / `organizer`) and enforced by security rules.
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
