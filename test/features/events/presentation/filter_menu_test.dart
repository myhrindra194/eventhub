import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le menu de filtres remplace l'ancienne bottom sheet : ces tests vérifient
/// que le changement de présentation n'a rien retiré au comportement.
///
/// La liste filtrée est remplacée par une valeur fixe : le menu n'en lit que
/// la longueur pour son compteur de résultats, et monter le vrai catalogue
/// tirerait Firestore dans un test qui ne porte que sur l'interface. Les
/// providers de filtres, eux, restent réels — c'est précisément leur
/// câblage qu'on veut prouver.
void main() {
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [
        filteredEventsProvider.overrideWithValue(
          const AsyncData<List<Event>>([]),
        ),
      ],
    );
    addTearDown(container.dispose);

    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.gutter),
                child: Align(
                  alignment: Alignment.topRight,
                  child: FilterButton(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(FilterButton));
    await tester.pumpAndSettle();
  }

  testWidgets('le bouton ouvre un menu ancré, pas une bottom sheet', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AppStrings.period.toUpperCase()), findsNothing);

    await openMenu(tester);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(AppStrings.period.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.sortBy.toUpperCase()), findsOneWidget);
    expect(find.text(EventPeriod.week.label), findsOneWidget);
    // Rien d'actif : l'action de réinitialisation n'a pas lieu d'être.
    expect(find.text(AppStrings.resetFilters), findsNothing);

    // Le menu se place sous le bouton, pas en travers.
    final button = tester.getRect(find.byType(FilterButton));
    final label = tester.getRect(find.text(AppStrings.period.toUpperCase()));
    expect(label.top, greaterThan(button.bottom));

    // Un second appui sur le bouton referme le menu.
    await tester.tap(find.byType(FilterButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.period.toUpperCase()), findsNothing);
  });

  testWidgets('choisir une option applique le filtre et garde le menu ouvert', (
    tester,
  ) async {
    await pump(tester);
    await openMenu(tester);

    await tester.tap(find.text(EventPeriod.week.label));
    await tester.pumpAndSettle();
    expect(container.read(eventPeriodFilterProvider), EventPeriod.week);

    await tester.tap(find.text(EventSort.alphabetical.label));
    await tester.pumpAndSettle();
    expect(container.read(eventSortOrderProvider), EventSort.alphabetical);

    await tester.tap(find.text(AppStrings.onlyAvailable));
    await tester.pumpAndSettle();
    expect(container.read(hideSoldOutProvider), isTrue);

    // Les réglages s'enchaînent sans rouvrir le menu.
    expect(find.text(AppStrings.period.toUpperCase()), findsOneWidget);
  });

  testWidgets('le bouton affiche le nombre de filtres actifs', (tester) async {
    await pump(tester);
    expect(find.text(AppStrings.filters), findsOneWidget);

    container
        .read(eventCategoryFilterProvider.notifier)
        .select(EventCategory.values.first);
    container
        .read(eventPeriodFilterProvider.notifier)
        .select(EventPeriod.today);
    await tester.pump();

    expect(find.text('${AppStrings.filters} · 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('${AppStrings.filters}, 2 actifs'),
      findsOneWidget,
    );
  });

  testWidgets('Réinitialiser remet tous les filtres à zéro', (tester) async {
    await pump(tester, size: const Size(1280, 900));
    container.read(eventSortOrderProvider.notifier).select(EventSort.dateDesc);
    container.read(hideSoldOutProvider.notifier).set(true);
    await tester.pump();
    expect(find.text('${AppStrings.filters} · 2'), findsOneWidget);

    await openMenu(tester);
    await tester.tap(find.text(AppStrings.resetFilters));
    await tester.pumpAndSettle();

    expect(container.read(activeFilterCountProvider), 0);
    expect(container.read(eventSortOrderProvider), EventSort.dateAsc);
    expect(container.read(hideSoldOutProvider), isFalse);
    expect(find.text(AppStrings.filters), findsWidgets);
    expect(find.text(AppStrings.resetFilters), findsNothing);

    // L'action de droite referme le menu.
    await tester.tap(find.text(AppStrings.applyFilters));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.period.toUpperCase()), findsNothing);
  });
}
