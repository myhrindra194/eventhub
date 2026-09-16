import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/auth/presentation/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Deux modes dans un seul écran, et ils n'appellent pas la même chose :
/// le changement ordinaire se réauthentifie avec le mot de passe actuel,
/// tandis que le mode récupération — ouvert par un lien qui a déjà prouvé la
/// possession de l'adresse — ne le demande pas.
///
/// Les cas de refus local sont au moins aussi importants que le cas nominal :
/// une confirmation qui diffère ou un mot de passe identique à l'ancien
/// doivent être arrêtés ici, sans aller-retour réseau, avec une phrase qui
/// dit quoi corriger.
void main() {
  late _MockAuthRepository repo;

  const user = AppUser(
    id: 'u1',
    name: 'Elie',
    email: 'elie@example.com',
    role: UserRole.participant,
  );

  setUp(() {
    repo = _MockAuthRepository();
    when(
      repo.watchSession,
    ).thenAnswer((_) => Stream.value(const SignedIn(user)));
  });

  Widget app({bool recovery = false}) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ChangePasswordScreen(recovery: recovery),
    ),
  );

  /// Surface de téléphone : sur la surface de test par défaut (800 × 600), le
  /// bouton tombe hors de l'écran et le tap ne part jamais.
  Future<void> pumpPhone(WidgetTester tester, {bool recovery = false}) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(recovery: recovery));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder submit() =>
      find.widgetWithText(AppButton, AppStrings.changePassword).first;

  void expectNoChange() => verifyNever(
    () => repo.changePassword(
      currentPassword: any(named: 'currentPassword'),
      newPassword: any(named: 'newPassword'),
    ),
  );

  testWidgets('une confirmation qui diffère est refusée sans appel', (
    tester,
  ) async {
    await pumpPhone(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ancien123');
    await tester.enterText(fields.at(1), 'nouveau123');
    await tester.enterText(fields.at(2), 'nouveau124');
    await tapVisible(tester, submit());

    expect(find.text(AppStrings.passwordMismatch), findsOneWidget);
    expectNoChange();
  });

  testWidgets('reprendre le mot de passe actuel est refusé', (tester) async {
    await pumpPhone(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ancien123');
    await tester.enterText(fields.at(1), 'ancien123');
    await tester.enterText(fields.at(2), 'ancien123');
    await tapVisible(tester, submit());

    expect(find.text(AppStrings.passwordSameAsOld), findsOneWidget);
    expectNoChange();
  });

  testWidgets('un formulaire valide transmet les deux mots de passe', (
    tester,
  ) async {
    // Un échec plutôt qu'un succès : le succès navigue, ce qui demanderait un
    // routeur complet. Ce qui est sous test, c'est l'appel et le message.
    when(
      () => repo.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer(
      (_) async => const Err(
        AuthFailure(
          code: AuthFailureCode.invalidCredentials,
          message: 'Mot de passe actuel incorrect.',
        ),
      ),
    );

    await pumpPhone(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ancien123');
    await tester.enterText(fields.at(1), 'nouveau123');
    await tester.enterText(fields.at(2), 'nouveau123');
    await tapVisible(tester, submit());

    verify(
      () => repo.changePassword(
        currentPassword: 'ancien123',
        newPassword: 'nouveau123',
      ),
    ).called(1);
    expect(find.text('Mot de passe actuel incorrect.'), findsOneWidget);
  });

  testWidgets('le mode récupération ne demande pas le mot de passe actuel', (
    tester,
  ) async {
    when(() => repo.setNewPassword(any())).thenAnswer(
      (_) async => const Err(
        AuthFailure(code: AuthFailureCode.unknown, message: 'Lien expiré.'),
      ),
    );

    await pumpPhone(tester, recovery: true);

    // Deux champs au lieu de trois : le lien a déjà prouvé l'identité.
    expect(find.byType(TextFormField), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nouveau123');
    await tester.enterText(fields.at(1), 'nouveau123');
    await tapVisible(tester, submit());

    verify(() => repo.setNewPassword('nouveau123')).called(1);
    expectNoChange();
  });
}
