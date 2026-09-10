import '../models/event_model.dart';

abstract class EventLocalDataSource {
  Future<List<EventModel>> getEvents();
}

class EventLocalDataSourceImpl implements EventLocalDataSource {
  @override
  Future<List<EventModel>> getEvents() async {
    return [
      const EventModel(
        id: '1',
        title: 'Tech Conference 2026',
        description:
            'A major conference about mobile development and the cloud.',
        date: '15 OCT',
        month: 'OCT',
        day: '15',
        time: '10:00 AM',
        location: 'Paris, France',
        imageUrl: 'assets/images/tech.jpg',
        imagePath: 'assets/images/tech.jpg',
        category: 'Tech',
        capacity: 120,
        availablePlaces: 120,
      ),
      const EventModel(
        id: '2',
        title: 'Music Festival',
        description: 'A live music festival featuring international artists.',
        date: '20 NOV',
        month: 'NOV',
        day: '20',
        time: '18:00 PM',
        location: 'Lyon, France',
        imageUrl: 'assets/images/music.jpg',
        imagePath: 'assets/images/music.jpg',
        category: 'Music',
        capacity: 500,
        availablePlaces: 0,
      ),
    ];
  }
}
