// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoritesRepository)
final favoritesRepositoryProvider = FavoritesRepositoryProvider._();

final class FavoritesRepositoryProvider
    extends
        $FunctionalProvider<
          FavoritesRepository,
          FavoritesRepository,
          FavoritesRepository
        >
    with $Provider<FavoritesRepository> {
  FavoritesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoritesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoritesRepository create(Ref ref) {
    return favoritesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesRepository>(value),
    );
  }
}

String _$favoritesRepositoryHash() =>
    r'408a4dc6fed9fb82a856b8aace2d6e7344ff6295';

@ProviderFor(favoriteIds)
final favoriteIdsProvider = FavoriteIdsProvider._();

final class FavoriteIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  FavoriteIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteIdsHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return favoriteIds(ref);
  }
}

String _$favoriteIdsHash() => r'7a89b3fd4c20654077c6b3483287c66514ae184c';

/// Toggles sent but not yet echoed by Realtime: event id → starred.
///
/// Unlike Firestore, Supabase has no local write cache, so the stream only
/// reflects a toggle after the round trip. Overlaying the intent keeps the
/// heart flipping at the tap; an entry is dropped once the stream agrees, or
/// when the write fails.

@ProviderFor(PendingFavorites)
final pendingFavoritesProvider = PendingFavoritesProvider._();

/// Toggles sent but not yet echoed by Realtime: event id → starred.
///
/// Unlike Firestore, Supabase has no local write cache, so the stream only
/// reflects a toggle after the round trip. Overlaying the intent keeps the
/// heart flipping at the tap; an entry is dropped once the stream agrees, or
/// when the write fails.
final class PendingFavoritesProvider
    extends $NotifierProvider<PendingFavorites, Map<String, bool>> {
  /// Toggles sent but not yet echoed by Realtime: event id → starred.
  ///
  /// Unlike Firestore, Supabase has no local write cache, so the stream only
  /// reflects a toggle after the round trip. Overlaying the intent keeps the
  /// heart flipping at the tap; an entry is dropped once the stream agrees, or
  /// when the write fails.
  PendingFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingFavoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingFavoritesHash();

  @$internal
  @override
  PendingFavorites create() => PendingFavorites();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$pendingFavoritesHash() => r'55040799600f6c397a9281ce36f05eeb2ad6a172';

/// Toggles sent but not yet echoed by Realtime: event id → starred.
///
/// Unlike Firestore, Supabase has no local write cache, so the stream only
/// reflects a toggle after the round trip. Overlaying the intent keeps the
/// heart flipping at the tap; an entry is dropped once the stream agrees, or
/// when the write fails.

abstract class _$PendingFavorites extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(isFavorite)
final isFavoriteProvider = IsFavoriteFamily._();

final class IsFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsFavoriteProvider._({
    required IsFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteHash();

  @override
  String toString() {
    return r'isFavoriteProvider'
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
    return isFavorite(ref, argument);
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
    return other is IsFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteHash() => r'838801f665ba2daa8a97ed647cb625246bd3fd13';

final class IsFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteFamily._()
    : super(
        retry: null,
        name: r'isFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsFavoriteProvider call(String eventId) =>
      IsFavoriteProvider._(argument: eventId, from: this);

  @override
  String toString() => r'isFavoriteProvider';
}

@ProviderFor(FavoriteController)
final favoriteControllerProvider = FavoriteControllerProvider._();

final class FavoriteControllerProvider
    extends $AsyncNotifierProvider<FavoriteController, void> {
  FavoriteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteControllerHash();

  @$internal
  @override
  FavoriteController create() => FavoriteController();
}

String _$favoriteControllerHash() =>
    r'4ed12d2452d7ad4a0eba9333cbbeeb3c5bda76e9';

abstract class _$FavoriteController extends $AsyncNotifier<void> {
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
