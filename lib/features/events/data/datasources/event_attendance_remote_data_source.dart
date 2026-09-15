import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// `events/{eventId}/attendees`: the short names of the latest people who
/// booked, for the "who's going" strip (F-07).
///
/// Reservations are private to their owner and the event team, so the names
/// are never read from them. The reservation flow writes one entry per
/// attendee instead, keyed by `sha256(uid)` and holding only "Prénom I." —
/// no uid, no email ever reaches another participant.
class EventAttendanceRemoteDataSource {
  const EventAttendanceRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// The strip shows a few faces and names two people: five is enough, and
  /// every document of a listener is a billed read.
  static const recentLimit = 5;

  /// Short names of the latest people who booked, most recent first, live.
  Stream<List<String>> watchRecentNames(String eventId) => _db
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.attendees)
      .orderBy('createdAt', descending: true)
      .limit(recentLimit)
      .snapshots()
      .map((s) => namesFrom([for (final doc in s.docs) doc.data()]))
      .resilient('events.attendees');

  /// Tolerant parser: an entry without a usable name is skipped, never
  /// thrown on.
  static List<String> namesFrom(Iterable<Map<String, dynamic>> docs) => [
    for (final doc in docs)
      if (doc['name'] case final String name when name.trim().isNotEmpty)
        name.trim(),
  ];
}
