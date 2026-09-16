import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// Supprimer un compte sans serveur : le propriétaire nettoie lui-même ses
/// propres données, dans un ordre que toutes les règles de sécurité
/// acceptent, avant que l’utilisateur Authentication ne soit supprimé.
///
/// Ce qui reste, volontairement : les réservations et les avis passés
/// (anonymisés — les statistiques et les notes de l’organisateur restent
/// justes), ainsi que les événements passés d’un organisateur (les billets
/// détenus par les participants pointent dessus).
class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  static const deletedName = 'Compte supprimé';
  static const deletedEmail = 'supprime@eventhub.invalid';

  /// Un batch Firestore n’accepte que 500 écritures au maximum.
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

    // 1. Refusé tant que des participants détiennent un billet pour un
    //    événement à venir.
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

    // 2. Les places à venir retournent aux événements, puis chaque billet
    //    est anonymisé (les règles exigent que le profil existe encore).
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

    // 3. Les avis restent, anonymisés.
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

    // 4. Les abonnements rendent leur compteur, un batch chacun (les règles
    //    prouvent l’opération contre le document d’abonnement).
    final user = _db.collection(Collections.users).doc(uid);
    final following = await user.collection(Collections.following).get();
    for (final follow in following.docs) {
      final organizer = _db.collection(Collections.organizers).doc(follow.id);
      final batch = _db.batch()..delete(follow.reference);
      if ((await organizer.get()).exists) {
        batch.update(organizer, {'followerCount': FieldValue.increment(-1)});
      }
      await batch.commit();
    }

    // 5. Organisateur : les événements que personne n’a réservés sont
    //    supprimés, puis la page publique.
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
    // 6. Les sous-collections personnelles, la page publique et son entrée
    //    de recherche par e-mail, puis le profil en tout dernier.
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
          _db
              .collection(Collections.organizerEmails)
              .doc(DocIds.emailKey(email)),
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
          if (tierId != null)
            'tiers.$tierId.available': FieldValue.increment(1),
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
