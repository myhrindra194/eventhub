import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reviews/data/review_dto.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

/// `reviews/{eventId}_{authorId}` et la note qu’il alimente sur
/// `organizers/{organizerId}` (`ratingSum`, `ratingCount`, `lastReviewId`).
///
/// Les règles n’acceptent une variation de note que dans le commit qui écrit
/// l’avis qui la justifie, et exactement de l’écart visible. Chaque écriture
/// ci-dessous est donc une transaction qui lit d’abord l’avis : le pas est
/// calculé à partir de la note et du drapeau `hidden` stockés, et non de ce
/// qu’un écran peut-être périmé affichait, et une modification concurrente
/// fait rejouer la transaction au lieu de la faire refuser.
class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Le détail d’un événement montre les derniers avis, pas une archive.
  static const maxPageSize = 100;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(Collections.reviews);

  DocumentReference<Map<String, dynamic>> _organizer(String organizerId) =>
      _db.collection(Collections.organizers).doc(organizerId);

  /// Les plus récents d’abord. `hidden == false` fait partie de la requête
  /// parce que les règles refusent une liste susceptible de renvoyer l’avis
  /// masqué de quelqu’un d’autre.
  Stream<List<Review>> watchEventReviews(String eventId) => _reviews
      .where('eventId', isEqualTo: eventId)
      .where('hidden', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(
        (query) => query.docs
            .map((d) => ReviewDto.fromJson(d.data()).toDomain(d.id))
            .toList(growable: false),
      )
      .resilient('event-reviews');

  /// L’avis de l’auteur, masqué ou non : un document absent reste lisible.
  Stream<Review?> watchReview({
    required String eventId,
    required String authorId,
  }) => watchById(DocIds.review(eventId, authorId));

  Stream<Review?> watchById(String reviewId) => _reviews
      .doc(reviewId)
      .snapshots()
      .map((s) {
        final data = s.data();
        return data == null ? null : ReviewDto.fromJson(data).toDomain(s.id);
      })
      .resilient('review:$reviewId');

  /// Crée l’avis de [author], ou le modifie s’il existe déjà (un second
  /// appareil, un flux pas encore à jour) : dans les deux cas, c’est ce que
  /// la personne voulait.
  ///
  /// [organizerId] est celui de l’événement, tel que copié sur la
  /// réservation de l’auteur — les règles le comparent à l’événement.
  Future<void> save({
    required String eventId,
    required String organizerId,
    required AppUser author,
    required int rating,
    required String comment,
  }) => _db.runTransaction((tx) async {
    final ref = _reviews.doc(DocIds.review(eventId, author.id));
    final current = (await tx.get(ref)).data();

    if (current == null) {
      tx
        ..set(ref, {
          'eventId': eventId,
          'organizerId': organizerId,
          'authorId': author.id,
          'authorName': author.name,
          'rating': rating,
          'comment': comment,
          'hidden': false,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(_organizer(organizerId), {
          'ratingSum': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
          'lastReviewId': ref.id,
        });
      return;
    }

    final previous = (current['rating'] as num?)?.toInt() ?? 0;
    tx.update(ref, {
      'rating': rating,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Un avis masqué ne compte pour rien : le modifier ne déplace aucune
    // note. Une note inchangée n’en déplace pas davantage, et n’exige
    // aucune écriture sur l’organisateur.
    if (current['hidden'] != true && rating != previous) {
      tx.update(_organizer(current['organizerId'] as String), {
        'ratingSum': FieldValue.increment(rating - previous),
        'lastReviewId': ref.id,
      });
    }
  });

  /// Supprime l’avis de [authorId] et, sauf si la modération l’avait masqué,
  /// sa part dans la note. Sans effet s’il n’y en a pas.
  Future<void> delete({required String eventId, required String authorId}) =>
      _db.runTransaction((tx) async {
        final ref = _reviews.doc(DocIds.review(eventId, authorId));
        final current = (await tx.get(ref)).data();
        if (current == null) return;
        tx.delete(ref);
        if (current['hidden'] != true) {
          tx.update(_organizer(current['organizerId'] as String), {
            'ratingSum': FieldValue.increment(
              -((current['rating'] as num?)?.toInt() ?? 0),
            ),
            'ratingCount': FieldValue.increment(-1),
            'lastReviewId': ref.id,
          });
        }
      });
}
