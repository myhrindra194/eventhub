import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';
import 'event_image_storage_datasource.dart';

class EventRemoteDataSource {
  final FirebaseFirestore firestore;
  final String organizerId;

  EventRemoteDataSource({required this.firestore, required this.organizerId});

  CollectionReference<Map<String, dynamic>> get _events =>
      firestore.collection('events');

  Future<List<Event>> getEvents() async {
    final snapshot = await _events
        .where('organizerId', isEqualTo: organizerId)
        .get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  Future<Event?> getEventById(String id) async {
    final document = await _events.doc(id).get();
    if (!document.exists) return null;
    final data = document.data();
    if (data == null || data['organizerId'] != organizerId) return null;
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
      saved = saved.copyWith(imageUrl: imageUrl, isBase64: false);
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
    if (event == null) throw StateError('Event not found or access denied.');
    return updateEvent(event.copyWith(status: EventStatus.live));
  }

  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId,
  ) async {
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
    final status = EventStatus.values.firstWhere(
      (value) => value.name == data['status'],
      orElse: () => EventStatus.draft,
    );
    return Event(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      date: date,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      currentAttendees: (data['currentAttendees'] as num?)?.toInt() ?? 0,
      status: status,
      location: data['location'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isBase64: data['isBase64'] as bool? ?? false,
      organizerId: data['organizerId'] as String? ?? '',
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
      'isBase64': event.isBase64,
      'organizerId': event.organizerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
