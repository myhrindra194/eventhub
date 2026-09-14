# EventHub

> Application mobile Flutter de découverte, de réservation et d'organisation
> d'événements, entièrement adossée à **Firebase** : Authentication (email et
> Google), Cloud Firestore, Cloud Storage, Cloud Messaging, Cloud Functions,
> App Check, Crashlytics et Analytics. Deux rôles, un parcours de bout en
> bout : un **organisateur** publie un événement et contrôle les billets à
> l'entrée ; un **participant** découvre, réserve, garde son billet et reçoit
> ses rappels. Cahier des charges : `EVENTHUB — Cahier des charges MVP.pdf`.

[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3-6366F1)
![Firebase](https://img.shields.io/badge/Firebase-Auth_·_Firestore_·_Storage_·_FCM_·_Functions_·_App_Check-FFCA28?logo=firebase&logoColor=black)
![Tests Dart](https://img.shields.io/badge/tests_Dart-172_passing-10B981)
![Tests règles](https://img.shields.io/badge/tests_règles-138_passing-10B981)
![Tests fonctions](https://img.shields.io/badge/tests_fonctions-29_passing-10B981)

---

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Fonctionnalités](#2-fonctionnalités)
3. [Mise en route](#3-mise-en-route)
4. [Stack technique](#4-stack-technique)
5. [Architecture](#5-architecture)
6. [Modèle de données](#6-modèle-de-données)
7. [Règles métier](#7-règles-métier)
8. [Sécurité](#8-sécurité)
9. [Notifications push](#9-notifications-push)
10. [Production : App Check, Crashlytics, Analytics, hors ligne](#10-production--app-check-crashlytics-analytics-hors-ligne)
11. [Design system](#11-design-system)
12. [Écrans, routes et correspondance maquette](#12-écrans-routes-et-correspondance-maquette)
13. [Configuration](#13-configuration)
14. [Qualité : lint, tests, CI](#14-qualité--lint-tests-ci)
15. [Commandes](#15-commandes)
16. [Scénario de démonstration](#16-scénario-de-démonstration)
17. [Décisions d'architecture (ADR)](#17-décisions-darchitecture-adr)
18. [Périmètre : ce qui est fait, ce qui reste](#18-périmètre--ce-qui-est-fait-ce-qui-reste)
19. [Dépannage](#19-dépannage)
20. [Contribuer](#20-contribuer)

Documentation détaillée : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
(référence technique), [`docs/SECURITY.md`](docs/SECURITY.md) (modèle de
menace, règles, fonctions), [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)
(langage visuel), [`docs/ROADMAP.md`](docs/ROADMAP.md) (feuille de route),
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) (conventions d'équipe).

---

## 1. Vue d'ensemble

| Rôle             | En une phrase |
|------------------|---------------|
| **Participant**  | découvre les événements (dont une sélection « Pour vous »), voit qui y va, en garde en favoris, suit ses organisateurs préférés, réserve une place ou rejoint la liste d'attente, présente son billet QR, laisse un avis après l'événement |
| **Organisateur** | publie ses événements (ses abonnés sont prévenus), soigne son profil public, reçoit une notification à chaque réservation, suit stats et alertes, exporte sa liste d'invités en fichier CSV et scanne les billets à l'entrée |

**Il n'y a pas de backend simulé.** Toutes les données viennent du projet
Firebase `eventhub-d411f` ; le développement local passe par la suite
d'émulateurs, qui exécute les vraies règles.

| Service Firebase | Rôle dans EventHub |
|---|---|
| Authentication | email / mot de passe, **Google**, vérification d'email, réinitialisation, changement de mot de passe |
| Cloud Firestore | profils privés et publics, événements, réservations, favoris, abonnements, liste d'attente, avis, signalements, entrées scannées, appareils, préférences, historique de notifications, agrégats ; cache hors ligne |
| Cloud Storage | bannières d'événements |
| Cloud Messaging | notifications push Android, web (et iOS une fois la clé APNs fournie) |
| Cloud Functions | rôle en custom claim, push organisateur, rappels J-1, liste d'attente, **suppression de compte en cascade**, profils organisateurs publics et compteurs, annonce aux abonnés, preuve sociale, modération, page publique d'événement |
| Hosting | page publique `/e/{id}` avec aperçu Open Graph, vérification des App Links Android |
| App Check | n'accepte que les requêtes de l'application authentique (Play Integrity, App Attest, reCAPTCHA v3) |
| Crashlytics · Analytics | rapports de plantage ; mesure d'audience **sur consentement** |

---

## 2. Fonctionnalités

### 2.1 Compte (les deux rôles)

| Fonctionnalité | Détail |
|---|---|
| Inscription | 2 étapes (identité → rôle définitif), jauge de robustesse, **email de vérification envoyé** |
| Connexion | email + mot de passe, ou **« Continuer avec Google »** (un premier compte Google choisit son rôle sur l'écran de complétion, nom pré-rempli) |
| Vérification d'email | bandeau « Confirmez votre adresse » (profil, tableau de bord organisateur) : renvoi limité à 1/min, « C'est fait » recharge le compte et le jeton. **Obligatoire pour publier un événement et laisser un avis** |
| Mots de passe | oubli (lien Firebase), changement avec ré-authentification |
| Profil | identité, statistiques du rôle, modification du nom (et de la **présentation publique** pour un organisateur) |
| **Profil organisateur public** | `/organizers/{id}`, ouvert depuis la fiche d'un événement : présentation, nombre d'événements, d'abonnés et note moyenne (tous calculés côté serveur), dates à venir puis passées, bouton **Suivre** |
| **Abonnements** | « Organisateurs suivis » : liste, désabonnement ; push à chaque nouvel événement publié par un organisateur suivi |
| **Signalement** | événement, organisateur ou avis : motif dans une liste fermée + précisions ; anonyme ; un signalement par compte et par contenu ; un avis signalé par 3 personnes est masqué en attendant la modération |
| Paramètres | thème ; notifications (préférences réelles lues par le serveur, dont « Nouveaux événements ») ; **mesure d'audience** ; **suppression du compte** (ré-authentification par mot de passe ou Google, cascade côté serveur) |
| Centre de notifications | historique 30 jours des push, groupé par jour, « tout lire », balayage pour supprimer, tap vers l'écran concerné ; cloche à pastille sur l'accueil et les alertes |
| Aide · Confidentialité · À propos | FAQ, notice fondée sur les vraies règles, version |

### 2.2 Participant — Explorer · Recherche · Billets · Profil

| Fonctionnalité | Détail |
|---|---|
| Fil éditorialisé | à la une, **pour vous**, ça se remplit vite, cette semaine, catalogue **paginé** (100 en temps réel, puis « Charger plus ») |
| **Pour vous** | recommandations calculées sur l'appareil : organisateurs suivis (+4), catégories des billets (+3) et des favoris (+2), remplissage pour départager ; jamais un événement complet, commencé, déjà réservé ou déjà en favori |
| Recherche et filtres | titre, lieu, organisateur, catégorie ; période, tri, masquer les complets |
| **Favoris** | cœur sur les cartes et la fiche ; écran « Mes favoris » (y compris événements complets, passés ou supprimés) |
| Fiche événement | 4 états, jauge temps réel, **« Soa, Hery R. et 40 autres y vont »** avec les visages des derniers inscrits, organisateur cliquable, signalement |
| **Partage** | feuille de partage native, lien public `https://eventhub-d411f.web.app/e/{id}` (aperçu Open Graph pour qui n'a pas l'app, ouverture directe dans l'app sur Android), invitation prête à coller |
| Réserver / annuler | transaction atomique ; re-réservation possible |
| **Liste d'attente** | sur un événement complet : rejoindre / quitter ; push dès qu'une place se libère |
| Billet | QR code + code `EH-XXXX-XXXX`, états annulé / passé |
| Rappel J-1 | push la veille, ouvre le billet |
| **Avis** | après le début de l'événement, pour les inscrits vérifiés : note 1–5 et commentaire, modifiable ; moyenne et répartition sur la fiche |

### 2.3 Organisateur — Événements · Stats · Alertes · Profil

| Fonctionnalité | Détail |
|---|---|
| Mes événements | KPI, à venir / passés ; suppression bloquée (avec explication) s'il y a des réservations |
| Créer / modifier | bannière Storage, validation, email vérifié requis pour publier |
| Participants | recherche, **export CSV en fichier** (feuille de partage : Drive, email, tableur ; UTF-8 avec BOM pour Excel, séparateur `;`) ou copie, **compteur d'entrées**, **personnes en liste d'attente**, marqueur « Entré · HH:mm » |
| Profil public | présentation modifiable, abonnés, note moyenne sur les avis visibles ; chaque publication prévient les abonnés |
| **Équipe (co-organisateurs)** | l'organisateur principal invite jusqu'à 10 organisateurs par email ; l'invité accepte ou refuse depuis « Invitations » ; un co-organisateur modifie l'événement, voit les participants, scanne les billets et reçoit les alertes de réservation, mais ne supprime pas l'événement et ne compose pas l'équipe ; il peut la quitter. Les événements co-organisés apparaissent dans le tableau de bord, marqués « Co-organisé » |
| **Contrôle à l'entrée** | scanner caméra (lampe), verdict plein écran en couleur : entrée validée, déjà scanné (heure), billet annulé, autre événement, code invalide, introuvable ; saisie manuelle du code ; retour haptique distinct ; enregistrement anti-doublon même à plusieurs portes |
| Stats · Alertes | remplissage, 14 jours de réservations (graphique + tableau), classement ; à surveiller + journal |
| Push | réservation et annulation en temps réel |

### 2.4 Administration (compte avec le rôle `admin`, quel que soit son rôle métier)

| Fonctionnalité | Détail |
|---|---|
| **File de modération** | Profil → Modération (pastille du nombre de dossiers ouverts) : « À traiter » trié par nombre de signalements, « Traités » par date ; filtre Avis / Événements / Organisateurs ; marque « Masqué auto » |
| **Dossier** | contenu signalé tel quel (avis masqué compris, événement avec description, compte avec email), chaque signalement (motif, précisions, date, clé courte du signaleur), historique des décisions |
| **Décisions** | avis : masquer / rétablir ; événement : **retirer** (réservations annulées, inscrits et organisateur prévenus, suppression) ; compte : **suspendre** / réactiver ; tous : classer sans suite. Conséquence expliquée avant confirmation, note obligatoire quand une personne perd quelque chose |
| **Administrateurs** | liste, ajout par email, retrait (jamais soi-même) |

### 2.5 Transverse

Bandeau **hors ligne** (les données en cache restent consultables, les
écritures sont envoyées au retour du réseau), rapport de plantage, consentement
à la mesure d'audience demandé une fois.

---

## 3. Mise en route

Prérequis : Flutter 3.47+, Node 22+, Java 17+ (émulateurs), un appareil
Android **avec Google Play**, `make` (Git Bash / WSL sous Windows).

```sh
git clone <repo> eventhub && cd eventhub
make setup              # pub get + génération de code
make functions-setup    # npm install dans functions/
```

### 3.1 Console Firebase (une seule fois)

Projet `eventhub-d411f` (`.firebaserc`). `lib/firebase_options.dart` est
généré par FlutterFire et ignoré par Git (`flutterfire configure --project=eventhub-d411f`).

1. **Authentication → Sign-in method** : activer *Email/Password* **et**
   *Google*. Pour Google sur Android, ajouter l'empreinte **SHA-1** (et
   SHA-256) de la clé de signature dans *Paramètres du projet → application
   Android* (`keytool -list -v -keystore …`, voir `android/key.properties.example`),
   puis récupérer l'**ID client OAuth Web** (type 3 dans `google-services.json`)
   → `GOOGLE_SERVER_CLIENT_ID`.
2. **Firestore Database** : base `(default)`, mode production, emplacement
   **`nam5`** (multi-région États-Unis, déclaré dans `firebase.json`). Les
   fonctions déclenchées par Firestore doivent tourner dans la région de la
   base : `REGION` (`functions/src/index.ts`) et `AppConfig.functionsRegion`
   valent donc **`us-central1`**. Si la base est un jour recréée ailleurs,
   changer ces deux constantes ensemble.
3. **Storage** : activer.
4. **Plan Blaze** : requis pour les Cloud Functions et Cloud Scheduler.
5. **Cloud Messaging** : *Web Push certificates* → générer la clé
   (`FIREBASE_WEB_VAPID_KEY`) ; iOS : téléverser la clé APNs.
6. **App Check** : enregistrer l'app Android (Play Integrity), iOS (App
   Attest), web (reCAPTCHA v3 → `APP_CHECK_RECAPTCHA_SITE_KEY`) ; déclarer
   les **jetons de debug** affichés dans les logs des appareils de dev.
   N'activer l'**application** d'App Check (Firestore, Storage, Functions via
   `ENFORCE_APP_CHECK=true`) qu'une fois ces enregistrements faits.
7. **Crashlytics** et **Analytics** : activer dans la console.
8. **Firestore → TTL** : politiques sur `notifications.expiresAt` et
   `audit.expiresAt` (déclarées dans `firestore.indexes.json`, déployées avec
   les index).
9. **Hosting** : le site `eventhub-d411f.web.app` sert `hosting/public` et
   réécrit `/e/**` vers la fonction `publicEventPage`. Pour que Android ouvre
   ces liens dans l'app, `hosting/public/.well-known/assetlinks.json` doit
   contenir l'empreinte **SHA-256** de chaque clé de signature : celle de la
   clé de debug de ce poste y est ; **ajouter celle de la clé release** avant
   publication.
10. **Premier administrateur** : le compte doit exister dans l'app, puis,
    depuis ce poste (une fois : `gcloud auth application-default login` avec
    un compte ayant le rôle *Firebase Admin* sur le projet) :
    ```sh
    make grant-admin EMAIL=moderation@exemple.org          # accorder
    make grant-admin EMAIL=moderation@exemple.org REVOKE=1 # retirer
    ```
    La personne se déconnecte puis se reconnecte : l'entrée **Modération**
    apparaît dans son profil. Les administrateurs suivants s'ajoutent depuis
    l'app (Modération → Administrateurs).

```sh
firebase login
firebase firestore:databases:get "(default)"    # doit afficher nam5
make deploy                                     # règles, index, Storage, fonctions, Hosting
```

### 3.2 Lancer

```sh
flutter run -d <id> --dart-define=FLAVOR=dev \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=930281380072-xxxx.apps.googleusercontent.com
```

Sans `GOOGLE_SERVER_CLIENT_ID`, le bouton Google est masqué sur Android. Au
premier lancement il n'y a aucun compte : on s'inscrit depuis l'app. Si
Firebase ne s'initialise pas, l'écran « Connexion à Firebase impossible »
s'affiche.

### 3.3 Émulateurs (développement)

```sh
make emulators              # Auth 9099, Firestore 8080, Storage 9199, Functions 5001, Hosting 5002, UI 4000
make run-emu DEVICE=<id>    # --dart-define=USE_EMULATORS=true
```

### 3.4 Release Android

Copier `android/key.properties.example` en `android/key.properties`, créer la
keystore, enregistrer ses empreintes dans Firebase, puis `make build-apk FLAVOR=prod`.
Sans ce fichier, un build release est signé avec la clé de debug et **ne doit
pas être publié**.

---

## 4. Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.47 / Dart 3.13 |
| État | Riverpod 3 + `riverpod_generator` |
| Navigation | go_router 18 (`StatefulShellRoute` par rôle, guard pur) |
| Modèles | freezed 4 + json_serializable |
| Firebase | `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `cloud_functions`, `firebase_app_check`, `firebase_crashlytics`, `firebase_analytics` |
| Auth tierce | `google_sign_in` 7 (natif) / popup Firebase (web) |
| Appareil | `flutter_local_notifications`, `mobile_scanner`, `connectivity_plus`, `image_picker`, `qr_flutter`, `share_plus` |
| Serveur | Cloud Functions 2ᵉ génération, TypeScript, Node 22, `firebase-admin` |
| UI | Material 3 clair/sombre, `google_fonts`, `cached_network_image` |
| Qualité | `flutter_lints` strict, `riverpod_lint`, `mocktail`, `@firebase/rules-unit-testing`, `node:test`, GitHub Actions |

---

## 5. Architecture

Feature-first, en couches (`domain` · `data` · `application` · `presentation`).
Référence : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```
lib/
├── bootstrap.dart            Firebase, App Check, Crashlytics, handler FCM, ProviderScope
├── app/                      MaterialApp, thèmes, bandeau hors ligne, consentement, identité analytics
├── routes/                   AppRoutes, RouteGuard (pur, testé), routeur, observateur → Analytics
├── core/
│   ├── analytics/            AppAnalytics (jamais bloquant), AnalyticsConsent (opt-in)
│   ├── connectivity/         isOnline
│   ├── config/ · errors/ · result/ · firebase/ · l10n/ · utils/
│   └── widgets/              design system, OfflineAware, feuille de consentement
└── features/
    ├── auth/                 email, Google, vérification, profil, paramètres, suppression de compte
    ├── events/               catalogue paginé, recherche, fiche, formulaire, partage
    ├── reservations/         réservation, portefeuille, billet
    ├── favorites/            favoris
    ├── waitlist/             liste d'attente
    ├── reviews/              avis
    ├── checkin/              contrôle à l'entrée (policy pure, scanner)
    ├── organizer/            dashboard, stats, alertes, participants, export CSV
    ├── organizers/           profil organisateur public, abonnements
    ├── moderation/           signalements (policy pure, feuille de signalement)
    ├── notifications/        préférences, appareils, FCM, centre de notifications
    ├── participant/          coque participant, recommandations « Pour vous »
    ├── onboarding/ · support/

functions/src/index.ts        setRoleClaim · notifyOrganizerOnReservation · notifyWaitlistOnSeatRelease
                              · sendEventReminders (runEventReminders) · deleteAccount
                              · syncOrganizerProfile · onFollowWritten · onEventWritten · aggregateOrganizerRating
                              · aggregateAttendance · onReportCreated · moderateContent · publicEventPage
functions/test/               tests d'intégration sur émulateurs
firebase/                     firestore.rules · storage.rules · firestore.indexes.json · tests/ (règles)
hosting/public/               accueil web, 404, .well-known/assetlinks.json (App Links)
```

Règle de dépendance : `presentation → application → domain ← data`. Seule
`data` importe les SDK Firebase (et `core/analytics`, qui est de
l'infrastructure). Une feature n'importe jamais la couche `data` d'une autre ;
elle compose ses providers (ex. le contrôle d'entrée lit les réservations via
`reservationRepositoryProvider`).

---

## 6. Modèle de données

```
users/{uid}                       name, email, role, bio?, createdAt, updatedAt?          (privé)
  ├── devices/{deviceId}          token, platform, locale, updatedAt
  ├── private/notifications       eventReminders, bookingAlerts, followedOrganizers
  ├── notifications/{id}          type, title, body, eventId, reservationId, createdAt, readAt, expiresAt (TTL)
  ├── favorites/{eventId}         eventId, createdAt
  ├── following/{organizerId}     organizerId, createdAt
  └── staffInvitations/{eventId}  copie de l'invitation, pour la boîte de l'invité          (serveur)

organizers/{uid}                  name, bio, photoUrl, memberSince, followerCount, eventCount,
                                  ratingSum, ratingCount, updatedAt                        (public, serveur)
  └── followers/{uid}             userId, createdAt                                        (serveur seul)

aggregates/event_{eventId}        eventId, recentAttendees [{key: sha256(uid)[0..16], name: "Hery R."}]
reports/{type}_{targetId}_{uid}   targetType, targetId, reason, details, reporterId, createdAt (écriture seule)
moderationQueue/{type}_{targetId} reportCount, lastReason, status, autoHidden?, decision?   (admin)
audit/{id}                        action, détails, at, expiresAt (TTL) — et fx_{triggerId} (idempotence)

events/{id}                       title, description, imageUrl?, category, startsAt, location,
                                  capacity, availablePlaces, organizerId, organizerName, createdAt, updatedAt,
                                  staffIds [≤ 10]                                          (équipe : serveur)
  ├── waitlist/{userId}           userId, userName, createdAt, notifiedAt? (serveur)
  ├── checkins/{reservationId}    reservationId, scannedBy, scannedAt
  └── invitations/{userId}        eventId, userId, email, name, invitedBy(Name), eventTitle, eventStartsAt,
                                  status (pending · accepted · declined), createdAt, respondedAt?  (serveur)

reservations/{eventId}_{userId}   eventId, userId, organizerId, userName, userEmail,
                                  eventTitle, eventStartsAt, eventLocation, status, reservedAt, cancelledAt?

reviews/{eventId}_{userId}        eventId, authorId, authorName, rating (1–5), comment, createdAt, updatedAt?,
                                  hidden?, hiddenAt?, moderatedAt?, moderatedBy?           (modération : serveur)
```

Identifiants déterministes (réservation, avis, favori, abonnement, entrée,
liste d'attente, signalement) : l'unicité est une propriété du stockage.
Compteurs publics (abonnés, événements, note) maintenus par des triggers
idempotents : chaque mise à jour enregistre l'id du déclenchement dans la même
transaction (`audit/fx_{id}`), car Firebase livre un trigger *au moins* une
fois. Dénormalisation sur la
réservation : portefeuille, invités, notifications et contrôle d'entrée sans
lecture supplémentaire. Code billet dérivé de l'id, jamais stocké.

---

## 7. Règles métier

| Règle | Client | Serveur |
|---|---|---|
| Une réservation par participant et par événement | `ReservationPolicy` + id déterministe | règles |
| Pas de réservation sur un événement complet / commencé | `ReservationPolicy` | règles + transaction |
| Re-réservation après annulation | nouvelle date de réservation | règles : heure récente, `cancelledAt` vidé |
| Publier un événement | email vérifié (`EventFormController`) | règles : `isVerified()` |
| Supprimer un événement | `EventPolicy.canDelete` : aucune réservation | règles : `takenSeats() == 0` |
| Liste d'attente | `WaitlistPolicy` : participant, complet, à venir, sans place | règles + fonction (FIFO, une notification par place libérée) |
| Avis | `ReviewPolicy` : inscrit confirmé, événement commencé, email vérifié, note 1–5, ≤ 2 000 caractères | règles (création et modification) |
| Entrée | `CheckInPolicy` : existe, bon événement, code conforme, non annulé, non déjà scanné | règles : organisateur seul, append-only |
| Suppression de compte | ré-authentification | fonction : refus si événement à venir avec participants ; places libérées ; anonymisation |
| Rôle | inchangeable | règles + custom claim |
| S'abonner | `FollowPolicy` : pas à soi-même | règles : id = organizerId, pas soi-même ; compteur par fonction |
| Signaler | `ReportPolicy` : motif de la liste, précisions si « Autre », ≤ 2 000, pas son propre contenu | règles : id `type_cible_uid` (un par compte), motifs fermés, lecture admin seule |
| Masquer un avis | automatique à 3 signalements distincts, ou décision admin | fonctions `onReportCreated` / `moderateContent` ; l'auteur ne peut pas modifier `hidden` |
| Profil public | le client ne l'écrit jamais | règles : écriture refusée ; `syncOrganizerProfile` copie nom et présentation |
| Équipe d'un événement | `EventPolicy` (gérer : principal ou co-organisateur ; supprimer et composer l'équipe : principal), `TeamPolicy` (email, pas soi-même, événement à venir, ≤ 10 avec les invitations en attente) | règles : `staffIds` jamais écrit par un client, `isEventTeam()` pour participants, entrées, liste d'attente ; fonctions `inviteCoOrganizer` (compte organisateur existant), `respondToStaffInvite`, `removeCoOrganizer` |

---

## 8. Sécurité

Les règles sont le seul contrôle qui s'exécute côté client ; les opérations
qui touchent les données d'autrui (suppression de compte, notifications,
liste d'attente) sont réservées aux Cloud Functions. App Check limite l'accès
aux applications authentiques. Correctifs importants : lecture d'une
réservation pas encore créée, re-réservation, listes de réservations
restreintes à l'appelant. Tout est détaillé et testé : [`docs/SECURITY.md`](docs/SECURITY.md).

> ⚠️ Toute modification de règles, d'index ou de fonctions doit être
> **redéployée** (`make deploy`).

---

## 9. Notifications push

| Notification | Destinataire | Déclencheur | Tap ouvre | Préférence |
|---|---|---|---|---|
| Nouvelle réservation / annulation | organisateur **et co-organisateurs** | `notifyOrganizerOnReservation` | liste des participants | `bookingAlerts` (chacun la sienne) |
| Invitation à co-organiser · Nouveau co-organisateur · Retiré de l'équipe | invité · principal · membre retiré | `inviteCoOrganizer` · `respondToStaffInvite` · `removeCoOrganizer` | invitations · équipe · tableau de bord | — (transactionnel) |
| Événement annulé · Avis masqué | détenteurs et organisateur · auteur | `moderateContent`, `onReportCreated` | billets · fiche | — (transactionnel) |
| Demain : … | participant | `sendEventReminders` (horaire) | billet | `eventReminders` |
| Une place s'est libérée | participant en attente | `notifyWaitlistOnSeatRelease` | fiche de l'événement | `eventReminders` |
| « Mirindra publie un événement » | abonnés de l'organisateur | `onEventWritten` (création, événement à venir) | fiche de l'événement | `followedOrganizers` |

Chaque envoi est aussi écrit dans `users/{uid}/notifications` (centre de
notifications, TTL 30 jours). Côté app, `PushNotifications` suit la session :
permission, jeton, affichage au premier plan, tap, invalidation du jeton à la
déconnexion. Web : `web/firebase-messaging-sw.js` + clé VAPID.

---

## 10. Production : App Check, Crashlytics, Analytics, hors ligne

| Sujet | Mise en œuvre |
|---|---|
| App Check | `bootstrap.dart` : Play Integrity / App Attest en release, fournisseurs debug sinon, reCAPTCHA v3 sur le web ; fonctions : `ENFORCE_APP_CHECK` |
| Crashlytics | erreurs Flutter et plateforme (fatales) + `AppLogger.error` (non fatales), désactivé en debug, identifiant technique du compte |
| Analytics | **opt-in** (collecte coupée par défaut dans le manifeste et l'`Info.plist`), feuille de consentement unique, interrupteur dans les Paramètres ; vues d'écran via l'observateur de routes ; événements : `login`, `sign_up`, `event_published`, `reservation_confirmed/cancelled`, `share` (lien, invitation, natif), `add_to_wishlist`, `waitlist_joined`, `review_published`, `ticket_scanned`, `organizer_followed/unfollowed`, `content_reported` (type et motif seulement) |
| Hors ligne | cache Firestore persistant (100 Mo), bandeau global via `connectivity_plus` |
| Pagination | première page temps réel, pages suivantes par curseur `startsAt` + id |
| Signature | `android/key.properties` |

---

## 11. Design system

« Aurora » : clair/sombre par tokens, rayons de 6 px pour tout ce qu'on touche
et pour les feuilles (sans poignée), bandes et filets plutôt que cartes
arrondies, graphiques à une teinte avec vue tableau, verdicts d'entrée en
aplat plein écran. Détails : [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

---

## 12. Écrans, routes et correspondance maquette

| Écran | Route |
|---|---|
| Splash · Onboarding · Connexion · Inscription · Bienvenue | `/splash` · `/onboarding` · `/login` · `/register` · `/welcome` |
| Mot de passe oublié / changement · Profil incomplet | `/forgot-password` · `/change-password` · `/complete-profile` |
| Explorer · Recherche · Billets · Profil | `/events` · `/search` · `/reservations` · `/profile` |
| Fiche événement (favori, partage, liste d'attente, avis, signalement) | `/events/:eventId` |
| Lien partagé (App Links) → fiche | `/e/:eventId` |
| Profil organisateur public · Organisateurs suivis | `/organizers/:organizerId` · `/following` |
| Modération · Dossier · Administrateurs (claim `admin`) | `/admin/moderation` · `/admin/moderation/:entryId` · `/admin/roles` |
| Confirmation · Billet | `/reservations/:reservationId/confirmation` · `/reservations/:reservationId/ticket` |
| Mes favoris | `/favorites` |
| Paramètres · Modifier le profil | `/profile/settings`, `/organizer/profile/settings` · `/account/edit` |
| Centre de notifications | `/notifications` |
| Aide · Confidentialité · À propos | `/help` · `/privacy` · `/about` |
| Mes événements · Stats · Alertes | `/organizer/events` · `/organizer/stats` · `/organizer/alerts` |
| Créer · Modifier · Publié | `/organizer/events/new` · `/organizer/events/:eventId/edit` · `/organizer/events/:eventId/published` |
| Participants · Contrôle à l'entrée | `/organizer/events/:eventId/participants` · `/organizer/events/:eventId/checkin` |
| Équipe · Invitations à co-organiser | `/organizer/events/:eventId/team` · `/organizer/invitations` |

---

## 13. Configuration

| `--dart-define` | Effet |
|---|---|
| `FLAVOR` | `dev` (défaut), `staging`, `prod` |
| `USE_EMULATORS` | `true` → Auth, Firestore, Storage et Functions sur les émulateurs |
| `GOOGLE_SERVER_CLIENT_ID` | ID client OAuth web ; requis pour Google Sign-In sur Android |
| `FIREBASE_WEB_VAPID_KEY` | clé Web Push ; sans elle, pas de push sur le web |
| `APP_CHECK_RECAPTCHA_SITE_KEY` | clé reCAPTCHA v3 ; sans elle, App Check inactif sur le web |

| Constante / paramètre | Où | À aligner avec |
|---|---|---|
| `REGION` / `AppConfig.functionsRegion` = `us-central1` | `functions/src/index.ts` / `app_config.dart` | emplacement Firestore `nam5` |
| bloc `flutter` de `firebase.json` | écrit par `flutterfire configure` | apps Android, iOS, macOS, web, Windows du projet `eventhub-d411f` ; régénère `lib/firebase_options.dart` et `android/app/google-services.json` (ignorés par Git) |
| `ENFORCE_APP_CHECK` | paramètre des fonctions | enregistrement App Check fait |
| `eventhub_default` | canal Android | manifeste, fonctions, app |
| `applicationId` | `build.gradle.kts` | app Android Firebase |

---

## 14. Qualité : lint, tests, CI

- **Analyse** : zéro issue (`flutter_lints` strict, `riverpod_lint`).
- **Tests Dart** (`make test`, **172**) : policies (réservation,
  événement dont suppression, liste d'attente, avis, entrée, abonnement,
  signalement), code billet, CSV (fichier, BOM, nom), stats et alertes,
  catalogue paginé, recommandations, phrase de preuve sociale, profil public,
  préférences et routage des notifications, mapping d'erreurs, logger,
  `RouteGuard` (dont liens profonds conservés à travers le splash et la
  connexion) ; widgets et goldens (connexion, écrans d'auth, démarrage, billet,
  stats, centre de notifications).
- **Tests de règles** (`make test-rules`, **138**) contre les émulateurs.
- **Tests des fonctions** (`make test-functions`, **29**) :
  claim de rôle, notifications organisateur et préférences, liste d'attente,
  rappels J-1, suppression de compte, profil public (publication, compteur
  d'abonnés, annonce aux abonnés, note moyenne hors avis masqués), preuve
  sociale, modération (masquage au seuil, file, décision admin), page publique
  (Open Graph, échappement, 404) — contre les émulateurs Auth, Firestore,
  Functions et Storage.
- **CI** : `quality`, `rules`, `functions` (compilation + intégration), `android`.

---

## 15. Commandes

| Commande | Rôle |
|---|---|
| `make setup` · `make gen` | dépendances, génération de code |
| `make analyze` · `make format` · `make test` | qualité Dart |
| `make rules-setup` · `make test-rules` | tests des règles |
| `make functions-setup` · `make functions-build` · `make test-functions` | fonctions |
| `make run DEVICE=<id>` · `make run-emu DEVICE=<id>` | lancer |
| `make emulators` | suite d'émulateurs |
| `make firebase-deploy` · `make deploy` | règles + index + Storage · tout, fonctions et Hosting compris |
| `make build-apk FLAVOR=prod` | APK release |
| `make grant-admin EMAIL=… [REVOKE=1]` | accorder / retirer le rôle administrateur (identifiants Google Cloud du poste) |

---

## 16. Scénario de démonstration

Deux appareils Android, projet déployé.

1. **Organisateur** : inscription (email) → lien de vérification → « C'est
   fait » → notifications acceptées → publier *Flutter Meetup*, capacité 1.
2. **Participant A** : « Continuer avec Google » → rôle participant → cœur sur
   l'événement → **Réserver**. L'organisateur reçoit « Nouvelle réservation ».
3. **Participant B** : l'événement est complet → **Rejoindre la liste d'attente**.
4. **Participant A** annule → B reçoit « Une place s'est libérée » → réserve.
5. **Organisateur** : Participants → scanner le billet de B → **Entrée validée** ;
   rescanner → **Déjà scanné à HH:mm**.
6. Après le début : B laisse un avis 5 ★ ; la fiche affiche la moyenne.
7. Paramètres de A → **Supprimer mon compte** → mot de passe / Google → compte
   effacé, avis et historique anonymisés.
8. Couper le réseau : le bandeau « Hors ligne » apparaît, les billets restent
   consultables.
9. **Participant B** : fiche → nom de l'organisateur → **Suivre**. L'organisateur
   publie un second événement → B reçoit « Mirindra publie un événement » ;
   l'accueil de B affiche le rail **Pour vous**.
10. **Partage** : fiche → Partager… → WhatsApp. Le lien s'ouvre dans l'app sur
    un Android qui l'a installée, et en page web avec aperçu ailleurs.
11. **Signalement** : trois comptes signalent un avis → il disparaît de la
    fiche ; son auteur voit « Votre avis est masqué… ».
12. **Organisateur** : Participants → **Exporter le CSV** → Drive ; le fichier
    s'ouvre correctement dans Excel.

---

## 17. Décisions d'architecture (ADR)

| # | Décision | Motivation |
|---|---|---|
| 1 | Transaction Firestore client + règles serveur pour réserver | atomicité sans latence de fonction ; intégrité par les règles |
| 2 | Ids déterministes (réservation, avis, favori, entrée, attente) | unicité structurelle, vérifiable par les règles |
| 3 | `Result<T>` + `Failure` scellée | erreurs exhaustives, pas de `try/catch` dans l'UI |
| 4 | Aucun backend simulé ; émulateurs pour le développement | un seul chemin de code, vraies règles en local |
| 5 | Push envoyés par Cloud Functions, préférences lues à l'envoi | le client ne cible jamais l'appareil d'autrui ; coupure immédiate |
| 6 | Rôle en custom claim | règles sans lecture de document |
| 7 | Google : même parcours de complétion que le profil manquant | un seul écran de choix du rôle, déjà protégé par le guard |
| 8 | Email vérifié pour publier et pour les avis | contenu visible par d'autres, barrière anti-spam minimale |
| 9 | Suppression de compte côté serveur | les règles interdisent de supprimer un profil ; cascade sur les données d'autrui |
| 10 | QR non signé, verdict par lecture serveur + code dérivé | rien à falsifier utilement ; un billet ne sert qu'une fois (entrée append-only) |
| 11 | Liste d'attente sans réservation de place | premier arrivé, premier servi, annoncé comme tel ; pas d'expiration à gérer |
| 12 | Catalogue : page live + pages par curseur | les règles plafonnent un `list` à 100 ; filtres côté client sur ce qui est chargé |
| 13 | Analytics opt-in, jamais bloquant | CNIL ; une mesure ne doit pas casser une réservation ni les tests |
| 14 | App Check activé tôt, appliqué plus tard (`ENFORCE_APP_CHECK`) | ne pas verrouiller les builds de dev avant l'enregistrement des jetons |
| 15 | Stats et alertes calculées côté client | aucune lecture en plus ; limite de 200 réservations assumée |
| 16 | Profil organisateur public dans une collection distincte, écrite par fonction | `users/{uid}` reste privé (email, rôle) ; un compteur écrit par le client ne vaudrait rien |
| 17 | Triggers idempotents par marqueur transactionnel | livraison *au moins une fois* : sans marqueur, un compteur dérive |
| 18 | Preuve sociale : compte exact depuis l'événement, noms courts depuis un agrégat | la jauge est transactionnelle ; les noms sont réduits à « Prénom I. », clés hachées |
| 19 | Signalements écriture seule, un par compte, masquage automatique des avis seulement | anonymat du signaleur ; seuil de personnes distinctes ; un événement a des billets, un humain tranche |
| 20 | Recommandations sur l'appareil, heuristique explicable | aucun profilage serveur ; chaque suggestion a une raison vraie |
| 21 | Page publique rendue par fonction derrière Hosting, App Links vérifiés | aperçu dans les messageries sans exposer les règles Firestore ; lien unique pour app et web |
| 22 | Lien profond conservé dans `?from=` à travers splash et connexion, liste blanche de destinations | un lien ouvre souvent l'app à froid ; `from` vient de l'extérieur |
| 23 | Rôle admin en claim, décisions par fonctions journalisées, premier admin en ligne de commande | aucun document ne confère de pouvoir ; chaque décision est traçable ; pas de porte dérobée dans l'app |
| 24 | Co-organisateurs dans `staffIds` sur l'événement, modifié par fonctions seulement ; invitation dupliquée (événement + invité) | une seule lecture pour que les règles prouvent l'appartenance ; chacun lit sa copie sans requête de groupe |
| 25 | Liste des participants : requête différente pour le principal (`organizerId ==`) et l'équipe (`eventId ==`) | chaque requête est celle que les règles savent prouver ; le principal ne paie aucune lecture supplémentaire |

---

## 18. Périmètre : ce qui est fait, ce qui reste

**Fait** : tout le cahier des charges et les maquettes, branchés sur Firebase ;
email + Google ; vérification d'email ; suppression de compte ; push (Android,
web) et centre de notifications ; favoris, liste d'attente, avis, contrôle à
l'entrée ; stats et alertes ; pagination ; App Check, Crashlytics, Analytics
sur consentement ; hors ligne ; signature release ; profils organisateurs
publics et abonnements (F-10) ; preuve sociale (F-07) ; partage natif, page
publique et App Links (F-08) ; export CSV en fichier (F-15) ; recommandations
(F-18) ; signalement et modération (F-19) ; tests Dart, règles et fonctions ;
CI.

| Reste | Pourquoi / action |
|---|---|
| **Déploiement** | nécessite `firebase login`, le plan Blaze et la configuration de la console (§3.1) |
| iOS | build sur Mac, clé APNs, capacités *Push* et *Background modes* dans Xcode, App Attest |
| Clés à fournir | `GOOGLE_SERVER_CLIENT_ID`, `FIREBASE_WEB_VAPID_KEY`, `APP_CHECK_RECAPTCHA_SITE_KEY`, keystore release |
| « Add to Cal » | plugin natif de calendrier |
| Empreinte release dans `assetlinks.json` | à ajouter avec la keystore release, sinon les liens s'ouvrent dans le navigateur |
| Types de billets (F-12), paiement Stripe (F-11), séries (F-13), carte (F-14), discussion (F-17), multilingue (F-20) | en cours, lot par lot (voir `docs/ROADMAP.md`) |
| Revue juridique | notice de confidentialité et consentement à valider (DPO) |

---

## 19. Dépannage

| Symptôme | Cause / correctif |
|---|---|
| « Connexion à Firebase impossible » | `flutterfire configure --project=eventhub-d411f` |
| `operation-not-allowed` | fournisseur non activé dans Authentication |
| Bouton Google absent (Android) | `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` |
| Google : `DEVELOPER_ERROR` / échec | SHA-1 de la clé de signature absent de la console |
| « Confirmez votre adresse email avant de publier » | ouvrir le lien reçu puis « C'est fait » |
| `permission-denied` | règles non déployées, ou App Check appliqué sans jeton de debug déclaré |
| « requires an index » | `make firebase-deploy`, attendre la construction |
| Aucune notification | permission refusée, appareil sans Google Play, fonctions non déployées, préférence coupée ; `firebase functions:log` |
| Suppression de compte refusée | événement à venir avec participants (message explicite) |
| Scanner : caméra indisponible | autoriser la caméra ; ou saisir le code du billet |
| `make test-functions` échoue | Java requis ; `make functions-setup` et `make rules-setup` une fois ; si l'émulateur Functions expire au chargement : `FUNCTIONS_DISCOVERY_TIMEOUT=60` |
| Un lien `/e/…` s'ouvre dans le navigateur au lieu de l'app | empreinte SHA-256 de la clé de signature absente de `assetlinks.json`, ou Hosting non déployé ; `adb shell pm get-app-links com.example.eventhub` |
| « Vous avez déjà signalé ce contenu » | normal : un signalement par compte et par contenu |
| Profil organisateur « indisponible » | fonctions non déployées (profil public jamais créé) ou compte supprimé |
| Pas d'entrée « Modération » après `make grant-admin` | se déconnecter puis se reconnecter (le rôle est dans le jeton) |
| `make grant-admin` : « Could not load the default credentials » | `gcloud auth application-default login`, ou `GOOGLE_APPLICATION_CREDENTIALS=<clé>` |

---

## 20. Contribuer

Branches par tâche, Conventional Commits, CI verte. Toute évolution (écran,
route, dépendance, règle, fonction) met à jour **ce README et le document
`docs/` concerné dans la même PR** ([`docs/CONVENTIONS.md`](docs/CONVENTIONS.md)).
