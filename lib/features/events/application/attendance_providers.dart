import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/features/events/data/datasources/event_attendance_remote_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
EventAttendanceRemoteDataSource eventAttendanceDataSource(Ref ref) =>
    EventAttendanceRemoteDataSource(ref.watch(firestoreProvider));

/// Recent attendees' short names for the "who's going" strip (F-07), live:
/// a booking adds its entry to `events/{id}/attendees` in the same batch as
/// the seat, so the names move with the counter.
@riverpod
Stream<List<String>> eventRecentAttendees(Ref ref, String eventId) =>
    ref.watch(eventAttendanceDataSourceProvider).watchRecentNames(eventId);
