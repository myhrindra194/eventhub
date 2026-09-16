# EventHub — Architecture

> Référence technique. La vue produit est dans le [`README.md`](../README.md),
> le modèle de sécurité dans [`SECURITY.md`](SECURITY.md), les règles
> d'écriture du code de données dans [`CONVENTIONS.md`](CONVENTIONS.md).

EventHub est une application Flutter **multiplateforme** (Android, iOS, web,
Windows, macOS) organisée par fonctionnalité et en couches, adossée à
**Firebase Auth** et **Cloud Firestore** sur le plan gratuit **Spark**.

La contrainte qui façonne tout le reste : **il n'y a pas de code serveur**.
Cloud Functions, Cloud Storage et Cloud Scheduler exigent le plan Blaze
(compte de facturation), écarté volontairement. Ce qu'un backend ferait
habituellement — compteurs, cascades, notifications, rappels — est donc
réparti entre **le client**, qui écrit, et **les règles de sécurité**, qui
prouvent que l'écriture est légitime.

---

## 1. Vue d'ensemble

```mermaid
flowchart LR
  subgraph Appareils["Application Flutter (un seul code)"]
    UI["presentation<br/>écrans responsives"] --> APP["application<br/>providers Riverpod"]
    APP --> DOM["domain<br/>entités, politiques"]
    DATA["data<br/>DTO, sources Firestore"] --> DOM
    APP --> DATA
    LOCAL["notifications locales<br/>rappels J-1"]
    CACHE[("cache Firestore<br/>hors ligne 100 Mo")]
  end

  subgraph Firebase["Firebase — plan Spark"]
    AUTH["Firebase Auth<br/>email + Google"]
    RULES{{"firestore.rules<br/>seul code côté Google"}}
    FS[("Cloud Firestore")]
    HOST["Hosting<br/>/e/{id}, App Links"]
    FCM["FCM<br/>jetons conservés"]
    CRASH["Crashlytics · Analytics"]
  end

  DATA -- "SDK (jeton Auth)" --> RULES --> FS
  DATA --> AUTH
  DATA -.-> CACHE
  APP --> LOCAL
  APP -.-> FCM
  APP -.-> CRASH
  WEB["Navigateur sans l'app"] --> HOST
  HOST -- "API REST, get public" --> RULES
```

| Brique | Rôle | Plan |
|---|---|---|
| Firebase Auth | email + mot de passe (vérification d'adresse), Google, réinitialisation | Spark |
| Cloud Firestore | toutes les données ; cache hors ligne sur chaque plateforme | Spark (1 Gio, 50 k lectures / 20 k écritures / 20 k suppressions par jour) |
| Règles de sécurité | droits, formes, invariants inter-documents | Spark |
| Politique TTL | purge des notifications expirées (`expiresAt`) | à activer une fois |
| Hosting | page publique `/e/{id}`, `assetlinks.json`, accueil | Spark |
| FCM | jetons enregistrés (`users/{uid}/devices`) ; messages de premier plan | Spark ; **envoi serveur absent** |
| Crashlytics · Analytics | plantages, mesure d'audience sur consentement | gratuits |

---

## 2. Arborescence

```
lib/
├── main.dart · main_dev.dart · main_staging.dart · main_prod.dart   points d'entrée (flavors)
├── bootstrap.dart            Firebase.initializeApp, cache Firestore, émulateurs, Crashlytics, handler FCM
├── firebase_options.dart     généré par flutterfire, versionné (identifiants publics)
├── app/                      MaterialApp.router, thèmes « Aurora », bandeau hors ligne, consentement
├── routes/                   AppRoutes, RouteGuard (pur, testé), routeur, observateur Analytics
├── core/
│   ├── config/               Flavor, AppConfig (dart-defines), AppLinks, Clock
│   ├── firebase/             providers (FirebaseFirestore, FirebaseAuth, messaging),
│   │                         Collections / DocIds (firestore_paths.dart), convertisseur Timestamp
│   ├── errors/ · result/     Failure, ErrorMapper (FirebaseException, FirebaseAuthException), Result, guard
│   ├── analytics/ · connectivity/ · l10n/ · utils/ · extensions/
│   └── widgets/              design system, OfflineAware, écran d'erreur de démarrage
└── features/
    ├── auth/                 inscription, vérification d'email, Google, profil, suppression de compte
    ├── events/               catalogue paginé, recherche, fiche, formulaire, preuve sociale
    ├── reservations/         réserver / annuler en transaction, portefeuille, billet QR
    ├── favorites/ · waitlist/ · reviews/ · checkin/ · team/
    ├── organizer/            tableau de bord, stats, alertes, participants, export CSV
    ├── organizers/           page publique d'organisateur, abonnements
    ├── moderation/ · admin/  signalements · file de modération, décisions
    ├── notifications/        centre de notifications, préférences, rappels locaux, jetons FCM
    ├── participant/          espace participant, recommandations « Pour vous »
    └── onboarding/ · support/

firebase/
├── firestore.rules           le backend : droits, formes, preuves inter-documents
├── firestore.indexes.json    index composites + TTL de notifications.expiresAt
└── tests/                    node:test + @firebase/rules-unit-testing sur l'émulateur
hosting/public/               accueil, e.html (/e/{id}), pay/* (inactif), .well-known/assetlinks.json
env/                          dart-defines publics par flavor (dev.json et example.json versionnés)
firebase.json · .firebaserc   Firestore, Hosting, émulateurs (auth 9099, firestore 8080, hosting 5002, UI 4000)
```

---

## 3. Règle de dépendance

```
presentation ──▶ application ──▶ domain ◀── data
```

* **domain** — Dart pur : entités, politiques (`ReservationPolicy`,
  `EventPolicy`, `ReviewPolicy`…), calculs, interfaces de repositories. Aucun
  SDK : testable en millisecondes, sans émulateur.
* **data** — seule couche qui importe `cloud_firestore` / `firebase_auth`.
  DTO `freezed` en camelCase, miroir exact des champs attendus par les règles.
* **application** — providers et contrôleurs Riverpod. Un contrôleur exécute
  d'abord la politique du domaine (réponse instantanée, message précis), puis
  écrit ; les règles tranchent.
* Une feature n'importe jamais la couche `data` d'une autre : elle compose ses
  providers.

**Pourquoi cette double vérification ?** Les règles ne renvoient qu'un
`permission-denied` muet. Le domaine explique (« Cet événement est complet »),
les règles garantissent. Un client modifié peut sauter le domaine ; il ne peut
pas sauter les règles.

---

## 4. Modèle de données

Source de vérité : les blocs de commentaires de `firebase/firestore.rules`.
`?` = facultatif.

### 4.1 Comptes

| Chemin | Champs | Lecture | Écriture |
|---|---|---|---|
| `users/{uid}` | `name` 2–80 · `email` (= jeton) · `role` `participant`\|`organizer` · `bio?` ≤ 500 · `photoUrl?` ≤ 140 000 · `coverUrl?` ≤ 280 000 · `suspended?` · `welcomedAt?` · `createdAt` · `updatedAt?` | soi, administrateurs ; **jamais listé** | création `participant` par soi ; nom, bio et photos par soi ; passage `organizer` (sens unique) ; `suspended` par un admin |
| `users/{uid}/private/notifications` | `eventReminders` · `bookingAlerts` · `followedOrganizers` (bool) · `updatedAt?` | soi | soi |
| `users/{uid}/devices/{deviceId}` | `token` · `platform` · `updatedAt` | soi | soi |
| `users/{uid}/favorites/{eventId}` | `eventId` · `createdAt` | soi | soi |
| `users/{uid}/following/{organizerId}` | `organizerId` · `createdAt` | soi | soi, **avec** `organizers/{id}.followerCount ± 1` dans le même batch |
| `users/{uid}/notifications/{id}` | `type` · `title` · `body` · `eventId?` · `reservationId?` · `actorId` · `createdAt` · `readAt?` · `expiresAt` | destinataire | l'**acteur** du fait, sous conditions (§5.3) ; `readAt` par le destinataire |
| `admins/{uid}` | `email` · `name?` · `grantedAt` | soi (« suis-je admin ? »), admins | **console Firebase uniquement** |

### 4.2 Organisateurs

| Chemin | Champs | Notes |
|---|---|---|
| `organizers/{uid}` | `name` · `bio` · `photoUrl?` · `memberSince` · `followerCount` · `eventCount` · `ratingSum` · `ratingCount` · `lastEventId?` · `lastReviewId?` · `suspended?` | page publique (comptes connectés). Compteurs **prouvés** : chaque variation cite le document qui la justifie (`lastEventId`, `lastReviewId`, le document `following` de l'appelant). `photoUrl` est le miroir exact de celle du profil privé, exigé par la règle : c'est le seul moyen pour les autres comptes de voir le visage d'un organisateur |
| `organizerEmails/{sha256(email)}` | `uid` | un organisateur retrouve un compte à inviter par `get` d'**un** hash ; `list` interdit |

Un compte organisateur naît **en un batch** : `users/{uid}` avec
`role: organizer` + `organizers/{uid}` (compteurs à zéro). La règle exige la
page (`existsAfter`) et n'accepte la page que si le compte n'existait pas
encore (`!exists`) : un participant ne peut pas se fabriquer un rôle
organisateur. `organizerEmails/{hash}` suit à la confirmation de l'adresse.

### 4.3 Événements

| Chemin | Champs |
|---|---|
| `events/{eventId}` | `title` 3–120 · `description` 1–5000 · `category` (liste fermée) · `startsAt` · `location` · `capacity` 1–100 000 · `availablePlaces` 0–capacity · `organizerId` (immuable) · `organizerName` · `imageUrl?` (lien Cloudinary) · `staffIds` ≤ 10 · `tiers?` ≤ 6 `{id: {name, description, price, capacity, available, order}}` · `currency?` EUR\|USD\|MGA · `createdAt` · `updatedAt?` |
| `events/{id}/waitlist/{uid}` | `userId` · `createdAt` · `notifiedAt?` — FIFO par `createdAt` |
| `events/{id}/checkins/{reservationId}` | `reservationId` · `scannedBy` · `scannedAt` — ajout seul, par l'équipe |
| `events/{id}/invitations/{inviteeId}` | `eventId` · `userId` · `email` · `name` · `invitedBy` · `invitedByName` · `eventTitle` · `eventStartsAt` · `status` pending\|accepted\|declined · `createdAt` · `respondedAt?` |
| `events/{id}/attendees/{sha256(uid)}` | `name` ≤ 40 · `createdAt` — « Soa, Hery R. et 40 autres y vont » |

Les **types de billets** sont une map dans l'événement, pas une
sous-collection : réserver lit **un** document dans la transaction, et la
règle vérifie en une passe que le type choisi et le total ont bougé du même
±1.

### 4.4 Réservations, avis, modération

| Chemin | Champs |
|---|---|
| `reservations/{eventId}_{uid}` | `eventId` · `userId` · `organizerId` · `userName` · `userEmail` · `eventTitle` · `eventStartsAt` · `eventLocation` (copies de l'événement, vérifiées) · `status` confirmed\|cancelled · `reservedAt` · `cancelledAt?` · `cancelledBy?` · `tierId?` · `tierName?` · `pricePaid` (toujours 0) |
| `reviews/{eventId}_{uid}` | `eventId` · `organizerId` · `authorId` · `authorName` · `rating` 1–5 · `comment` ≤ 2000 · `hidden` · `createdAt` · `updatedAt?` |
| `reports/{type}_{target}_{uid}` | `targetType` event\|user\|review · `targetId` · `reason` (liste fermée) · `details` · `reporterId` · `createdAt` — écriture seule |
| `moderationQueue/{type}_{target}` | `targetType` · `targetId` · `reportCount` · `lastReason` · `status` open\|resolved\|dismissed · `decision?` · `decisionNote?` · `decidedBy?` · `decidedAt?` · `updatedAt` |
| `moderationQueue/{id}/decisions/{auto}` | `action` · `note` · `by` · `at` — journal, ajout seul |

**Dénormalisation assumée.** La réservation copie titre, date et lieu : le
portefeuille, la liste d'invités et le contrôle à l'entrée se lisent sans
jointure (Firestore n'en a pas), et un billet reste lisible après la
suppression de l'événement. La règle `matchesEvent()` empêche une copie
mensongère à la création.

---

## 5. Patterns « sans serveur »

### 5.1 Preuves dans les batchs (`getAfter` / `existsAfter`)

Un compteur n'est jamais écrit seul. Il part dans le **même commit** que le
document qui le justifie, et la règle lit l'état **tel qu'il sera après le
commit** :

```mermaid
sequenceDiagram
  participant App as App (participant)
  participant R as firestore.rules
  participant FS as Firestore
  App->>FS: transaction.get(events/e1)
  FS-->>App: availablePlaces = 12
  App->>R: commit { events/e1.availablePlaces = 11,<br/>reservations/e1_uid {status: confirmed} }
  R->>R: events/e1 : -1 exactement, et getAfter(reservations/e1_uid).status == confirmed
  R->>R: reservations/e1_uid : id = eventId_uid, copie conforme, place libre,<br/>getAfter(events/e1).availablePlaces == avant - 1
  R-->>FS: les deux écritures sont autorisées
  FS-->>App: commit atomique (sinon aucune écriture)
```

Chaque moitié exige l'autre : un client qui n'envoie que la réservation (place
gratuite) ou que le décrément (vandalisme) est refusé. Deux personnes qui
réservent la dernière place au même instant : la transaction la plus lente
est rejouée, relit `availablePlaces = 0` et échoue proprement. **Aucune
survente**, sans verrou serveur.

Même mécanisme pour : abonnés (`following` ↔ `followerCount`), nombre
d'événements (`events` ↔ `eventCount` via `lastEventId`), note (`reviews` ↔
`ratingSum`/`ratingCount` via `lastReviewId`), type de billet (`tiers[id].available`
↔ `tierId` de la réservation), équipe (`staffIds` ↔ invitation acceptée),
signalement (`reports` ↔ `moderationQueue.reportCount`), passage organisateur.

### 5.2 Identifiants déterministes

L'identifiant **est** la contrainte d'unicité : `reservations/{eventId}_{uid}`,
`reviews/{eventId}_{uid}`, `reports/{type}_{target}_{uid}`. Détails et table
complète : `CONVENTIONS.md` §3.1.

### 5.3 Notifications écrites par l'acteur

Sans Cloud Function, c'est la personne **qui cause** le fait qui écrit la
notification dans `users/{destinataire}/notifications`. Pour que ce ne soit
pas une porte ouverte au spam, la règle exige :

1. un `type` connu, `actorId == request.auth.uid`, `createdAt` serveur, non lue ;
2. un **identifiant déterministe** construit à partir du fait (ex.
   `booking_{eventId}_{uid}_{reservedAtMillis}`) : une seule notification par
   fait, rejouer n'inonde pas ;
3. la **preuve du fait** : la réservation de l'appelant est confirmée, le
   destinataire est bien dans l'équipe, la place est bien libre pour la liste
   d'attente, l'invitation existe, l'appelant est admin pour une décision de
   modération…

Écriture **best-effort** après le commit métier (`CONVENTIONS.md` §3.3). Les
notifications expirent via la **politique TTL** sur `expiresAt` (30 jours).

### 5.4 Rappels J-1 sur l'appareil

Le rappel de la veille est une **notification locale** planifiée par
`flutter_local_notifications` au moment de la réservation (et replanifiée au
démarrage à partir du portefeuille, annulée à l'annulation). Contreparties :
pas de rappel sur un appareil où l'app n'a jamais été ouverte depuis la
réservation ; pas de rappel sur le web (pas de planification fiable dans un
onglet fermé). Préférence : `eventReminders`.

### 5.5 Push

Envoyer un message FCM exige la clé d'un compte de service, qui ne peut pas
vivre dans l'app. Cloud Functions exigeant Blaze, l'émetteur est un **Worker
Cloudflare** (`workers/api/`, plan gratuit) appelé par l'auteur de la
notification juste après l'avoir écrite :

```
client (auteur)                      Worker eventhub-api                 Google
───────────────                      ────────────────────                 ──────
1. écrit users/{r}/notifications/{n}
   (règles : fait prouvé, actorId)
2. POST /v1/dispatch ───────────────► 3. vérifie l'ID token (RS256, aud,
   Bearer <ID token>                    iss, exp) avec les clés publiques
   {recipientId, notificationId}     4. lit la notification (REST) ─────► Firestore
                                        · actorId == appelant
                                        · créée il y a < 10 min
                                     5. crée pushReceipts/{r}:{n} ──────► (échoue si déjà envoyée)
                                     6. lit private/notifications ──────► préférences
                                     7. lit devices, envoie ────────────► FCM HTTP v1
                                     8. supprime les jetons UNREGISTERED ► Firestore
```

* **Sécurité.** Le Worker ne crée rien : il relaie une notification que les
  règles ont déjà acceptée. Un client forgé ne peut pas pousser un texte
  arbitraire, ni rejouer une ancienne notification, ni déclencher le push
  d'un fait provoqué par quelqu'un d'autre.
* **Idempotence.** Le reçu `pushReceipts/{recipientId}:{notificationId}` est
  créé avec la sémantique « échoue s'il existe » : deux appels simultanés ne
  produisent qu'un push. Un reçu ne vit que 15 minutes (au-delà, le contrôle
  d'âge suffit) ; les politiques TTL de Firestore exigeant la facturation,
  c'est une tâche planifiée du Worker (`crons`, toutes les heures) qui les
  supprime.
* **Côté app.** `PushDispatcher` (`features/notifications/data/`) est injecté
  dans les trois écrivains (réservations, équipe, modération). Il ne lève
  jamais, n'est jamais attendu, et plafonne à 4 appels simultanés (une
  décision de modération peut viser 200 personnes). Sans `API_WORKER_URL`,
  c'est `NoPushDispatcher` : rien ne part, le centre in-app reste la source.
* **Contrepartie assumée.** Pas de déclencheur : si l'app meurt entre
  l'écriture et l'appel, la notification existe mais le push ne part pas. Le
  centre de notifications la montre quand même à la prochaine ouverture.
* **Réception.** Bloc `notification` pour l'affichage app fermée, clés `data`
  (`type`, `eventId`, `reservationId`) lues par `NotificationRoute` au toucher,
  canal Android `eventhub_default`.

### 5.6 Suppression de compte côté client

Séquence (chaque étape autorisée par une branche dédiée des règles) :

1. ré-authentification (mot de passe ou Google) — Auth exige une connexion
   récente pour supprimer ;
2. l'app refuse s'il reste un événement à venir **avec** participants
   (supprimer l'événement serait refusé par les règles de toute façon) ;
3. places à venir **libérées** : transaction réservation `cancelled` +
   `availablePlaces + 1` ;
4. historique **anonymisé** : `reservations.userId = ''`, `userName = 'Compte
   supprimé'`, `userEmail = 'supprime@eventhub.invalid'` ; idem `reviews.authorId` ;
5. abonnements supprimés (avec `followerCount - 1`), favoris, appareils,
   préférences, notifications, entrée `organizerEmails`, page `organizers`,
   puis `users/{uid}` ;
6. `FirebaseAuth.currentUser.delete()` en **dernier**.

Si l'app est interrompue au milieu, la personne est encore connectée et peut
relancer : chaque étape est idempotente. Contrepartie : sans serveur, un
compte Auth supprimé ne peut pas « nettoyer derrière lui » ce qui a échoué
avant.

### 5.7 Images

Cloud Storage exigeant Blaze, les images vivent sur **Cloudinary** ; Firestore
ne stocke que leur lien (`users.photoUrl`, `users.coverUrl`,
`events.imageUrl`). Le module `lib/core/media/` porte toute la chaîne :

```
DeviceImagePicker ──► ImageUploadFlow ──► CloudinaryImageUploader ──► secure_url
 (image_picker,        (choisir puis         (multipart non signé :        │
  compression,          envoyer : renoncer,   preset, dossier,             ▼
  plafond 10 Mo)        refus, succès)        étiquettes, context uid)  Firestore
                                                                       (lien seul)

EventImage / AppAvatar ──► CloudinaryUrl.sized(url, width) ──► variante WebP au palier
```

* **Envoi** : dès que l'image est choisie, pour montrer l'image hébergée avant
  d'enregistrer. Le lien n'entre dans Firestore qu'à l'enregistrement du
  formulaire ; un abandon laisse une image orpheline dans la médiathèque.
* **Affichage** : l'URL d'origine est réécrite à la volée
  (`c_limit,w_<palier>,f_webp,q_auto`, ou `c_fill,g_face` pour un avatar).
  Les paliers (160 → 1920 px physiques) gardent le cache utile.
* **Règles** : `isCloudinaryImage` n'accepte qu'un lien
  `https://res.cloudinary.com/<cloud>/image/upload/…` ; une valeur déjà en
  place (ancien lien collé, image `data:` d'avant la migration) reste acceptée
  tant qu'elle n'est pas modifiée (`validImageField`).
* **Sans configuration** (`CLOUDINARY_*` vides), l'import est masqué : l'app
  reste utilisable et les événements gardent leur visuel généré.

### 5.8 Pagination et limites

* Catalogue : première page en temps réel (`limit ≤ 200` imposé par les
  règles), pages suivantes par curseur `startAfterDocument` sur `startsAt`.
* Toute requête `list` est bornée et épingle le filtre qui prouve le droit
  (`CONVENTIONS.md` §3.4).
* Budget des règles : 10 lectures de documents par requête, 20 dans un batch
  ou une transaction — les helpers qui lisent sont marqués `// read`.
* Quotas Spark : 50 000 lectures/jour. Le cache hors ligne et les écouteurs
  temps réel (une lecture par document **modifié**, pas par rafraîchissement)
  sont les premières économies.

### 5.9 Paiements

Désactivés. `reservations.pricePaid` doit valoir 0 et seul un type de billet
**gratuit** est réservable (`tierBookable()`). Encaisser exige un secret Stripe
et un webhook signé : impossible sans serveur (`ROADMAP.md` F-11).

---

## 6. Authentification

* **Session** : `authStateChanges()` → document `users/{uid}` écouté en temps
  réel ; un délai de grâce (`profileGracePeriod`, 3 s) couvre l'écart entre
  création du compte et création du profil.
* **Inscription** : le formulaire demande le rôle (Participant ou
  Organisateur, sans valeur par défaut). Compte Auth, puis **une seule
  écriture** du profil (partagée avec le flux de session, qui voit le compte
  avant la fin de `signUp`) : `users/{uid}` avec le rôle choisi et
  `intendedRole`, plus, pour un organisateur, sa page `organizers/{uid}` dans
  le même batch — la règle refuse un rôle organisateur sans elle.
  L'entrée `organizerEmails` (invitations de co-organisateurs) suppose une
  adresse vérifiée : elle est écrite à la confirmation. Un compte ancien
  resté participant malgré `intendedRole: organizer` est promu à sa session
  suivante. L'app demande ensuite au
  Worker `eventhub-api` le **mail de bienvenue** (`POST /v1/welcome`, une fois
  par compte, adresse lue dans le jeton). **Aucun lien de vérification ne part
  à l'inscription.** Une première connexion Google reprend le rôle choisi sur
  l'écran d'inscription.
* **Vérification d'email, au moment où elle sert** : exigée par les règles
  pour publier un événement et laisser un avis
  (`request.auth.token.email_verified`). Le bandeau `EmailVerificationBanner`
  n'apparaît que là : dans Profil pour un compte inscrit comme organisateur,
  dans la fiche d'un événement quand seule l'adresse bloque l'avis. Il
  envoie le lien à la demande (Firebase Auth), puis « C'est fait » force
  `user.reload()` et `getIdToken(true)` ; pour un inscrit organisateur, la
  confirmation enchaîne sur l'ouverture de l'espace.
* **Emails transactionnels** : bienvenue et « Nous contacter » partent du
  Worker via l'API Brevo (clé en secret Cloudflare). Le contact écrit à
  `COMPANY_EMAIL` avec l'adresse du compte en « répondre à », limité à un
  message toutes les deux minutes par compte (`contactThrottle/{uid}`).
* **Google** : web par popup Firebase ; iOS par `GIDClientID` (Info.plist) ;
  Android par `google_sign_in` avec `GOOGLE_SERVER_CLIENT_ID` (sinon bouton
  masqué) ; pas de fournisseur Google sur desktop dans FlutterFire.
* **Administrateur** : `admins/{uid}` lu par un `get` sur son propre uid,
  autorisé même si le document n'existe pas.
* **Suspension** : `users/{uid}.suspended`, relu par les règles à chaque
  écriture qui passe par `isActive()` — effet immédiat, sans attendre
  l'expiration du jeton.

---

## 7. Navigation et liens profonds

Deux `StatefulShellRoute` (espace participant, espace organisateur) ;
`RouteGuard.redirect` est une fonction pure testée. `/admin/**` n'est ouvert
qu'aux administrateurs.

`https://eventhub-d411f.web.app/e/{id}` est un lien unique :

* **Android avec l'app** — intent filter auto-vérifié
  (`hosting/public/.well-known/assetlinks.json`) → route `/e/:eventId`.
* **Sans l'app** — Hosting réécrit `/e/**` vers `e.html`, qui lit
  l'événement par l'**API REST Firestore** (`GET …/documents/events/{id}?key=…`
  avec un masque de champs), décode les valeurs typées et rend la page avec
  `textContent` uniquement. Les robots d'aperçu (WhatsApp, Slack) n'exécutent
  pas JavaScript : ils voient un titre générique (un rendu serveur Open Graph
  demanderait une Cloud Function).

Un lien ouvre souvent l'app à froid : `RouteGuard` le conserve dans `?from=`
à travers `/splash` et `/login` (liste blanche `AppRoutes.isDeepLinkTarget`).

---

## 8. Hors ligne

`bootstrap.dart` active la persistance Firestore sur **toutes** les plateformes
(le web la désactive par défaut) avec 100 Mo de cache : un billet déjà affiché
s'ouvre à la porte sans réseau. Les écritures hors ligne sont mises en file
par le SDK, **sauf les transactions**, qui exigent le serveur (réserver,
annuler) : l'UI les désactive hors ligne (`OfflineAware`).

---

## 9. Configuration et flavors

`FLAVOR` + `env/<flavor>.json` passés par `--dart-define-from-file` :

| Clé | Effet |
|---|---|
| `USE_FIREBASE_EMULATOR` | `true` → Auth 9099 et Firestore 8080 locaux |
| `FIREBASE_EMULATOR_HOST` | `localhost` ; `10.0.2.2` depuis l'émulateur Android ; IP du poste depuis un téléphone |
| `GOOGLE_SERVER_CLIENT_ID` | client OAuth *web* ; requis pour Google Sign-In sur Android |
| `FIREBASE_WEB_VAPID_KEY` | clé Web Push publique ; sans elle, pas de jeton FCM web |

---

## 10. Stratégie de test

| Couche | Comment |
|---|---|
| domain | tests unitaires purs (politiques, calculs, recommandations, phrase de preuve sociale) |
| data | parsing des DTO, construction des identifiants, payloads conformes aux règles |
| core | Result/guard, ErrorMapper, AppLogger |
| routes | RouteGuard comme fonction pure |
| presentation | widgets et goldens avec providers surchargés, à plusieurs largeurs d'écran |
| **règles** | `make rules-test` : `@firebase/rules-unit-testing` contre l'émulateur Firestore — chaque règle est éprouvée **en tant qu'attaquant** (batch incomplet, compteur gonflé, identifiant forgé, rôle usurpé) ; job CI `firestore-rules` |
