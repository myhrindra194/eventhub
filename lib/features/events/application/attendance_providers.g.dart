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
    r'e54c0fcebf5dded8181b607735f4bfb0782cfd8a';

/// Recent attendees' short names for the "who's going" strip (F-07).

@ProviderFor(eventRecentAttendees)
final eventRecentAttendeesProvider = EventRecentAttendeesFamily._();

/// Recent attendees' short names for the "who's going" strip (F-07).

final class EventRecentAttendeesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  /// Recent attendees' short names for the "who's going" strip (F-07).
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
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
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
    r'e0a5bd8975ed751e0305aa97c91ce99a50378ab7';

/// Recent attendees' short names for the "who's going" strip (F-07).

final class EventRecentAttendeesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String> {
  EventRecentAttendeesFamily._()
    : super(
        retry: null,
        name: r'eventRecentAttendeesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recent attendees' short names for the "who's going" strip (F-07).

  EventRecentAttendeesProvider call(String eventId) =>
      EventRecentAttendeesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventRecentAttendeesProvider';
}
