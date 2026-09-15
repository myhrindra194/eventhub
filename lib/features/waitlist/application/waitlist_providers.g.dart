// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(waitlistRepository)
final waitlistRepositoryProvider = WaitlistRepositoryProvider._();

final class WaitlistRepositoryProvider
    extends
        $FunctionalProvider<
          WaitlistRepository,
          WaitlistRepository,
          WaitlistRepository
        >
    with $Provider<WaitlistRepository> {
  WaitlistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waitlistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waitlistRepositoryHash();

  @$internal
  @override
  $ProviderElement<WaitlistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WaitlistRepository create(Ref ref) {
    return waitlistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaitlistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaitlistRepository>(value),
    );
  }
}

String _$waitlistRepositoryHash() =>
    r'c8f6cd235b0468da832c168abae3fa4515aaf3fe';

/// Any signed-in account may wait (one account, two spaces); the event's
/// team is excluded by `WaitlistPolicy`, not here.

@ProviderFor(isOnWaitlist)
final isOnWaitlistProvider = IsOnWaitlistFamily._();

/// Any signed-in account may wait (one account, two spaces); the event's
/// team is excluded by `WaitlistPolicy`, not here.

final class IsOnWaitlistProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Any signed-in account may wait (one account, two spaces); the event's
  /// team is excluded by `WaitlistPolicy`, not here.
  IsOnWaitlistProvider._({
    required IsOnWaitlistFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isOnWaitlistProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isOnWaitlistHash();

  @override
  String toString() {
    return r'isOnWaitlistProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isOnWaitlist(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsOnWaitlistProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isOnWaitlistHash() => r'10512c5dd69f6ff386e71cd6b4967ea93a610f45';

/// Any signed-in account may wait (one account, two spaces); the event's
/// team is excluded by `WaitlistPolicy`, not here.

final class IsOnWaitlistFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  IsOnWaitlistFamily._()
    : super(
        retry: null,
        name: r'isOnWaitlistProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Any signed-in account may wait (one account, two spaces); the event's
  /// team is excluded by `WaitlistPolicy`, not here.

  IsOnWaitlistProvider call(String eventId) =>
      IsOnWaitlistProvider._(argument: eventId, from: this);

  @override
  String toString() => r'isOnWaitlistProvider';
}

/// Organizer view, capped at [WaitlistRepository.queueLengthCap].

@ProviderFor(waitlistLength)
final waitlistLengthProvider = WaitlistLengthFamily._();

/// Organizer view, capped at [WaitlistRepository.queueLengthCap].

final class WaitlistLengthProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Organizer view, capped at [WaitlistRepository.queueLengthCap].
  WaitlistLengthProvider._({
    required WaitlistLengthFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'waitlistLengthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$waitlistLengthHash();

  @override
  String toString() {
    return r'waitlistLengthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return waitlistLength(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WaitlistLengthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$waitlistLengthHash() => r'b2a37c8b69e15a3ae967aef319f5d72568a3dcc7';

/// Organizer view, capped at [WaitlistRepository.queueLengthCap].

final class WaitlistLengthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  WaitlistLengthFamily._()
    : super(
        retry: null,
        name: r'waitlistLengthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Organizer view, capped at [WaitlistRepository.queueLengthCap].

  WaitlistLengthProvider call(String eventId) =>
      WaitlistLengthProvider._(argument: eventId, from: this);

  @override
  String toString() => r'waitlistLengthProvider';
}

@ProviderFor(WaitlistController)
final waitlistControllerProvider = WaitlistControllerProvider._();

final class WaitlistControllerProvider
    extends $AsyncNotifierProvider<WaitlistController, void> {
  WaitlistControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waitlistControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waitlistControllerHash();

  @$internal
  @override
  WaitlistController create() => WaitlistController();
}

String _$waitlistControllerHash() =>
    r'dad2f8773d503b3cd6d752927ed391f330fc939d';

abstract class _$WaitlistController extends $AsyncNotifier<void> {
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
