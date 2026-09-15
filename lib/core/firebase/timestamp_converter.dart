import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Firestore [Timestamp] <-> [DateTime] for DTOs.
///
/// Read in local time, because every formatter in the app reads the fields
/// of the DateTime as they are. [DateTime], ISO-8601 strings and epoch millis
/// are accepted too, for fixtures and the local cache.
///
/// A field written with `FieldValue.serverTimestamp()` is `null` in the
/// pending local snapshot, until the server acknowledges the write: DTOs
/// declare such fields with [NullableTimestampConverter].
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) => switch (json) {
    Timestamp() => json.toDate(),
    DateTime() => json,
    String() => DateTime.parse(json).toLocal(),
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
