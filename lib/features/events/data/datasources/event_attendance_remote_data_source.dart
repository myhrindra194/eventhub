import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// Reads `aggregates/event_{eventId}` — written by the `aggregateAttendance`
/// Cloud Function, read-only for clients.
class EventAttendanceRemoteDataSource {
  EventAttendanceRemoteDataSource(FirebaseFirestore firestore)
    : _aggregates = firestore.collection(FirestorePaths.aggregates);

  final CollectionReference<Map<String, dynamic>> _aggregates;

  /// Short names of the latest people who booked, most recent first.
  Stream<List<String>> watchRecentNames(String eventId) => _aggregates
      .doc(FirestorePaths.eventAggregateDoc(eventId))
      .snapshots()
      .map((s) => namesFrom(s.data()));

  /// Tolerant parser: a malformed entry is skipped, never thrown on.
  static List<String> namesFrom(Map<String, dynamic>? data) {
    final raw = data?['recentAttendees'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map && entry['name'] is String)
          if ((entry['name'] as String).trim().isNotEmpty)
            entry['name'] as String,
    ];
  }
}
