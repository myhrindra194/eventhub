import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/data/datasources/event_attendance_remote_data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
EventAttendanceRemoteDataSource eventAttendanceDataSource(Ref ref) =>
    EventAttendanceRemoteDataSource(ref.watch(supabaseClientProvider));

/// Recent attendees' short names for the "who's going" strip (F-07).
///
/// `event_attendance` is a function, not a table, so there is nothing to
/// subscribe to: the names are fetched again whenever the live seat counter
/// of the event moves, which is exactly when they can have changed.
@riverpod
Future<List<String>> eventRecentAttendees(Ref ref, String eventId) {
  ref.watch(
    eventByIdProvider(eventId).select((event) => event.value?.reservedCount),
  );
  return ref.watch(eventAttendanceDataSourceProvider).fetchRecentNames(eventId);
}
