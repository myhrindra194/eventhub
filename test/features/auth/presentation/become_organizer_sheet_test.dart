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
import 'package:eventhub/features/auth/presentation/widgets/become_organizer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// L'activation de l'espace organisateur est le seul endroit du produit où un
/// compte change de rôle. Deux garanties sont vérifiées ici, et ce sont les
/// deux qui peuvent coûter cher :
///
///  1. **Le garde-fou de l'adresse vérifiée.** Ce sont les règles qui exigent
///     `email_verified`, et elles répondent par un `permission-denied` muet.
///     L'écran doit donc refuser le départ lui-même, en expliquant pourquoi —
///     sans quoi l'utilisateur ne voit qu'un échec sans cause.
///  2. **La demande part bien au repository.** C'est précisément ce qui
///     manquait : la méthode existait, aucun écran ne l'appelait, et le
///     compte organisateur était impossible à créer.
void main() {
  late _MockAuthRepository repo;

  const participant = AppUser(
    id: 'u1',
    name: 'Elie',
    email: 'elie@example.com',
    role: UserRole.participant,
  );

  setUp(() {
    repo = _MockAuthRepository();
  });

  /// Monte un écran quelconque, d'où la feuille est ouverte comme depuis le
  /// profil : la feuille a besoin d'un contexte de page sous elle.
  Future<void> openSheet(WidgetTester tester, {required bool verified}) async {
    when(repo.watchSession).thenAnswer(
      (_) =>
          Stream.value(SignedIn(participant.copyWith(emailVerified: verified))),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showBecomeOrganizerSheet(context),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('une adresse non vérifiée bloque le départ et l’explique', (
    tester,
  ) async {
    await openSheet(tester, verified: false);

    expect(find.text(AppStrings.becomeOrganizerVerifyFirst), findsOneWidget);

    await tester.tap(
      find.widgetWithText(AppButton, AppStrings.becomeOrganizerCta),
    );
    await tester.pumpAndSettle();

    // Rien n'est parti au serveur : le refus est local, donc immédiat et
    // porteur d'une phrase.
    verifyNever(() => repo.becomeOrganizer(bio: any(named: 'bio')));
  });

  testWidgets('une adresse vérifiée envoie la demande, présentation comprise', (
    tester,
  ) async {
    when(() => repo.becomeOrganizer(bio: any(named: 'bio'))).thenAnswer(
      // Un échec plutôt qu'un succès : le succès referme la feuille puis
      // navigue vers l'espace organisateur, ce qui demanderait un routeur
      // complet. Ce qui est sous test ici, c'est l'appel et le retour
      // d'erreur — la navigation est couverte par `route_guard_test`.
      (_) async => const Err(
        BusinessRuleFailure(
          rule: BusinessRule.emailNotVerified,
          message: 'Refus du serveur.',
        ),
      ),
    );

    await openSheet(tester, verified: true);
    expect(find.text(AppStrings.becomeOrganizerVerifyFirst), findsNothing);

    await tester.enterText(find.byType(TextField), 'J’organise des meetups.');
    await tester.tap(
      find.widgetWithText(AppButton, AppStrings.becomeOrganizerCta),
    );
    await tester.pumpAndSettle();

    verify(
      () => repo.becomeOrganizer(bio: 'J’organise des meetups.'),
    ).called(1);
    // Le refus du serveur s'affiche dans la feuille, qui reste ouverte : la
    // saisie de l'utilisateur n'est pas perdue.
    expect(find.text('Refus du serveur.'), findsOneWidget);
  });
}
