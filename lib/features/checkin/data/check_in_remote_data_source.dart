import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/reservations/data/dtos/reservation_dto.dart';

/// `events/{eventId}/checkins/{reservationId}` {reservationId, scannedBy,
/// scannedAt}.
class CheckInRemoteDataSource {
  const CheckInRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _checkins(String eventId) => _db
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.checkins);

  /// Feeds the live "12 / 80" counter and "Entré · HH:mm" on the guest list.
  /// A scan just made on this device has no server time yet: it counts
  /// immediately, at the local time.
  Stream<Map<String, DateTime>> watchCheckIns(String eventId) =>
      _checkins(eventId)
          .snapshots()
          .map(
            (query) => {
              for (final doc in query.docs)
                doc.id:
                    const NullableTimestampConverter().fromJson(
                      doc.data()['scannedAt'],
                    ) ??
                    DateTime.now(),
            },
          )
          .resilient('checkins:$eventId');

  /// One transaction: read the ticket and its check-in entry, decide with
  /// [CheckInPolicy.judge], create the entry only when admitting.
  ///
  /// A reservation id that does not exist cannot be read by the team (the
  /// rules only let a person probe their own missing seat), so the read is
  /// refused with `permission-denied`. `CheckInPolicy.precheck` has already
  /// proven the id belongs to this event and the screen is reserved to its
  /// team, so that refusal means an unknown ticket.
  Future<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
    required String scannedBy,
  }) async {
    final reservationRef = _db
        .collection(Collections.reservations)
        .doc(reservationId);
    final checkinRef = _checkins(eventId).doc(reservationId);
    try {
      return await _db.runTransaction((tx) async {
        final reservationSnap = await tx.get(reservationRef);
        final checkinSnap = await tx.get(checkinRef);
        final data = reservationSnap.data();
        final verdict = CheckInPolicy.judge(
          eventId: eventId,
          reservationId: reservationId,
          reservation: data == null
              ? null
              : ReservationDto.fromJson(data).toDomain(reservationId),
          alreadyScanned: checkinSnap.exists,
          scannedAt: const NullableTimestampConverter().fromJson(
            checkinSnap.data()?['scannedAt'],
          ),
          now: DateTime.now(),
        );
        if (verdict.isAdmitted) {
          tx.set(checkinRef, {
            'reservationId': reservationId,
            'scannedBy': scannedBy,
            'scannedAt': FieldValue.serverTimestamp(),
          });
        }
        return verdict;
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      return CheckInVerdict(
        CheckInStatus.notFound,
        reservationId: reservationId,
      );
    }
  }
}
