import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/features/auth/presentation/screens/splash_screen.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'écran de démarrage est purement présentationnel : il n'a rien à décider,
/// c'est le garde du router qui le quitte. Ce qui peut malgré tout mal se
/// passer tient en deux points, et ce sont ceux éprouvés ici.
///
///  1. **Le réglage système « réduire les animations » est respecté.** Une
///     marque qui se trace pendant 2,6 secondes devant quelqu'un qui a
///     demandé l'inverse est au mieux désagréable, au pire un déclencheur.
///  2. **L'animation se termine et ne laisse rien tourner.** Un minuteur qui
///     survit à l'écran est une fuite que seul un test de widget attrape ;
///     `pumpAndSettle` échouerait ici si la marque bouclait.
void main() {
  Widget app({bool reduceMotion = false}) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const SplashScreen(),
      ),
    ),
  );

  testWidgets('trace la marque puis s’immobilise', (tester) async {
    await tester.pumpWidget(app());

    expect(find.byType(EventMark), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Échouerait sur une animation qui boucle ou un minuteur laissé actif.
    await tester.pumpAndSettle();
    expect(find.byType(EventMark), findsOneWidget);
  });

  testWidgets('montre la marque achevée quand les animations sont réduites', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump();

    final mark = tester.widget<EventMark>(find.byType(EventMark));
    expect(
      mark.progress.value,
      1.0,
      reason:
          'le tracé doit être complet dès la première frame, sans attendre '
          'les 2,6 secondes de l’animation',
    );
  });
}
