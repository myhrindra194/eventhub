enum EventCategory { conference, concert, sport, workshop, festival, other }

enum EventStatus { draft, live, completed, cancelled }

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
  final bool isBase64;
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
    this.isBase64 = false,
    this.organizerId = '',
    this.category = EventCategory.other,
  });

  double get attendanceRate => capacity > 0 ? currentAttendees / capacity : 0;

  bool get isFull => currentAttendees >= capacity;

  bool get isLive => status == EventStatus.live;

  String get formattedPrice => '€${price.toStringAsFixed(2)}';

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
    bool? isBase64,
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
      isBase64: isBase64 ?? this.isBase64,
      organizerId: organizerId ?? this.organizerId,
      category: category ?? this.category,
    );
  }
}
