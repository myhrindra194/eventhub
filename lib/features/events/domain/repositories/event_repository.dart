import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';

abstract interface class EventRepository {
  /// Events starting at or after [from], ordered by start time.
  Stream<List<Event>> watchUpcoming({required DateTime from});

  /// All events of an organizer, most recent first.
  Stream<List<Event>> watchByOrganizer(String organizerId);

  /// Emits `null` when the event does not exist (or was deleted).
  Stream<Event?> watchById(String eventId);

  AsyncResult<Event> getById(String eventId);

  /// Returns the new event id.
  AsyncResult<String> create({
    required EventDraft draft,
    required AppUser organizer,
  });

  /// Enforces ownership and keeps `availablePlaces` consistent with the
  /// reservations already made when capacity changes.
  AsyncResult<void> update({
    required String eventId,
    required EventDraft draft,
    required AppUser organizer,
  });

  AsyncResult<void> delete({
    required String eventId,
    required AppUser organizer,
  });
}
