// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the device has a network interface up.
///
/// "Up" is not "Firebase reachable" (a captive portal says online), which is
/// why this only drives an informational banner: Firestore itself keeps
/// working from its cache and replays writes when the link comes back.

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Whether the device has a network interface up.
///
/// "Up" is not "Firebase reachable" (a captive portal says online), which is
/// why this only drives an informational banner: Firestore itself keeps
/// working from its cache and replays writes when the link comes back.

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the device has a network interface up.
  ///
  /// "Up" is not "Firebase reachable" (a captive portal says online), which is
  /// why this only drives an informational banner: Firestore itself keeps
  /// working from its cache and replays writes when the link comes back.
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
