/// Entités métier partagées : source unique de vérité pour les événements.
///
/// Les features `events` (participant) et `organizer` utilisaient deux
/// classes `Event` / `EventCategory` dupliquées avec des représentations
/// de date différentes (String vs DateTime). Toute la logique métier
/// utilise désormais ce modèle unique :
/// - `date` : DateTime (Firestore Timestamp)
/// - `status` : draft / live / completed / cancelled
/// - `currentAttendees` + `capacity` : source de vérité des places
///
/// Les vues "participant" dérivent l'affichage (date, month, day, time,
/// availablePlaces) via les getters ci-dessous.
enum EventCategory { conference, concert, sport, workshop, festival, other }

enum EventStatus { draft, live, completed, cancelled }

EventCategory eventCategoryFromString(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  for (final category in EventCategory.values) {
    if (category.name == normalized) return category;
  }
  return EventCategory.other;
}

EventStatus eventStatusFromString(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  for (final status in EventStatus.values) {
    if (status.name == normalized) return status;
  }
  return EventStatus.draft;
}

class Event {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime date;
  final int capacity;
  final int currentAttendees;
  final EventStatus status;
  final String location;
  final double price;
  final String organizerId;
  final EventCategory category;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.capacity,
    required this.currentAttendees,
    required this.status,
    required this.location,
    required this.price,
    this.organizerId = '',
    this.category = EventCategory.other,
  });

  int get availablePlaces => capacity - currentAttendees;

  double get attendanceRate => capacity > 0 ? currentAttendees / capacity : 0;

  bool get isFull => currentAttendees >= capacity;

  bool get isLive => status == EventStatus.live;

  String get formattedPrice => '€${price.toStringAsFixed(2)}';

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// Affichage "09/12/2026" pour les vues participant.
  String get displayDate => '${date.day}/${date.month}/${date.year}';

  String get month => _months[date.month - 1];

  String get day => date.day.toString();

  String get time =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? date,
    int? capacity,
    int? currentAttendees,
    EventStatus? status,
    String? location,
    double? price,
    String? organizerId,
    EventCategory? category,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      capacity: capacity ?? this.capacity,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      status: status ?? this.status,
      location: location ?? this.location,
      price: price ?? this.price,
      organizerId: organizerId ?? this.organizerId,
      category: category ?? this.category,
    );
  }
}
