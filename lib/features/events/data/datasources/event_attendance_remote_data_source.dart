import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// `events/{eventId}/attendees` : les noms courts des dernières personnes à
/// avoir réservé, pour le bandeau « qui y va » (F-07).
///
/// Les réservations sont privées, réservées à leur auteur et à l’équipe de
/// l’événement : les noms ne sont donc jamais lus depuis celles-ci. Le
/// parcours de réservation écrit à la place une entrée par participant,
/// indexée par `sha256(uid)` et ne contenant que « Prénom I. » — aucun uid,
/// aucun e-mail n’atteint jamais un autre participant.
class EventAttendanceRemoteDataSource {
  const EventAttendanceRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Le bandeau montre quelques visages et cite deux personnes : cinq
  /// suffisent, et chaque document d’un listener est une lecture facturée.
  static const recentLimit = 5;

  /// Noms courts des dernières personnes à avoir réservé, de la plus
  /// récente à la plus ancienne, en temps réel.
  Stream<List<String>> watchRecentNames(String eventId) => _db
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.attendees)
      .orderBy('createdAt', descending: true)
      .limit(recentLimit)
      .snapshots()
      .map((s) => namesFrom([for (final doc in s.docs) doc.data()]))
      .resilient('events.attendees');

  /// Analyse tolérante : une entrée sans nom exploitable est ignorée, on ne
  /// lève jamais d’exception dessus.
  static List<String> namesFrom(Iterable<Map<String, dynamic>> docs) => [
    for (final doc in docs)
      if (doc['name'] case final String name when name.trim().isNotEmpty)
        name.trim(),
  ];
}
