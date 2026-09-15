import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../events/domain/entities/event.dart';
import 'event_image_storage_datasource.dart';

class EventRemoteDataSource {
  final FirebaseFirestore firestore;
  final String organizerId;

  EventRemoteDataSource({required this.firestore, required this.organizerId});

  CollectionReference<Map<String, dynamic>> get _events =>
      firestore.collection('events');

  /// Stream temps réel des événements de l'organizer : plus besoin de
  /// invalidate() manuel après create/update/delete/publish.
  Stream<List<Event>> watchEvents() {
    return _events
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  Future<List<Event>> getEvents() async {
    final snapshot = await _events
        .where('organizerId', isEqualTo: organizerId)
        .get();

    return snapshot.docs.map(_fromDocument).toList();
  }

  Future<Event?> getEventById(String id) async {
    final document = await _events.doc(id).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['organizerId'] != organizerId) {
      return null;
    }

    return _fromDocument(document);
  }

  Future<Event> createEvent(
    Event event, {
    Uint8List? imageBytes,
    String? imageExtension,
    required EventImageStorageDataSource imageStorage,
  }) async {
    final reference = event.id.isEmpty ? _events.doc() : _events.doc(event.id);

    var saved = event.copyWith(id: reference.id, organizerId: organizerId);

    if (imageBytes != null) {
      if (imageExtension == null || imageExtension.isEmpty) {
        throw ArgumentError('An image extension is required for uploads.');
      }

      final imageUrl = await imageStorage.upload(
        bytes: imageBytes,
        organizerId: organizerId,
        eventId: reference.id,
        fileExtension: imageExtension,
      );

      saved = saved.copyWith(imageUrl: imageUrl);
    }

    await reference.set(_toMap(saved));

    return saved;
  }

  Future<Event> updateEvent(Event event) async {
    final reference = _events.doc(event.id);

    final existing = await reference.get();

    if (!existing.exists || existing.data()?['organizerId'] != organizerId) {
      throw StateError('Event not found or access denied.');
    }

    final saved = event.copyWith(organizerId: organizerId);

    await reference.update(_toMap(saved));

    return saved;
  }

  Future<void> deleteEvent(String id) async {
    final reference = _events.doc(id);

    final existing = await reference.get();

    if (!existing.exists || existing.data()?['organizerId'] != organizerId) {
      throw StateError('Event not found or access denied.');
    }

    await reference.delete();
  }

  Future<Event> publishEvent(String id) async {
    final event = await getEventById(id);

    if (event == null) {
      throw StateError('Event not found or access denied.');
    }

    return updateEvent(event.copyWith(status: EventStatus.live));
  }

  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId,
  ) async {
    // On vérifie d'abord que l'événement appartient bien à cet organisateur :
    // les règles Firestore l'autorisent implicitement, mais un organizerId
    // erroné (session changée) produirait sinon une liste vide trompeuse.
    final event = await getEventById(eventId);

    if (event == null) {
      throw StateError('Event not found or access denied.');
    }

    final snapshot = await firestore
        .collection('reservations')
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs.map((document) {
      return {'id': document.id, ...document.data()};
    }).toList();
  }

  Event _fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;

    final timestamp = data['date'];

    final date = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now();

    final status = eventStatusFromString(data['status']?.toString());

    final category = eventCategoryFromString(data['category']?.toString());

    final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
    final currentAttendees = (data['currentAttendees'] as num?)?.toInt() ?? 0;

    return Event(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      date: date,
      capacity: capacity < 0 ? 0 : capacity,
      // Clamp : une donnée corrompue ne doit pas produire
      // negative availablePlaces plus loin dans l'UI.
      currentAttendees: currentAttendees.clamp(0, capacity < 0 ? 0 : capacity),
      status: status,
      location: data['location'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      organizerId: data['organizerId'] as String? ?? '',
      category: category,
    );
  }

  Map<String, dynamic> _toMap(Event event) {
    return {
      'title': event.title,
      'description': event.description,
      'imageUrl': event.imageUrl,
      'date': Timestamp.fromDate(event.date),
      'capacity': event.capacity,
      'currentAttendees': event.currentAttendees,
      'status': event.status.name,
      'location': event.location,
      'price': event.price,
      'organizerId': event.organizerId,

      // Event category
      'category': event.category.name,

      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
