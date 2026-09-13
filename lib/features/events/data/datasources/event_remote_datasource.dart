import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';

class EventRemoteDataSource {
  final FirebaseFirestore _firestore;

  EventRemoteDataSource(this._firestore);

  Future<List<EventModel>> getPublishedEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .where('status', isEqualTo: 'live')
        .get();
    return snapshot.docs.map((document) => _toModel(document)).toList();
  }

  /// Lecture temps réel des événements publiés.
  ///
  /// Le rôle du lecteur n'entre pas en compte ici : les règles Firestore
  /// n'autorisent de toute façon que les documents `status == 'live'` pour
  /// un participant et les événements de l'organisateur courant.
  Stream<List<EventModel>> watchPublishedEvents() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: 'live')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_toModel).toList());
  }

  Future<EventModel?> getEventById(String id) async {
    final snapshot = await _firestore.collection('events').doc(id).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return _toModel(snapshot, dataOverride: data);
  }

  EventModel _toModel(
    DocumentSnapshot<Map<String, dynamic>> document, {
    Map<String, dynamic>? dataOverride,
  }) {
    final data = dataOverride ?? document.data() ?? const <String, dynamic>{};
    final rawDate = data['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse('${rawDate ?? ''}') ?? DateTime.now();
    return EventModel.fromJson({
      ...data,
      'id': document.id,
      'date': date,
      'category': (data['category'] ?? 'other').toString(),
      'status': (data['status'] ?? 'live').toString(),
    });
  }
}
