import 'dart:typed_data';

import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'mock_store.g.dart';

/// In-memory backend used when `--dart-define=MOCK=true`.
///
/// Holds users, events and reservations in `BehaviorSubject`s so the app
/// behaves exactly like Firestore streams (live updates across screens).
/// Seeded with the demo scenario from the spec (§9: "Flutter Meetup
/// Madagascar", 100 seats) plus the events shown on the Figma boards.
class MockStore {
  MockStore({required DateTime now}) : _now = now {
    _seed();
  }

  final DateTime _now;

  /// email -> (user, password)
  final accounts = <String, ({AppUser user, String password})>{};
  final events = BehaviorSubject<List<Event>>.seeded(const []);
  final reservations = BehaviorSubject<List<Reservation>>.seeded(const []);
  final session = BehaviorSubject<AuthSession>.seeded(const SignedOut());
  final images = <String, Uint8List>{};

  Future<void> dispose() async {
    await events.close();
    await reservations.close();
    await session.close();
  }

  static const demoPassword = 'demo123';
  static const demoParticipantEmail = 'jean@demo.com';
  static const demoOrganizerEmail = 'mirindra@demo.com';

  static const _organizer = AppUser(
    id: 'org-mirindra',
    name: 'Mirindra Rakoto',
    email: demoOrganizerEmail,
    role: UserRole.organizer,
  );
  static const _organizer2 = AppUser(
    id: 'org-elie',
    name: 'Elie Andrian',
    email: 'elie@demo.com',
    role: UserRole.organizer,
  );
  static const _participant = AppUser(
    id: 'user-jean',
    name: 'Jean Rakoto',
    email: demoParticipantEmail,
    role: UserRole.participant,
  );

  void _seed() {
    for (final u in [_organizer, _organizer2, _participant]) {
      accounts[u.email] = (user: u, password: demoPassword);
    }

    DateTime at(int days, int hour, [int minute = 0]) =>
        DateTime(_now.year, _now.month, _now.day + days, hour, minute);
    // Curated Unsplash photos so the demo looks like a real product.
    const photos = <String, String>{
      'flutter-meetup-mg': 'photo-1515187029135-18ee286d815b',
      'neon-pulse': 'photo-1470229722913-7c0e2dbbafd3',
      'startup-conf': 'photo-1540575467063-178a50c2df87',
      'jazz-night': 'photo-1415201364774-f6f0bb35f28f',
      'pulse-fest': 'photo-1459749411175-04bf5292ceea',
      'devconf': 'photo-1505373877841-8d25f7d46678',
      'art-gala': 'photo-1460661419201-fd4cecdf8a8b',
      'basket-derby': 'photo-1504450758481-7338eba7524a',
      'ux-workshop': 'photo-1531482615713-2afd69097998',
    };
    String img(String seed) =>
        'https://images.unsplash.com/${photos[seed]}?w=1000&q=80&auto=format&fit=crop';

    Event e({
      required String id,
      required String title,
      required EventCategory category,
      required DateTime startsAt,
      required String location,
      required int capacity,
      required int available,
      required AppUser organizer,
      required String description,
    }) => Event(
      id: id,
      title: title,
      description: description,
      category: category,
      startsAt: startsAt,
      location: location,
      capacity: capacity,
      availablePlaces: available,
      organizerId: organizer.id,
      organizerName: organizer.name,
      imageUrl: img(id),
      createdAt: _now,
      updatedAt: _now,
    );

    events.add([
      e(
        id: 'flutter-meetup-mg',
        title: 'Flutter Meetup Madagascar',
        category: EventCategory.meetup,
        startsAt: at(7, 18, 30),
        location: 'Antananarivo',
        capacity: 100,
        available: 100,
        organizer: _organizer,
        description:
            'Première rencontre de la communauté Flutter à Antananarivo. '
            'Talks, live coding et networking autour de Dart, Riverpod et '
            'Firebase. Ouvert à tous les niveaux.',
      ),
      e(
        id: 'neon-pulse',
        title: 'Neon Pulse Festival',
        category: EventCategory.concert,
        startsAt: at(3, 20),
        location: 'Zénith Paris',
        capacity: 250,
        available: 124,
        organizer: _organizer2,
        description:
            'Une nuit électro immersive avec lasers, scénographie néon et '
            'trois scènes. Line-up international.',
      ),
      e(
        id: 'startup-conf',
        title: 'Startup Conference 2026',
        category: EventCategory.conference,
        startsAt: at(5, 9),
        location: 'Carlton Anosy',
        capacity: 300,
        available: 252,
        organizer: _organizer,
        description:
            'Pitchs, keynotes et ateliers pour fondateurs et investisseurs. '
            'Rencontrez l\'écosystème tech de la Grande Île.',
      ),
      e(
        id: 'jazz-night',
        title: 'Late Night Jazz Session',
        category: EventCategory.concert,
        startsAt: at(4, 22, 30),
        location: 'Blue Note Club',
        capacity: 60,
        available: 3,
        organizer: _organizer2,
        description:
            'Session intimiste avec le quartet de Midnight Jazz. Plus que '
            'quelques places : réservez vite.',
      ),
      e(
        id: 'pulse-fest',
        title: 'Pulse Festival 2026',
        category: EventCategory.concert,
        startsAt: at(9, 19),
        location: 'Central Stadium',
        capacity: 5000,
        available: 0,
        organizer: _organizer2,
        description:
            'Le plus grand festival de l\'année, complet en 48 heures. '
            'Merci à tous !',
      ),
      e(
        id: 'devconf',
        title: 'DevConf Global 2026',
        category: EventCategory.conference,
        startsAt: at(14, 9),
        location: 'Convention Center',
        capacity: 500,
        available: 411,
        organizer: _organizer,
        description:
            'Deux jours de conférences sur le mobile, le cloud et l\'IA. '
            'Sessions en français et en anglais.',
      ),
      e(
        id: 'art-gala',
        title: 'Abstract Visions Art Gala',
        category: EventCategory.culture,
        startsAt: at(12, 18),
        location: 'Modern Art Museum',
        capacity: 120,
        available: 87,
        organizer: _organizer2,
        description:
            'Vernissage privé et rencontre avec les artistes de la '
            'collection Abstract Visions.',
      ),
      e(
        id: 'basket-derby',
        title: 'Paris Basketball vs Lyon',
        category: EventCategory.sport,
        startsAt: at(2, 20),
        location: 'Adidas Arena',
        capacity: 8000,
        available: 1540,
        organizer: _organizer,
        description: 'Le derby de la saison. Ambiance garantie.',
      ),
      e(
        id: 'ux-workshop',
        title: 'Atelier UX Mobile',
        category: EventCategory.workshop,
        startsAt: at(-3, 14),
        location: 'Espace Champerret',
        capacity: 30,
        available: 4,
        organizer: _organizer,
        description: 'Atelier passé : prototypage rapide sur Figma.',
      ),
    ]);
  }
}

@Riverpod(keepAlive: true)
MockStore mockStore(Ref ref) {
  final store = MockStore(now: ref.watch(clockProvider)());
  ref.onDispose(store.dispose);
  return store;
}
