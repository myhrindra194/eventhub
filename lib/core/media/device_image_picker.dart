import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// D'où vient l'image choisie.
enum PhotoSource { gallery, camera }

/// Une image choisie sur l'appareil, prête à partir.
///
/// On transporte les octets, pas un chemin de fichier : sur le web il n'y a
/// pas de système de fichiers, et l'envoi multipart fonctionne de la même
/// façon partout à partir d'octets.
@immutable
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String filename;
}

/// Choisit une image sur l'appareil.
///
/// Le redimensionnement et la recompression sont demandés au sélecteur
/// lui-même : sur Android et iOS il ré-encode en JPEG à la taille voulue, ce
/// qui fait passer une photo de 8 Mo à quelques centaines de Ko avant
/// l'envoi, sans dépendance de traitement d'image supplémentaire.
///
/// Sur le bureau et le web, `imageQuality` est ignoré par le greffon : un
/// fichier trop lourd n'est donc pas envoyé pour se faire refuser par
/// Cloudinary au bout d'une longue attente, il est refusé ici, tout de
/// suite, avec une phrase qui dit quoi faire.
class DeviceImagePicker {
  const DeviceImagePicker([this._picker]);

  final ImagePicker? _picker;

  /// Plafond d'un fichier image sur l'offre gratuite de Cloudinary. Le
  /// reprendre côté client transforme un refus serveur opaque en une phrase
  /// affichée avant même le premier octet envoyé.
  static const maxBytes = 10 * 1024 * 1024;

  ImagePicker get _pickerOrDefault => _picker ?? ImagePicker();

  /// Renvoie l'image choisie, ou `null` si l'utilisateur a renoncé.
  ///
  /// Lève une [FailureException] portant une [ValidationFailure] quand le
  /// fichier dépasse [maxBytes].
  Future<PickedImage?> pick(ImageKind kind, PhotoSource source) async {
    final file = await _pickerOrDefault.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: kind.maxSide,
      maxHeight: kind.maxSide,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > maxBytes) {
      throw FailureException(
        ValidationFailure(
          message:
              'Cette image est trop lourde (${_megabytes(bytes.lengthInBytes)}). '
              'Choisissez-en une de ${_megabytes(maxBytes)} au maximum.',
        ),
      );
    }
    return PickedImage(
      bytes: bytes,
      mimeType: _mimeType(file),
      filename: file.name,
    );
  }

  /// Le type réel du fichier. Cloudinary détecte le format tout seul, mais
  /// un type faux dans l'en-tête multipart fait refuser l'envoi par certains
  /// proxys d'entreprise : on annonce donc ce que le fichier contient.
  static String _mimeType(XFile file) {
    final declared = file.mimeType;
    if (declared != null && declared.startsWith('image/')) return declared;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  static String _megabytes(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';
}
