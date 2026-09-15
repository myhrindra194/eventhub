import '../../domain/entities/event.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String imageUrl;
  final String category;
  final String status;
  final double price;
  final int capacity;
  final int currentAttendees;
  final String organizerId;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.category,
    required this.status,
    this.price = 0.0,
    this.capacity = 0,
    this.currentAttendees = 0,
    this.organizerId = '',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    DateTime asDate(Object? value) {
      if (value is DateTime) return value;
      return DateTime.tryParse('${value ?? ''}') ?? DateTime.now();
    }

    final image =
        json['imageUrl'] as String? ?? json['imagePath'] as String? ?? '';
    return EventModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: asDate(json['date']),
      location: (json['location'] ?? '').toString(),
      imageUrl: image,
      category: (json['category'] ?? 'other').toString(),
      status: (json['status'] ?? 'live').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      capacity: asInt(json['capacity']),
      currentAttendees: asInt(json['currentAttendees']),
      organizerId: (json['organizerId'] ?? '').toString(),
    );
  }

  Event toEntity() {
    return Event(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      date: date,
      capacity: capacity,
      currentAttendees: currentAttendees,
      status: eventStatusFromString(status),
      location: location,
      price: price,
      organizerId: organizerId,
      category: eventCategoryFromString(category),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'status': status,
      'price': price,
      'capacity': capacity,
      'currentAttendees': currentAttendees,
      'organizerId': organizerId,
    };
  }
}
