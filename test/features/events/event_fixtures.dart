import 'package:eventhub/features/events/data/models/event_model.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';

/// Fixtures partagées des tests `events`.
///
/// EventModel : vivant, gratuit, capacité 100.
EventModel buildEvent({
  String id = 'event-1',
  String title = 'Tech Meetup',
  String category = 'conference',
  String status = 'live',
  String location = 'Paris',
}) {
  return EventModel(
    id: id,
    title: title,
    description: 'Description',
    date: DateTime(2026, 11, 20, 18),
    location: location,
    imageUrl: 'assets/images/tech.jpg',
    category: category,
    status: status,
    price: 0,
    capacity: 100,
    currentAttendees: 20,
    organizerId: 'org-1',
  );
}

Event buildEventEntity({
  String id = 'event-1',
  String title = 'Tech Meetup',
  EventCategory category = EventCategory.conference,
  int capacity = 100,
  int currentAttendees = 0,
}) {
  return Event(
    id: id,
    title: title,
    description: 'Description',
    imageUrl: 'assets/images/tech.jpg',
    date: DateTime(2026, 11, 20, 18),
    capacity: capacity,
    currentAttendees: currentAttendees,
    status: EventStatus.live,
    location: 'Paris',
    price: 0,
    organizerId: 'org-1',
    category: category,
  );
}
