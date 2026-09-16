import 'package:eventhub/core/media/camera_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class _MockCameraPermission extends Mock implements CameraPermission {}

/// Le parcours d'accès à la caméra. Chaque issue se traduit différemment à
/// l'écran — caméra ouverte, rien, message court, renvoi aux réglages — et
/// une branche mal aiguillée coûte cher : une invite système dépensée sans
/// explication peut devenir un refus définitif, et une explication montrée
/// alors que le système ne posera plus la question est un bouton qui ne fait
/// rien. Ce fichier éprouve chacune d'elles.
void main() {
  late _MockCameraPermission permission;
  late CameraAccessGate gate;
  late int explanations;

  setUp(() {
    permission = _MockCameraPermission();
    gate = CameraAccessGate(permission);
    explanations = 0;
    when(() => permission.isRequired).thenReturn(true);
  });

  /// Simule la feuille d'explication : [accept] vaut « Continuer ».
  Future<bool> Function() explainer({required bool accept}) => () async {
    explanations++;
    return accept;
  };

  group('CameraAccessGate', () {
    test('accès déjà accordé : ni explication ni invite', () async {
      when(
        permission.check,
      ).thenAnswer((_) async => CameraPermissionState.granted);

      final outcome = await gate.resolve(explain: explainer(accept: true));

      expect(outcome, CameraAccessOutcome.granted);
      expect(explanations, 0);
      verifyNever(permission.request);
    });

    test('jamais demandé puis accordé : explication, puis invite', () async {
      when(
        permission.check,
      ).thenAnswer((_) async => CameraPermissionState.denied);
      when(
        permission.request,
      ).thenAnswer((_) async => CameraPermissionState.granted);

      final outcome = await gate.resolve(explain: explainer(accept: true));

      expect(outcome, CameraAccessOutcome.granted);
      expect(explanations, 1);
      verify(permission.request).called(1);
    });

    test('« Plus tard » ne dépense pas l’invite système', () async {
      when(
        permission.check,
      ).thenAnswer((_) async => CameraPermissionState.denied);

      final outcome = await gate.resolve(explain: explainer(accept: false));

      expect(outcome, CameraAccessOutcome.dismissed);
      verifyNever(permission.request);
    });

    test('refus dans l’invite : message court, pas de réglages', () async {
      when(
        permission.check,
      ).thenAnswer((_) async => CameraPermissionState.denied);
      when(
        permission.request,
      ).thenAnswer((_) async => CameraPermissionState.denied);

      expect(
        await gate.resolve(explain: explainer(accept: true)),
        CameraAccessOutcome.denied,
      );
    });

    test('refus devenu définitif pendant l’invite : toujours un simple '
        'refus, les réglages attendront la tentative suivante', () async {
      // iOS marque le refus comme définitif dès la première réponse ;
      // renvoyer aux réglages une personne qui vient de dire non se lirait
      // comme de l'insistance.
      when(
        permission.check,
      ).thenAnswer((_) async => CameraPermissionState.denied);
      when(
        permission.request,
      ).thenAnswer((_) async => CameraPermissionState.blocked);

      expect(
        await gate.resolve(explain: explainer(accept: true)),
        CameraAccessOutcome.denied,
      );
    });

    test(
      'accès bloqué : renvoi aux réglages, sans explication inutile',
      () async {
        when(
          permission.check,
        ).thenAnswer((_) async => CameraPermissionState.blocked);

        final outcome = await gate.resolve(explain: explainer(accept: true));

        expect(outcome, CameraAccessOutcome.blocked);
        expect(explanations, 0);
        verifyNever(permission.request);
      },
    );

    test('web et bureau : le parcours ne touche pas au greffon', () async {
      when(() => permission.isRequired).thenReturn(false);

      final outcome = await gate.resolve(explain: explainer(accept: false));

      expect(outcome, CameraAccessOutcome.granted);
      expect(explanations, 0);
      verifyNever(permission.check);
      verifyNever(permission.request);
    });

    test('ouvrir les réglages délègue à la plateforme', () async {
      when(permission.openSettings).thenAnswer((_) async => true);
      expect(await gate.openSettings(), isTrue);
      verify(permission.openSettings).called(1);
    });
  });

  group('cameraPermissionApplies', () {
    test('seuls Android et iOS passent par permission_handler', () {
      for (final platform in TargetPlatform.values) {
        expect(
          cameraPermissionApplies(isWeb: false, platform: platform),
          platform == TargetPlatform.android || platform == TargetPlatform.iOS,
          reason: '$platform',
        );
      }
    });

    test('le web est toujours ignoré, quel que soit le système hôte', () {
      for (final platform in TargetPlatform.values) {
        expect(
          cameraPermissionApplies(isWeb: true, platform: platform),
          isFalse,
          reason: '$platform',
        );
      }
    });
  });

  group('PermissionHandlerCameraPermission.mapPermissionStatus', () {
    test('replie les six statuts du greffon sur trois cas', () {
      const expected = {
        PermissionStatus.granted: CameraPermissionState.granted,
        PermissionStatus.limited: CameraPermissionState.granted,
        PermissionStatus.provisional: CameraPermissionState.granted,
        PermissionStatus.denied: CameraPermissionState.denied,
        PermissionStatus.permanentlyDenied: CameraPermissionState.blocked,
        PermissionStatus.restricted: CameraPermissionState.blocked,
      };
      for (final status in PermissionStatus.values) {
        expect(
          PermissionHandlerCameraPermission.mapPermissionStatus(status),
          expected[status],
          reason: '$status',
        );
      }
    });
  });
}
