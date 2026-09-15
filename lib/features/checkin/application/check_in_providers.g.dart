// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkInRepository)
final checkInRepositoryProvider = CheckInRepositoryProvider._();

final class CheckInRepositoryProvider
    extends
        $FunctionalProvider<
          CheckInRepository,
          CheckInRepository,
          CheckInRepository
        >
    with $Provider<CheckInRepository> {
  CheckInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckInRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckInRepository create(Ref ref) {
    return checkInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInRepository>(value),
    );
  }
}

String _$checkInRepositoryHash() => r'b3fac1386185efaace521507b3fd1a6e92220f45';

@ProviderFor(eventCheckIns)
final eventCheckInsProvider = EventCheckInsFamily._();

final class EventCheckInsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DateTime>>,
          Map<String, DateTime>,
          Stream<Map<String, DateTime>>
        >
    with
        $FutureModifier<Map<String, DateTime>>,
        $StreamProvider<Map<String, DateTime>> {
  EventCheckInsProvider._({
    required EventCheckInsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventCheckInsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventCheckInsHash();

  @override
  String toString() {
    return r'eventCheckInsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, DateTime>> create(Ref ref) {
    final argument = this.argument as String;
    return eventCheckIns(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventCheckInsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventCheckInsHash() => r'2c8445388050ea26f7b1e6d257bd3520081c006f';

final class EventCheckInsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, DateTime>>, String> {
  EventCheckInsFamily._()
    : super(
        retry: null,
        name: r'eventCheckInsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventCheckInsProvider call(String eventId) =>
      EventCheckInsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventCheckInsProvider';
}

/// One scan at the door: the local precheck (CheckInPolicy), then the
/// transaction's verdict.

@ProviderFor(CheckInController)
final checkInControllerProvider = CheckInControllerProvider._();

/// One scan at the door: the local precheck (CheckInPolicy), then the
/// transaction's verdict.
final class CheckInControllerProvider
    extends $AsyncNotifierProvider<CheckInController, void> {
  /// One scan at the door: the local precheck (CheckInPolicy), then the
  /// transaction's verdict.
  CheckInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInControllerHash();

  @$internal
  @override
  CheckInController create() => CheckInController();
}

String _$checkInControllerHash() => r'7f4533f56cdb320f5f71b16bb9e69dd3006d8445';

/// One scan at the door: the local precheck (CheckInPolicy), then the
/// transaction's verdict.

abstract class _$CheckInController extends $AsyncNotifier<void> {
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
