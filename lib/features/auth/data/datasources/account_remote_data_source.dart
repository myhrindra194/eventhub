import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// Deleting an account without a server: the owner cleans up their own data,
/// in an order every security rule accepts, before the Authentication user
/// is deleted.
///
/// What stays, on purpose: past reservations and reviews (anonymised — the
/// organizer's statistics and ratings remain true), and past events of an
/// organizer (the tickets people hold point at them).
class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  static const deletedName = 'Compte supprimé';
  static const deletedEmail = 'supprime@eventhub.invalid';

  /// Firestore batches hold at most 500 writes.
  static const _batchLimit = 450;

  Future<void> deleteAccountData(
    String uid, {
    required String email,
    required bool isOrganizer,
    required DateTime now,
  }) async {
    final events = await _db
        .collection(Collections.events)
        .where('organizerId', isEqualTo: uid)
        .limit(200)
        .get();

    // 1. Refused while people hold a ticket for an upcoming event.
    for (final event in events.docs) {
      final data = event.data();
      final startsAt = (data['startsAt'] as Timestamp).toDate();
      final taken =
          (data['capacity'] as num).toInt() -
          (data['availablePlaces'] as num).toInt();
      if (startsAt.isAfter(now) && taken > 0) {
        throw const FailureException(
          BusinessRuleFailure(
            rule: BusinessRule.eventHasReservations,
            message:
                'Un de vos événements à venir a des participants : annulez-le '
                'ou attendez qu’il soit passé avant de supprimer le compte.',
          ),
        );
      }
    }

    // 2. Upcoming seats go back to the events, then every ticket is
    //    anonymised (the rules require the profile to still exist).
    final reservations = await _db
        .collection(Collections.reservations)
        .where('userId', isEqualTo: uid)
        .limit(500)
        .get();
    for (final reservation in reservations.docs) {
      final data = reservation.data();
      final startsAt = (data['eventStartsAt'] as Timestamp).toDate();
      if (data['status'] == 'confirmed' && startsAt.isAfter(now)) {
        await _releaseSeat(reservation.reference, data, uid);
      }
    }
    await _commitInChunks([
      for (final reservation in reservations.docs)
        (WriteBatch batch) => batch.update(reservation.reference, {
          'userId': '',
          'userName': deletedName,
          'userEmail': deletedEmail,
        }),
      for (final reservation in reservations.docs)
        (WriteBatch batch) => batch.delete(
          _db
              .collection(Collections.events)
              .doc(reservation.data()['eventId'] as String)
              .collection(Collections.attendees)
              .doc(DocIds.attendeeKey(uid)),
        ),
    ]);

    // 3. Reviews stay, anonymised.
    final reviews = await _db
        .collection(Collections.reviews)
        .where('authorId', isEqualTo: uid)
        .limit(500)
        .get();
    await _commitInChunks([
      for (final review in reviews.docs)
        (WriteBatch batch) => batch.update(review.reference, {
          'authorId': '',
          'authorName': deletedName,
        }),
    ]);

    // 4. Follows give their counter back, one batch each (the rules prove
    //    the step against the follow document).
    final user = _db.collection(Collections.users).doc(uid);
    final following = await user.collection(Collections.following).get();
    for (final follow in following.docs) {
      final organizer = _db
          .collection(Collections.organizers)
          .doc(follow.id);
      final batch = _db.batch()..delete(follow.reference);
      if ((await organizer.get()).exists) {
        batch.update(organizer, {'followerCount': FieldValue.increment(-1)});
      }
      await batch.commit();
    }

    // 5. Organizer: events nobody booked are removed, then the public page.
    for (final event in events.docs) {
      final data = event.data();
      final taken =
          (data['capacity'] as num).toInt() -
          (data['availablePlaces'] as num).toInt();
      if (taken == 0) {
        await (_db.batch()
              ..delete(event.reference)
              ..update(_db.collection(Collections.organizers).doc(uid), {
                'eventCount': FieldValue.increment(-1),
                'lastEventId': event.id,
              }))
            .commit();
      }
    }
    // 6. Personal sub-collections, the public page and its e-mail lookup
    //    entry, then the profile last.
    final personal = [
      for (final name in [
        Collections.favorites,
        Collections.notifications,
        Collections.devices,
        Collections.private,
      ])
        ...(await user.collection(name).get()).docs.map((d) => d.reference),
    ];
    await _commitInChunks([
      for (final ref in personal) (WriteBatch batch) => batch.delete(ref),
      if (isOrganizer) ...[
        (WriteBatch batch) => batch.delete(
          _db.collection(Collections.organizerEmails).doc(DocIds.emailKey(email)),
        ),
        (WriteBatch batch) =>
            batch.delete(_db.collection(Collections.organizers).doc(uid)),
      ],
    ]);
    await user.delete();
  }

  Future<void> _releaseSeat(
    DocumentReference<Map<String, dynamic>> reservation,
    Map<String, dynamic> data,
    String uid,
  ) {
    final eventRef = _db
        .collection(Collections.events)
        .doc(data['eventId'] as String);
    return _db.runTransaction((tx) async {
      final event = await tx.get(eventRef);
      if (event.exists) {
        final tierId = data['tierId'] as String?;
        tx.update(eventRef, {
          'availablePlaces': FieldValue.increment(1),
          if (tierId != null) 'tiers.$tierId.available': FieldValue.increment(1),
        });
      }
      tx.update(reservation, {
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
        'cancelledBy': uid,
      });
    });
  }

  Future<void> _commitInChunks(List<void Function(WriteBatch)> writes) async {
    for (var start = 0; start < writes.length; start += _batchLimit) {
      final batch = _db.batch();
      for (final write in writes.skip(start).take(_batchLimit)) {
        write(batch);
      }
      await batch.commit();
    }
  }
}
