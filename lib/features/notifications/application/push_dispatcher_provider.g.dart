// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_dispatcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le porte-voix FCM partagé par tous les écrivains de notifications
/// (réservations, équipe, modération).
///
/// Dans un fichier à part plutôt que dans `notification_providers.dart` :
/// ces trois features en dépendent, et les faire importer tout le centre de
/// notifications créerait des cycles d'import entre features.

@ProviderFor(pushDispatcher)
final pushDispatcherProvider = PushDispatcherProvider._();

/// Le porte-voix FCM partagé par tous les écrivains de notifications
/// (réservations, équipe, modération).
///
/// Dans un fichier à part plutôt que dans `notification_providers.dart` :
/// ces trois features en dépendent, et les faire importer tout le centre de
/// notifications créerait des cycles d'import entre features.

final class PushDispatcherProvider
    extends $FunctionalProvider<PushDispatcher, PushDispatcher, PushDispatcher>
    with $Provider<PushDispatcher> {
  /// Le porte-voix FCM partagé par tous les écrivains de notifications
  /// (réservations, équipe, modération).
  ///
  /// Dans un fichier à part plutôt que dans `notification_providers.dart` :
  /// ces trois features en dépendent, et les faire importer tout le centre de
  /// notifications créerait des cycles d'import entre features.
  PushDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushDispatcherHash();

  @$internal
  @override
  $ProviderElement<PushDispatcher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushDispatcher create(Ref ref) {
    return pushDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushDispatcher>(value),
    );
  }
}

String _$pushDispatcherHash() => r'4683e7033580ab33aa7d53fad8e2aad0c175e756';
