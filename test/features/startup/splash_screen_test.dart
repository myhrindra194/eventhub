import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/features/auth/presentation/screens/splash_screen.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:eventhub/routes/startup_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'écran de démarrage n'a rien à décider, mais il règle désormais le tempo
/// du démarrage : le router attend la fin de son intro pour partir. Ce qui
/// peut mal tourner, et que ce fichier éprouve :
///
///  1. **L'intro se termine et le dit** — sinon le router attendrait le
///     minuteur de secours à chaque lancement ;
///  2. **« Réduire les animations » est respecté** — marque achevée dès la
///     première image, et démarrage libéré sans attendre ;
///  3. **La ligne « préparation » n'apparaît que si le démarrage traîne** —
///     jamais pendant une intro normale ;
///  4. **Rien ne tourne après** — `pumpAndSettle` échouerait sur une boucle.
void main() {
  late ProviderContainer container;

  Widget app({bool reduceMotion = false}) {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const SplashScreen(),
        ),
      ),
    );
  }

  testWidgets('trace la marque, puis libère le démarrage', (tester) async {
    await tester.pumpWidget(app());

    expect(find.byType(EventMark), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(container.read(startupIntroProvider), isFalse);

    // Le ticker démarre à la première image ; on avance ensuite d'un peu
    // plus que la durée de l'intro, puis une image pour vider la micro-tâche.
    await tester.pump();
    await tester.pump(SplashScreen.duration + const Duration(milliseconds: 50));
    await tester.pump();
    final mark = tester.widget<EventMark>(find.byType(EventMark));
    expect(
      mark.progress.value,
      1.0,
      reason: 'la marque est entièrement tracée',
    );
    expect(
      container.read(startupIntroProvider),
      isTrue,
      reason: 'le router attend ce signal pour quitter le splash',
    );
    expect(find.text(AppStrings.splashLoading), findsOneWidget);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
      reason: 'aucune ligne d’attente pendant une intro normale',
    );

    // Échouerait sur une animation qui boucle ou un minuteur laissé actif.
    await tester.pumpAndSettle(SplashScreen.slowHint);
  });

  testWidgets('signale un démarrage lent après 2,5 s', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(SplashScreen.slowHint);
    await tester.pumpAndSettle();

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
  });

  testWidgets('animations réduites : marque achevée et démarrage immédiat', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump();

    final mark = tester.widget<EventMark>(find.byType(EventMark));
    expect(mark.progress.value, 1.0);
    expect(container.read(startupIntroProvider), isTrue);
    await tester.pumpAndSettle(SplashScreen.slowHint);
  });

  test('le minuteur de secours libère le démarrage sans splash', () async {
    final alone = ProviderContainer();
    addTearDown(alone.dispose);
    expect(alone.read(startupIntroProvider), isFalse);
    await Future<void>.delayed(
      StartupIntro.fallback + const Duration(milliseconds: 50),
    );
    expect(alone.read(startupIntroProvider), isTrue);
  });
}
