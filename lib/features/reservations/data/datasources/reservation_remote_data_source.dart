import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/reservations/data/dtos/reservation_dto.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.reservations`.
///
/// Clients only read the table (RLS: the participant sees their own rows,
/// the event team — owner and co-organizers — the event's rows). Booking
/// and cancelling a free seat are the `reserve_seat` and
/// `cancel_reservation` functions: they lock the event, check every rule of
/// `ReservationPolicy` again and move the seat counters in the same
/// transaction, so concurrent bookings cannot overbook.
///
/// A Realtime stream accepts a single filter: each query keeps the one that
/// narrows the rows the most on the server, and finishes in Dart.
class ReservationRemoteDataSource {
  const ReservationRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Bound on a participant's or an organizer's list.
  static const maxPageSize = 200;

  /// Bound on an event's guest list. Its rows include cancellations, which
  /// are filtered out in Dart, so the bound is wider than [maxPageSize].
  static const maxGuestList = 1000;

  Stream<List<Reservation>> watchByUser(String userId) => _client
      .from(Tables.reservations)
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('reserved_at')
      .limit(maxPageSize)
      .map(_toDomainList)
      .resilient('reservations:user');

  /// Confirmed seats of an event, most recent first. One query for the
  /// owner and the co-organizers alike: RLS proves team membership from
  /// `event_id`.
  Stream<List<Reservation>> watchActiveByEvent(String eventId) => _client
      .from(Tables.reservations)
      .stream(primaryKey: ['id'])
      .eq('event_id', eventId)
      .order('reserved_at')
      .limit(maxGuestList)
      .map(
        (rows) => _toDomainList(
          rows,
        ).where((r) => r.isActive).toList(growable: false),
      )
      .resilient('reservations:event');

  /// All statuses: cancellations are part of what an organizer monitors.
  Stream<List<Reservation>> watchByOrganizer(String organizerId) => _client
      .from(Tables.reservations)
      .stream(primaryKey: ['id'])
      .eq('organizer_id', organizerId)
      .order('reserved_at')
      .limit(maxPageSize)
      .map(_toDomainList)
      .resilient('reservations:organizer');

  /// The participant's row for an event. Filtered on `user_id` rather than
  /// `event_id`: the channel then follows the participant's own history,
  /// instead of receiving every booking of a popular event only for RLS to
  /// drop it. `distinct` hides changes to their other reservations.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => _client
      .from(Tables.reservations)
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map(
        (rows) =>
            _toDomainList(rows).where((r) => r.eventId == eventId).firstOrNull,
      )
      .distinct()
      .resilient('reservations:mine:$eventId');

  Stream<Reservation?> watchById(String reservationId) => _client
      .from(Tables.reservations)
      .stream(primaryKey: ['id'])
      .eq('id', reservationId)
      .map((rows) => rows.isEmpty ? null : _toDomain(rows.first))
      .resilient('reservation:$reservationId');

  /// A free seat. [tierId] is required by the database on an event with
  /// ticket types, refused on one without.
  Future<Reservation> reserve({required String eventId, String? tierId}) async {
    final row = await _client.rpc<dynamic>(
      Rpc.reserveSeat,
      params: {'p_event_id': eventId, 'p_tier_id': tierId},
    );
    return _toDomain(row);
  }

  /// Gives a free seat back; the cancelled row is returned.
  Future<Reservation> cancel(String reservationId) async {
    final row = await _client.rpc<dynamic>(
      Rpc.cancelReservation,
      params: {'p_reservation_id': reservationId},
    );
    return _toDomain(row);
  }

  static Reservation _toDomain(Object? row) => ReservationDto.fromJson(
    Map<String, dynamic>.from(row! as Map),
  ).toDomain();

  static List<Reservation> _toDomainList(List<Map<String, dynamic>> rows) =>
      rows.map(_toDomain).toList(growable: false);
}
