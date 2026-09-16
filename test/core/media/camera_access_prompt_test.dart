import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/media/camera_access_prompt.dart';
import 'package:eventhub/core/media/camera_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCameraPermission extends Mock implements CameraPermission {}

/// L'habillage du parcours : on vérifie que chaque issue de la décision
/// montre la bonne feuille, et surtout que l'invite système et les réglages
/// ne partent que sur un geste explicite de l'utilisateur.
void main() {
  late _MockCameraPermission permission;
  bool? allowed;

  setUp(() {
    permission = _MockCameraPermission();
    allowed = null;
    when(() => permission.isRequired).thenReturn(true);
  });

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => allowed = await ensureCameraAccess(
                  context,
                  CameraAccessGate(permission),
                ),
                child: const Text('prendre une photo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('prendre une photo'));
    await tester.pumpAndSettle();
  }

  testWidgets('« Continuer » déclenche l’invite système puis autorise', (
    tester,
  ) async {
    when(
      permission.check,
    ).thenAnswer((_) async => CameraPermissionState.denied);
    when(
      permission.request,
    ).thenAnswer((_) async => CameraPermissionState.granted);

    await start(tester);
    expect(find.textContaining('photo de profil ou de couverture'), findsOne);
    verifyNever(permission.request);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    verify(permission.request).called(1);
    expect(allowed, isTrue);
  });

  testWidgets('« Plus tard » referme sans rien demander ni rien dire', (
    tester,
  ) async {
    when(
      permission.check,
    ).thenAnswer((_) async => CameraPermissionState.denied);

    await start(tester);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    verifyNever(permission.request);
    expect(allowed, isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('un refus dans l’invite affiche un message court', (
    tester,
  ) async {
    when(
      permission.check,
    ).thenAnswer((_) async => CameraPermissionState.denied);
    when(
      permission.request,
    ).thenAnswer((_) async => CameraPermissionState.denied);

    await start(tester);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(allowed, isFalse);
    expect(find.byType(SnackBar), findsOne);
  });

  testWidgets('un accès bloqué propose d’ouvrir les réglages', (tester) async {
    when(
      permission.check,
    ).thenAnswer((_) async => CameraPermissionState.blocked);
    when(permission.openSettings).thenAnswer((_) async => true);

    await start(tester);
    expect(find.text('Continuer'), findsNothing);

    await tester.tap(find.text('Ouvrir les réglages'));
    await tester.pumpAndSettle();

    verify(permission.openSettings).called(1);
    verifyNever(permission.request);
    // La caméra ne s'ouvre pas au retour des réglages : le geste sera
    // relancé et l'état réel revérifié.
    expect(allowed, isFalse);
  });
}
