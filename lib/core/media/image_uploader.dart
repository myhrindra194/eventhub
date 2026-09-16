import 'dart:async';
import 'dart:convert';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Une image hébergée, telle que l'envoi l'a rendue.
@immutable
class UploadedImage {
  const UploadedImage({
    required this.url,
    required this.publicId,
    this.width,
    this.height,
  });

  /// URL https d'origine : c'est elle, et elle seule, qu'on écrit dans
  /// Firestore. Les variantes redimensionnées se dérivent à l'affichage.
  final String url;

  /// Identifiant Cloudinary, utile pour retrouver le fichier dans la
  /// médiathèque lors d'une modération ou d'un nettoyage manuel.
  final String publicId;
  final int? width;
  final int? height;
}

/// Envoie une image vers un hébergement d'images.
///
/// Une interface plutôt que la classe Cloudinary directement : les écrans
/// et leurs tests dépendent de « envoyer une image », pas du protocole
/// multipart d'un fournisseur donné.
abstract interface class ImageUploader {
  /// Faux quand l'application a été construite sans configuration
  /// d'hébergement : les écrans masquent alors l'import au lieu de proposer
  /// un bouton qui échouerait à chaque fois.
  bool get isConfigured;

  AsyncResult<UploadedImage> upload(
    PickedImage image, {
    required ImageKind kind,
    required String ownerId,
  });
}

/// Envoi **non signé** vers Cloudinary, directement depuis l'appareil.
///
/// **Pourquoi non signé.** Un envoi signé exige la clé secrète du compte,
/// qui ne peut vivre que sur un serveur ; or le projet tourne sur le plan
/// Spark, sans Cloud Functions. Un envoi non signé ne nécessite que le nom du
/// cloud et celui d'un *upload preset* — deux valeurs publiques, visibles
/// dans n'importe quel binaire de l'app.
///
/// **Le compromis accepté.** Quiconque lit ces deux valeurs peut déposer des
/// images sur le compte. Le preset borne ce risque côté Cloudinary (formats,
/// poids, dimensions, dossier, écrasement interdit) et les règles Firestore
/// n'acceptent qu'une URL Cloudinary : un fichier déposé hors de l'app
/// consomme du quota mais n'apparaît nulle part. Le détail et les réglages du
/// preset sont dans `docs/SECURITY.md`.
///
/// **Ce qui manque.** Un envoi non signé ne peut pas supprimer : une image
/// remplacée reste dans la médiathèque. C'est la contrepartie de l'absence
/// de serveur, documentée dans `docs/ROADMAP.md`.
class CloudinaryImageUploader implements ImageUploader {
  CloudinaryImageUploader({
    required http.Client client,
    required this.cloudName,
    required this.uploadPreset,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client;

  final http.Client _client;
  final String cloudName;
  final String uploadPreset;

  /// Une minute : une affiche de 2 Mo en 3G lente tient dedans, et au-delà
  /// l'utilisateur a de toute façon quitté l'écran.
  final Duration timeout;

  /// Racine commune de tous les dossiers de l'app dans la médiathèque, pour
  /// qu'EventHub cohabite avec d'autres projets sur le même compte.
  static const rootFolder = 'eventhub';

  @override
  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  Uri get _endpoint =>
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload');

  @override
  AsyncResult<UploadedImage> upload(
    PickedImage image, {
    required ImageKind kind,
    required String ownerId,
  }) async {
    if (!isConfigured) {
      return const Err(
        StorageFailure(
          message:
              'L’envoi d’images n’est pas configuré sur cette version de '
              'l’application.',
        ),
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..fields.addAll({
        'upload_preset': uploadPreset,
        'folder': '$rootFolder/${kind.folder}',
        // Les étiquettes et le contexte ne donnent aucun droit : ils servent
        // à retrouver, depuis la console Cloudinary, toutes les images d'un
        // compte signalé par la modération.
        'tags': '$rootFolder,${kind.name}',
        'context': 'uid=$ownerId',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          image.bytes,
          filename: image.filename,
          contentType: MediaType.parse(image.mimeType),
        ),
      );

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on TimeoutException catch (error, stackTrace) {
      return Err(
        NetworkFailure(
          message: 'L’envoi de l’image a pris trop de temps. Réessayez.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on http.ClientException catch (error, stackTrace) {
      // Perte de réseau, DNS, TLS : sur mobile comme sur le web, le paquet
      // http les ramène toutes à ClientException.
      return Err(NetworkFailure(cause: error, stackTrace: stackTrace));
    }
  }

  Result<UploadedImage> _parse(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Cloudinary returned a non-JSON body (${response.statusCode})',
        error: error,
        stackTrace: stackTrace,
      );
      return Err(StorageFailure(cause: error, stackTrace: stackTrace));
    }

    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      final url = body['secure_url'];
      final publicId = body['public_id'];
      if (url is String && publicId is String) {
        return Ok(
          UploadedImage(
            url: url,
            publicId: publicId,
            width: body['width'] as int?,
            height: body['height'] as int?,
          ),
        );
      }
    }

    final error = body is Map<String, dynamic> ? body['error'] : null;
    final detail = error is Map<String, dynamic> ? error['message'] : null;
    AppLogger.warning(
      'Cloudinary upload refused (${response.statusCode}): $detail',
    );
    return Err(StorageFailure(message: _messageFor(response.statusCode)));
  }

  /// Le message montré à l'utilisateur. Le détail technique de Cloudinary
  /// (en anglais, et qui peut nommer le preset) part dans les journaux,
  /// jamais à l'écran.
  static String _messageFor(int status) => switch (status) {
    // Fichier illisible, format refusé ou dimensions hors du preset.
    400 => 'Cette image a été refusée : utilisez un JPEG, PNG ou WebP.',
    // Preset absent, supprimé ou repassé en « signé ».
    401 || 403 || 404 =>
      'L’envoi d’images est momentanément indisponible. Réessayez plus tard.',
    // Limitation de débit du compte.
    420 || 429 =>
      'Trop d’envois en peu de temps. Patientez une minute avant de réessayer.',
    _ => "L'envoi de l'image a échoué. Réessayez.",
  };
}
