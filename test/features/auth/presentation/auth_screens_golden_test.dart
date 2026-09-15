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

/// Rendered snapshots of the four authentication screens, in both themes.
///
/// Why goldens rather than a screenshot taken by hand on a phone: the device
/// used during development refuses synthetic input (`INJECT_EVENTS` is locked
/// on MIUI), so driving it is a manual chore that nobody repeats. These run on
/// every `flutter test` and fail the build the day a padding, a radius or a
/// shadow drifts — which is precisely the class of regression a screenshot in
/// a chat thread cannot catch.
///
/// Regenerate after an intentional design change:
///
/// ```bash
/// flutter test --update-goldens test/features/auth/presentation/auth_screens_golden_test.dart
/// ```
///
/// Note on type: `google_fonts` fetches over the network, which is disabled in
/// tests, so the goldens render with the fallback face. They therefore verify
/// **layout, colour, radius and elevation** — not the final typography.
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUpAll(() {
    // Deterministic goldens: never reach for a font over the network.
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

  /// A 360 × 800 dp surface — the phone the design is drawn for.
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
