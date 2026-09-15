import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase access for `events`, `event_tiers` and `event_staff`.
///
/// Reads go straight to the tables (RLS: the catalogue is visible to every
/// signed-in user); writes go through `save_event` / `delete_event`, which
/// re-validate the draft and own the seat counters. SDK exceptions pass
/// through for `ErrorMapper`.
class EventRemoteDataSource {
  const EventRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Every list is explicitly bounded: a Realtime subscription replays its
  /// whole result on each change, and the `in` filter used to join the
  /// related tables accepts at most 100 values.
  static const maxPageSize = 100;

  /// Embeds what a one-shot read needs to build a complete [Event].
  static const _withRelations = '*, event_tiers(*), event_staff(user_id)';

  /// First page of the catalogue, live.
  ///
  /// A Realtime stream orders by one column only, so ties on `starts_at`
  /// are broken client-side by id. The page boundary itself is therefore
  /// exact only up to events starting at the very same instant as the last
  /// one; `mergeCatalogue` deduplicates whatever [fetchUpcomingAfter]
  /// returns twice.
  Stream<List<Event>> watchUpcoming({required DateTime from}) => _withRelated(
    _client
        .from(Tables.events)
        .stream(primaryKey: ['id'])
        .gte('starts_at', _iso(from))
        .order('starts_at', ascending: true)
        .limit(maxPageSize),
    sort: _catalogueOrder,
  ).resilient('events.upcoming');

  /// The page after [after] in catalogue order (`starts_at`, then id): a
  /// keyset cursor, so two events at the same minute are neither skipped
  /// nor repeated.
  Future<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  }) async {
    final at = _iso(after.startsAt);
    // Quoted: an ISO timestamp contains `.` and `:`, reserved in a
    // PostgREST logic tree.
    final rows = await _client
        .from(Tables.events)
        .select(_withRelations)
        .gte('starts_at', _iso(from))
        .or('starts_at.gt."$at",and(starts_at.eq."$at",id.gt.${after.id})')
        .order('starts_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit.clamp(1, maxPageSize));
    return [for (final row in rows) EventDto.fromJson(row).toDomain()];
  }

  /// All events of an organizer, most recent first.
  Stream<List<Event>> watchByOrganizer(String organizerId) => _withRelated(
    _client
        .from(Tables.events)
        .stream(primaryKey: ['id'])
        .eq('organizer_id', organizerId)
        .order('starts_at')
        .limit(maxPageSize),
    sort: _mostRecentFirst,
  ).resilient('events.organizer');

  /// Events the user co-organizes (F-16), most recent first: the team rows
  /// give the ids, then the events are followed by id.
  Stream<List<Event>> watchByStaff(String userId) => _client
      .from(Tables.eventStaff)
      .stream(primaryKey: ['event_id', 'user_id'])
      .eq('user_id', userId)
      .limit(maxPageSize)
      .map(_eventIds)
      .distinct(listEquals)
      .switchMap(
        (ids) => ids.isEmpty
            ? Stream.value(const <Event>[])
            : _withRelated(
                _client
                    .from(Tables.events)
                    .stream(primaryKey: ['id'])
                    .inFilter('id', ids)
                    .order('starts_at')
                    .limit(maxPageSize),
                sort: _mostRecentFirst,
              ),
      )
      .resilient('events.staff');

  /// Emits `null` when the event does not exist or was deleted.
  Stream<Event?> watchById(String eventId) => _withRelated(
    _client.from(Tables.events).stream(primaryKey: ['id']).eq('id', eventId),
  ).map((events) => events.isEmpty ? null : events.first).resilient('event');

  Future<Event> getById(String eventId) async {
    final row = await _client
        .from(Tables.events)
        .select(_withRelations)
        .eq('id', eventId)
        .maybeSingle();
    if (row == null) {
      throw FailureException(
        NotFoundFailure(
          resource: 'events/$eventId',
          message: 'Événement introuvable.',
        ),
      );
    }
    return EventDto.fromJson(row).toDomain();
  }

  /// Creates ([eventId] null) or updates an event; returns its id. The
  /// database checks the team membership, the seats already sold per type
  /// and the currency lock in the same transaction as the write.
  Future<String> save(EventDraft draft, {String? eventId}) =>
      _client.rpc<String>(
        Rpc.saveEvent,
        params: {'p_event': EventDto.saveEventPayload(draft, eventId: eventId)},
      );

  /// Owner only, and only while no seat is taken (checked server-side). Its
  /// ticket types, team and favorites go with it (foreign-key cascade).
  Future<void> delete(String eventId) async {
    await _client.rpc<void>(Rpc.deleteEvent, params: {'p_event_id': eventId});
  }

  /// Joins a live `events` query with the live rows of its ticket types and
  /// team.
  ///
  /// Realtime cannot embed relations, so the related tables are followed
  /// with an `in` filter on the event ids. Those two subscriptions are
  /// renewed only when the *set* of ids changes — not on every seat booked —
  /// and a list is emitted only once the related rows cover every event, so
  /// a paid event never flashes as free while its types load.
  Stream<List<Event>> _withRelated(
    Stream<List<Map<String, dynamic>>> eventRows, {
    int Function(Event, Event)? sort,
  }) {
    final events = eventRows
        .map((rows) => [for (final row in rows) EventDto.fromJson(row)])
        .shareReplay(maxSize: 1);

    final related = events
        .map((dtos) => [for (final dto in dtos) dto.id]..sort())
        .distinct(listEquals)
        .switchMap(_relatedRows);

    return Rx.combineLatest2(events, related, (
      List<EventDto> dtos,
      _Related rel,
    ) {
      if (!dtos.every((dto) => rel.eventIds.contains(dto.id))) return null;
      final list = [
        for (final dto in dtos)
          dto.toDomain(
            tiers: rel.tiers[dto.id] ?? const [],
            staffIds: rel.staff[dto.id] ?? const [],
          ),
      ];
      if (sort != null) list.sort(sort);
      return List<Event>.unmodifiable(list);
    }).whereType<List<Event>>();
  }

  Stream<_Related> _relatedRows(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const _Related.empty());
    final tiers = _client
        .from(Tables.eventTiers)
        .stream(primaryKey: ['id'])
        .inFilter('event_id', ids);
    final staff = _client
        .from(Tables.eventStaff)
        .stream(primaryKey: ['event_id', 'user_id'])
        .inFilter('event_id', ids);
    return Rx.combineLatest2(tiers, staff, (
      List<Map<String, dynamic>> tierRows,
      List<Map<String, dynamic>> staffRows,
    ) {
      final byEvent = <String, List<EventTierDto>>{};
      for (final row in tierRows) {
        final tier = EventTierDto.fromJson(row);
        (byEvent[tier.eventId] ??= []).add(tier);
      }
      final team = <String, List<String>>{};
      for (final row in staffRows) {
        (team[row['event_id'] as String] ??= []).add(row['user_id'] as String);
      }
      return _Related(eventIds: ids.toSet(), tiers: byEvent, staff: team);
    });
  }

  static List<String> _eventIds(List<Map<String, dynamic>> rows) =>
      [for (final row in rows) row['event_id'] as String]..sort();

  static String _iso(DateTime date) =>
      const TimestampConverter().toJson(date) as String;

  static int _catalogueOrder(Event a, Event b) {
    final byDate = a.startsAt.compareTo(b.startsAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  static int _mostRecentFirst(Event a, Event b) => _catalogueOrder(b, a);
}

/// Ticket types and team members of a set of events, keyed by event id.
class _Related {
  const _Related({
    required this.eventIds,
    required this.tiers,
    required this.staff,
  });

  const _Related.empty()
    : eventIds = const {},
      tiers = const {},
      staff = const {};

  /// The events these rows were fetched for: an event outside this set has
  /// not loaded its relations yet.
  final Set<String> eventIds;
  final Map<String, List<EventTierDto>> tiers;
  final Map<String, List<String>> staff;
}
