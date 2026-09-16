import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Cet écran a deux états dans un seul widget — le formulaire, puis la
/// confirmation — et c'est la bascule entre les deux qui compte : une
/// réinitialisation qui renvoie l'utilisateur sans rien dire produit le
/// ticket de support le plus fréquent de tout parcours d'authentification
/// (« ai-je vraiment reçu quelque chose ? »).
void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(repo.watchSession).thenAnswer((_) => Stream.value(const SignedOut()));
  });

  Widget app() => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const ForgotPasswordScreen(),
    ),
  );

  /// Surface de téléphone : la surface de test par défaut (800 × 600) est plus
  /// courte que l'écran, et un bouton hors champ ne reçoit pas les taps.
  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder submit() =>
      find.widgetWithText(AppButton, AppStrings.sendResetLink).first;

  testWidgets('une adresse invalide ne déclenche aucun envoi', (tester) async {
    await pumpPhone(tester);

    await tester.enterText(find.byType(TextFormField), 'pas-une-adresse');
    await tapVisible(tester, submit());

    expect(find.text('Email invalide.'), findsOneWidget);
    verifyNever(() => repo.sendPasswordReset(email: any(named: 'email')));
  });

  testWidgets('un envoi réussi confirme, en répétant l’adresse', (
    tester,
  ) async {
    when(
      () => repo.sendPasswordReset(email: any(named: 'email')),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPhone(tester);
    await tester.enterText(find.byType(TextFormField), 'elie@example.com');
    await tapVisible(tester, submit());

    verify(() => repo.sendPasswordReset(email: 'elie@example.com')).called(1);

    // L'écran a basculé : le formulaire a disparu au profit de la
    // confirmation, qui rappelle l'adresse servie.
    expect(find.text(AppStrings.resetSentTitle), findsOneWidget);
    expect(find.text('elie@example.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('« Renvoyer le lien » ramène au formulaire', (tester) async {
    when(
      () => repo.sendPasswordReset(email: any(named: 'email')),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPhone(tester);
    await tester.enterText(find.byType(TextFormField), 'elie@example.com');
    await tapVisible(tester, submit());

    await tapVisible(
      tester,
      find.widgetWithText(AppButton, 'Renvoyer le lien'),
    );

    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('un échec reste sur le formulaire et l’explique', (tester) async {
    when(() => repo.sendPasswordReset(email: any(named: 'email'))).thenAnswer(
      (_) async => const Err(
        AuthFailure(
          code: AuthFailureCode.invalidCredentials,
          message: 'Aucun compte avec cette adresse.',
        ),
      ),
    );

    await pumpPhone(tester);
    await tester.enterText(find.byType(TextFormField), 'elie@example.com');
    await tapVisible(tester, submit());

    expect(find.text('Aucun compte avec cette adresse.'), findsOneWidget);
    // Surtout pas de confirmation : annoncer un envoi qui n'a pas eu lieu
    // ferait attendre un e-mail qui n'arrivera jamais.
    expect(find.text(AppStrings.resetSentTitle), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
