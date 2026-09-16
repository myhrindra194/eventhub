import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_permission.g.dart';

/// L'état de l'accès à l'appareil photo, réduit à ce que l'interface doit
/// distinguer.
///
/// `permission_handler` expose six valeurs (`limited`, `provisional`…) dont
/// la plupart n'ont aucun sens pour la caméra. Les replier ici en trois cas
/// évite que chaque écran réécrive son propre `switch` — et qu'un oubli
/// (`restricted` traité comme `denied`, par exemple) fasse redemander un
/// accès que le système ne présentera jamais.
enum CameraPermissionState {
  /// L'accès est accordé : la caméra peut s'ouvrir.
  granted,

  /// L'accès n'est pas (encore) accordé, mais le système accepte de poser la
  /// question. Sur iOS, c'est aussi l'état « jamais demandé ».
  denied,

  /// Le système ne posera plus la question : refus définitif de
  /// l'utilisateur, ou restriction imposée (contrôle parental, profil MDM).
  /// Seuls les réglages de l'appareil peuvent rouvrir l'accès.
  blocked,
}

/// L'accès à la caméra, vu depuis l'application.
///
/// Une interface plutôt qu'un appel direct au greffon : le greffon parle à
/// la plateforme par un canal natif, absent des tests. L'injecter permet
/// d'éprouver chaque branche du parcours — accordé, refusé, bloqué — sans
/// appareil ni simulateur.
abstract interface class CameraPermission {
  /// `false` quand la plateforme n'a pas de permission caméra à gérer par ce
  /// biais (web, bureau) : le parcours saute alors directement à l'ouverture
  /// du sélecteur, comme avant l'ajout de ce contrôle.
  bool get isRequired;

  /// L'état courant, **sans** afficher d'invite système.
  Future<CameraPermissionState> check();

  /// Affiche l'invite système (si le système l'accepte) et rend la réponse.
  Future<CameraPermissionState> request();

  /// Ouvre la page de l'application dans les réglages de l'appareil. Rend
  /// `false` si le système a refusé de l'ouvrir.
  Future<bool> openSettings();
}

/// Indique si la permission caméra doit passer par `permission_handler` sur
/// cette plateforme.
///
/// Fonction pure, paramétrée par la plateforme, pour que la règle se teste
/// sans dépendre de la machine qui exécute les tests. Seuls Android et iOS
/// sont concernés : le greffon n'a pas d'implémentation caméra sur macOS ni
/// Linux, et celle du web ou de Windows rendrait un état sans rapport avec
/// ce que fait réellement `image_picker` (le navigateur pose sa propre
/// question au moment de `getUserMedia`, le bureau ouvre un sélecteur de
/// fichiers). Y appeler le greffon ferait échouer le geste au lieu de le
/// laisser fonctionner comme aujourd'hui.
bool cameraPermissionApplies({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

/// Implémentation adossée à `permission_handler`.
class PermissionHandlerCameraPermission implements CameraPermission {
  const PermissionHandlerCameraPermission();

  @override
  bool get isRequired =>
      cameraPermissionApplies(isWeb: kIsWeb, platform: defaultTargetPlatform);

  @override
  Future<CameraPermissionState> check() async =>
      mapPermissionStatus(await Permission.camera.status);

  @override
  Future<CameraPermissionState> request() async =>
      mapPermissionStatus(await Permission.camera.request());

  @override
  Future<bool> openSettings() => openAppSettings();

  /// Replie un [PermissionStatus] sur les trois cas de l'interface.
  ///
  /// `limited` et `provisional` n'existent pas pour la caméra, mais le
  /// greffon pourrait un jour les renvoyer : ce sont des accès *accordés*,
  /// donc la caméra s'ouvre plutôt que de bloquer l'utilisateur sur une
  /// valeur inattendue. `restricted` rejoint `permanentlyDenied` parce que,
  /// dans les deux cas, redemander ne montrerait aucune invite.
  @visibleForTesting
  static CameraPermissionState mapPermissionStatus(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited ||
        PermissionStatus.provisional => CameraPermissionState.granted,
        PermissionStatus.denied => CameraPermissionState.denied,
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted => CameraPermissionState.blocked,
      };
}

/// L'issue du parcours d'accès, telle que l'écran doit y réagir.
enum CameraAccessOutcome {
  /// Ouvrir la caméra.
  granted,

  /// L'utilisateur a choisi « Plus tard » dans l'explication : il n'a rien
  /// refusé, l'écran ne dit donc rien.
  dismissed,

  /// L'utilisateur vient de refuser dans l'invite système : un message court
  /// suffit, sans insister.
  denied,

  /// L'accès est bloqué d'avance : seule une invitation à ouvrir les
  /// réglages peut encore débloquer la situation.
  blocked,
}

/// La décision « peut-on ouvrir la caméra ? », séparée de toute interface.
///
/// Le parcours reprend celui d'Instagram ou d'Airbnb :
///
///  1. si l'accès est déjà accordé, rien ne s'affiche ;
///  2. s'il est bloqué, on le dit tout de suite — montrer d'abord une
///     explication suivie d'une invite système qui ne viendra jamais serait
///     un bouton qui ne fait rien ;
///  3. sinon, une explication *dans l'application* précède l'invite système.
///     Le système n'accorde qu'un nombre très limité d'invites (une seule sur
///     iOS) : la dépenser sur un utilisateur qui ne sait pas encore pourquoi
///     on la demande, c'est risquer un refus définitif.
///
/// Juste après un refus dans l'invite système, l'issue est [denied] et non
/// [blocked], même si iOS considère déjà le refus comme définitif : renvoyer
/// vers les réglages une personne qui vient de dire non se lit comme de
/// l'insistance. C'est à la tentative *suivante* que la vérification initiale
/// rendra [blocked] et proposera les réglages.
class CameraAccessGate {
  const CameraAccessGate(this._permission);

  final CameraPermission _permission;

  /// [explain] affiche l'explication et rend `true` si l'utilisateur veut
  /// continuer. Elle n'est appelée que lorsqu'une invite système va suivre.
  Future<CameraAccessOutcome> resolve({
    required Future<bool> Function() explain,
  }) async {
    if (!_permission.isRequired) return CameraAccessOutcome.granted;

    switch (await _permission.check()) {
      case CameraPermissionState.granted:
        return CameraAccessOutcome.granted;
      case CameraPermissionState.blocked:
        return CameraAccessOutcome.blocked;
      case CameraPermissionState.denied:
        break;
    }

    if (!await explain()) return CameraAccessOutcome.dismissed;

    return switch (await _permission.request()) {
      CameraPermissionState.granted => CameraAccessOutcome.granted,
      CameraPermissionState.denied ||
      CameraPermissionState.blocked => CameraAccessOutcome.denied,
    };
  }

  /// Ouvre les réglages de l'application.
  Future<bool> openSettings() => _permission.openSettings();
}

/// La permission caméra de l'appareil.
///
/// Exposée comme dépendance, dans le même esprit que le sélecteur d'images :
/// un test de widget la remplace pour décider lui-même de la réponse du
/// système, sans canal natif.
@Riverpod(keepAlive: true)
CameraPermission cameraPermission(Ref ref) =>
    const PermissionHandlerCameraPermission();

@Riverpod(keepAlive: true)
CameraAccessGate cameraAccessGate(Ref ref) =>
    CameraAccessGate(ref.watch(cameraPermissionProvider));
