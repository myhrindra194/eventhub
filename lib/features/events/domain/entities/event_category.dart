/// Event categories used for filtering. Persisted as enum `name`.
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
