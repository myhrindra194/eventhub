import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/image_uploader.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_providers.g.dart';

/// Le sélecteur d'images de l'appareil.
///
/// Exposé comme dépendance plutôt qu'instancié dans les écrans : il ouvre la
/// galerie ou l'appareil photo par un canal de plateforme, donc un test de
/// widget doit pouvoir le remplacer pour ne rien ouvrir du tout.
@Riverpod(keepAlive: true)
DeviceImagePicker deviceImagePicker(Ref ref) => const DeviceImagePicker();

/// L'hébergement d'images, configuré par `--dart-define` (voir
/// [AppConfig.cloudinaryCloudName]).
@Riverpod(keepAlive: true)
ImageUploader imageUploader(Ref ref) {
  final config = ref.watch(appConfigProvider);
  // Un client partagé réutilise la connexion TLS d'un envoi à l'autre ; il
  // est fermé avec le conteneur, jamais par l'appelant.
  final client = http.Client();
  ref.onDispose(client.close);
  return CloudinaryImageUploader(
    client: client,
    cloudName: config.cloudinaryCloudName,
    uploadPreset: config.cloudinaryUploadPreset,
  );
}

@Riverpod(keepAlive: true)
ImageUploadFlow imageUploadFlow(Ref ref) => ImageUploadFlow(
  picker: ref.watch(deviceImagePickerProvider),
  uploader: ref.watch(imageUploaderProvider),
);

/// « Choisir puis envoyer », le geste que partagent le profil et le
/// formulaire d'événement.
///
/// Le regrouper ici garantit que les deux écrans traitent de la même façon
/// les trois issues possibles — renoncement, refus local, échec d'envoi — au
/// lieu que chacun réinvente sa gestion d'erreur autour du sélecteur.
class ImageUploadFlow {
  const ImageUploadFlow({
    required DeviceImagePicker picker,
    required ImageUploader uploader,
  }) : _picker = picker,
       _uploader = uploader;

  final DeviceImagePicker _picker;
  final ImageUploader _uploader;

  bool get isAvailable => _uploader.isConfigured;

  /// `null` quand l'utilisateur a refermé le sélecteur sans rien choisir :
  /// ce n'est pas une erreur, l'écran n'affiche rien.
  Future<Result<UploadedImage>?> run({
    required ImageKind kind,
    required PhotoSource source,
    required String ownerId,
  }) async {
    final PickedImage? picked;
    try {
      picked = await _picker.pick(kind, source);
    } on FailureException catch (error) {
      return Err(error.failure);
    }
    if (picked == null) return null;
    return _uploader.upload(picked, kind: kind, ownerId: ownerId);
  }
}
