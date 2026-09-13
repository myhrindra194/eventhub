import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reservation_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<ReservationModel>> fetchUserReservations();
  Future<void> saveReservation(ReservationModel reservation);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ReservationRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<List<ReservationModel>> fetchUserReservations() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return [];

    final snapshot = await firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      return ReservationModel.fromJson({'id': doc.id, ...doc.data()});
    }).toList();
  }

  @override
  Future<void> saveReservation(ReservationModel reservation) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('An authenticated user is required.');
    }

    // `reservedAt` doit être un timestamp réel (pas
    // `FieldValue.serverTimestamp()`) pour que les règles Firestore
    // (`request.resource.data.reservedAt != null`) s'évaluent correctement
    // côté serveur avant que le timestamp serveur ne soit résolu.
    final now = DateTime.now();

    final eventRef = firestore.collection('events').doc(reservation.eventId);
    final reservationsRef = firestore.collection('reservations');

    await firestore.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw StateError('Event not found.');
      }

      final data = eventSnapshot.data() ?? {};
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final currentAttendees = (data['currentAttendees'] as num?)?.toInt() ?? 0;
      if (currentAttendees + reservation.quantity > capacity) {
        throw StateError('The requested quantity is not available.');
      }

      final reservationRef = reservationsRef.doc();
      transaction.set(reservationRef, {
        'userId': user.uid,
        'eventId': reservation.eventId,
        'eventTitle': reservation.eventTitle,
        'date': reservation.date,
        'status': 'confirmed',
        'seatInfo': reservation.seatInfo,
        'quantity': reservation.quantity,
        'reservedAt': now,
      });
      transaction.update(eventRef, {
        'currentAttendees': currentAttendees + reservation.quantity,
        // Requis par firestore.rules : le diff autorisé est limité à
        // ['currentAttendees', 'updatedAt'].
        'updatedAt': now,
      });
    });
  }
}
