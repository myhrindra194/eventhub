import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// [Timestamp] Firestore <-> [DateTime] pour les DTO.
///
/// La lecture se fait en heure locale, parce que tous les formateurs de
/// l’app lisent les champs du DateTime tels quels. [DateTime], les chaînes
/// ISO-8601 et les millisecondes epoch sont également acceptées, pour les
/// fixtures et le cache local.
///
/// Un champ écrit avec `FieldValue.serverTimestamp()` vaut `null` dans le
/// snapshot local en attente, tant que le serveur n’a pas acquitté
/// l’écriture : les DTO déclarent ces champs avec
/// [NullableTimestampConverter].
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
