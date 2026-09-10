class Event {
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

  const Event({
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
}