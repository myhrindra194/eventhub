import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Widget-test pattern: override the repository provider with a mock and
/// pump the screen inside a ProviderScope. No Firebase involved.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    when(repo.watchSession).thenAnswer((_) => Stream.value(const SignedOut()));
  });

  Widget app() => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
  );

  testWidgets('shows validation errors and does not call the repository', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.widgetWithText(AppButton, 'Se connecter'));
    await tester.pump();

    expect(find.text("L'email est obligatoire."), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
    verifyNever(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submits credentials to the repository', (tester) async {
    const user = AppUser(
      id: 'u1',
      name: 'Elie',
      email: 'elie@example.com',
      role: UserRole.participant,
    );
    when(
      () => repo.signIn(email: 'elie@example.com', password: 'secret1'),
    ).thenAnswer((_) async => const Ok(user));

    await tester.pumpWidget(app());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'elie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(AppButton, 'Se connecter'));
    await tester.pumpAndSettle();

    verify(
      () => repo.signIn(email: 'elie@example.com', password: 'secret1'),
    ).called(1);
  });
}
