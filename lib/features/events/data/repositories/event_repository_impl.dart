import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/data/datasources/event_remote_data_source.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:eventhub/features/events/domain/repositories/event_repository.dart';

/// The domain checks run first for an instant, precise message; `save_event`
/// and `delete_event` enforce the same rules again, atomically, and are the
/// authority (a concurrent booking, a stale screen).
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl({
    required EventRemoteDataSource remote,
    required Clock clock,
  }) : _remote = remote,
       _clock = clock;

  final EventRemoteDataSource _remote;
  final Clock _clock;

  @override
  Stream<List<Event>> watchUpcoming({required DateTime from}) =>
      _remote.watchUpcoming(from: from);

  @override
  Stream<List<Event>> watchByOrganizer(String organizerId) =>
      _remote.watchByOrganizer(organizerId);

  @override
  Stream<List<Event>> watchCoOrganized(String userId) =>
      _remote.watchByStaff(userId);

  @override
  Stream<Event?> watchById(String eventId) => _remote.watchById(eventId);

  @override
  AsyncResult<Event> getById(String eventId) =>
      guard(() => _remote.getById(eventId));

  @override
  AsyncResult<String> create({
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(() async {
      if (!organizer.isOrganizer) {
        throw const FailureException(_notOrganizer);
      }
      // The organizer name is copied from the profile by the database.
      return _remote.save(_validated(draft));
    });
  }

  /// Seats already sold, per type or in the single pool, are kept by the
  /// database while the row is locked: no read-then-write race with a
  /// booking.
  @override
  AsyncResult<void> update({
    required String eventId,
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(() async {
      await _remote.save(_validated(draft), eventId: eventId);
    });
  }

  @override
  AsyncResult<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  }) => guard(
    () => _remote.fetchUpcomingAfter(from: from, after: after, limit: limit),
  );

  @override
  AsyncResult<void> delete({
    required String eventId,
    required AppUser organizer,
  }) {
    return guard(() async {
      final event = await _remote.getById(eventId);
      if (EventPolicy.canDelete(event: event, user: organizer) case Err(
        :final failure,
      )) {
        throw FailureException(failure);
      }
      await _remote.delete(eventId);
    });
  }

  EventDraft _validated(EventDraft draft) =>
      switch (draft.validate(now: _clock())) {
        Ok(:final value) => value,
        Err(:final failure) => throw FailureException(failure),
      };

  static const _notOrganizer = PermissionFailure(
    message: 'Seul un organisateur peut créer un événement.',
  );
}
