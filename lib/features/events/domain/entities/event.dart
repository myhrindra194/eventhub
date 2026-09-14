import 'dart:math' as math;

import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';

/// Published event.
///
/// The spec lists `date` and `time` separately; they are stored as a single
/// [startsAt] instant so that ordering, "upcoming" queries and the
/// "already started" rule are exact. [date] / [time] remain as views.
@freezed
abstract class Event with _$Event {
  const Event._();

  const factory Event({
    required String id,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startsAt,
    required String location,
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// Co-organizers (F-16): organizers who accepted an invitation. They
    /// manage the content, the guest list and the door; only the owner
    /// ([organizerId]) composes the team and may delete the event.
    @Default(<String>[]) List<String> staffIds,

    /// Ticket types (F-12), in display order. Empty for a simple event with
    /// one free pool of [capacity] seats.
    @Default(<EventTier>[]) List<EventTier> tiers,

    /// ISO code of the paid types' prices (`EUR`, `USD`, `MGA`).
    String? currency,
  }) = _Event;

  DateTime get date => DateTime(startsAt.year, startsAt.month, startsAt.day);
  TimeOfDayValue get time =>
      TimeOfDayValue(hour: startsAt.hour, minute: startsAt.minute);

  int get reservedCount => capacity - availablePlaces;
  bool get isFull => availablePlaces <= 0;
  double get fillRate => capacity == 0 ? 0 : reservedCount / capacity;

  bool hasStarted(DateTime now) => !startsAt.isAfter(now);
  bool isOwnedBy(String userId) => organizerId == userId;
  bool isStaff(String userId) => staffIds.contains(userId);

  /// Owner or co-organizer.
  bool isManagedBy(String userId) => isOwnedBy(userId) || isStaff(userId);

  bool get hasTiers => tiers.isNotEmpty;

  /// Free to attend: no ticket type, or only free ones.
  bool get isFree => tiers.every((t) => t.isFree);

  /// Cheapest paid ticket, `null` when nothing is paid.
  int? get minPrice {
    final paid = tiers.where((t) => !t.isFree).map((t) => t.price);
    return paid.isEmpty ? null : paid.reduce(math.min);
  }

  bool get hasFreeTier => !hasTiers || tiers.any((t) => t.isFree);

  String get currencyCode => currency ?? 'EUR';

  EventTier? tier(String id) {
    for (final t in tiers) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Flutter-free time-of-day value so the domain stays framework-agnostic.
@freezed
abstract class TimeOfDayValue with _$TimeOfDayValue {
  const factory TimeOfDayValue({required int hour, required int minute}) =
      _TimeOfDayValue;
}
