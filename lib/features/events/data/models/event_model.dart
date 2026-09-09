import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.date,
    required super.month,
    required super.day,
    required super.time,
    required super.location,
    required super.imageUrl,
    required super.imagePath,
    required super.category,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String? ?? json['imagePath'] as String? ?? '';
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      month: json['month'] as String? ?? '',
      day: json['day'] as String? ?? '',
      time: json['time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrl: image,
      imagePath: image,
      category: json['category'] as String? ?? 'All',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'month': month,
      'day': day,
      'time': time,
      'location': location,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'category': category,
    };
  }
}