import 'package:eventhub/features/events/domain/entities/event_category.dart';
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
  }) = _Event;

  DateTime get date => DateTime(startsAt.year, startsAt.month, startsAt.day);
  TimeOfDayValue get time =>
      TimeOfDayValue(hour: startsAt.hour, minute: startsAt.minute);

  int get reservedCount => capacity - availablePlaces;
  bool get isFull => availablePlaces <= 0;
  double get fillRate => capacity == 0 ? 0 : reservedCount / capacity;

  bool hasStarted(DateTime now) => !startsAt.isAfter(now);
  bool isOwnedBy(String userId) => organizerId == userId;
}

/// Flutter-free time-of-day value so the domain stays framework-agnostic.
@freezed
abstract class TimeOfDayValue with _$TimeOfDayValue {
  const factory TimeOfDayValue({required int hour, required int minute}) =
      _TimeOfDayValue;
}
