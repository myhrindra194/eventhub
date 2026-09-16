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
import 'package:eventhub/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// L'inscription est le seul écran du produit qui compose une donnée à partir
/// de deux champs, et le seul qui porte une condition légale. Ce sont donc les
/// deux choses éprouvées ici :
///
///  1. **La case des conditions bloque réellement l'envoi.** Une case qui
///     n'empêche rien est pire qu'absente : elle donne l'illusion d'un
///     consentement recueilli.
///  2. **Le nom transmis est « prénom nom », dans cet ordre.** L'écran saisit
///     le nom en premier à l'écran mais compose l'inverse ; c'est exactement
///     le genre d'inversion qu'une relecture ne voit pas et qu'un compte créé
///     à l'envers révèle trop tard.
void main() {
  late _MockAuthRepository repo;

  setUpAll(() => registerFallbackValue(UserRole.participant));

  setUp(() {
    repo = _MockAuthRepository();
    when(repo.watchSession).thenAnswer((_) => Stream.value(const SignedOut()));
  });

  Widget app() => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const RegisterScreen()),
  );

  /// Monte l'écran sur une surface de téléphone (360 × 800 dp).
  ///
  /// La surface de test par défaut ne fait que 800 × 600 : ce formulaire y
  /// dépasse, le bouton se retrouve hors écran, et un tap sur un widget hors
  /// écran ne déclenche rien. L'échec ressemble alors à une assertion fausse
  /// alors que l'interaction n'a simplement jamais eu lieu.
  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  /// Fait défiler jusqu'à la cible avant d'appuyer : le formulaire reste plus
  /// haut qu'un écran de téléphone, même à cette taille.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Le rôle d'abord, puis les champs dans l'ordre de déclaration : nom,
  /// prénom, adresse, mot de passe.
  Future<void> fillValidForm(
    WidgetTester tester, {
    UserRole role = UserRole.participant,
  }) async {
    await tapVisible(tester, find.text(role.label));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rakoto');
    await tester.enterText(fields.at(1), 'Elie');
    await tester.enterText(fields.at(2), 'elie@example.com');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.pump();
  }

  Finder submit() =>
      find.widgetWithText(AppButton, AppStrings.createAccount).first;

  void expectNoSignUp() => verifyNever(
    () => repo.signUp(
      name: any(named: 'name'),
      email: any(named: 'email'),
      password: any(named: 'password'),
      intendedRole: any(named: 'intendedRole'),
    ),
  );

  testWidgets('sans les conditions acceptées, rien n’est envoyé', (
    tester,
  ) async {
    await pumpPhone(tester);
    await fillValidForm(tester);

    await tapVisible(tester, submit());

    expectNoSignUp();
    expect(find.text(AppStrings.acceptTermsRequired), findsOneWidget);
  });

  testWidgets('un formulaire vide ne part pas non plus', (tester) async {
    await pumpPhone(tester);

    await tapVisible(tester, submit());

    // La validation du formulaire passe avant la case : c'est elle qui parle.
    expect(find.text("L'email est obligatoire."), findsOneWidget);
    expect(find.text('Email invalide.'), findsNothing);
    expectNoSignUp();
  });

  testWidgets('une adresse mal formée est refusée avant tout appel', (
    tester,
  ) async {
    await pumpPhone(tester);
    await fillValidForm(tester);
    await tester.enterText(find.byType(TextFormField).at(2), 'elie@');
    await tapVisible(tester, find.byType(AppCheckbox));

    await tapVisible(tester, submit());

    expect(find.text('Email invalide.'), findsOneWidget);
    expectNoSignUp();
  });

  testWidgets('formulaire valide et conditions cochées : le compte part', (
    tester,
  ) async {
    when(
      () => repo.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        intendedRole: any(named: 'intendedRole'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        AppUser(
          id: 'u1',
          name: 'Elie Rakoto',
          email: 'elie@example.com',
          role: UserRole.participant,
        ),
      ),
    );

    await pumpPhone(tester);
    await fillValidForm(tester);
    await tapVisible(tester, find.byType(AppCheckbox));

    await tapVisible(tester, submit());

    verify(
      () => repo.signUp(
        name: 'Elie Rakoto',
        email: 'elie@example.com',
        password: 'secret123',
        intendedRole: UserRole.participant,
      ),
    ).called(1);
  });

  testWidgets('sans rôle choisi, rien n’est envoyé', (tester) async {
    await pumpPhone(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rakoto');
    await tester.enterText(fields.at(1), 'Elie');
    await tester.enterText(fields.at(2), 'elie@example.com');
    await tester.enterText(fields.at(3), 'secret123');
    await tapVisible(tester, find.byType(AppCheckbox));

    await tapVisible(tester, submit());

    expectNoSignUp();
    // Le toast et le message sous les tuiles disent la même chose.
    expect(find.text(AppStrings.roleRequired), findsWidgets);
  });

  testWidgets('le rôle organisateur part avec l’inscription', (tester) async {
    when(
      () => repo.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        intendedRole: any(named: 'intendedRole'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        AppUser(
          id: 'u1',
          name: 'Elie Rakoto',
          email: 'elie@example.com',
          role: UserRole.participant,
          intendedRole: UserRole.organizer,
        ),
      ),
    );

    await pumpPhone(tester);
    await fillValidForm(tester, role: UserRole.organizer);
    expect(find.text(AppStrings.roleOrganizerNote), findsOneWidget);
    await tapVisible(tester, find.byType(AppCheckbox));

    await tapVisible(tester, submit());

    verify(
      () => repo.signUp(
        name: 'Elie Rakoto',
        email: 'elie@example.com',
        password: 'secret123',
        intendedRole: UserRole.organizer,
      ),
    ).called(1);
  });

  testWidgets('un refus du serveur s’affiche sans vider la saisie', (
    tester,
  ) async {
    when(
      () => repo.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        intendedRole: any(named: 'intendedRole'),
      ),
    ).thenAnswer(
      (_) async => const Err(
        AuthFailure(
          code: AuthFailureCode.emailAlreadyInUse,
          message: 'Cette adresse est déjà utilisée.',
        ),
      ),
    );

    await pumpPhone(tester);
    await fillValidForm(tester);
    await tapVisible(tester, find.byType(AppCheckbox));
    await tapVisible(tester, submit());

    expect(find.text('Cette adresse est déjà utilisée.'), findsOneWidget);
    // Refaire saisir quatre champs après un refus serait une punition.
    expect(find.text('elie@example.com'), findsOneWidget);
  });
}
