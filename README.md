# EventHub

> Application mobile Flutter de découverte et de réservation d'événements.
> Deux rôles, un parcours de bout en bout : un **organisateur** publie un
> événement, un **participant** le découvre et réserve une place, l'organisateur
> voit le participant dans sa liste. Cahier des charges :
> `EVENTHUB — Cahier des charges MVP.pdf`. Maquettes Figma : `im/`.

[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3-6366F1)
![Firebase](https://img.shields.io/badge/Firebase-Auth_·_Firestore_·_Storage-FFCA28?logo=firebase&logoColor=black)
![Tests](https://img.shields.io/badge/tests-26_passing-10B981)

---

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Démarrage rapide](#2-démarrage-rapide)
   - [Mode simulation (sans Firebase)](#21-mode-simulation-sans-firebase)
   - [Mode Firebase](#22-mode-firebase)
   - [Émulateurs Firebase](#23-émulateurs-firebase)
3. [Stack technique](#3-stack-technique)
4. [Architecture](#4-architecture)
   - [Arborescence](#41-arborescence)
   - [Règle de dépendance](#42-règle-de-dépendance)
   - [Flux d'une action](#43-flux-dune-action)
   - [Gestion des erreurs](#44-gestion-des-erreurs)
   - [Session d'authentification](#45-session-dauthentification)
   - [Navigation et guards](#46-navigation-et-guards)
5. [Modèle de données](#5-modèle-de-données)
6. [Règles métier](#6-règles-métier)
7. [Sécurité Firestore et Storage](#7-sécurité-firestore-et-storage)
8. [Design system](#8-design-system)
9. [Écrans et correspondance maquette](#9-écrans-et-correspondance-maquette)
10. [Configuration, flavors et variables](#10-configuration-flavors-et-variables)
11. [Qualité : lint, tests, CI](#11-qualité--lint-tests-ci)
12. [Commandes](#12-commandes)
13. [Scénario de démonstration](#13-scénario-de-démonstration)
14. [Décisions d'architecture (ADR)](#14-décisions-darchitecture-adr)
15. [Périmètre : ce qui est fait, ce qui ne l'est pas](#15-périmètre--ce-qui-est-fait-ce-qui-ne-lest-pas)
16. [Dépannage](#16-dépannage)
17. [Contribuer](#17-contribuer)

---

## 1. Vue d'ensemble

| Rôle             | Peut                                                                                   |
|------------------|----------------------------------------------------------------------------------------|
| **Participant**  | créer un compte, se connecter, parcourir / rechercher / filtrer les événements, voir le détail, réserver une place, annuler, consulter ses billets |
| **Organisateur** | créer un compte, se connecter, créer / modifier / supprimer ses événements, consulter la liste des participants de chaque événement |

Le MVP est réputé fonctionnel lorsque le scénario suivant se déroule sans
intervention manuelle dans les données (cahier des charges §12) :

```
Organisateur crée un événement
  → l'événement apparaît dans le catalogue
  → un participant le consulte
  → le participant réserve une place
  → la réservation est enregistrée et les places disponibles décrémentées
  → l'organisateur voit le participant dans la liste des réservations
```

Le projet est livré avec **deux backends interchangeables** derrière les mêmes
interfaces de repository :

- **Firebase** (Auth, Cloud Firestore, Storage) pour la production ;
- **Mock en mémoire** pour développer, démontrer et tester l'UI sans projet
  Firebase, activé par `--dart-define=MOCK=true`.

---

## 2. Démarrage rapide

Prérequis : Flutter 3.47+ (Dart 3.13), un appareil ou émulateur Android,
`make` (Git Bash / WSL sous Windows) ou les commandes `flutter` équivalentes.

```sh
git clone <repo> eventhub && cd eventhub
make setup          # flutter pub get + génération de code (freezed, riverpod, json)
flutter devices     # récupérer l'id de l'appareil
```

### 2.1 Mode simulation (sans Firebase)

C'est le mode à utiliser tant que le projet Firebase n'est pas créé. Aucune
configuration n'est nécessaire : tous les repositories sont servis par
`MockStore` (voir `lib/core/mock/`).

**Bascule automatique** : en flavor `dev` ou `staging`, si
`lib/firebase_options.dart` n'a pas été généré, `bootstrap()` détecte l'échec
d'initialisation de Firebase et bascule seul sur le backend simulé (un
avertissement est journalisé). Un simple `flutter run` suffit donc :

```sh
flutter run -d <id>                     # dev → simulation automatique sans Firebase
make run-mock DEVICE=<id>               # simulation forcée (même avec Firebase configuré)
# équivalent : flutter run -d <id> --dart-define=FLAVOR=dev --dart-define=MOCK=true
```

En flavor `prod`, aucune bascule : l'écran « Firebase non configuré » s'affiche
pour ne jamais livrer une production sur des données factices.

Comptes de démonstration (mot de passe commun : `demo123`) :

| Rôle          | Email                | Contenu pré-chargé                                         |
|---------------|----------------------|------------------------------------------------------------|
| Participant   | `jean@demo.com`      | aucune réservation, catalogue de 9 événements              |
| Organisateur  | `mirindra@demo.com`  | 5 événements dont *Flutter Meetup Madagascar* (100 places) |
| Organisateur  | `elie@demo.com`      | 4 événements dont un complet et un « dernières places »    |

L'écran de connexion affiche ces comptes en mode simulation : un tap remplit
le formulaire. Les données vivent en mémoire et sont réinitialisées à chaque
lancement. Le jeu de données couvre tous les états des maquettes : événement
disponible, dernières places (3 restantes), complet, passé, formulaire vide,
liste vide.

Les images d'événements sont servies par `picsum.photos` (réseau requis). Une
image choisie dans le formulaire est conservée en mémoire via une URL
`memory://…` résolue par `EventImage`.

### 2.2 Mode Firebase

Une seule fois par projet Firebase :

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>   # génère lib/firebase_options.dart
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Dans la console Firebase, activer **Authentication → Email/Password**,
**Cloud Firestore** (mode production, les règles du dépôt s'appliquent) et
**Storage**.

Puis :

```sh
make run DEVICE=<id>                  # flavor dev
make run FLAVOR=prod DEVICE=<id>
```

Les fichiers `lib/firebase_options.dart`, `android/app/google-services.json`
et `ios/Runner/GoogleService-Info.plist` sont **ignorés par Git**. Tant que
`flutterfire configure` n'a pas été exécuté, l'application démarre sur un
écran « Firebase non configuré » explicite au lieu de planter
(`lib/firebase_options.dart` est un stub qui lève une `UnsupportedError`).

### 2.3 Émulateurs Firebase

```sh
make emulators                          # firebase emulators:start (Auth 9099, Firestore 8080, Storage 9199, UI 4000)
make run-emu DEVICE=<id>                # --dart-define=USE_EMULATORS=true
```

Sur appareil physique, remplacer `AppConfig.emulatorHost` (`10.0.2.2`, loopback
de l'émulateur Android) par l'IP LAN de la machine.

---

## 3. Stack technique

| Domaine            | Choix                                              | Pourquoi                                                                 |
|--------------------|----------------------------------------------------|--------------------------------------------------------------------------|
| Framework          | Flutter 3.47 / Dart 3.13                           | patterns, records, sealed classes, primary constructors                  |
| État               | Riverpod 3 + `riverpod_generator`                  | providers typés, `keepAlive` explicite, overrides pour les tests         |
| Navigation         | go_router 18                                       | `StatefulShellRoute` par rôle, `redirect` central piloté par la session  |
| Modèles            | freezed 4 + json_serializable                      | immutabilité, `copyWith`, égalité structurelle, DTO ↔ entité             |
| Backend            | firebase_auth, cloud_firestore, firebase_storage   | transactions Firestore pour l'atomicité des réservations                |
| Flux               | rxdart (`switchMap`, `BehaviorSubject`, `TimerStream`) | composition de la session auth + profil, store mock réactif         |
| Persistance locale | shared_preferences                                 | drapeau « onboarding vu » jusqu'à désinstallation                       |
| UI                 | Material 3 dark, `google_fonts` (Inter), `cached_network_image`, `image_picker` | tokens Figma, cache d'images, upload de bannière |
| Qualité            | `flutter_lints` + règles strictes, `riverpod_lint`, `mocktail`, GitHub Actions | analyse sans warning, tests unitaires + widget |

---

## 4. Architecture

Architecture **feature-first** avec quatre couches par feature. Détails et
justifications dans [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), conventions
d'équipe dans [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md), langage visuel et
décisions de design dans [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md),
modèle de menace et règles serveur dans [`docs/SECURITY.md`](docs/SECURITY.md),
et feuille de route fonctionnelle dans [`docs/ROADMAP.md`](docs/ROADMAP.md).

### 4.1 Arborescence

```
lib/
├── main.dart · main_dev.dart · main_staging.dart · main_prod.dart
├── bootstrap.dart                 séquence de démarrage (Firebase ou mock, handlers d'erreurs, ProviderScope)
├── firebase_options.dart          généré par flutterfire (ignoré par Git ; stub par défaut)
├── app/
│   ├── app.dart                   MaterialApp.router, locale fr_FR, thème clair/sombre, bannière debug désactivée
│   └── theme/                     design system « Aurora » : palette, tokens, espacements,
│                                  typographie, mouvement, ThemeData clair + sombre, ThemeModeController
├── routes/                        AppRoutes (chemins + noms), RouteGuard (politique pure, testée),
│                                  AppPage/AppTransition (motion), AppRouteObserver, appRouterProvider
├── core/
│   ├── config/                    Flavor, AppConfig (MOCK, USE_EMULATORS), Clock injectable
│   ├── errors/                    Failure (sealed), ErrorMapper, FailureException
│   ├── result/                    Result<T> = Ok | Err, guard()
│   ├── firebase/                  providers SDK, noms de collections/champs, TimestampConverter
│   ├── mock/                      MockStore (données de démo) + implémentations mock des repositories
│   ├── l10n/                      AppStrings (FR)
│   ├── utils/ · extensions/       logger, validators, formats de date, helpers de contexte
│   └── widgets/                   bibliothèque de composants (barrel design_system.dart) :
│                                  surfaces, boutons, badges, avatars, jauges, feuilles,
│                                  squelettes, barre de navigation, états vide/erreur/chargement
└── features/
    ├── onboarding/                carrousel de premier lancement (vu une fois, shared_preferences)
    ├── auth/                      inscription 2 étapes, connexion, session, profil, bienvenue
    ├── events/                    catalogue, recherche, détail, formulaire création/édition
    ├── reservations/              réservation transactionnelle, confirmation, mes billets
    ├── organizer/                 shell organisateur, dashboard, participants, événement publié
    └── participant/               shell participant (Explorer · Recherche · Billets · Profil)
        └── <feature>/
            ├── domain/            entités freezed, policies (règles métier), interfaces de repositories
            ├── data/              DTOs, data sources Firestore/Storage, implémentations
            ├── application/       providers et contrôleurs Riverpod (cas d'usage)
            └── presentation/      écrans et widgets
```

### 4.2 Règle de dépendance

```
presentation ──▶ application ──▶ domain ◀── data
                                    ▲
                                    └── core/mock (implémentations de démo)
```

- `domain` ne dépend que de `core/result` et `core/errors`. Ni Flutter, ni
  Firebase : `TimeOfDayValue` existe pour ne pas importer `material.dart`.
- `data` et `core/mock` implémentent les interfaces du domaine. Seule `data`
  importe les SDK Firebase.
- `application` compose les repositories en providers. Les contrôleurs
  exposent `Future<Result<T>>` **et** reflètent l'état en cours dans un
  `AsyncValue`, ce qui permet à l'écran d'attendre le résultat et d'afficher
  chargement/erreur avec le même objet.
- `presentation` consomme des providers, jamais un repository.
- Une feature n'importe jamais la couche `data` d'une autre feature.

### 4.3 Flux d'une action

Exemple : le participant appuie sur « Réserver ma place ».

```
EventDetailScreen
  └─ ref.read(reservationControllerProvider.notifier).reserve(eventId)
       └─ ReservationController._run()          state = AsyncLoading
            └─ ReservationRepository.reserve()  (impl Firebase ou mock)
                 └─ guard(() => dataSource.reserve())
                      └─ Firestore.runTransaction
                           ├─ lit events/{id} et reservations/{id}_{uid}
                           ├─ ReservationPolicy.canReserve(...)   → FailureException si refus
                           ├─ set reservation (status: confirmed)
                           └─ update event.availablePlaces -1
                 ◀─ Result<Reservation>
       ◀─ state = AsyncData | AsyncError(failure)
  └─ switch (result) { Ok → push(confirmation) ; Err → snackbar(failure.message) }
```

Les streams Firestore (`eventByIdProvider`, `myReservationForEventProvider`)
mettent à jour l'écran de détail sans rechargement : le compteur de places
et l'état « Réservé » changent en direct.

### 4.4 Gestion des erreurs

Les repositories **ne lèvent jamais**. Chaque méthode retourne `Result<T>` :

```dart
switch (await repo.reserve(eventId: id, participant: user)) {
  case Ok(:final value):   context.push(confirmationPath(value.id));
  case Err(:final failure): context.showFailure(failure);
}
```

`guard()` est l'unique `try/catch` : il passe toute exception par
`ErrorMapper` qui la convertit en `Failure` scellée :

| Failure               | Origine typique                                              |
|-----------------------|--------------------------------------------------------------|
| `AuthFailure(code)`   | `FirebaseAuthException` (identifiants, email déjà utilisé…)   |
| `NetworkFailure`      | `unavailable`, `deadline-exceeded`, `SocketException`         |
| `PermissionFailure`   | `permission-denied` (règles Firestore)                       |
| `NotFoundFailure`     | document absent                                              |
| `ValidationFailure`   | `EventDraft.validate()` — erreurs par champ                  |
| `BusinessRuleFailure` | `ReservationPolicy` / `EventPolicy` (complet, déjà réservé…) |
| `StorageFailure`      | upload d'image                                               |
| `UnexpectedFailure`   | tout le reste                                                |

À l'intérieur d'une transaction Firestore, une règle refusée est levée sous
forme de `FailureException(failure)` puis dépliée par `guard()`.

### 4.5 Session d'authentification

`authSessionProvider` (kept alive) expose un type scellé :

Un **onboarding** de trois écrans est affiché au tout premier lancement
(`OnboardingSeen`, persisté avec `shared_preferences`). Il ne réapparaît plus
ensuite, y compris après déconnexion ou mise à jour ; seule une
désinstallation réinitialise ce drapeau.

| État                          | Signification                                              | Redirection                 |
|-------------------------------|------------------------------------------------------------|-----------------------------|
| `SignedOut`                   | pas d'utilisateur Firebase                                 | `/login`                    |
| `SignedIn(AppUser)`           | utilisateur Firebase **et** document `users/{uid}` présent | accueil du rôle             |
| `ProfileMissing(uid, email)`  | compte sans document profil (inscription interrompue)      | `/complete-profile`         |

Le flux est composé avec `switchMap` : un changement d'utilisateur Firebase
annule l'abonnement au profil précédent. Un **délai de grâce**
(`AppConfig.profileGracePeriod`, 3 s) absorbe la fenêtre entre
`createUserWithEmailAndPassword` et l'écriture du document profil, sans
quoi chaque inscription passerait fugitivement par `ProfileMissing`.

### 4.6 Navigation et guards

Toute la navigation vit dans **`lib/routes/`**, un dossier autonome dont les
écrans ne connaissent qu'un seul point d'entrée :

```dart
import 'package:eventhub/routes/routes.dart';
```

| Fichier                 | Responsabilité |
|-------------------------|----------------|
| `app_routes.dart`       | Registre des chemins, des noms symboliques et des constructeurs `*Path()`. **Aucun chemin n'est interpolé à la main ailleurs** : changer la forme d'une URL est une modification à un seul fichier |
| `route_guard.dart`      | La politique « qui a le droit de voir quoi », écrite comme une **fonction pure** de `RouteGuardState` → redirection. Donc testable sans arbre de widgets : voir `test/routes/route_guard_test.dart` |
| `route_transitions.dart`| Vocabulaire de mouvement : `AppTransition.sharedAxisX` (navigation latérale), `fadeThrough` (contenus sans lien), `modal` (feuille), `none`. Une route déclare une **intention**, pas une animation |
| `route_observer.dart`   | Télémétrie de navigation — le point de branchement exact pour Analytics ou les breadcrumbs Crashlytics |
| `router_refresh.dart`   | `Listenable` minimal passé à `refreshListenable` |
| `app_router.dart`       | Assemblage : deux `StatefulShellRoute`, les routes feuilles, l'observateur |
| `routes.dart`           | Barrel public |

Le routeur est `keepAlive` : le reconstruire réinitialiserait toute la pile de
navigation. Les changements de session sont donc **poussés** via
`RouterRefresh` plutôt que de provoquer une reconstruction.

Sortir la politique du routeur n'est pas cosmétique : c'est ce qui permet
d'écrire un test par règle d'autorisation (démarrage à froid, premier
lancement, profil incomplet, confinement des rôles) sans démarrer
l'application.

| Situation                                  | Redirection              |
|--------------------------------------------|--------------------------|
| session ou préférences inconnues (démarrage à froid) | reste sur `/splash` |
| premier lancement de l'installation        | `/onboarding` puis `/login` |
| déconnecté sur une route privée            | `/login`                 |
| connecté sur `/login`                      | accueil du rôle          |
| connecté juste après `/register`           | `/welcome` (« Tout est prêt ! »), puis accueil après 3 s |
| participant sur `/organizer/*`             | `/events`                |
| organisateur hors `/organizer/*`           | `/organizer/events`      |

Deux `StatefulShellRoute` (participant : 4 onglets, organisateur : 2 onglets)
conservent une pile par onglet. Les écrans plein écran (détail, formulaire,
confirmation) sont poussés sur le navigateur racine, au-dessus de la barre.

---

## 5. Modèle de données

```
users/{uid}
  name, email, role ∈ {participant, organizer}, createdAt

events/{id}
  title, description, imageUrl?, category, startsAt (Timestamp),
  location, capacity, availablePlaces, organizerId, organizerName,
  createdAt, updatedAt

reservations/{eventId}_{userId}
  eventId, userId, organizerId, userName, userEmail,
  eventTitle, eventStartsAt, eventLocation,
  status ∈ {confirmed, cancelled}, reservedAt, cancelledAt?
```

Décisions :

- **`startsAt` unique** au lieu de `date` + `time` séparés (cahier des charges
  §6) : tri exact, requête « à venir », règle « déjà commencé ». L'entité
  `Event` expose `date` et `time` en lecture.
- **Id de réservation déterministe** `eventId_userId` : l'unicité « une
  réservation par participant et par événement » devient une propriété du
  stockage, vérifiable dans la transaction **et** dans les règles.
- **Dénormalisation** des champs utilisateur et événement sur la réservation :
  « Mes billets » et la liste des participants se rendent en une requête, et
  survivent à la suppression d'un événement.
- **`organizerId` copié sur la réservation** : la requête « participants de
  mon événement » est prouvable par les règles Firestore sans `get()` par
  document.

Index composites (`firebase/firestore.indexes.json`) : `events(organizerId,
startsAt desc)`, `reservations(userId, reservedAt desc)`,
`reservations(eventId, organizerId, status, reservedAt desc)`.

---

## 6. Règles métier

Les règles du cahier des charges (§4.4, §7) sont des **policies pures** du
domaine, testées unitairement, évaluées **dans la transaction Firestore**
(deux réservations simultanées de la dernière place ne peuvent pas toutes
deux réussir) et **rejouées côté serveur** par `firestore.rules`.

| Règle                                              | Client (domaine)                                      | Serveur (règles)                                  |
|----------------------------------------------------|-------------------------------------------------------|---------------------------------------------------|
| Une réservation par participant et par événement   | `ReservationPolicy.canReserve` + id déterministe      | `reservationId == eventId + '_' + uid`            |
| Pas de réservation sur un événement complet        | `ReservationPolicy.canReserve` (`event.isFull`)       | `availablePlaces >= 0` après décrément            |
| Pas de réservation après le début                  | `ReservationPolicy.canReserve` (`hasStarted(now)`)    | —                                                 |
| Places disponibles mises à jour à chaque réservation | `FieldValue.increment(±1)` dans la transaction      | participant : seuls `availablePlaces` et `updatedAt`, variation de ±1 |
| Ré-réservation possible après annulation           | réservation `cancelled` → autorisée                   | `update` avec `status ∈ {confirmed, cancelled}`   |
| Organisateur modifie/supprime ses seuls événements | `EventPolicy.canManage`                               | `existing().organizerId == uid`                   |
| Capacité jamais inférieure aux réservations        | `EventPolicy.availablePlacesAfterCapacityChange` (transaction) | bornes `0 ≤ availablePlaces ≤ capacity` |
| Rôle immuable, un seul rôle                        | `UserRole` sur `AppUser`                              | `update` autorisé sur `name` uniquement           |
| Événement supprimé non réservable                  | suppression physique, réservations conservées        | `delete` réservé au propriétaire                  |

---

## 7. Sécurité Firestore et Storage

Les règles sont **le seul contrôle qui s'exécute réellement** : l'application
Flutter est une commodité, n'importe qui peut appeler l'API directement avec
une charge utile fabriquée. Chaque invariant de
`lib/features/*/domain/policies` est donc répliqué côté serveur.

Les huit garanties, en résumé :

1. `role` et `email` d'un profil sont **immuables** — aucune escalade de
   privilège possible ;
2. seul un organisateur crée un événement, seul son propriétaire le modifie ;
3. `availablePlaces` reste dans `[0, capacity]`, et un participant ne le
   déplace que d'exactement **une** place ;
4. la capacité ne descend jamais sous les places déjà vendues ;
5. une réservation par (événement, participant), garantie **structurellement**
   par l'identifiant déterministe `<eventId>_<uid>` ;
6. les champs dénormalisés d'une réservation doivent correspondre à
   l'événement dont ils sont copiés — pas de billet forgé ;
7. les horodatages sont contrôlés côté serveur (`request.time`) ;
8. tout ce qui n'est pas explicitement autorisé est **refusé**.

Le rôle est résolu **par custom claim en priorité**
(`request.auth.token.role`, gratuit et infalsifiable), avec repli sur le
document `users/{uid}` tant que la Cloud Function n'est pas déployée.
`isAdmin()` est exclusivement un claim : aucun document ne permet de se
promouvoir.

⚠️ **Point à connaître** : les règles exigent `request.query.limit`, donc une
requête sans `.limit()` est refusée. C'est pourquoi les data sources portent
`maxPageSize` (100 événements, 200 réservations) — et pourquoi la pagination
réelle est une tâche identifiée de la feuille de route.

Côté Storage : propriété par le chemin, images matricielles uniquement
(**`image/svg+xml` exclu volontairement** — c'est du balisage exécutable),
plafonds 5 Mo / 2 Mo, préfixe `private/` fermé à tout client.

Le modèle de menace complet, les transitions d'état autorisées, le régime des
horodatages et les limites connues sont détaillés dans
[`docs/SECURITY.md`](docs/SECURITY.md).

---

## 8. Design system

L'interface implémente le fichier Figma **Eventhub** (exports dans `im/`).
Le produit est **dark-only**.

| Token            | Valeur    | Usage                                     |
|------------------|-----------|-------------------------------------------|
| `background`     | `#0B0D10` | fond d'écran                              |
| `surface`        | `#14171C` | cartes, champs                            |
| `surfaceLight`   | `#1E2229` | chips, boutons secondaires, tuiles d'icône |
| `accent`         | `#6366F1` | actions principales, sélection, liens     |
| `textPrimary`    | `#F3F4F6` | titres, corps                             |
| `textSecondary`  | `#9CA3AF` | légendes, sous-titres                     |
| `success`        | `#10B981` | disponible, confirmé, en ligne            |
| `error`          | `#EF4444` | complet, annulé, suppression              |
| `warning`        | `#F59E0B` | dernières places                          |

Typographie **Inter** (via `google_fonts`) : Display 40/800, H1 28/700,
H2 22/700, H3 18/700, Body Large 16, Body 14, Caption 11 majuscules espacées.
Rayons : cartes 16 px, boutons et champs 12 px, pills 20 px.

Le design system complet — tokens, composants et **les décisions derrière
eux** — est documenté dans [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

En résumé : aucune valeur hexadécimale n'existe hors de
`app/theme/app_palette.dart` ; les rampes brutes deviennent des tokens
sémantiques (`AppTokens`, une `ThemeExtension`) que les widgets consomment via
`context.tokens`. C'est cette indirection qui rend le **thème clair** possible
sans toucher un seul widget : on échange deux instances de tokens, rien
d'autre — et `AppTokens.lerp` fait fondre la bascule au lieu de la claquer.

Les composants partagés sont exposés par le barrel
`lib/core/widgets/design_system.dart` : `AppScaffold`, `AppSurface`,
`AppButton`, `AppBadge`, `AppAvatar`, `CapacityMeter`, `StatTile`,
`AppNavBar`, `Skeleton`, `showConfirmSheet`, `EmptyStateView`…

---

## 9. Écrans et correspondance maquette

| Planche Figma                          | Écran                                | Route                                  |
|----------------------------------------|--------------------------------------|----------------------------------------|
| P00 Splash                             | `SplashScreen`                       | `/splash`                              |
| Onboarding (3 écrans, une seule fois)  | `OnboardingScreen`                   | `/onboarding`                          |
| A01 Login (défaut/focus/erreur/loading)| `LoginScreen`                        | `/login`                               |
| A02 Register (compte → rôle)           | `RegisterScreen`                     | `/register`                            |
| A02 Success « You're all set »         | `WelcomeScreen`                      | `/welcome`                             |
| Mot de passe oublié (+ confirmation)   | `ForgotPasswordScreen`               | `/forgot-password`                     |
| P01 Explore (+ loading, + empty)       | `EventListScreen`                    | `/events`                              |
| P02 Search                             | `EventSearchScreen`                  | `/search`                              |
| P04 Event details — Available          | `EventDetailScreen`                  | `/events/:id`                          |
| P04 — Selling fast (≤ 3 places)        | idem, bouton ambre                   |                                        |
| P04 — Sold out                         | idem, image assombrie, CTA désactivé |                                        |
| P04 — Reserved                         | idem, carte billet + Annuler         |                                        |
| P05 Booking confirmed                  | `ReservationConfirmationScreen`      | `/reservations/:id/confirmation`       |
| P06 My tickets (+ empty)               | `MyReservationsScreen`               | `/reservations`                        |
| Profile                                | `ProfileScreen`                      | `/profile`, `/organizer/profile`       |
| Paramètres (thème, notifications)      | `SettingsScreen`                     | `/profile/settings`, `/organizer/profile/settings` |
| O01 My events (+ empty)                | `OrganizerDashboardScreen`           | `/organizer/events`                    |
| O02 Create event                       | `EventFormScreen`                    | `/organizer/events/new`                |
| O03 Edit event                         | `EventFormScreen(eventId)`           | `/organizer/events/:id/edit`           |
| O02 Success « Event is live »          | `EventPublishedScreen`               | `/organizer/events/:id/published`      |
| O04 Delete                             | `showDestructiveSheet`               | bottom sheet                           |
| O05 Participants                       | `EventParticipantsScreen`            | `/organizer/events/:id/participants`   |
| Complete profile (récupération)        | `CompleteProfileScreen`              | `/complete-profile`                    |

---

## 10. Configuration, flavors et variables

| `--dart-define` | Valeurs                  | Effet                                                        |
|-----------------|--------------------------|--------------------------------------------------------------|
| `FLAVOR`        | `dev` (défaut), `staging`, `prod` | nom d'app, bannière debug, valeurs par défaut         |
| `MOCK`          | `true`                   | backend mémoire forcé (dev et staging) ; automatique si Firebase absent |
| `USE_EMULATORS` | `true`                   | Auth/Firestore/Storage vers la suite d'émulateurs (dev)      |

Points d'entrée : `main.dart` (lit `FLAVOR`), `main_dev.dart`,
`main_staging.dart`, `main_prod.dart`. Configurations VS Code prêtes dans
`.vscode/launch.json` (dev, dev + émulateurs, staging, prod profile ; ajouter
`--dart-define=MOCK=true` aux `args` pour la simulation).

`AppConfig` est injecté dans `ProviderScope` par `bootstrap()` ; le provider
par défaut lève volontairement une erreur pour qu'un oubli soit visible
immédiatement.

---

## 11. Qualité : lint, tests, CI

- **Analyse** : `flutter_lints` + `strict-casts`, `strict-inference`,
  `strict-raw-types` et des règles supplémentaires (`unawaited_futures`,
  `prefer_final_locals`, `require_trailing_commas`…). Objectif : zéro issue.
- **Tests Dart** (`make test`, **38 tests**) :
  - domaine : `ReservationPolicy`, `EventPolicy`, `EventDraft.validate`,
    getters d'`Event` ;
  - core : `Result`, `guard`, dépliage de `FailureException` ;
  - **routage** : `RouteGuard` — 15 cas couvrant démarrage à froid, premier
    lancement, profil incomplet, confinement des rôles, encodage des chemins.
    Possible parce que la politique est une fonction pure : aucun arbre de
    widgets n'est monté ;
  - widget : `LoginScreen` avec `ProviderScope` + `mocktail`.
- **Tests de règles** (`make test-rules`, **70 tests**) : suite Node dans
  `firebase/tests/`, exécutée contre les émulateurs Firestore et Storage avec
  `@firebase/rules-unit-testing`. Chaque test pilote l'émulateur via le SDK
  client avec des charges utiles fabriquées à la main — comme le ferait un
  attaquant. Les sept cas prioritaires sont marqués `[P-n]`. Détail dans
  [`docs/SECURITY.md`](docs/SECURITY.md) §10.

  ```bash
  make rules-setup   # une seule fois (npm install)
  make test-rules    # démarre les émulateurs, exécute, les arrête
  ```

- **CI** (`.github/workflows/ci.yml`), trois jobs :
  1. `quality` — `pub get` → `build_runner` → `dart format
     --set-exit-if-changed` → `flutter analyze` → `flutter test --coverage` ;
  2. `rules` — émulateurs + suite de règles. Aucun secret requis :
     l'identifiant `demo-eventhub` dispense de credentials, donc le job passe
     aussi sur un fork ;
  3. `android` — APK debug sur `push` (config Firebase depuis les secrets
     `FIREBASE_OPTIONS_DART` / `GOOGLE_SERVICES_JSON` en base64, sinon stub).

À ajouter : tests d'intégration des data sources contre l'émulateur, golden
tests des écrans, et les tests de règles des sous-collections anticipées
(`favorites`, `waitlist`, `checkins`…) — à écrire **en même temps** que la
fonctionnalité qui les consomme.

---

## 12. Commandes

| Commande               | Rôle                                                       |
|------------------------|------------------------------------------------------------|
| `make setup`           | `flutter pub get` + génération de code                     |
| `make gen` / `make watch` | `build_runner` (freezed, riverpod, json) une fois / en continu |
| `make analyze`         | `flutter analyze --no-pub`                                 |
| `make format`          | `dart format lib test`                                     |
| `make test` / `make test-cov` | tests, avec couverture                              |
| `make run DEVICE=<id> [FLAVOR=prod]` | lancer avec Firebase                         |
| `make run-mock DEVICE=<id>` | lancer en simulation (sans Firebase)                  |
| `make run-emu DEVICE=<id>`  | lancer contre les émulateurs                          |
| `make build-apk [FLAVOR=prod]` | APK release                                        |
| `make emulators`       | `firebase emulators:start`                                 |
| `make firebase-deploy` | déployer règles et index Firestore + règles Storage        |
| `make clean`           | `flutter clean`                                            |

Après toute modification d'un fichier annoté `@freezed`, `@riverpod` ou
`@JsonSerializable`, relancer `make gen`. Les fichiers générés sont commités.

---

## 13. Scénario de démonstration

Reprend le cahier des charges §9. En mode simulation, l'organisateur est
`mirindra@demo.com`, le participant `jean@demo.com`.

1. **Organisateur** : connexion → « Mes événements » → « + » → *Flutter Meetup
   Madagascar*, capacité 100, date et lieu → **Publier** → écran « Événement
   publié ! ».
2. **Participant** : déconnexion, connexion → l'événement apparaît dans
   « Explorer » → recherche « Flutter » → détail (badge *Disponible*, 100 / 100
   places) → **Réserver ma place** → « Réservation confirmée ! ».
3. Le compteur passe de **100 → 99** en direct sur le détail et dans le
   catalogue ; le billet apparaît dans « Billets » avec le statut *Confirmée*.
4. **Organisateur** : dashboard → carte de l'événement affiche **1/100** →
   « Participants » → *Jean Rakoto*, email, date de réservation.

Variantes visibles avec les données de démo : *Late Night Jazz Session*
(3 places, bouton ambre « Réserver les dernières places »), *Pulse Festival*
(complet), *Atelier UX Mobile* (passé), annulation d'une réservation via la
carte billet du détail.

---

## 14. Décisions d'architecture (ADR)

| # | Décision | Alternatives | Motivation |
|---|----------|--------------|------------|
| 1 | Firebase Storage pour les images, derrière `ImageStorageRepository` | Supabase Storage (tableau de suivi T-12) | une seule console, une seule auth, un seul jeu de règles ; l'interface permet de basculer sans toucher aux features |
| 2 | Transaction Firestore côté client + règles serveur | Cloud Function `reserve` | pas de backend à déployer pour le MVP ; l'atomicité est garantie par la transaction, l'intégrité par les règles |
| 3 | Id de réservation déterministe | id auto + requête d'unicité | l'unicité devient structurelle et vérifiable par les règles |
| 4 | `Result<T>` + `Failure` scellée | exceptions | erreurs exhaustives au `switch`, pas de `try/catch` dans l'UI |
| 5 | Session scellée avec `ProfileMissing` + délai de grâce | booléen connecté | gère proprement l'inscription interrompue sans flicker |
| 6 | Recherche et filtre côté client | index full-text (Algolia) | catalogue petit ; remplaçable dans `filteredEventsProvider` |
| 7 | Backend mock activable par `dart-define` | fixtures Firestore | démonstrations et tests d'UI sans projet Firebase, même code d'écran |
| 8 | Dark-only | thème clair + sombre | la maquette Figma est un système sombre ; pas de dette de contraste |
| 9 | Textes en français dans `AppStrings` | ARB / `flutter_localizations` | cahier des charges en français ; migration mécanique vers ARB si besoin |

---

## 15. Périmètre : ce qui est fait, ce qui ne l'est pas

**Fait** : tout le cahier des charges MVP (§3 à §8), les 11 écrans plus les
écrans additionnels de la maquette (recherche, profil, bienvenue, événement
publié), les 4 états du détail, les états vides / chargement / erreur, la
réinitialisation de mot de passe, les règles et index Firestore, le mode
simulation, les tests et la CI.

**Écarts assumés avec la maquette Figma** (hors cahier des charges §10) :

| Élément de la maquette            | État                                                       |
|-----------------------------------|------------------------------------------------------------|
| Bouton « Continue with Google »   | non implémenté (nécessite SHA-1 et config OAuth)           |
| Prix des événements (`$89.00`)    | remplacé par « Gratuit » (pas de paiement dans le MVP)     |
| Cœur / favoris                    | non implémenté (hors MVP)                                  |
| « Add to calendar », « Share »    | non implémentés                                            |
| Export CSV de la liste des invités | non implémenté                                            |
| Onglets organisateur Stats / Alerts | réduits à Événements / Profil                            |
| Revenu dans les statistiques      | remplacé par « Restantes »                                 |
| Textes anglais                    | traduits en français                                       |

---

## 16. Dépannage

| Symptôme | Cause / correctif |
|----------|-------------------|
| Écran « Firebase non configuré » | n'apparaît qu'en flavor `prod` ; en dev la simulation prend le relais. Sinon lancer `flutterfire configure` |
| Revoir l'onboarding | désinstaller puis réinstaller l'application (`adb uninstall com.example.eventhub`) |
| `Gradle version … lower than minimum` / `AGP` / `Kotlin` | le projet exige Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 (déjà configurés dans `android/`) |
| `INSTALL_FAILED_USER_RESTRICTED` sur Xiaomi/Redmi | activer « Installation via USB » dans les options développeur, accepter la fenêtre sur le téléphone |
| `part 'xxx.g.dart' not found` | `make gen` |
| `appConfigProvider must be overridden` dans un test | ajouter `appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev))` au `ProviderScope` |
| Images de démo absentes | `picsum.photos` nécessite le réseau ; le placeholder s'affiche sinon |
| Requête Firestore refusée `permission-denied` | déployer les règles, vérifier que `users/{uid}.role` existe |
| Requête Firestore « requires an index » | déployer `firestore.indexes.json` |

---

## 17. Contribuer

Branches par tâche du tableau de suivi (`feat/T-31-recherche-evenements`),
commits **Conventional Commits** en anglais, PR vers `develop` avec CI verte
et une review. Definition of Done et détails dans
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md).

```sh
git checkout -b feat/T-xx-sujet
make gen && make analyze && make test
git commit -m "feat(events): …"
```
