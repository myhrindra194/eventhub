import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/checkin/domain/check_in_repository.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(FirebaseFirestore firestore)
    : _events = firestore.collection(FirestorePaths.events);

  final CollectionReference<Map<String, dynamic>> _events;

  CollectionReference<Map<String, dynamic>> _checkins(String eventId) =>
      _events.doc(eventId).collection(FirestorePaths.checkins);

  static DateTime _scannedAt(Map<String, dynamic>? data) =>
      switch (data?['scannedAt']) {
        final Timestamp t => t.toDate(),
        // Local write not acknowledged yet: the scan is happening now.
        _ => DateTime.now(),
      };

  @override
  Stream<Map<String, DateTime>> watchCheckIns(String eventId) =>
      _checkins(eventId).snapshots().map(
        (s) => {for (final d in s.docs) d.id: _scannedAt(d.data())},
      );

  @override
  AsyncResult<DateTime?> checkedInAt({
    required String eventId,
    required String reservationId,
  }) => guard(() async {
    final snap = await _checkins(eventId).doc(reservationId).get();
    return snap.exists ? _scannedAt(snap.data()) : null;
  });

  @override
  AsyncResult<bool> record({
    required String eventId,
    required String reservationId,
    required String organizerId,
  }) => guard(() async {
    final ref = _checkins(eventId).doc(reservationId);
    try {
      await ref.set({
        'reservationId': reservationId,
        'scannedBy': organizerId,
        'scannedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      // An existing check-in turns this `set` into a refused update: two
      // doors scanned the same ticket at the same moment.
      if (e.code == 'permission-denied' && (await ref.get()).exists) {
        return false;
      }
      rethrow;
    }
  });
}
