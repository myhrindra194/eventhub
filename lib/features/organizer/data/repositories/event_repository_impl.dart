import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final List<Event> _events = [
    Event(
      id: '1',
      title: 'Tech Nexus 2024',
      description: 'Annual technology conference featuring the latest innovations',
      imageUrl: 'assets/images/tech.jpg',
      date: DateTime(2024, 10, 24),
      capacity: 100,
      currentAttendees: 48,
      status: EventStatus.live,
      location: 'Paris, France',
      price: 49.99,
      isBase64: false,
    ),
    Event(
      id: '2',
      title: 'Acoustic Sessions #4',
      description: 'Live acoustic music performances',
      imageUrl: 'assets/images/music.jpg',
      date: DateTime(2024, 11, 2),
      capacity: 25,
      currentAttendees: 0,
      status: EventStatus.draft,
      location: 'Lyon, France',
      price: 25.00,
      isBase64: false,
    ),
  ];

  @override
  Future<List<Event>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _events;
  }

  @override
  Future<Event?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Event> createEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _events.add(event);
    return event;
  }

  @override
  Future<Event> updateEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      return event;
    }
    throw Exception('Event not found');
  }

  @override
  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _events.removeWhere((event) => event.id == id);
  }

  @override
  Future<void> publishEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _events.indexWhere((event) => event.id == id);
    if (index != -1) {
      final event = _events[index];
      _events[index] = Event(
        id: event.id,
        title: event.title,
        description: event.description,
        imageUrl: event.imageUrl,
        date: event.date,
        capacity: event.capacity,
        currentAttendees: event.currentAttendees,
        status: EventStatus.live,
        location: event.location,
        price: event.price,
        isBase64: event.isBase64,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'id': '1', 'name': 'RAKOTO', 'email': 'rakoto@example.com', 'status': 'confirmed'},
      {'id': '2', 'name': 'rabe', 'email': 'rabe@example.com', 'status': 'confirmed'},
      {'id': '3', 'name': 'rasoa', 'email': 'rasoa@example.com', 'status': 'pending'},
      {'id': '4', 'name': 'Ranaivo', 'email': 'ranaivo@example.com', 'status': 'confirmed'},
      {'id': '5', 'name': 'Nivo', 'email': 'nivo@example.com', 'status': 'pending'},
    ];
  }
}
