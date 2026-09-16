// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase constitue tout le backend sur le plan Spark : Authentication
/// pour les comptes, Cloud Firestore pour les données (protégé par
/// `firebase/firestore.rules`), FCM pour les tokens push, Crashlytics et
/// Analytics. Les data sources reçoivent les objets du SDK via ces providers
/// et ne touchent jamais aux singletons eux-mêmes, ce qui permet aux tests
/// de les surcharger.

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

/// Firebase constitue tout le backend sur le plan Spark : Authentication
/// pour les comptes, Cloud Firestore pour les données (protégé par
/// `firebase/firestore.rules`), FCM pour les tokens push, Crashlytics et
/// Analytics. Les data sources reçoivent les objets du SDK via ces providers
/// et ne touchent jamais aux singletons eux-mêmes, ce qui permet aux tests
/// de les surcharger.

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  /// Firebase constitue tout le backend sur le plan Spark : Authentication
  /// pour les comptes, Cloud Firestore pour les données (protégé par
  /// `firebase/firestore.rules`), FCM pour les tokens push, Crashlytics et
  /// Analytics. Les data sources reçoivent les objets du SDK via ces providers
  /// et ne touchent jamais aux singletons eux-mêmes, ce qui permet aux tests
  /// de les surcharger.
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8c3e9d11b27110ca96130356b5ef4d5d34a5ffc2';

@ProviderFor(firestore)
final firestoreProvider = FirestoreProvider._();

final class FirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  FirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'864285def6284159b44f9598dcde96347e0c1dce';

@ProviderFor(firebaseMessaging)
final firebaseMessagingProvider = FirebaseMessagingProvider._();

final class FirebaseMessagingProvider
    extends
        $FunctionalProvider<
          FirebaseMessaging,
          FirebaseMessaging,
          FirebaseMessaging
        >
    with $Provider<FirebaseMessaging> {
  FirebaseMessagingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseMessagingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseMessagingHash();

  @$internal
  @override
  $ProviderElement<FirebaseMessaging> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseMessaging create(Ref ref) {
    return firebaseMessaging(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseMessaging value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseMessaging>(value),
    );
  }
}

String _$firebaseMessagingHash() => r'6765ce963b9b8c50186b5132356d60eb68265741';
