// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mockStore)
final mockStoreProvider = MockStoreProvider._();

final class MockStoreProvider
    extends $FunctionalProvider<MockStore, MockStore, MockStore>
    with $Provider<MockStore> {
  MockStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mockStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mockStoreHash();

  @$internal
  @override
  $ProviderElement<MockStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MockStore create(Ref ref) {
    return mockStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MockStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MockStore>(value),
    );
  }
}

String _$mockStoreHash() => r'179592b49363940df7f25e88e5f4bd3a896aaaae';
