import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:image_picker/image_picker.dart';

/// D'où vient l'image choisie.
enum PhotoSource { gallery, camera }

/// Choisit une image sur l'appareil et la rend prête à être stockée.
///
/// Le redimensionnement et la recompression sont demandés au sélecteur
/// lui-même : sur Android et iOS il ré-encode en JPEG à la taille voulue, ce
/// qui fait passer une photo de 4 Mo sous les 100 Kio sans dépendance de
/// traitement d'image supplémentaire.
///
/// Sur le bureau et le web, `imageQuality` est ignoré par le greffon : une
/// image trop lourde n'est donc pas tronquée en silence, elle est refusée
/// avec une phrase qui dit quoi faire. C'est la contrepartie assumée de
/// l'absence de Cloud Storage — voir [ImageDataUrl].
class ProfilePhotoPicker {
  const ProfilePhotoPicker([this._picker]);

  final ImagePicker? _picker;

  ImagePicker get _pickerOrDefault => _picker ?? ImagePicker();

  /// Photo de profil : carrée à l'affichage, 512 px suffisent largement.
  Future<String?> pickAvatar(PhotoSource source) =>
      _pick(source, maxSide: 512, maxBytes: ImageDataUrl.maxAvatarBytes);

  /// Couverture : une bande large, donc plus de pixels utiles.
  Future<String?> pickCover(PhotoSource source) =>
      _pick(source, maxSide: 1280, maxBytes: ImageDataUrl.maxCoverBytes);

  /// Renvoie l'URL `data:` à stocker, ou `null` si l'utilisateur a renoncé.
  Future<String?> _pick(
    PhotoSource source, {
    required double maxSide,
    required int maxBytes,
  }) async {
    final file = await _pickerOrDefault.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 78,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > maxBytes) {
      throw FailureException(
        ValidationFailure(
          message:
              'Cette image est trop lourde (${_kilobytes(bytes.lengthInBytes)}). '
              'Choisissez-en une plus petite : ${_kilobytes(maxBytes)} au '
              'maximum.',
        ),
      );
    }
    return ImageDataUrl.encode(bytes, mimeType: _mimeType(file));
  }

  /// Le type réel du fichier, parce que c'est lui qui permettra de le
  /// décoder : annoncer du JPEG pour un PNG donnerait une image illisible.
  static String _mimeType(XFile file) {
    final declared = file.mimeType;
    if (declared != null && declared.startsWith('image/')) return declared;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _kilobytes(int bytes) => '${(bytes / 1024).round()} Ko';
}
