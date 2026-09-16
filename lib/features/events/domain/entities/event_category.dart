/// Catégories d’événement utilisées pour le filtrage. Persistées sous la
/// forme du `name` de l’enum.
enum EventCategory {
  conference,
  meetup,
  workshop,
  concert,
  sport,
  culture,
  other;

  String get label => switch (this) {
    EventCategory.conference => 'Conférence',
    EventCategory.meetup => 'Meetup',
    EventCategory.workshop => 'Atelier',
    EventCategory.concert => 'Concert',
    EventCategory.sport => 'Sport',
    EventCategory.culture => 'Culture',
    EventCategory.other => 'Autre',
  };
}
