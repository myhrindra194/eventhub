import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:eventhub/features/events/presentation/widgets/event_layout_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La bascule liste / grille : son état, sa sémantique et sa persistance.
///
/// La persistance passe par le vrai `SharedPreferences`, alimenté en mémoire
/// par `setMockInitialValues` : c'est le câblage réel du contrôleur — lecture
/// différée au démarrage, écriture à chaque choix — qu'on veut prouver, pas
/// un double qui le contournerait.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Center(child: EventLayoutToggle())),
        ),
      ),
    );
    // Laisse aboutir la lecture différée des préférences.
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('liste par défaut ; un appui passe en grille et le persiste', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = await pump(tester);

    expect(container.read(eventLayoutControllerProvider), EventLayout.rows);

    await tester.tap(find.byTooltip(EventLayoutCopy.grid));
    await tester.pumpAndSettle();

    expect(container.read(eventLayoutControllerProvider), EventLayout.grid);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(EventLayoutController.storageKey), 'grid');

    await tester.tap(find.byTooltip(EventLayoutCopy.rows));
    await tester.pumpAndSettle();
    expect(container.read(eventLayoutControllerProvider), EventLayout.rows);
    expect(prefs.getString(EventLayoutController.storageKey), 'rows');
  });

  testWidgets('restaure la disposition enregistrée au lancement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      EventLayoutController.storageKey: 'grid',
    });
    final container = await pump(tester);

    expect(container.read(eventLayoutControllerProvider), EventLayout.grid);
  });

  testWidgets('une valeur stockée inconnue retombe sur la liste', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      EventLayoutController.storageKey: 'mosaic',
    });
    final container = await pump(tester);

    expect(container.read(eventLayoutControllerProvider), EventLayout.rows);
  });

  testWidgets('chaque segment annonce son libellé et son état', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(EventLayoutCopy.rows)),
      matchesSemantics(
        label: EventLayoutCopy.rows,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(EventLayoutCopy.grid)),
      matchesSemantics(
        label: EventLayoutCopy.grid,
        isButton: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
