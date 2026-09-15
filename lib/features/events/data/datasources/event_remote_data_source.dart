import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';

/// What an edit writes, decided from the event as read inside the
/// transaction.
class EventEdit {
  const EventEdit({
    required this.draft,
    required this.capacity,
    required this.availablePlaces,
    required this.tiers,
  });

  /// Validated draft.
  final EventDraft draft;
  final int capacity;
  final int availablePlaces;
  final List<EventTier> tiers;
}

/// Decides an edit from the fresh event: a [Failure] to refuse it, an
/// [EventEdit] to write.
typedef EventEditDecision =
    ({Failure? failure, EventEdit? edit}) Function(Event current);

/// Cloud Firestore access for `events/{eventId}`.
///
/// There is no server code on the Spark plan: every write here is shaped
/// exactly as `firebase/firestore.rules` expects (see
/// `firebase/tests/events.rules.test.js`) — the event and the organizer's
/// public counter move in one batch, and an edit recomputes the seat counter
/// from the document read in the same transaction. SDK exceptions pass
/// through for `ErrorMapper`.
class EventRemoteDataSource {
  const EventRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Every list is explicitly bounded: the rules refuse an event query
  /// without `limit` (≤ 200), and a listener re-reads its whole result after
  /// a reconnection — on the free quota, reads are the budget.
  static const maxPageSize = 100;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(Collections.events);

  DocumentReference<Map<String, dynamic>> _organizer(String uid) =>
      _db.collection(Collections.organizers).doc(uid);

  /// First page of the catalogue, live, in catalogue order (`startsAt`, then
  /// id — the document id breaks ties so the cursor of
  /// [fetchUpcomingAfter] is exact).
  Stream<List<Event>> watchUpcoming({required DateTime from}) => _upcoming(
    from,
  ).limit(maxPageSize).snapshots().map(_toEvents).resilient('events.upcoming');

  /// The page after [after] in catalogue order: a keyset cursor on
  /// (`startsAt`, id), so two events at the same minute are neither skipped
  /// nor repeated.
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

  /// All events of an organizer, most recent first (composite index
  /// `organizerId ASC, startsAt DESC`).
  Stream<List<Event>> watchByOrganizer(String organizerId) => _events
      .where('organizerId', isEqualTo: organizerId)
      .orderBy('startsAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toEvents)
      .resilient('events.organizer');

  /// Events the user co-organizes (F-16), most recent first: `staffIds` is
  /// on the event itself, so one `array-contains` query replaces a join
  /// (composite index `staffIds CONTAINS, startsAt DESC`).
  Stream<List<Event>> watchByStaff(String userId) => _events
      .where('staffIds', arrayContains: userId)
      .orderBy('startsAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toEvents)
      .resilient('events.staff');

  /// Emits `null` when the event does not exist or was deleted.
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

  /// Publishes a new event and returns its id, in the one batch the rules
  /// accept: the event (every seat free, `createdAt` from the server) and
  /// `organizers/{uid}.eventCount + 1` proven by `lastEventId`.
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

  /// Edits an event inside a transaction.
  ///
  /// The seats already taken are read from the document the write is
  /// conditioned on: a booking landing in between makes Firestore retry the
  /// transaction with the new counter, so `availablePlaces = capacity −
  /// taken` always holds. [decide] runs on each attempt with the fresh event
  /// and may refuse; the refusal is returned, not thrown, so it is never
  /// confused with a transaction error.
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

  /// Owner only, and only while no seat is taken (the rules check both).
  /// The public counter goes down in the same batch. Favorites pointing at
  /// the event stay behind and are ignored by the lists that resolve them.
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
