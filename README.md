# EventHub

> Application mobile Flutter de découverte et de réservation d'événements.
> Deux rôles, un parcours de bout en bout : un **organisateur** publie un
> événement, un **participant** le découvre, réserve une place et présente son
> billet ; l'organisateur suit ses réservations en direct. Cahier des charges :
> `EVENTHUB — Cahier des charges MVP.pdf`. Maquettes Figma : `im/`.

[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3-6366F1)
![Firebase](https://img.shields.io/badge/Firebase-Auth_·_Firestore_·_Storage-FFCA28?logo=firebase&logoColor=black)
![Tests](https://img.shields.io/badge/tests_Dart-68_passing-10B981)
![Rules](https://img.shields.io/badge/tests_règles-110_passing-10B981)

---

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Fonctionnalités](#2-fonctionnalités)
3. [Démarrage rapide](#3-démarrage-rapide)
4. [Stack technique](#4-stack-technique)
5. [Architecture](#5-architecture)
6. [Modèle de données](#6-modèle-de-données)
7. [Règles métier](#7-règles-métier)
8. [Sécurité Firestore et Storage](#8-sécurité-firestore-et-storage)
9. [Design system](#9-design-system)
10. [Écrans, routes et correspondance maquette](#10-écrans-routes-et-correspondance-maquette)
11. [Configuration, flavors et variables](#11-configuration-flavors-et-variables)
12. [Qualité : lint, tests, CI](#12-qualité--lint-tests-ci)
13. [Commandes](#13-commandes)
14. [Scénario de démonstration](#14-scénario-de-démonstration)
15. [Décisions d'architecture (ADR)](#15-décisions-darchitecture-adr)
16. [Périmètre : ce qui est fait, ce qui ne l'est pas](#16-périmètre--ce-qui-est-fait-ce-qui-ne-lest-pas)
17. [Dépannage](#17-dépannage)
18. [Contribuer](#18-contribuer)

Documentation détaillée : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
(référence technique), [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)
(langage visuel et décisions), [`docs/SECURITY.md`](docs/SECURITY.md) (modèle
de menace et règles serveur), [`docs/ROADMAP.md`](docs/ROADMAP.md) (feuille de
route), [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) (conventions d'équipe).

---

## 1. Vue d'ensemble

| Rôle             | En une phrase |
|------------------|---------------|
| **Participant**  | découvre les événements, réserve une place en un geste, garde son billet (QR code) dans l'application |
| **Organisateur** | publie ses événements, suit leur remplissage et leurs réservations en direct, exporte sa liste d'invités |

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
  Firebase, activé par `--dart-define=MOCK=true` (ou automatiquement en dev si
  Firebase n'est pas configuré).

---

## 2. Fonctionnalités

### 2.1 Communes aux deux rôles

| Fonctionnalité | Détail | Où dans le code |
|---|---|---|
| Onboarding | 3 écrans au tout premier lancement, jamais revus ensuite | `features/onboarding/` |
| Inscription | 2 étapes (identité → rôle), jauge de robustesse du mot de passe, rôle **définitif** | `auth/presentation/screens/register_screen.dart` |
| Connexion | email + mot de passe ; comptes de démo pré-remplissables en mode simulation | `login_screen.dart` |
| Mot de passe oublié | envoi du lien + écran de confirmation | `forgot_password_screen.dart` |
| Changer le mot de passe | ré-authentification par le mot de passe actuel | `change_password_screen.dart` |
| Profil récupérable | un compte sans document profil est guidé vers `/complete-profile` | `complete_profile_screen.dart` |
| Profil | identité, statistiques du rôle, menu compte et aide | `profile_screen.dart` |
| **Modifier mon profil** | seul le **nom** est modifiable ; email et rôle affichés verrouillés, avec la raison | `edit_profile_screen.dart` |
| Paramètres | thème clair / sombre / automatique (persisté), préférences de notification (UI) | `settings_screen.dart` |
| **Centre d'aide** | FAQ par moment d'usage (réserver, organiser, compte) + contact support | `features/support/` |
| **Confidentialité** | notice écrite d'après le vrai modèle de données et les vraies règles | `features/support/` |
| **À propos** | principes du produit, version, environnement, backend actif | `features/support/` |

### 2.2 Participant — onglets Explorer · Recherche · Billets · Profil

| Fonctionnalité | Détail |
|---|---|
| Fil éditorialisé | « À la une », « Ça se remplit vite », « Cette semaine », catalogue complet, rail de catégories |
| Recherche | titre, lieu, organisateur, catégorie |
| Filtres avancés | période, tri, masquer les complets, compteur de filtres actifs (feuille modale) |
| Fiche événement | 4 états : disponible, dernières places (≤ 3), complet, déjà réservé ; jauge de capacité en direct |
| **Partager** | feuille de partage : copier le lien public `eventhub.app/e/<id>` ou une invitation texte prête à coller |
| Réserver / annuler | transaction atomique ; ré-réservation possible après annulation |
| Confirmation | écran « Réservation confirmée ! » |
| Mes billets | portefeuille segmenté À venir / Passés / Annulés, pastille sur l'onglet quand un billet est à venir |
| **Billet** | QR code noir sur blanc, code court `EH-XXXX-XXXX` à lire à voix haute, champs date / heure / lieu / titulaire, états annulé et passé, copier le code |

### 2.3 Organisateur — onglets Événements · Stats · Alertes · Profil

| Fonctionnalité | Détail |
|---|---|
| Mes événements | KPI (à venir, participants, remplissage), bascule à venir / passés, actions par carte |
| Créer / modifier | formulaire avec bannière (image), validation par champ, capacité jamais sous les places vendues |
| Événement publié | écran de succès avec **lien public copiable** et partage |
| Supprimer | feuille de confirmation destructive |
| Participants | recherche par nom ou email, compteurs, **export CSV** (séparateur `;`, copié dans le presse-papiers) |
| **Stats** | remplissage global (chiffre-héros), réservations, 7 derniers jours, annulations, complets ; histogramme des réservations sur 14 jours avec **vue tableau** ; classement des événements à venir par remplissage |
| **Alertes** | « À surveiller » (commence dans moins de 24 h, dernières places, complet) + journal des réservations et annulations groupé par jour ; pastille sur l'onglet tant qu'une alerte est ouverte |

---

## 3. Démarrage rapide

Prérequis : Flutter 3.47+ (Dart 3.13), un appareil ou émulateur Android,
`make` (Git Bash / WSL sous Windows) ou les commandes `flutter` équivalentes.

```sh
git clone <repo> eventhub && cd eventhub
make setup          # flutter pub get + génération de code (freezed, riverpod, json)
flutter devices     # récupérer l'id de l'appareil
```

### 3.1 Mode simulation (sans Firebase)

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

| Rôle          | Email                | Contenu pré-chargé |
|---------------|----------------------|--------------------|
| Participant   | `jean@demo.com`      | aucune réservation, catalogue de 10 événements |
| Organisateur  | `mirindra@demo.com`  | 6 événements dont *Flutter Meetup Madagascar* (100 places) et *Design Sprint Express* (commence dans 20 h, 2 places), **13 réservations** d'invités fictifs dont une annulation — les onglets Stats et Alertes ont du contenu dès le premier lancement |
| Organisateur  | `elie@demo.com`      | 4 événements dont un complet et un « dernières places » |

Les données vivent en mémoire et sont réinitialisées à chaque lancement. Le jeu
de données couvre tous les états des maquettes : disponible, dernières places,
complet, passé, formulaire vide, liste vide, billet annulé.

Les images d'événements sont des photos **Unsplash** (réseau requis) ; sans
réseau, `EventImage` affiche un dégradé déterministe dérivé de l'id. Une image
choisie dans le formulaire est conservée en mémoire via une URL `memory://…`.

### 3.2 Mode Firebase

Une seule fois par projet Firebase :

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>   # génère lib/firebase_options.dart
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Dans la console Firebase, activer **Authentication → Email/Password**,
**Cloud Firestore** (mode production, les règles du dépôt s'appliquent) et
**Storage**. Déployer les index **avant** d'ouvrir les onglets Stats et
Alertes : la requête `reservations(organizerId, reservedAt desc)` en dépend.

Puis :

```sh
make run DEVICE=<id>                  # flavor dev
make run FLAVOR=prod DEVICE=<id>
```

Les fichiers `lib/firebase_options.dart`, `android/app/google-services.json`
et `ios/Runner/GoogleService-Info.plist` sont **ignorés par Git**.

### 3.3 Émulateurs Firebase

```sh
make emulators                          # firebase emulators:start (Auth 9099, Firestore 8080, Storage 9199, UI 4000)
make run-emu DEVICE=<id>                # --dart-define=USE_EMULATORS=true
```

Sur appareil physique, remplacer `AppConfig.emulatorHost` (`10.0.2.2`, loopback
de l'émulateur Android) par l'IP LAN de la machine.

---

## 4. Stack technique

| Domaine            | Choix                                              | Pourquoi |
|--------------------|----------------------------------------------------|----------|
| Framework          | Flutter 3.47 / Dart 3.13                           | patterns, records, sealed classes |
| État               | Riverpod 3 + `riverpod_generator`                  | providers typés, `keepAlive` explicite, overrides pour les tests |
| Navigation         | go_router 18                                       | `StatefulShellRoute` par rôle, `redirect` central piloté par la session |
| Modèles            | freezed 4 + json_serializable                      | immutabilité, `copyWith`, égalité structurelle, DTO ↔ entité |
| Backend            | firebase_auth, cloud_firestore, firebase_storage   | transactions Firestore pour l'atomicité des réservations |
| Flux               | rxdart (`switchMap`, `BehaviorSubject`, `TimerStream`) | composition session auth + profil, store mock réactif |
| Persistance locale | shared_preferences                                 | onboarding vu, thème choisi |
| UI                 | Material 3 clair + sombre, `google_fonts` (Plus Jakarta Sans + Inter), `cached_network_image`, `image_picker` | tokens, cache d'images, upload de bannière |
| Billet             | `qr_flutter`                                       | QR code scannable généré localement, sans service externe |
| Qualité            | `flutter_lints` + règles strictes, `riverpod_lint`, `mocktail`, `@firebase/rules-unit-testing`, GitHub Actions | analyse sans warning, tests unitaires, widget, golden et règles |

---

## 5. Architecture

Architecture **feature-first**, en couches par feature. Référence technique
complète : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

### 5.1 Arborescence

```
lib/
├── main.dart · main_dev.dart · main_staging.dart · main_prod.dart
├── bootstrap.dart                 séquence de démarrage (Firebase ou mock, handlers d'erreurs, ProviderScope)
├── firebase_options.dart          généré par flutterfire (ignoré par Git ; stub par défaut)
├── app/
│   ├── app.dart                   MaterialApp.router, locale fr_FR, thème clair/sombre
│   └── theme/                     design system « Aurora » : palette, tokens, espacements et rayons,
│                                  typographie, mouvement, ThemeData, ThemeModeController
├── routes/                        AppRoutes (chemins + noms + builders), RouteGuard (politique pure, testée),
│                                  AppPage/AppTransition, AppRouteObserver, appRouterProvider
├── core/
│   ├── config/                    Flavor, AppConfig (MOCK, USE_EMULATORS), Clock injectable, AppLinks (liens publics)
│   ├── errors/                    Failure (sealed), ErrorMapper, FailureException
│   ├── result/                    Result<T> = Ok | Err, guard()
│   ├── firebase/                  providers SDK, noms de collections/champs, TimestampConverter
│   ├── mock/                      MockStore (données de démo) + implémentations mock des repositories
│   ├── l10n/                      AppStrings (FR)
│   ├── utils/ · extensions/       logger, validators, formats de date, helpers de contexte
│   └── widgets/                   bibliothèque de composants (barrel design_system.dart)
└── features/
    ├── onboarding/                carrousel de premier lancement
    ├── auth/                      inscription, connexion, session, profil, modification du profil,
    │                              paramètres, mot de passe (oubli, changement)
    ├── events/                    catalogue, recherche, filtres, fiche, formulaire, feuille de partage
    ├── reservations/              réservation transactionnelle, confirmation, portefeuille, billet QR
    ├── organizer/                 shell 4 onglets, dashboard, stats, alertes, participants + export,
    │   ├── domain/                  événement publié ; calculs purs : OrganizerStats, OrganizerAlerts,
    │   └── application/             GuestListCsv ; providers dérivés (organizer_providers.dart)
    ├── participant/               shell participant (Explorer · Recherche · Billets · Profil)
    └── support/                   centre d'aide, confidentialité, à propos (présentation seule)
        └── <feature>/
            ├── domain/            entités freezed, policies, calculs purs, interfaces de repositories
            ├── data/              DTOs, data sources Firestore/Storage, implémentations
            ├── application/       providers et contrôleurs Riverpod (cas d'usage)
            └── presentation/      écrans et widgets
```

Une feature n'a que les couches dont elle a besoin : `support/` n'est que de
la présentation, `organizer/` n'a pas de `data/` car il compose les
repositories d'`events` et de `reservations`.

### 5.2 Règle de dépendance

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
  `AsyncValue`.
- `presentation` consomme des providers, jamais un repository.
- Une feature n'importe jamais la couche `data` d'une autre feature.

### 5.3 Flux d'une action

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
  └─ switch (result) { Ok → push(confirmation) ; Err → toast(failure.message) }
```

Les streams Firestore mettent à jour sans rechargement la fiche, le
portefeuille, et côté organisateur les onglets Stats et Alertes : une
réservation apparaît dans le journal de l'organisateur au moment où le
participant la confirme.

### 5.4 Gestion des erreurs

Les repositories **ne lèvent jamais**. Chaque méthode retourne `Result<T>` :

```dart
switch (await repo.reserve(eventId: id, participant: user)) {
  case Ok(:final value):    context.push(confirmationPath(value.id));
  case Err(:final failure): context.showFailure(failure);
}
```

`guard()` est l'unique `try/catch` : il passe toute exception par
`ErrorMapper` qui la convertit en `Failure` scellée :

| Failure               | Origine typique |
|-----------------------|-----------------|
| `AuthFailure(code)`   | `FirebaseAuthException` (identifiants, email déjà utilisé…) |
| `NetworkFailure`      | `unavailable`, `deadline-exceeded`, `SocketException` |
| `PermissionFailure`   | `permission-denied` (règles Firestore) |
| `NotFoundFailure`     | document absent |
| `ValidationFailure`   | `EventDraft.validate()` — erreurs par champ |
| `BusinessRuleFailure` | `ReservationPolicy` / `EventPolicy` (complet, déjà réservé…) |
| `StorageFailure`      | upload d'image |
| `UnexpectedFailure`   | tout le reste |

### 5.5 Session d'authentification

`authSessionProvider` (kept alive) expose un type scellé :

| État                          | Signification | Redirection |
|-------------------------------|---------------|-------------|
| `SignedOut`                   | pas d'utilisateur Firebase | `/login` |
| `SignedIn(AppUser)`           | utilisateur Firebase **et** document `users/{uid}` présent | accueil du rôle |
| `ProfileMissing(uid, email)`  | compte sans document profil (inscription interrompue) | `/complete-profile` |

Le flux est composé avec `switchMap` : un changement d'utilisateur Firebase
annule l'abonnement au profil précédent. Un **délai de grâce**
(`AppConfig.profileGracePeriod`, 3 s) absorbe la fenêtre entre la création du
compte et l'écriture du profil. Une modification du nom repasse par ce même
flux : aucun écran n'a à rafraîchir l'utilisateur.

### 5.6 Navigation et guards

Toute la navigation vit dans **`lib/routes/`** ; les écrans n'importent que
`package:eventhub/routes/routes.dart`.

| Fichier                 | Responsabilité |
|-------------------------|----------------|
| `app_routes.dart`       | Registre des chemins, des noms et des constructeurs `*Path()`. **Aucun chemin n'est interpolé à la main ailleurs** |
| `route_guard.dart`      | « Qui a le droit de voir quoi », écrit comme une **fonction pure** → testable sans widget |
| `route_transitions.dart`| `sharedAxisX`, `fadeThrough`, `modal`, `none` : une route déclare une intention, pas une animation |
| `route_observer.dart`   | Télémétrie de navigation (point de branchement Analytics / Crashlytics) |
| `router_refresh.dart`   | `Listenable` minimal passé à `refreshListenable` |
| `app_router.dart`       | Assemblage : deux `StatefulShellRoute`, routes feuilles, observateur |

| Situation                                  | Redirection |
|--------------------------------------------|-------------|
| session ou préférences inconnues (démarrage à froid) | reste sur `/splash` |
| premier lancement de l'installation        | `/onboarding` puis `/login` |
| déconnecté sur une route privée            | `/login` |
| connecté sur `/login`                      | accueil du rôle |
| connecté juste après `/register`           | `/welcome` |
| participant sur `/organizer/*`             | `/events` |
| organisateur hors `/organizer/*`           | `/organizer/events` |
| pages communes (`/welcome`, `/change-password`, `/account/edit`, `/help`, `/privacy`, `/about`) | accessibles aux deux rôles |

Deux `StatefulShellRoute` à 4 onglets conservent une pile par onglet. Les
écrans plein écran (fiche, billet, formulaire, participants, pages d'aide)
sont poussés sur le navigateur racine, au-dessus de la barre.

---

## 6. Modèle de données

```
users/{uid}
  name, email, role ∈ {participant, organizer}, createdAt, updatedAt?

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

- **`startsAt` unique** au lieu de `date` + `time` séparés : tri exact, requête
  « à venir », règle « déjà commencé ».
- **Id de réservation déterministe** `eventId_userId` : l'unicité « une
  réservation par participant et par événement » devient une propriété du
  stockage.
- **Dénormalisation** des champs utilisateur et événement sur la réservation :
  portefeuille et liste des participants en une requête, qui survivent à la
  suppression d'un événement. Un changement de nom ne réécrit pas les billets
  passés.
- **`organizerId` copié sur la réservation** : les requêtes de l'organisateur
  (par événement, et toutes ses réservations pour les stats) sont prouvables
  par les règles.
- **Code billet dérivé, pas stocké** : `Reservation.ticketCode` est un hachage
  FNV-1a de l'id, stable sur toutes les plateformes.
- **Statistiques dérivées côté client** : aucun document agrégé ; tout est
  calculé depuis les flux d'événements et de réservations déjà ouverts.

Index composites utilisés par l'application (`firebase/firestore.indexes.json`) :
`events(organizerId, startsAt desc)`, `reservations(userId, reservedAt desc)`,
`reservations(eventId, organizerId, status, reservedAt desc)`,
`reservations(organizerId, reservedAt desc)`. Le fichier en déclare d'autres,
anticipés pour la feuille de route.

---

## 7. Règles métier

Les règles du cahier des charges sont des **policies pures** du domaine,
testées unitairement, évaluées **dans la transaction Firestore** et
**rejouées côté serveur** par `firestore.rules`.

| Règle | Client (domaine) | Serveur (règles) |
|---|---|---|
| Une réservation par participant et par événement | `ReservationPolicy.canReserve` + id déterministe | `reservationId == eventId + '_' + uid` |
| Pas de réservation sur un événement complet | `ReservationPolicy.canReserve` (`event.isFull`) | `availablePlaces >= 0` après décrément |
| Pas de réservation après le début | `ReservationPolicy.canReserve` (`hasStarted(now)`) | réservation refusée après `startsAt` |
| Places mises à jour à chaque réservation | `FieldValue.increment(±1)` dans la transaction | participant : `availablePlaces` et `updatedAt` seulement, ±1 |
| Ré-réservation possible après annulation | réservation `cancelled` → autorisée | `status ∈ {confirmed, cancelled}` |
| Organisateur : ses seuls événements | `EventPolicy.canManage` | `existing().organizerId == uid` |
| Capacité jamais sous les réservations | `EventPolicy.availablePlacesAfterCapacityChange` | bornes `0 ≤ availablePlaces ≤ capacity` |
| Rôle et email immuables, nom modifiable | `AuthRepository.updateProfile(name)` | `onlyChanged(['name', 'photoUrl', 'bio', 'updatedAt'])` |
| On ne liste que ses propres réservations | requêtes filtrées sur `userId` ou `organizerId` | la règle `list` exige que la requête le prouve |
| Dernières places / commence bientôt (alertes) | `OrganizerAlerts` : ≤ 3 places, < 24 h | — (affichage seul) |

---

## 8. Sécurité Firestore et Storage

Les règles sont **le seul contrôle qui s'exécute réellement** : n'importe qui
peut appeler l'API avec une charge utile fabriquée. Chaque invariant du
domaine est donc répliqué côté serveur.

Les garanties, en résumé :

1. `role` et `email` d'un profil sont **immuables** ;
2. seul un organisateur crée un événement, seul son propriétaire le modifie ;
3. `availablePlaces` reste dans `[0, capacity]`, un participant ne le déplace
   que d'**une** place ;
4. la capacité ne descend jamais sous les places déjà vendues ;
5. une réservation par (événement, participant), **structurellement** ;
6. les champs dénormalisés d'une réservation correspondent à l'événement ;
7. les horodatages sont contrôlés côté serveur ;
8. une **liste** de réservations n'est servie que si la requête prouve que
   chaque document appartient à l'appelant (participant ou organisateur) ;
9. tout ce qui n'est pas explicitement autorisé est **refusé**.

> ⚠️ **Correctif récent (garantie 8).** La règle `list` des réservations ne
> vérifiait que la borne `limit <= 200` : une requête bornée sans filtre
> renvoyait les listes d'invités de tout le monde, noms et emails compris.
> Elle exige maintenant `userId == uid()` ou `organizerId == uid()`, et deux
> tests de règles le vérifient. **À redéployer** (`make firebase-deploy`) sur
> tout projet existant.

Les requêtes `list` doivent porter un `.limit()` (100 événements, 200
réservations), sans quoi les règles les refusent — d'où la pagination prévue
en feuille de route. Côté Storage : propriété par le chemin, images matricielles
uniquement (SVG exclu), plafonds de taille, préfixe `private/` fermé.

Détails : [`docs/SECURITY.md`](docs/SECURITY.md).

---

## 9. Design system

Le design system **« Aurora »** part des maquettes Figma (`im/`) mais ne les
copie pas au pixel : les tokens et la structure viennent de Figma, le rendu a
été retravaillé pour paraître dessiné à la main plutôt que sorti d'un gabarit.

- **Thème clair et sombre** (automatique par défaut, choix persisté). Les deux
  sont le même code exécuté sur deux jeux de tokens (`AppTokens`,
  `ThemeExtension`), et la bascule est animée.
- **Aucune valeur hexadécimale** hors de `app/theme/app_palette.dart` : les
  widgets lisent `context.tokens`.
- **Rayons : 6 px** pour tout ce qu'on touche ou remplit (boutons, champs,
  puces, bouton ✕) et pour les **feuilles modales**, qui n'ont **pas de
  poignée** mais un bouton de fermeture explicite.
- **Typographie** : Plus Jakarta Sans (titres) + Inter (interface) ; chiffres
  tabulaires pour les colonnes de nombres.
- **Graphiques** : une série = une teinte, marques fines, étiquettes sélectives,
  vue tableau équivalente.

Composants partagés via `lib/core/widgets/design_system.dart` : `AppScaffold`,
`AppSurface`, `AppButton`, `AppBadge`, `AppAvatar`, `CapacityMeter`,
`StatTile`, `AppNavBar`, `FieldGroup`, `Skeleton`, `showAppSheet` /
`AppSheet` / `showConfirmSheet` / `SheetCloseButton`, `EmptyStateView`…

Tout le détail — tokens, composants et **les décisions derrière eux** — est
dans [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

---

## 10. Écrans, routes et correspondance maquette

| Planche Figma / besoin                 | Écran | Route |
|----------------------------------------|-------|-------|
| P00 Splash                             | `SplashScreen` | `/splash` |
| Onboarding (une seule fois)            | `OnboardingScreen` | `/onboarding` |
| A01 Login                              | `LoginScreen` | `/login` |
| A02 Register (compte → rôle)           | `RegisterScreen` | `/register` |
| A02 Success « You're all set »         | `WelcomeScreen` | `/welcome` |
| Mot de passe oublié                    | `ForgotPasswordScreen` | `/forgot-password` |
| Changer le mot de passe                | `ChangePasswordScreen` | `/change-password` |
| Profil incomplet (récupération)        | `CompleteProfileScreen` | `/complete-profile` |
| P01 Explore (+ loading, + empty)       | `EventListScreen` | `/events` |
| P02 Search                             | `EventSearchScreen` | `/search` |
| P04 Event details (4 états)            | `EventDetailScreen` + feuille de partage | `/events/:eventId` |
| P05 Booking confirmed                  | `ReservationConfirmationScreen` | `/reservations/:reservationId/confirmation` |
| P06 My tickets (+ empty)               | `MyReservationsScreen` | `/reservations` |
| P04 Reserved — « View Ticket »         | `TicketScreen` | `/reservations/:reservationId/ticket` |
| Profile                                | `ProfileScreen` | `/profile`, `/organizer/profile` |
| Paramètres                             | `SettingsScreen` | `/profile/settings`, `/organizer/profile/settings` |
| Modifier mon profil                    | `EditProfileScreen` | `/account/edit` |
| Centre d'aide · Confidentialité · À propos | `HelpCenterScreen` · `PrivacyScreen` · `AboutScreen` | `/help` · `/privacy` · `/about` |
| O01 My events (+ empty)                | `OrganizerDashboardScreen` | `/organizer/events` |
| Barre organisateur — Stats             | `OrganizerStatsScreen` | `/organizer/stats` |
| Barre organisateur — Alerts            | `OrganizerAlertsScreen` | `/organizer/alerts` |
| O02 Create event                       | `EventFormScreen` | `/organizer/events/new` |
| O03 Edit event                         | `EventFormScreen(eventId)` | `/organizer/events/:eventId/edit` |
| O02 Success « Event is live »          | `EventPublishedScreen` (+ lien public) | `/organizer/events/:eventId/published` |
| O04 Delete                             | `showConfirmSheet` | feuille modale |
| O05 Participants (+ export)            | `EventParticipantsScreen` | `/organizer/events/:eventId/participants` |

---

## 11. Configuration, flavors et variables

| `--dart-define` | Valeurs | Effet |
|-----------------|---------|-------|
| `FLAVOR`        | `dev` (défaut), `staging`, `prod` | nom d'app, valeurs par défaut |
| `MOCK`          | `true` | backend mémoire forcé (dev et staging) ; automatique si Firebase absent |
| `USE_EMULATORS` | `true` | Auth/Firestore/Storage vers la suite d'émulateurs (dev) |

Points d'entrée : `main.dart` (lit `FLAVOR`), `main_dev.dart`,
`main_staging.dart`, `main_prod.dart`. Configurations VS Code dans
`.vscode/launch.json`.

`AppConfig` est injecté dans `ProviderScope` par `bootstrap()` ; le provider
par défaut lève volontairement une erreur pour qu'un oubli soit visible
immédiatement. Les adresses publiques (lien d'événement, email support) sont
centralisées dans `core/config/app_links.dart`.

---

## 12. Qualité : lint, tests, CI

- **Analyse** : `flutter_lints` + `strict-casts`, `strict-inference`,
  `strict-raw-types` et règles supplémentaires. Objectif : zéro issue.
- **Tests Dart** (`make test`, **68 tests**) :
  - domaine : `ReservationPolicy`, `EventPolicy`, `EventDraft.validate`,
    getters d'`Event`, **code billet** (format, stabilité, unicité),
    **export CSV** (en-tête, échappement, CRLF), **statistiques et alertes
    organisateur** (remplissage, fenêtre de 14 jours, annulations, classement,
    watchlist, journal) ;
  - core : `Result`, `guard`, dépliage de `FailureException` ;
  - **routage** : `RouteGuard` — démarrage à froid, premier lancement, profil
    incomplet, confinement des rôles, pages communes, billet réservé aux
    participants, stats/alertes réservées aux organisateurs ;
  - widget et golden : `LoginScreen`, écrans d'authentification, démarrage.
- **Tests de règles** (`make test-rules`, **110 tests**) : suite Node
  dans `firebase/tests/`, exécutée contre les émulateurs Firestore et Storage
  avec `@firebase/rules-unit-testing`, charges utiles fabriquées à la main
  comme le ferait un attaquant. Nécessite Java.

  ```bash
  make rules-setup   # une seule fois (npm install)
  make test-rules    # démarre les émulateurs, exécute, les arrête
  ```

- **CI** (`.github/workflows/ci.yml`) : `quality` (format, analyse, tests,
  couverture), `rules` (émulateurs + suite de règles, sans secret), `android`
  (APK debug).

À ajouter : tests d'intégration des data sources contre l'émulateur, tests
widget des nouveaux écrans (billet, stats, alertes).

---

## 13. Commandes

| Commande               | Rôle |
|------------------------|------|
| `make setup`           | `flutter pub get` + génération de code |
| `make gen` / `make watch` | `build_runner` une fois / en continu |
| `make analyze`         | `flutter analyze --no-pub` |
| `make format`          | `dart format lib test` |
| `make test` / `make test-cov` | tests, avec couverture |
| `make rules-setup` / `make test-rules` | dépendances puis tests des règles de sécurité |
| `make run DEVICE=<id> [FLAVOR=prod]` | lancer avec Firebase |
| `make run-mock DEVICE=<id>` | lancer en simulation |
| `make run-emu DEVICE=<id>`  | lancer contre les émulateurs |
| `make build-apk [FLAVOR=prod]` | APK release |
| `make emulators`       | `firebase emulators:start` |
| `make firebase-deploy` | déployer règles et index Firestore + règles Storage |
| `make clean`           | `flutter clean` |

Après toute modification d'un fichier annoté `@freezed`, `@riverpod` ou
`@JsonSerializable`, relancer `make gen`. Les fichiers générés sont commités.

---

## 14. Scénario de démonstration

En mode simulation, l'organisateur est `mirindra@demo.com`, le participant
`jean@demo.com` (mot de passe `demo123`).

1. **Organisateur** : connexion → onglet **Alertes** : *Design Sprint Express*
   commence dans 20 h et n'a plus que 2 places ; le journal liste les
   réservations des derniers jours et une annulation. Onglet **Stats** :
   remplissage global, histogramme sur 14 jours (touchez une colonne, ou
   passez en vue « Tableau »), classement des événements.
2. **Organisateur** : « Mes événements » → « + » → *Flutter Meetup Madagascar
   2*, capacité 100, date et lieu → **Publier** → écran « Événement publié ! »
   → **Copier** le lien public.
3. **Participant** : déconnexion, connexion → l'événement apparaît dans
   « Explorer » → recherche « Flutter » → fiche (100 / 100 places) →
   **Partager** (copier une invitation) → **Réserver ma place** →
   « Réservation confirmée ! ».
4. Le compteur passe de **100 → 99** en direct. « Billets » → touchez le
   billet : **QR code** et code `EH-XXXX-XXXX`.
5. **Organisateur** : l'onglet **Alertes** affiche « Jean Rakoto a réservé » ;
   « Mes événements » → « Participants » → **Exporter la liste** (CSV copié).

Variantes visibles : *Late Night Jazz Session* (3 places, bouton ambre),
*Pulse Festival* (complet), *Atelier UX Mobile* (passé), annulation depuis la
fiche puis billet affiché « annulé ». Côté compte : Profil → « Modifier mon
profil », « Centre d'aide », « Confidentialité », « À propos ».

---

## 15. Décisions d'architecture (ADR)

| # | Décision | Alternatives | Motivation |
|---|----------|--------------|------------|
| 1 | Firebase Storage pour les images, derrière `ImageStorageRepository` | Supabase Storage | une seule console, une seule auth, un seul jeu de règles |
| 2 | Transaction Firestore côté client + règles serveur | Cloud Function `reserve` | pas de backend à déployer pour le MVP ; atomicité par la transaction, intégrité par les règles |
| 3 | Id de réservation déterministe | id auto + requête d'unicité | unicité structurelle, vérifiable par les règles |
| 4 | `Result<T>` + `Failure` scellée | exceptions | erreurs exhaustives au `switch`, pas de `try/catch` dans l'UI |
| 5 | Session scellée avec `ProfileMissing` + délai de grâce | booléen connecté | gère l'inscription interrompue sans clignotement |
| 6 | Recherche et filtre côté client | index full-text (Algolia) | catalogue petit ; remplaçable dans `filteredEventsProvider` |
| 7 | Backend mock activable par `dart-define` | fixtures Firestore | démos et tests d'UI sans projet Firebase, même code d'écran |
| 8 | Thème clair + sombre par tokens | dark-only | même code sur deux jeux de tokens, aucun widget touché, bascule animée |
| 9 | Textes en français dans `AppStrings` | ARB / `flutter_localizations` | cahier des charges en français ; migration mécanique vers ARB |
| 10 | QR généré localement (`qr_flutter`), code dérivé de l'id | QR signé par Cloud Function | affichage livrable sans backend ; la signature et le scan sont la suite (F-01) |
| 11 | Partage et export par presse-papiers | `share_plus`, fichier via Storage | identique sur Android, iOS, web et desktop, sans configuration native |
| 12 | Statistiques et alertes calculées côté client | agrégats Firestore / Cloud Function | aucune lecture en plus, temps réel gratuit ; limite assumée de 200 réservations |

---

## 16. Périmètre : ce qui est fait, ce qui ne l'est pas

**Fait** : tout le cahier des charges MVP, les écrans des maquettes (y compris
billet, partage, export et les onglets Stats / Alertes de la barre
organisateur), les états vides / chargement / erreur, la gestion du compte,
les pages d'aide, les règles et index Firestore, le mode simulation, les tests
et la CI.

**Écarts assumés avec la maquette Figma** :

| Élément de la maquette | État | Pourquoi |
|---|---|---|
| « Continue with Google » | non implémenté | nécessite empreinte SHA-1, client OAuth et configuration par plateforme |
| « Add to Cal » | non implémenté | nécessite un plugin natif de calendrier ou `url_launcher` + fichier `.ics` |
| « Join Waitlist » (événement complet) | non implémenté | demande un backend (Cloud Function de promotion) ; règles et index déjà prêts (F-06) |
| Cœur / favoris | non implémenté | hors MVP ; règles prêtes (F-05) |
| Billet **vérifiable** | partiel | le QR identifie mais n'est pas signé ; pas encore de scanner organisateur (F-01) |
| Partage natif | partiel | lien et invitation copiés ; pas de feuille système ni de page web publique (F-08) |
| Prix, « Revenue », types de billets | remplacés | pas de paiement dans le MVP (« Gratuit », « Restantes ») |
| Notifications push | UI seulement | les interrupteurs attendent FCM (F-02) |
| Textes anglais | traduits | produit en français |

---

## 17. Dépannage

| Symptôme | Cause / correctif |
|----------|-------------------|
| Écran « Firebase non configuré » | n'apparaît qu'en flavor `prod` ; en dev la simulation prend le relais. Sinon `flutterfire configure` |
| Onglets Stats / Alertes : « requires an index » | déployer `firestore.indexes.json` (index `reservations(organizerId, reservedAt desc)`) |
| `permission-denied` sur une liste de réservations | la requête doit filtrer sur `userId` ou `organizerId` ; redéployer les règles |
| Revoir l'onboarding | désinstaller puis réinstaller (`adb uninstall com.example.eventhub`) |
| `Gradle version … lower than minimum` / `AGP` / `Kotlin` | Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 (déjà configurés) |
| `INSTALL_FAILED_USER_RESTRICTED` sur Xiaomi/Redmi | activer « Installation via USB » dans les options développeur |
| `part 'xxx.g.dart' not found` | `make gen` |
| `appConfigProvider must be overridden` dans un test | ajouter `appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev))` |
| Images de démo absentes | Unsplash nécessite le réseau ; le dégradé de repli s'affiche sinon |
| `make test-rules` échoue au démarrage | Java requis par les émulateurs ; lancer `make rules-setup` une fois |

---

## 18. Contribuer

Branches par tâche (`feat/T-31-recherche-evenements`), commits **Conventional
Commits** en anglais, PR avec CI verte et une review. Definition of Done dans
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md). Toute évolution qui ajoute un
écran, une route, une dépendance ou une règle met à jour **ce README et le
document `docs/` concerné dans la même PR**.

```sh
git checkout -b feat/T-xx-sujet
make gen && make analyze && make test
git commit -m "feat(events): …"
```
