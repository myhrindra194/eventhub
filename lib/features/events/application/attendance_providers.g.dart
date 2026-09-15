// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventAttendanceDataSource)
final eventAttendanceDataSourceProvider = EventAttendanceDataSourceProvider._();

final class EventAttendanceDataSourceProvider
    extends
        $FunctionalProvider<
          EventAttendanceRemoteDataSource,
          EventAttendanceRemoteDataSource,
          EventAttendanceRemoteDataSource
        >
    with $Provider<EventAttendanceRemoteDataSource> {
  EventAttendanceDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventAttendanceDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventAttendanceDataSourceHash();

  @$internal
  @override
  $ProviderElement<EventAttendanceRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventAttendanceRemoteDataSource create(Ref ref) {
    return eventAttendanceDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventAttendanceRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventAttendanceRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$eventAttendanceDataSourceHash() =>
    r'96f36e8ae97c5af85d621f3825e9696a77252507';

/// Recent attendees' short names for the "who's going" strip (F-07).
///
/// `event_attendance` is a function, not a table, so there is nothing to
/// subscribe to: the names are fetched again whenever the live seat counter
/// of the event moves, which is exactly when they can have changed.

@ProviderFor(eventRecentAttendees)
final eventRecentAttendeesProvider = EventRecentAttendeesFamily._();

/// Recent attendees' short names for the "who's going" strip (F-07).
///
/// `event_attendance` is a function, not a table, so there is nothing to
/// subscribe to: the names are fetched again whenever the live seat counter
/// of the event moves, which is exactly when they can have changed.

final class EventRecentAttendeesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Recent attendees' short names for the "who's going" strip (F-07).
  ///
  /// `event_attendance` is a function, not a table, so there is nothing to
  /// subscribe to: the names are fetched again whenever the live seat counter
  /// of the event moves, which is exactly when they can have changed.
  EventRecentAttendeesProvider._({
    required EventRecentAttendeesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventRecentAttendeesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventRecentAttendeesHash();

  @override
  String toString() {
    return r'eventRecentAttendeesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return eventRecentAttendees(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventRecentAttendeesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventRecentAttendeesHash() =>
    r'3ab8957799c923ed3742a830ef7f2f8597b65a57';

/// Recent attendees' short names for the "who's going" strip (F-07).
///
/// `event_attendance` is a function, not a table, so there is nothing to
/// subscribe to: the names are fetched again whenever the live seat counter
/// of the event moves, which is exactly when they can have changed.

final class EventRecentAttendeesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  EventRecentAttendeesFamily._()
    : super(
        retry: null,
        name: r'eventRecentAttendeesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recent attendees' short names for the "who's going" strip (F-07).
  ///
  /// `event_attendance` is a function, not a table, so there is nothing to
  /// subscribe to: the names are fetched again whenever the live seat counter
  /// of the event moves, which is exactly when they can have changed.

  EventRecentAttendeesProvider call(String eventId) =>
      EventRecentAttendeesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventRecentAttendeesProvider';
}
