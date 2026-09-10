import '../../domain/entities/event.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String month;
  final String day;
  final String time;
  final String location;
  final String imageUrl;
  final String imagePath;
  final String category;
  final double price;
  final int capacity;
  final int availablePlaces;
  final String organizerId;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.month,
    required this.day,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.imagePath,
    required this.category,
    this.price = 0.0,
    this.capacity = 0,
    this.availablePlaces = 0,
    this.organizerId = '',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final image =
        json['imageUrl'] as String? ?? json['imagePath'] as String? ?? '';
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
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] as int? ?? 0,
      availablePlaces: json['availablePlaces'] as int? ?? 0,
      organizerId: json['organizerId'] as String? ?? '',
    );
  }

  Event toEntity() {
    return Event(
      id: id,
      title: title,
      description: description,
      date: date,
      month: month,
      day: day,
      time: time,
      location: location,
      imageUrl: imageUrl,
      imagePath: imagePath,
      category: category,
      price: price,
      capacity: capacity,
      availablePlaces: availablePlaces,
      organizerId: organizerId,
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
      'price': price,
      'capacity': capacity,
      'availablePlaces': availablePlaces,
      'organizerId': organizerId,
    };
  }
}
