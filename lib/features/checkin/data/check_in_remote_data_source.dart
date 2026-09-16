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

  /// Alimente le compteur « 12 / 80 » en direct et « Entré · HH:mm » sur la
  /// liste des invités. Un scan qui vient d’être fait sur cet appareil n’a
  /// pas encore d’heure serveur : il compte immédiatement, à l’heure locale.
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

  /// Une seule transaction : lire le billet et son entrée de check-in,
  /// décider avec [CheckInPolicy.judge], ne créer l’entrée qu’en cas
  /// d’admission.
  ///
  /// Un id de réservation inexistant ne peut pas être lu par l’équipe (les
  /// règles ne laissent une personne sonder que sa propre place absente) :
  /// la lecture est donc refusée par un `permission-denied`.
  /// `CheckInPolicy.precheck` a déjà prouvé que l’id appartient à cet
  /// événement et l’écran est réservé à son équipe, si bien que ce refus
  /// signifie un billet inconnu.
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
