import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/presentation/views/mes_billets_screen.dart';

/// Vérifie que les billets affichent le statut réel de la réservation
/// (bug Phase 1 : 'CONFIRMED' était codé en dur) et la séparation
/// upcoming / past via `isPast`.
void main() {
  Future<void> pumpBillets(
    WidgetTester tester,
    List<Reservation> reservations,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: MesBilletsScreen(reservations: reservations)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche CONFIRMED pour une réservation à venir', (tester) async {
    await pumpBillets(tester, [
      Reservation(
        id: 'r-1',
        eventId: 'event-1',
        eventTitle: 'Tech Meetup',
        date: '20/11/2026 • 18:00',
        status: 'confirmed',
        seatInfo: '2 x GENERAL ACCESS',
        quantity: 2,
      ),
    ]);

    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('CANCELLED'), findsNothing);
  });

  testWidgets('affiche aussi les billets passés sans badge CONFIRMED', (
    tester,
  ) async {
    await pumpBillets(tester, [
      Reservation(
        id: 'r-1',
        eventId: 'event-1',
        eventTitle: 'Tech Meetup',
        date: '20/11/2026 • 18:00',
        status: 'confirmed',
        seatInfo: '2 x GENERAL ACCESS',
      ),
      Reservation(
        id: 'r-2',
        eventId: 'event-2',
        eventTitle: 'Old Meetup',
        date: '10/01/2026 • 10:00',
        status: 'past',
        seatInfo: '1 x GENERAL ACCESS',
      ),
    ]);

    // Le billet à venir porte le badge de statut, le billet passé est rendu
    // dans une carte dédiée (sans badge) mais reste visible.
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('Old Meetup'), findsOneWidget);
  });

  testWidgets('affiche l\'état vide sans réservation', (tester) async {
    await pumpBillets(tester, const []);

    expect(find.text('No Tickets Yet'), findsOneWidget);
  });
}
