// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le sélecteur d'images de l'appareil.
///
/// Exposé comme dépendance plutôt qu'instancié dans les écrans : il ouvre la
/// galerie ou l'appareil photo par un canal de plateforme, donc un test de
/// widget doit pouvoir le remplacer pour ne rien ouvrir du tout.

@ProviderFor(deviceImagePicker)
final deviceImagePickerProvider = DeviceImagePickerProvider._();

/// Le sélecteur d'images de l'appareil.
///
/// Exposé comme dépendance plutôt qu'instancié dans les écrans : il ouvre la
/// galerie ou l'appareil photo par un canal de plateforme, donc un test de
/// widget doit pouvoir le remplacer pour ne rien ouvrir du tout.

final class DeviceImagePickerProvider
    extends
        $FunctionalProvider<
          DeviceImagePicker,
          DeviceImagePicker,
          DeviceImagePicker
        >
    with $Provider<DeviceImagePicker> {
  /// Le sélecteur d'images de l'appareil.
  ///
  /// Exposé comme dépendance plutôt qu'instancié dans les écrans : il ouvre la
  /// galerie ou l'appareil photo par un canal de plateforme, donc un test de
  /// widget doit pouvoir le remplacer pour ne rien ouvrir du tout.
  DeviceImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceImagePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceImagePickerHash();

  @$internal
  @override
  $ProviderElement<DeviceImagePicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceImagePicker create(Ref ref) {
    return deviceImagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceImagePicker>(value),
    );
  }
}

String _$deviceImagePickerHash() => r'a0f70e5525731a8295307f565cef1d3ea12c656f';

/// L'hébergement d'images, configuré par `--dart-define` (voir
/// [AppConfig.cloudinaryCloudName]).

@ProviderFor(imageUploader)
final imageUploaderProvider = ImageUploaderProvider._();

/// L'hébergement d'images, configuré par `--dart-define` (voir
/// [AppConfig.cloudinaryCloudName]).

final class ImageUploaderProvider
    extends $FunctionalProvider<ImageUploader, ImageUploader, ImageUploader>
    with $Provider<ImageUploader> {
  /// L'hébergement d'images, configuré par `--dart-define` (voir
  /// [AppConfig.cloudinaryCloudName]).
  ImageUploaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageUploaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageUploaderHash();

  @$internal
  @override
  $ProviderElement<ImageUploader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageUploader create(Ref ref) {
    return imageUploader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageUploader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageUploader>(value),
    );
  }
}

String _$imageUploaderHash() => r'5bcad7325c6be91788f3b4d35133bb47148d2abc';

@ProviderFor(imageUploadFlow)
final imageUploadFlowProvider = ImageUploadFlowProvider._();

final class ImageUploadFlowProvider
    extends
        $FunctionalProvider<ImageUploadFlow, ImageUploadFlow, ImageUploadFlow>
    with $Provider<ImageUploadFlow> {
  ImageUploadFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageUploadFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageUploadFlowHash();

  @$internal
  @override
  $ProviderElement<ImageUploadFlow> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageUploadFlow create(Ref ref) {
    return imageUploadFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageUploadFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageUploadFlow>(value),
    );
  }
}

String _$imageUploadFlowHash() => r'05cb0533d183b69eec0d63d6e3427479e9453158';
