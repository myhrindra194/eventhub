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
  });

  double get attendanceRate => capacity > 0 ? currentAttendees / capacity : 0;
  bool get isFull => currentAttendees >= capacity;
  bool get isLive => status == EventStatus.live;
  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}

enum EventStatus {
  draft,
  live,
  completed,
  cancelled,
}
