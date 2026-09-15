import 'package:json_annotation/json_annotation.dart';

/// `timestamptz` <-> [DateTime] for Supabase DTOs.
///
/// PostgREST and Realtime send ISO-8601 strings with an offset; they are
/// returned in local time, because every formatter in the app reads the
/// fields of the DateTime as they are. Epoch millis and DateTime values are
/// accepted too, for fixtures. Written back as UTC ISO-8601.
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) => switch (json) {
    DateTime() => json,
    String() => DateTime.parse(json).toLocal(),
    int() => DateTime.fromMillisecondsSinceEpoch(json),
    _ => throw ArgumentError.value(json, 'json', 'Unsupported timestamp'),
  };

  @override
  Object toJson(DateTime date) => date.toUtc().toIso8601String();
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
