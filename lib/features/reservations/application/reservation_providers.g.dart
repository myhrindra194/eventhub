// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reservationRepository)
final reservationRepositoryProvider = ReservationRepositoryProvider._();

final class ReservationRepositoryProvider
    extends
        $FunctionalProvider<
          ReservationRepository,
          ReservationRepository,
          ReservationRepository
        >
    with $Provider<ReservationRepository> {
  ReservationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reservationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reservationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReservationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReservationRepository create(Ref ref) {
    return reservationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReservationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReservationRepository>(value),
    );
  }
}

String _$reservationRepositoryHash() =>
    r'9a648e0ac1a7791d7eef0457ef552fc0940c0fd7';

/// Reservations of the signed-in participant.

@ProviderFor(myReservations)
final myReservationsProvider = MyReservationsProvider._();

/// Reservations of the signed-in participant.

final class MyReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reservation>>,
          List<Reservation>,
          Stream<List<Reservation>>
        >
    with
        $FutureModifier<List<Reservation>>,
        $StreamProvider<List<Reservation>> {
  /// Reservations of the signed-in participant.
  MyReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReservationsHash();

  @$internal
  @override
  $StreamProviderElement<List<Reservation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Reservation>> create(Ref ref) {
    return myReservations(ref);
  }
}

String _$myReservationsHash() => r'ad48f3a1737e846624f7a3f20c6c24012a35465a';

/// The signed-in participant's reservation for [eventId], if any.

@ProviderFor(myReservationForEvent)
final myReservationForEventProvider = MyReservationForEventFamily._();

/// The signed-in participant's reservation for [eventId], if any.

final class MyReservationForEventProvider
    extends
        $FunctionalProvider<
          AsyncValue<Reservation?>,
          Reservation?,
          Stream<Reservation?>
        >
    with $FutureModifier<Reservation?>, $StreamProvider<Reservation?> {
  /// The signed-in participant's reservation for [eventId], if any.
  MyReservationForEventProvider._({
    required MyReservationForEventFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myReservationForEventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myReservationForEventHash();

  @override
  String toString() {
    return r'myReservationForEventProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Reservation?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Reservation?> create(Ref ref) {
    final argument = this.argument as String;
    return myReservationForEvent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyReservationForEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myReservationForEventHash() =>
    r'825632ce46f4eaac551c1000b2c5915adf7c5067';

/// The signed-in participant's reservation for [eventId], if any.

final class MyReservationForEventFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Reservation?>, String> {
  MyReservationForEventFamily._()
    : super(
        retry: null,
        name: r'myReservationForEventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The signed-in participant's reservation for [eventId], if any.

  MyReservationForEventProvider call(String eventId) =>
      MyReservationForEventProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myReservationForEventProvider';
}

/// Confirmed reservations of an event the signed-in organizer owns or
/// co-organizes. RLS returns nothing to anyone outside the team.

@ProviderFor(eventParticipants)
final eventParticipantsProvider = EventParticipantsFamily._();

/// Confirmed reservations of an event the signed-in organizer owns or
/// co-organizes. RLS returns nothing to anyone outside the team.

final class EventParticipantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reservation>>,
          List<Reservation>,
          Stream<List<Reservation>>
        >
    with
        $FutureModifier<List<Reservation>>,
        $StreamProvider<List<Reservation>> {
  /// Confirmed reservations of an event the signed-in organizer owns or
  /// co-organizes. RLS returns nothing to anyone outside the team.
  EventParticipantsProvider._({
    required EventParticipantsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventParticipantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventParticipantsHash();

  @override
  String toString() {
    return r'eventParticipantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Reservation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Reservation>> create(Ref ref) {
    final argument = this.argument as String;
    return eventParticipants(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventParticipantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventParticipantsHash() => r'0d88dbb0c12b7f191b30c1319bf47101dd40efa7';

/// Confirmed reservations of an event the signed-in organizer owns or
/// co-organizes. RLS returns nothing to anyone outside the team.

final class EventParticipantsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Reservation>>, String> {
  EventParticipantsFamily._()
    : super(
        retry: null,
        name: r'eventParticipantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Confirmed reservations of an event the signed-in organizer owns or
  /// co-organizes. RLS returns nothing to anyone outside the team.

  EventParticipantsProvider call(String eventId) =>
      EventParticipantsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventParticipantsProvider';
}

@ProviderFor(reservationById)
final reservationByIdProvider = ReservationByIdFamily._();

final class ReservationByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Reservation?>,
          Reservation?,
          Stream<Reservation?>
        >
    with $FutureModifier<Reservation?>, $StreamProvider<Reservation?> {
  ReservationByIdProvider._({
    required ReservationByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reservationByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reservationByIdHash();

  @override
  String toString() {
    return r'reservationByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Reservation?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Reservation?> create(Ref ref) {
    final argument = this.argument as String;
    return reservationById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReservationByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reservationByIdHash() => r'689e87dccc7bc7ad4288c0c62a5002af63cd42c6';

final class ReservationByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Reservation?>, String> {
  ReservationByIdFamily._()
    : super(
        retry: null,
        name: r'reservationByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReservationByIdProvider call(String reservationId) =>
      ReservationByIdProvider._(argument: reservationId, from: this);

  @override
  String toString() => r'reservationByIdProvider';
}

@ProviderFor(ReservationController)
final reservationControllerProvider = ReservationControllerProvider._();

final class ReservationControllerProvider
    extends $AsyncNotifierProvider<ReservationController, void> {
  ReservationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reservationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reservationControllerHash();

  @$internal
  @override
  ReservationController create() => ReservationController();
}

String _$reservationControllerHash() =>
    r'5044007542727c8ce01699f3baddf2301e6a4f22';

abstract class _$ReservationController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
