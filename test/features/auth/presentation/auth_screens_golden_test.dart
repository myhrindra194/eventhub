import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/auth/presentation/screens/change_password_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/login_screen.dart';
import 'package:eventhub/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

/// Les captures rendues des quatre écrans d'authentification, dans les deux
/// thèmes.
///
/// Pourquoi des goldens plutôt qu'une capture prise à la main sur un
/// téléphone : l'appareil de développement refuse la saisie synthétique
/// (`INJECT_EVENTS` est verrouillé sur MIUI), le piloter est donc une corvée
/// manuelle que personne ne répète. Ceux-ci tournent à chaque `flutter test`
/// et font échouer le build le jour où une marge, un rayon ou une élévation
/// dérive — exactement la classe de régression qu'une capture d'écran
/// envoyée dans une conversation ne rattrapera jamais.
///
/// Regenerate after an intentional design change:
///
/// ```bash
/// flutter test --update-goldens test/features/auth/presentation/auth_screens_golden_test.dart
/// ```
///
/// Note sur la typographie : `google_fonts` télécharge par le réseau, qui est
/// coupé en test ; les goldens sont donc rendus avec la police de repli. Ils
/// vérifient par conséquent **la mise en page, la couleur et les rayons** —
/// pas la typographie finale.
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUpAll(() {
    // Des goldens déterministes : jamais de police cherchée sur le réseau.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    repo = _MockAuthRepository();
    when(repo.watchSession).thenAnswer(
      (_) => Stream.value(
        const SignedIn(
          AppUser(
            id: 'u1',
            name: 'Elie Rakoto',
            email: 'elie@example.com',
            role: UserRole.participant,
          ),
        ),
      ),
    );
  });

  Widget host(Widget child, {required Brightness brightness}) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: child,
    ),
  );

  /// Une surface de 360 × 800 dp — le téléphone pour lequel le design est
  /// dessiné.
  Future<void> pumpPhone(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  final screens = <String, Widget Function()>{
    'login': LoginScreen.new,
    'register': RegisterScreen.new,
    'forgot_password': ForgotPasswordScreen.new,
    'change_password': ChangePasswordScreen.new,
  };

  for (final entry in screens.entries) {
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark ? 'dark' : 'light';

      testWidgets('${entry.key} — $theme', (tester) async {
        await pumpPhone(tester, host(entry.value(), brightness: brightness));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${entry.key}_$theme.png'),
        );
      });
    }
  }
}
