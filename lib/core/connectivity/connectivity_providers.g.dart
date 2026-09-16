// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Indique si l’appareil a une interface réseau active.
///
/// « Active » ne veut pas dire « Firebase joignable » (un portail captif se
/// déclare en ligne) : c’est pourquoi ce provider ne pilote qu’un bandeau
/// informatif. Firestore, lui, continue de fonctionner depuis son cache et
/// rejoue les écritures au retour du lien.

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Indique si l’appareil a une interface réseau active.
///
/// « Active » ne veut pas dire « Firebase joignable » (un portail captif se
/// déclare en ligne) : c’est pourquoi ce provider ne pilote qu’un bandeau
/// informatif. Firestore, lui, continue de fonctionner depuis son cache et
/// rejoue les écritures au retour du lien.

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Indique si l’appareil a une interface réseau active.
  ///
  /// « Active » ne veut pas dire « Firebase joignable » (un portail captif se
  /// déclare en ligne) : c’est pourquoi ce provider ne pilote qu’un bandeau
  /// informatif. Firestore, lui, continue de fonctionner depuis son cache et
  /// rejoue les écritures au retour du lien.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isOnline(ref);
  }
}

String _$isOnlineHash() => r'bd3c8e36471681c69e5b784871f69b4d78dad7b5';
