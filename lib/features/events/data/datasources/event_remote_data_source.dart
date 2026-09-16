import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';

/// Ce qu’une modification écrit, décidé à partir de l’événement tel qu’il
/// est lu dans la transaction.
class EventEdit {
  const EventEdit({
    required this.draft,
    required this.capacity,
    required this.availablePlaces,
    required this.tiers,
  });

  /// Brouillon validé.
  final EventDraft draft;
  final int capacity;
  final int availablePlaces;
  final List<EventTier> tiers;
}

/// Décide d’une modification à partir de l’événement frais : une [Failure]
/// pour la refuser, un [EventEdit] à écrire.
typedef EventEditDecision =
    ({Failure? failure, EventEdit? edit}) Function(Event current);

/// Accès Cloud Firestore à `events/{eventId}`.
///
/// Il n’y a pas de code serveur sur le plan Spark : chaque écriture est ici
/// façonnée exactement comme `firebase/firestore.rules` l’attend (voir
/// `firebase/tests/events.rules.test.js`) — l’événement et le compteur
/// public de l’organisateur bougent dans un même batch, et une modification
/// recalcule le compteur de places depuis le document lu dans la même
/// transaction. Les exceptions du SDK remontent telles quelles, pour
/// `ErrorMapper`.
class EventRemoteDataSource {
  const EventRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Toute liste est explicitement bornée : les règles refusent une requête
  /// d’événements sans `limit` (≤ 200), et un listener relit tout son
  /// résultat après une reconnexion — sur le quota gratuit, ce sont les
  /// lectures qui constituent le budget.
  static const maxPageSize = 100;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(Collections.events);

  DocumentReference<Map<String, dynamic>> _organizer(String uid) =>
      _db.collection(Collections.organizers).doc(uid);

  /// Première page du catalogue, en temps réel, dans l’ordre du catalogue
  /// (`startsAt`, puis id — l’identifiant du document départage les ex
  /// æquo, pour que le curseur de [fetchUpcomingAfter] soit exact).
  Stream<List<Event>> watchUpcoming({required DateTime from}) => _upcoming(
    from,
  ).limit(maxPageSize).snapshots().map(_toEvents).resilient('events.upcoming');

  /// La page qui suit [after] dans l’ordre du catalogue : un curseur keyset
  /// sur (`startsAt`, id), pour que deux événements à la même minute ne
  /// soient ni sautés ni répétés.
  Future<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  }) async {
    final snapshot = await _upcoming(from)
        .startAfter([Timestamp.fromDate(after.startsAt), after.id])
        .limit(limit.clamp(1, maxPageSize))
        .get();
    return _toEvents(snapshot);
  }

  Query<Map<String, dynamic>> _upcoming(DateTime from) => _events
      .where('startsAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .orderBy('startsAt')
      .orderBy(FieldPath.documentId);

  /// Tous les événements d’un organisateur, du plus récent au plus ancien
  /// (index composite `organizerId ASC, startsAt DESC`).
  Stream<List<Event>> watchByOrganizer(String organizerId) => _events
      .where('organizerId', isEqualTo: organizerId)
      .orderBy('startsAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toEvents)
      .resilient('events.organizer');

  /// Événements que l’utilisateur co-organise (F-16), du plus récent au
  /// plus ancien : `staffIds` est porté par l’événement lui-même, donc une
  /// seule requête `array-contains` remplace une jointure (index composite
  /// `staffIds CONTAINS, startsAt DESC`).
  Stream<List<Event>> watchByStaff(String userId) => _events
      .where('staffIds', arrayContains: userId)
      .orderBy('startsAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toEvents)
      .resilient('events.staff');

  /// Émet `null` quand l’événement n’existe pas ou a été supprimé.
  Stream<Event?> watchById(String eventId) => _events
      .doc(eventId)
      .snapshots()
      .map((s) => s.data() == null ? null : _event(s.id, s.data()!))
      .resilient('event');

  Future<Event> getById(String eventId) async {
    final snapshot = await _events.doc(eventId).get();
    final data = snapshot.data();
    if (data == null) throw FailureException(_notFound(eventId));
    return _event(snapshot.id, data);
  }

  /// Publie un nouvel événement et renvoie son id, dans l’unique batch que
  /// les règles acceptent : l’événement (toutes places libres, `createdAt`
  /// venant du serveur) et `organizers/{uid}.eventCount + 1`, attesté par
  /// `lastEventId`.
  Future<String> create({
    required EventDraft draft,
    required TierPlan? plan,
    required String organizerId,
    required String organizerName,
  }) async {
    final ref = _events.doc();
    final batch = _db.batch()
      ..set(
        ref,
        EventDto.createFields(
          draft,
          organizerId: organizerId,
          organizerName: organizerName,
          plan: plan,
        ),
      )
      ..update(_organizer(organizerId), {
        'eventCount': FieldValue.increment(1),
        'lastEventId': ref.id,
      });
    await batch.commit();
    return ref.id;
  }

  /// Modifie un événement à l’intérieur d’une transaction.
  ///
  /// Les places déjà prises sont lues sur le document auquel l’écriture est
  /// conditionnée : une réservation qui s’intercale fait rejouer la
  /// transaction par Firestore avec le nouveau compteur, si bien que
  /// `availablePlaces = capacity − taken` reste toujours vrai. [decide] est
  /// exécuté à chaque tentative avec l’événement frais et peut refuser ; le
  /// refus est renvoyé, pas levé, pour ne jamais être confondu avec une
  /// erreur de transaction.
  Future<Failure?> update(String eventId, EventEditDecision decide) {
    final ref = _events.doc(eventId);
    return _db.runTransaction<Failure?>((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null) return _notFound(eventId);
      final (:failure, :edit) = decide(_event(snapshot.id, data));
      if (failure != null) return failure;
      if (edit == null) return null;
      tx.update(ref, {
        ...EventDto.contentFields(
          edit.draft,
          capacity: edit.capacity,
          availablePlaces: edit.availablePlaces,
          tiers: edit.tiers,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    });
  }

  /// Réservé au propriétaire, et seulement tant qu’aucune place n’est prise
  /// (les règles vérifient les deux). Le compteur public décroît dans le
  /// même batch. Les favoris qui pointent vers l’événement subsistent et
  /// sont ignorés par les listes qui les résolvent.
  Future<void> delete({
    required String eventId,
    required String organizerId,
  }) async {
    final batch = _db.batch()
      ..delete(_events.doc(eventId))
      ..update(_organizer(organizerId), {
        'eventCount': FieldValue.increment(-1),
        'lastEventId': eventId,
      });
    await batch.commit();
  }

  static List<Event> _toEvents(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      List.unmodifiable([
        for (final doc in snapshot.docs) _event(doc.id, doc.data()),
      ]);

  static Event _event(String id, Map<String, dynamic> data) =>
      EventDto.fromFirestore(id, data).toDomain();

  static NotFoundFailure _notFound(String eventId) => NotFoundFailure(
    resource: '${Collections.events}/$eventId',
    message: 'Événement introuvable.',
  );
}
