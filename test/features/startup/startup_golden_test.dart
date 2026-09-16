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

/// Le chemin de démarrage — splash et onboarding — rendu à trois largeurs.
///
/// Deux affirmations sont mises à l'épreuve ici, et aucune ne se vérifie en
/// lisant le code :
///
///  1. **L'adaptabilité.** Le même écran est rendu sur un téléphone d'entrée
///     de gamme de 320 dp, sur un téléphone courant de 390 dp et dans une
///     fenêtre de tablette de 900 dp. Un golden par bande est le seul moyen
///     qu'une mise en page qui déborde silencieusement à 320 dp cesse de
///     partir en production.
///  2. **Aucun sélecteur d'apparence sur le chemin de démarrage.** Le design
///     de référence pose un bouton soleil/lune sur les deux écrans ; ce
///     produit non, et ce sont les goldens qui le maintiendront ainsi après
///     le prochain remaniement.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Les trois bandes que distingue `ScreenSize`, en pixels logiques.
  const bands = <String, Size>{
    'small': Size(320, 720),
    'medium': Size(390, 844),
    'expanded': Size(900, 1000),
  };

  Widget host(Widget child, {required Brightness brightness}) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      // Le carrousel ne doit jamais écrire sur le disque depuis un test.
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
      // Le splash s'anime pendant environ 2,6 s ; on passe au-delà pour que
      // le golden capture la marque achevée, et non une image au hasard.
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

/// Doublure « déjà vu » : le vrai notifier passe par `SharedPreferences`.
class _SeenStub extends OnboardingSeen {
  @override
  Future<bool> build() async => true;

  @override
  Future<void> markSeen() async {}
}
