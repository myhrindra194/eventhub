import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Tolerant Timestamp <-> DateTime converter for Firestore DTOs.
/// Accepts `Timestamp`, `DateTime`, ISO-8601 `String` and epoch millis so the
/// same DTOs work against Firestore, fixtures and the emulator export format.
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) => switch (json) {
    Timestamp() => json.toDate(),
    DateTime() => json,
    String() => DateTime.parse(json),
    int() => DateTime.fromMillisecondsSinceEpoch(json),
    _ => throw ArgumentError.value(json, 'json', 'Unsupported timestamp'),
  };

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}

class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) =>
      json == null ? null : const TimestampConverter().fromJson(json);

  @override
  Object? toJson(DateTime? date) =>
      date == null ? null : const TimestampConverter().toJson(date);
}
