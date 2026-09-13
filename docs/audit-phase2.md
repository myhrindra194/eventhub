# Audit & corrections — Phase 2 (architecture propre)

> Résultat : `flutter analyze --no-pub` → **No issues found**,
> `flutter test` → **10/10 passed**.
> `dart format lib test` appliqué.

## Phase 1 — Bugs bloquants corrigés

| # | Problème | Fichier | Correction |
|---|----------|---------|------------|
| 1 | Filtre catégorie Home toujours vide | `events/data/repositories/event_repository_impl.dart` | Comparaison `model.category` (String Firestore) vs normalisation minuscule |
| 2 | `capacity as int` crashait (Firestore renvoie `double`) | `events/data/models/event_model.dart` | Helper `_asInt` : `num.toInt()` / `int.tryParse` |
| 3 | Réservations 100 % en mémoire (perdues au restart, places non décrémentées) | `reservations/data/datasources/reservation_remote_data_source.dart` | Écriture Firestore + `runTransaction` (contrôle capacité + `currentAttendees`) |
| 4 | `sendPasswordResetEmail` déconnectait visuellement | `auth/presentation/providers/auth_provider.dart` | État restauré + exception relancée à l'appelant |
| 5 | `userRole()` Firestore sans `exists()` (throw) | `firestore.rules` | `exists(...) ? get(...).data.role : ''` |
| 6 | `dart:io File()` incompatible Web | `organizer/.../create_event_screen.dart` | `Uint8List` + `Image.memory` uniquement |
| 7 | `CircleAvatar` / `participant['name'][0]` crash sur données nulles | `organizer/.../event_participants_screen.dart` | Guards + `onBackgroundImageError` + `try/catch` |
| 8 | `Supabase.instance.client` throw si `.env` absent | `organizer/.../organizer_events_provider.dart` | Client nullable + `EventImageStorageNop` |

## Phase 2 — Architecture propre

### 1. Suppression de la duplication `Event`
- `features/organizer/domain/entities/event.dart` ne contient plus de copie :
  c'est un simple `export '../../../events/domain/entities/event.dart';`.
- **Source unique de vérité** : `features/events/domain/entities/event.dart`
  - `date` : `DateTime` (Firestore `Timestamp`)
  - `status` : `draft | live | completed | cancelled`
  - `capacity` + `currentAttendees` : source de vérité des places
  - Getters d'affichage participant : `month`, `day`, `time`, `displayDate`,
    `availablePlaces`, `isFull`, `formattedPrice`
- Helpers de parsing tolérants : `eventCategoryFromString`,
  `eventStatusFromString` (insensibles à la casse, fallback sûr).

### 2. Temps réel au lieu d'`invalidate()` manuel
- `EventRemoteDataSource.watchPublishedEvents()` + `EventRepository.watchEvents()`
  + `eventsStreamProvider` : le Home reflète immédiatement publication,
  modification des places et suppression.
- `eventDetailProvider` ne re-télécharge plus toute la collection :
  `EventRemoteDataSource.getEventById()` fait un seul `doc().get()`.

### 3. Frontière de données Firestore
- L'organisateur reçoit les mêmes helpers de conversion (`clamp` sur
  `currentAttendees`, parsing `num`), plus de `as int` non protégé.
- `getEventParticipants` vérifie que l'événement appartient à l'organisateur
  (sinon liste vide trompeuse).

### 4. Règles Firestore réellement fonctionnelles
> Bug critique : la transaction de réservation met à jour
> `events.currentAttendees`, mais `allow update` n'autorisait que
> l'organisateur → **toute réservation échouait avec `permission-denied`**.

- Nouvelle clause `update` participant : uniquement `currentAttendees` +
  `updatedAt`, sur un événement `live`, strictement croissant et
  `<= capacity`.
- `create` événement : `status` whitelisté + `capacity` entier > 0.

### 5. Qualité & outillage
- `firestore.indexes.json` : ajout des index composites
  (`events.organizerId+date`, `events.status+date`,
  `reservations.eventId+reservedAt`, `reservations.userId+reservedAt`).
- Tests mis à jour : mapping modèle→entité, tolérance `double`,
  validation du use case, arguments du router.
- `.env.example` documente l'alternative `--dart-define` (CI).
- `dart format lib test` : 113 fichiers, 17 reformatés.

### 6. Sécurité des secrets
- `.env` est bien ignoré par git (`.gitignore:47`) et **n'est plus suivi** par
  git (`git ls-files` ne renvoie que `.env.example`). Le fichier local reste
  nécessaire en dev.
- En CI/prod, préférer `--dart-define=SUPABASE_URL/...` pour ne jamais
  embarquer de secret dans le bundle.

## Étape 1 — Nettoyage du code mort (fait)

Vérifié par `grep -rn` sur `lib/`, `test/`, `docs/`, `README.md` → **0 référence**.

| Supprimé | Raison |
|----------|--------|
| `lib/features/organizer/presentation/views/organizer_main_screen.dart` | Coquille morte : dupliquait le `Scaffold` + `IndexedStack` + `OrganizerBottomNavBar` déjà présents dans `OrganizerEventsScreen` (utilisé par `AppRouter.organizer`) |
| `lib/features/events/data/models/reservation_model.dart` | Modèle obsolète (enum `ReservationStatus`, `reservedAt`) sans rapport avec le modèle réel de `features/reservations/` ; mauvais propriétaire de feature |
| `lib/core/utils/date_formater.dart` | Fichier vide (1 octet), jamais importé |
| `lib/features/bookings/` | Arborescence vide (`presentation/screens`, `data/models`, `domain/usecases`…) + `.gitkeep`, absente de `docs/architecture.md` |
| `lib/features/profile/` | Arborescence vide : feature planifiée dans `docs/architecture.md` mais **sans aucun code**. À recréer au moment de l'implémenter (voir Étape 6). |
| `lib/features/organizer/data/models/` | Répertoire vide, aucun import, aucun DTO organizer (les `EventModel` vivent dans `features/events/data/models/`) |
| `lib/core/errors/`, `lib/core/network/` | Répertoires vides + `.gitkeep`, jamais utilisés (`AuthFailure` fait déjà office de couche erreurs) |
| `lib/core/constants/` | Répertoire vide + `.gitkeep`, aucune constante globale (elles sont locales aux features) |
| `.gitkeep` orphelins (`core/router`, `core/theme`, `core/utils`, `features/{auth,events,organizer}`) | Dossiers déjà peuplés de vrais fichiers → marqueurs inutiles |

### Arborescence après nettoyage

```text
lib/
├── core/            di  router  theme  utils  widgets
└── features/        auth  events  home  onboarding  organizer  reservations  splash
```

Vérifié : `find lib test -type d -empty` → **aucun**,
`find lib -name .gitkeep` → **aucun**.

Après suppression : `flutter analyze --no-pub` → **No issues found**,
`flutter test` → **10/10 passed**.

## Reste à faire (roadmap)

### Étape 2 — Infrastructure de test (priorité haute)
1. **`mocktail` / `firebase_auth_mocks`** : tester `AuthNotifier`, `EventRepositoryImpl`,
   `ReservationRepositoryImpl` sans Firebase.
2. **`fake_cloud_firestore`** : valider la transaction de réservation
   (contrôle capacité, `currentAttendees`, `sold out`).
3. **`firebase_rules_unit_test`** : tests des règles `firestore.rules`
   (participant ne peut pas modifier un event hors `currentAttendees`,
   organizer ne peut pas créer un event d'un autre `organizerId`).
4. Tests de widgets : `HomeScreen` (filtre catégorie), `MesBilletsScreen`
   (`displayStatus`, `isPast`), `CreateEventScreen` (validation formulaire).

### Étape 3 — DI & testabilité (priorité moyenne)
5. Extraire `Supabase.instance.client` dans un `supabaseClientProvider`
   nullable (le provider organizer fait encore l'appel directement).
6. Mutualiser les requêtes Firestore `events` (`events` + `organizer` ont
   chacun leur `EventRemoteDataSource`).

### Étape 4 — Performance (priorité moyenne)
7. **Pagination** : `limit(20) + startAfter()` sur les listes d'événements.
8. **Cache d'images** : `cached_network_image` pour les `imageUrl`.
9. Ajouter les index composites manquants une fois les requêtes paginées
   stabilisées (vérifier avec `firebase deploy --only firestore:indexes`).

### Étape 5 — CI & release (priorité haute avant merge)
10. **GitHub Actions** : `flutter analyze` + `flutter test` + `dart format --set-exit-if-changed`.
11. **Secrets** : migrer Supabase de `.env` embarqué vers
    `--dart-define=SUPABASE_URL/...` dans le build CI/prod.
12. Déployer les règles : `firebase deploy --only firestore:rules,firestore:indexes`.

### Étape 6 — Fonctionnalités incomplètes (backlog produit)
13. `organizer_alerts_screen.dart` / `organizer_settings_screen.dart` :
    écrans encore statiques.
14. `organizer_stats_screen.dart` : graphiques réels (actuellement agrégats simples).
15. `features/profile/` : à implémenter (édition du nom, déconnexion, switch
    de rôle), puis recréer son arborescence `data/ domain/ presentation/`.

