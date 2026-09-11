import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/features/auth/presentation/screens/splash_screen.dart';
import 'package:eventhub/features/onboarding/application/onboarding_providers.dart';
import 'package:eventhub/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Startup path — splash and onboarding — rendered at three widths.
///
/// Two claims are under test here, and neither can be verified by reading the
/// code:
///
///  1. **Responsiveness.** The same screen is rendered on a 320 dp budget
///     phone, a 390 dp mainstream phone and a 900 dp tablet window. A golden
///     per band is the only way a layout that silently overflows at 320 dp
///     stops shipping.
///  2. **No appearance toggle on the startup path.** The reference design
///     puts a sun/moon button on both screens; this product does not, and
///     the goldens are what keeps it that way after the next refactor.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// The three bands `ScreenSize` distinguishes, in logical pixels.
  const bands = <String, Size>{
    'small': Size(320, 720),
    'medium': Size(390, 844),
    'expanded': Size(900, 1000),
  };

  Widget host(Widget child, {required Brightness brightness}) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      // The carousel must never write to disk from a test.
      onboardingSeenProvider.overrideWith(_SeenStub.new),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: child,
    ),
  );

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Widget widget, {
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The splash animates for ~2.6 s; step past it so the golden captures
      // the finished mark rather than a random frame.
      await tester.pump(const Duration(seconds: 3));
    }
  }

  for (final band in bands.entries) {
    testWidgets('splash — ${band.key}', (tester) async {
      await pumpAt(
        tester,
        band.value,
        host(const SplashScreen(), brightness: Brightness.light),
        settle: false,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/splash_${band.key}.png'),
      );
    });

    testWidgets('onboarding — ${band.key}', (tester) async {
      await pumpAt(
        tester,
        band.value,
        host(const OnboardingScreen(), brightness: Brightness.light),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/onboarding_${band.key}.png'),
      );
    });
  }

  testWidgets('splash — dark', (tester) async {
    await pumpAt(
      tester,
      bands['medium']!,
      host(const SplashScreen(), brightness: Brightness.dark),
      settle: false,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/splash_dark.png'),
    );
  });
}

/// Always-seen stub: the real notifier touches `SharedPreferences`.
class _SeenStub extends OnboardingSeen {
  @override
  Future<bool> build() async => true;

  @override
  Future<void> markSeen() async {}
}
