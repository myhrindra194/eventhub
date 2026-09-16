import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/features/events/data/datasources/event_attendance_remote_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
EventAttendanceRemoteDataSource eventAttendanceDataSource(Ref ref) =>
    EventAttendanceRemoteDataSource(ref.watch(firestoreProvider));

/// Noms courts des participants récents pour le bandeau « qui y va »
/// (F-07), en temps réel : une réservation ajoute son entrée dans
/// `events/{id}/attendees` dans le même batch que la place, si bien que les
/// noms bougent avec le compteur.
@riverpod
Stream<List<String>> eventRecentAttendees(Ref ref, String eventId) =>
    ref.watch(eventAttendanceDataSourceProvider).watchRecentNames(eventId);
