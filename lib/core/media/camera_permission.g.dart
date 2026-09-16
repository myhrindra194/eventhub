// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_permission.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La permission caméra de l'appareil.
///
/// Exposée comme dépendance, dans le même esprit que le sélecteur d'images :
/// un test de widget la remplace pour décider lui-même de la réponse du
/// système, sans canal natif.

@ProviderFor(cameraPermission)
final cameraPermissionProvider = CameraPermissionProvider._();

/// La permission caméra de l'appareil.
///
/// Exposée comme dépendance, dans le même esprit que le sélecteur d'images :
/// un test de widget la remplace pour décider lui-même de la réponse du
/// système, sans canal natif.

final class CameraPermissionProvider
    extends
        $FunctionalProvider<
          CameraPermission,
          CameraPermission,
          CameraPermission
        >
    with $Provider<CameraPermission> {
  /// La permission caméra de l'appareil.
  ///
  /// Exposée comme dépendance, dans le même esprit que le sélecteur d'images :
  /// un test de widget la remplace pour décider lui-même de la réponse du
  /// système, sans canal natif.
  CameraPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraPermissionHash();

  @$internal
  @override
  $ProviderElement<CameraPermission> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraPermission create(Ref ref) {
    return cameraPermission(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraPermission>(value),
    );
  }
}

String _$cameraPermissionHash() => r'ce5b6982d64f3a0fec7c60252fe1cc34b0abecdc';

@ProviderFor(cameraAccessGate)
final cameraAccessGateProvider = CameraAccessGateProvider._();

final class CameraAccessGateProvider
    extends
        $FunctionalProvider<
          CameraAccessGate,
          CameraAccessGate,
          CameraAccessGate
        >
    with $Provider<CameraAccessGate> {
  CameraAccessGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraAccessGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraAccessGateHash();

  @$internal
  @override
  $ProviderElement<CameraAccessGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraAccessGate create(Ref ref) {
    return cameraAccessGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraAccessGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraAccessGate>(value),
    );
  }
}

String _$cameraAccessGateHash() => r'bc2cd47ecd2941a5033a3c2d22b7b4b5a2671394';
