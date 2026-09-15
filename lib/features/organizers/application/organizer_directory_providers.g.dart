// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organizer_directory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(organizerDirectoryRepository)
final organizerDirectoryRepositoryProvider =
    OrganizerDirectoryRepositoryProvider._();

final class OrganizerDirectoryRepositoryProvider
    extends
        $FunctionalProvider<
          OrganizerDirectoryRepository,
          OrganizerDirectoryRepository,
          OrganizerDirectoryRepository
        >
    with $Provider<OrganizerDirectoryRepository> {
  OrganizerDirectoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerDirectoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerDirectoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrganizerDirectoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OrganizerDirectoryRepository create(Ref ref) {
    return organizerDirectoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrganizerDirectoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrganizerDirectoryRepository>(value),
    );
  }
}

String _$organizerDirectoryRepositoryHash() =>
    r'f44d2745d8c884184924c2b870b4446808ef94d5';

@ProviderFor(organizerProfile)
final organizerProfileProvider = OrganizerProfileFamily._();

final class OrganizerProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizerProfile?>,
          OrganizerProfile?,
          Stream<OrganizerProfile?>
        >
    with
        $FutureModifier<OrganizerProfile?>,
        $StreamProvider<OrganizerProfile?> {
  OrganizerProfileProvider._({
    required OrganizerProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'organizerProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$organizerProfileHash();

  @override
  String toString() {
    return r'organizerProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrganizerProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrganizerProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return organizerProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrganizerProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$organizerProfileHash() => r'17fd90af101690fcbb1c69746ed253e3a1e67959';

final class OrganizerProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrganizerProfile?>, String> {
  OrganizerProfileFamily._()
    : super(
        retry: null,
        name: r'organizerProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrganizerProfileProvider call(String organizerId) =>
      OrganizerProfileProvider._(argument: organizerId, from: this);

  @override
  String toString() => r'organizerProfileProvider';
}

/// Organizers the signed-in user follows (either role may follow).

@ProviderFor(followingIds)
final followingIdsProvider = FollowingIdsProvider._();

/// Organizers the signed-in user follows (either role may follow).

final class FollowingIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  /// Organizers the signed-in user follows (either role may follow).
  FollowingIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followingIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followingIdsHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return followingIds(ref);
  }
}

String _$followingIdsHash() => r'8eb57171284f03bb5f0a19da3252a8d92ee9d4fe';

@ProviderFor(isFollowing)
final isFollowingProvider = IsFollowingFamily._();

final class IsFollowingProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsFollowingProvider._({
    required IsFollowingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFollowingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFollowingHash();

  @override
  String toString() {
    return r'isFollowingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFollowing(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFollowingHash() => r'9b127f91ca717e7559b9f04e563505386a98653a';

final class IsFollowingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFollowingFamily._()
    : super(
        retry: null,
        name: r'isFollowingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsFollowingProvider call(String organizerId) =>
      IsFollowingProvider._(argument: organizerId, from: this);

  @override
  String toString() => r'isFollowingProvider';
}

@ProviderFor(FollowController)
final followControllerProvider = FollowControllerProvider._();

final class FollowControllerProvider
    extends $AsyncNotifierProvider<FollowController, void> {
  FollowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followControllerHash();

  @$internal
  @override
  FollowController create() => FollowController();
}

String _$followControllerHash() => r'5b162017365dda815fc02250878e50df23dcb41c';

abstract class _$FollowController extends $AsyncNotifier<void> {
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
