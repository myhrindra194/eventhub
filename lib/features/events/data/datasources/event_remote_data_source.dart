import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';

/// Firestore access for `events/{id}`. Throws; the repository maps errors.
class EventRemoteDataSource {
  EventRemoteDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _events = firestore.collection(FirestorePaths.events);

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _events;

  /// Every list query is explicitly bounded.
  ///
  /// Two reasons, both non-negotiable at scale: an unbounded listener bills
  /// one read per document on every snapshot, and the security rules refuse a
  /// `list` without a limit (`request.query.limit <= 100`), so an unlimited
  /// query would be rejected outright in production.
  static const maxPageSize = 100;

  /// First page of the catalogue, live. Ordered by start date then document
  /// id, so a page boundary is a total order and [fetchUpcomingAfter] can
  /// resume exactly after the last event (two events at the same minute
  /// would otherwise be skipped or repeated).
  Stream<List<Event>> watchUpcoming({required DateTime from}) {
    return _upcoming(from).limit(maxPageSize).snapshots().map(_toDomainList);
  }

  Future<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  }) async {
    final snapshot = await _upcoming(from)
        .startAfter([Timestamp.fromDate(after.startsAt), after.id])
        .limit(limit.clamp(1, maxPageSize))
        .get();
    return _toDomainList(snapshot);
  }

  Query<Map<String, dynamic>> _upcoming(DateTime from) => _events
      .where(
        EventFields.startsAt,
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      )
      .orderBy(EventFields.startsAt)
      .orderBy(FieldPath.documentId);

  Stream<List<Event>> watchByOrganizer(String organizerId) {
    return _events
        .where(EventFields.organizerId, isEqualTo: organizerId)
        .orderBy(EventFields.startsAt, descending: true)
        .limit(maxPageSize)
        .snapshots()
        .map(_toDomainList);
  }

  /// Events the user co-organizes (F-16), most recent first.
  Stream<List<Event>> watchByStaff(String userId) {
    return _events
        .where('staffIds', arrayContains: userId)
        .orderBy(EventFields.startsAt, descending: true)
        .limit(maxPageSize)
        .snapshots()
        .map(_toDomainList);
  }

  Stream<Event?> watchById(String eventId) =>
      _events.doc(eventId).snapshots().map(_toDomainOrNull);

  Future<Event> getById(String eventId) async {
    final event = _toDomainOrNull(await _events.doc(eventId).get());
    if (event == null) throw FailureException(_notFound(eventId));
    return event;
  }

  Future<String> create(EventDto dto) async {
    final ref = await _events.add({
      ...dto.toJson(),
      EventFields.createdAt: FieldValue.serverTimestamp(),
      EventFields.updatedAt: FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Ownership + capacity consistency are checked inside a transaction so a
  /// concurrent reservation cannot be lost when the organizer edits capacity.
  Future<void> update({
    required String eventId,
    required EventDraft draft,
    required String organizerId,
  }) {
    final ref = _events.doc(eventId);
    return _firestore.runTransaction((tx) async {
      final current = _toDomainOrNull(await tx.get(ref));
      if (current == null) throw FailureException(_notFound(eventId));
      if (!current.isManagedBy(organizerId)) {
        throw const FailureException(
          BusinessRuleFailure(
            rule: BusinessRule.notEventOwner,
            message:
                'Vous ne pouvez modifier que vos événements ou ceux que vous '
                'co-organisez.',
          ),
        );
      }
      // Ticket types (F-12): every seat already sold stays sold, in its type.
      final plan = switch (TierPlanner.apply(
        soldWithoutTiers: current.hasTiers ? 0 : current.reservedCount,
        current: current.tiers,
        drafts: draft.tiers,
      )) {
        Ok(:final value) => value,
        Err(:final failure) => throw FailureException(failure),
      };

      final int capacity;
      final int availablePlaces;
      if (plan == null) {
        capacity = draft.capacity;
        availablePlaces =
            switch (EventPolicy.availablePlacesAfterCapacityChange(
              event: current,
              newCapacity: draft.capacity,
            )) {
              Ok(:final value) => value,
              Err(:final failure) => throw FailureException(failure),
            };
      } else {
        capacity = plan.capacity;
        availablePlaces = plan.available;
      }

      tx.update(ref, {
        EventFields.title: draft.title,
        EventFields.description: draft.description,
        EventFields.category: draft.category.name,
        EventFields.startsAt: Timestamp.fromDate(draft.startsAt),
        EventFields.location: draft.location,
        EventFields.capacity: capacity,
        EventFields.availablePlaces: availablePlaces,
        EventFields.imageUrl: draft.imageUrl,
        EventFields.tiers: plan == null
            ? const <String, Object?>{}
            : EventDto.tiersToMap(plan.tiers),
        EventFields.currency: (plan?.hasPaid ?? false)
            ? draft.currency
            : FieldValue.delete(),
        EventFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete(String eventId) => _events.doc(eventId).delete();

  List<Event> _toDomainList(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => EventDto.fromJson(doc.data()).toDomain(doc.id))
          .toList(growable: false);

  Event? _toDomainOrNull(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return data == null ? null : EventDto.fromJson(data).toDomain(snapshot.id);
  }

  NotFoundFailure _notFound(String eventId) => NotFoundFailure(
    resource: 'events/$eventId',
    message: 'Événement introuvable.',
  );
}
