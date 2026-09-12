import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';

class EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSource(this.firestore);

  Future<List<EventModel>> getPublishedEvents() async {
    final snapshot = await firestore
        .collection('events')
        .where('status', isEqualTo: 'live')
        .get();
    return snapshot.docs.map(_toModel).toList();
  }

  EventModel _toModel(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final rawDate = data['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
    final currentAttendees = (data['currentAttendees'] as num?)?.toInt() ?? 0;
    final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
    return EventModel.fromJson({
      ...data,
      'id': document.id,
      'date': '${date.day}/${date.month}/${date.year}',
      'month': _month(date.month),
      'day': date.day.toString(),
      'time':
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      'imagePath': data['imageUrl'] ?? '',
      'category': data['category'] ?? 'All',
      'availablePlaces': capacity - currentAttendees,
    });
  }

  String _month(int month) {
    const names = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return names[month - 1];
  }
}
