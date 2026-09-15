# EventHub

> Application mobile Flutter de découverte, de réservation et d'organisation
> d'événements, adossée à **Supabase** : Postgres avec Row Level Security,
> fonctions et triggers SQL, Auth (email et Google), Storage, Realtime et Edge
> Functions (paiements Stripe, envoi des push, page publique). Firebase ne
> garde que ce que Supabase ne fournit pas : la livraison des notifications
> (FCM), Crashlytics et Analytics. Deux rôles, un parcours de bout en bout : un
> **organisateur** publie un événement et contrôle les billets à l'entrée ; un
> **participant** découvre, réserve, garde son billet et reçoit ses rappels.
> Cahier des charges : `EVENTHUB — Cahier des charges MVP.pdf`.

[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3-6366F1)
![Supabase](https://img.shields.io/badge/Supabase-Postgres_·_RLS_·_Auth_·_Storage_·_Realtime_·_Edge_Functions-3ECF8E?logo=supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FCM_·_Crashlytics_·_Analytics-FFCA28?logo=firebase&logoColor=black)
![Tests Dart](https://img.shields.io/badge/tests_Dart-232_passing-10B981)
![Tests base de données](https://img.shields.io/badge/tests_base_de_données-39_passing-10B981)

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
10. [Production : Crashlytics, Analytics, hors ligne](#10-production--crashlytics-analytics-hors-ligne)
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
menace, droits, RLS, fonctions, paiements), [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)
(langage visuel), [`docs/ROADMAP.md`](docs/ROADMAP.md) (feuille de route),
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) (conventions d'équipe).

---

## 1. Vue d'ensemble

| Rôle             | En une phrase |
|------------------|---------------|
| **Participant**  | découvre les événements (dont une sélection « Pour vous »), voit qui y va, en garde en favoris, suit ses organisateurs préférés, réserve une place gratuite ou achète un billet, rejoint la liste d'attente, présente son billet QR, laisse un avis après l'événement |
| **Organisateur** | publie ses événements avec des types de billets (ses abonnés sont prévenus), compose une équipe, soigne son profil public, reçoit une notification à chaque réservation, suit stats, recettes et alertes, exporte sa liste d'invités en CSV et scanne les billets à l'entrée |

**Il n'y a pas de backend simulé.** Toutes les données viennent d'un projet
Supabase ; les règles s'exécutent dans la base, et toute la logique serveur est
versionnée dans `supabase/` (migrations, Edge Functions, tests).

| Brique | Rôle dans EventHub |
|---|---|
| **Postgres** | profils, événements et types de billets, réservations, équipes, favoris, abonnements, liste d'attente, avis, signalements et modération, entrées scannées, appareils, préférences, notifications |
| **Row Level Security + droits par colonne** | chaque utilisateur ne lit et n'écrit que ce qui lui revient ; les colonnes sensibles (rôle, montants, compteurs) ne sont jamais écrites par un client |
| **Fonctions SQL** | toutes les opérations métier en une transaction : publier, réserver, annuler, entrée à la porte, équipe, modération, suppression de compte, paiements |
| **Triggers** | compteurs et note des organisateurs, totaux des types de billets, notifications, seuil de signalements, instantanés des billets |
| **Middleware de requête** | compte suspendu refusé à la requête suivante, écritures limitées en débit |
| **pg_cron + file de jobs** | rappels J-1, libération des places tenues, rétention ; push, remboursements et nettoyage des fichiers mis en file et exécutés par le worker |
| **Auth** | email + mot de passe avec **confirmation obligatoire**, **Google**, réinitialisation, changement de mot de passe |
| **Storage** | bannières d'événements (taille, type et chemin imposés) |
| **Realtime** | jauges, billets, liste des participants, compteur d'entrées, cloche de notifications, file de modération en direct |
| **Edge Functions** | Stripe Checkout, remboursements, webhook signé, worker (FCM, Stripe, Storage), instantané public d'un événement |
| Firebase | **FCM** (livraison des push), **Crashlytics**, **Analytics sur consentement**, **Hosting** (page `/e/{id}`, retours de paiement, App Links) |

---

## 2. Fonctionnalités

### 2.1 Compte (les deux rôles)

| Fonctionnalité | Détail |
|---|---|
| Inscription | 2 étapes (identité → rôle définitif), jauge de robustesse (8 caractères, lettres et chiffres) ; **le profil est créé par la base avec le compte**, puis l'app invite à ouvrir le lien de confirmation reçu par email |
| Connexion | email + mot de passe (adresse confirmée), ou **« Continuer avec Google »** (un premier compte Google choisit son rôle sur l'écran de complétion, nom pré-rempli) |
| Confirmation d'email | obligatoire avant la première connexion ; le lien revient dans l'app (`eventhub://auth-callback`) ; renvoi du lien depuis le bandeau |
| Mots de passe | oubli : le lien reçu ouvre l'app sur « Choisissez un mot de passe » (sans l'ancien) ; changement avec l'actuel |
| Profil | identité, statistiques du rôle, modification du nom (et de la **présentation publique** pour un organisateur) |
| **Profil organisateur public** | `/organizers/{id}`, ouvert depuis la fiche d'un événement : présentation, nombre d'événements, d'abonnés et note moyenne (tous maintenus par la base), dates à venir puis passées, bouton **Suivre** |
| **Abonnements** | « Organisateurs suivis » : liste, désabonnement ; push à chaque nouvel événement publié par un organisateur suivi |
| **Signalement** | événement, organisateur ou avis : motif dans une liste fermée + précisions ; anonyme ; un signalement par compte et par contenu ; un avis signalé par 3 personnes est masqué en attendant la modération |
| Paramètres | thème ; notifications (préférences lues par la base à chaque envoi, dont « Nouveaux événements ») ; **mesure d'audience** ; **suppression du compte** (ré-authentification par mot de passe ou Google, une seule transaction côté serveur) |
| Centre de notifications | historique 30 jours, groupé par jour, « tout lire », balayage pour supprimer, tap vers l'écran concerné ; cloche à pastille en direct |
| Aide · Confidentialité · À propos | FAQ, notice fondée sur les vraies règles, version, projet Supabase utilisé |

### 2.2 Participant — Explorer · Recherche · Billets · Profil

| Fonctionnalité | Détail |
|---|---|
| Fil éditorialisé | à la une, **pour vous**, ça se remplit vite, cette semaine, catalogue **paginé** (100 en temps réel, puis « Charger plus ») |
| **Pour vous** | recommandations calculées sur l'appareil : organisateurs suivis (+4), catégories des billets (+3) et des favoris (+2), remplissage pour départager ; jamais un événement complet, commencé, déjà réservé ou déjà en favori |
| Recherche et filtres | titre, lieu, organisateur, catégorie ; période, tri, masquer les complets |
| **Favoris** | cœur sur les cartes et la fiche (bascule immédiate, annulée si l'écriture échoue) ; écran « Mes favoris » (événements complets et passés compris ; un événement supprimé disparaît de la liste) |
| Fiche événement | 4 états, **prix** (« Gratuit », « 25,00 € », « Dès 15,00 € »), jauge temps réel, **« Soa, Hery R. et 40 autres y vont »**, organisateur cliquable, signalement |
| **Types de billets** | section « Billets » de la fiche : chaque type (Standard, VIP, Étudiant…) avec sa description, son prix et ses places restantes, « Complet » par type ; au moment de réserver, choix du type dans une feuille |
| **Paiement** | un billet payant ouvre la page **Stripe Checkout** (carte, Apple/Google Pay selon l'appareil) ; la place est **tenue 30 minutes** ; retour automatique dans l'app, écran « Paiement en cours » qui bascule sur le billet dès que Stripe confirme ; « Reprendre le paiement » ou « Abandonner » tant que la place est tenue ; montant payé sur le billet |
| **Remboursement** | « Annuler et être remboursé » sur un billet payé, jusqu'au début de l'événement : remboursement Stripe intégral, place remise en vente |
| **Partage** | feuille de partage native, lien public `https://eventhub-d411f.web.app/e/{id}` (page web pour qui n'a pas l'app, ouverture directe dans l'app sur Android), invitation prête à coller |
| Réserver / annuler | une fonction de la base verrouille l'événement : **aucune survente possible**, même à plusieurs au même instant ; re-réservation possible |
| **Liste d'attente** | sur un événement complet : rejoindre / quitter ; push dès qu'une place se libère |
| Billet | QR code + code `EH-XXXX-XXXX`, états annulé / passé |
| Rappel J-1 | push la veille, ouvre le billet (un seul rappel par billet, rattrapé si une exécution est manquée) |
| **Avis** | après le début de l'événement, pour les inscrits vérifiés : note 1–5 et commentaire, modifiable ; moyenne et répartition sur la fiche |

### 2.3 Organisateur — Événements · Stats · Alertes · Profil

| Fonctionnalité | Détail |
|---|---|
| Mes événements | KPI, à venir / passés, co-organisés ; suppression bloquée (avec explication) s'il y a des réservations |
| Créer / modifier | bannière (Storage), validation immédiate dans le formulaire puis par la base (erreurs affichées champ par champ), email vérifié requis pour publier ; les billets existants suivent un changement de date, de titre ou de lieu |
| **Types de billets et prix** | interrupteur « Plusieurs types de billets » : jusqu'à 6 types (nom ≤ 40, description ≤ 160, places, prix), devise EUR, USD ou MGA ; la capacité est la somme des types. Un type qui a vendu ne peut pas être supprimé ni descendre sous ses ventes ; on ne bascule plus entre « capacité unique » et « types » une fois des places vendues ; la devise se fige après un paiement |
| Participants | type de billet sur chaque ligne, recherche, **export CSV en fichier** (colonnes Billet et Montant payé ; feuille de partage : Drive, email, tableur ; UTF-8 avec BOM pour Excel, séparateur `;`) ou copie, **compteur d'entrées**, **personnes en liste d'attente**, marqueur « Entré · HH:mm » |
| Profil public | présentation modifiable, abonnés, note moyenne sur les avis visibles ; chaque publication prévient les abonnés |
| **Équipe (co-organisateurs)** | l'organisateur principal invite jusqu'à 10 organisateurs par email ; l'invité accepte ou refuse depuis « Invitations » ; un co-organisateur modifie l'événement, voit les participants, scanne les billets et reçoit les alertes de réservation, mais ne supprime pas l'événement et ne compose pas l'équipe ; il peut la quitter |
| **Contrôle à l'entrée** | scanner caméra (lampe), verdict plein écran en couleur : entrée validée, déjà scanné (heure), billet annulé, non payé, autre événement, code invalide, introuvable ; saisie manuelle du code ; retour haptique distinct ; **verdict décidé et enregistré en une instruction** : deux portes qui scannent le même billet n'admettent qu'une personne |
| Stats · Alertes | remplissage, **recettes encaissées** par devise, 14 jours de réservations (graphique + tableau), classement ; à surveiller + journal |
| Push | réservation et annulation en temps réel, pour le principal et chaque co-organisateur |

### 2.4 Administration (compte administrateur, quel que soit son rôle métier)

| Fonctionnalité | Détail |
|---|---|
| **File de modération** | Profil → Modération (pastille du nombre de dossiers ouverts, en direct) : « À traiter » trié par nombre de signalements, « Traités » par date ; filtre Avis / Événements / Organisateurs ; marque « Masqué auto » |
| **Dossier** | contenu signalé tel quel (avis masqué compris, événement avec description, compte avec email), chaque signalement (motif, précisions, date, clé courte du signaleur), historique des décisions |
| **Décisions** | avis : masquer / rétablir ; événement : **retirer** (réservations annulées, billets payés remboursés, inscrits et organisateur prévenus, suppression) ; compte : **suspendre** (refusé dès la requête suivante, sessions révoquées) / réactiver ; tous : classer sans suite. Conséquence expliquée avant confirmation, note obligatoire quand une personne perd quelque chose |
| **Administrateurs** | liste, ajout par email, retrait (jamais soi-même) |

### 2.5 Transverse

Bandeau **hors ligne** (ce qui est déjà à l'écran reste consultable ; les
écritures demandent le réseau), rapport de plantage, consentement à la mesure
d'audience demandé une fois.

---

## 3. Mise en route

Prérequis : Flutter 3.47+, Node 22+ (tests de la base, CLI Supabase via
`npx`), un appareil Android **avec Google Play** (push), `make` (Git Bash /
WSL sous Windows). **Ni Docker ni Java** ne sont nécessaires.

```sh
git clone <repo> eventhub && cd eventhub
make setup              # pub get + génération de code
make db-setup           # dépendances de la suite de tests de la base (PGlite)
make test-db            # toutes les migrations + 39 tests, en local, en ~15 s
```

### 3.1 Projet Supabase (une seule fois)

1. **Créer le projet** sur [supabase.com](https://supabase.com) (région proche
   des utilisateurs), noter la **référence** (`https://<ref>.supabase.co`) et
   le **mot de passe de la base**.
2. **Relier ce dossier et appliquer les migrations** :
   ```sh
   make supabase-login                       # ouvre le navigateur
   make supabase-link PROJECT_REF=<ref>      # demande le mot de passe de la base
   make db-push                              # lance d'abord make test-db, puis applique les 11 migrations
   ```
   Les extensions `pg_cron`, `pg_net`, `pgcrypto` et `citext` sont activées par
   les migrations ; les quatre tâches planifiées (`eventhub-*`) apparaissent
   dans *Integrations → Cron*.
3. **Auth** : `make config-push` applique `supabase/config.toml` (confirmation
   d'email obligatoire, mot de passe de 8 caractères avec lettres et chiffres,
   redirections `eventhub://auth-callback` et site public). Pour **Google** :
   dans Google Cloud, créer un client OAuth *Web* (ID et secret) et un client
   *Android* (package + **SHA-1** de la clé de signature, voir
   `android/key.properties.example`) ; renseigner l'ID et le secret Web dans
   *Authentication → Providers → Google* (ou via
   `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` / `_SECRET` avant `config-push`) ;
   l'ID Web va aussi dans `GOOGLE_SERVER_CLIENT_ID`.
4. **Secrets des Edge Functions** : copier `supabase/functions/.env.example`
   en `supabase/functions/.env` (ignoré par Git) et le remplir :
   - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (étape 6) ;
   - `WORKER_SECRET` : `openssl rand -hex 32` ;
   - `FCM_SERVICE_ACCOUNT` : JSON sur une ligne d'un compte de service
     Firebase avec le rôle *Firebase Cloud Messaging API Admin* ;
   - `PUBLIC_ORIGIN` : `https://eventhub-d411f.web.app`.

   Puis :
   ```sh
   make secrets-push
   make functions-deploy     # deno check puis déploiement des 6 fonctions
   ```
5. **Réveil du worker** : dans *SQL Editor*, exécuter
   `supabase/snippets/wire_worker.sql` avec la référence du projet et le même
   `WORKER_SECRET` (URL et secret rangés dans **Vault**, jamais dans une
   migration). Sans cette étape, push, remboursements en file et nettoyage des
   fichiers attendent.
6. **Stripe (billets payants)** : compte Stripe en mode test pour commencer.
   Dans *Développeurs → Webhooks*, ajouter
   `https://<ref>.supabase.co/functions/v1/stripe-webhook` avec les événements
   `checkout.session.completed`, `checkout.session.async_payment_succeeded`,
   `checkout.session.expired`, `checkout.session.async_payment_failed` ;
   copier son secret de signature dans `STRIPE_WEBHOOK_SECRET`, puis
   `make secrets-push`. Sans ces secrets, tout fonctionne sauf l'achat d'un
   billet payant (« Le paiement est indisponible pour le moment »).
7. **Premier administrateur** : le compte doit exister dans l'app ; dans
   *SQL Editor*, exécuter `supabase/snippets/grant_admin.sql` avec son email.
   La personne se déconnecte puis se reconnecte : l'entrée **Modération**
   apparaît. Les administrateurs suivants s'ajoutent depuis l'app.

### 3.2 Firebase (push, Crashlytics, Analytics, Hosting)

Projet `eventhub-d411f` (`.firebaserc`). `lib/firebase_options.dart` est
généré par FlutterFire et **versionné** (`flutterfire configure --project=eventhub-d411f`
pour le régénérer) : il ne contient que les clés client Firebase, présentes de
toute façon dans chaque build de l'app ; restreindre ces clés dans Google Cloud
(applications Android/iOS/web autorisées) reste la bonne pratique.

1. **Cloud Messaging** : *Web Push certificates* → générer la clé
   (`FIREBASE_WEB_VAPID_KEY`) ; iOS : téléverser la clé APNs. Le compte de
   service de l'étape 3.1.4 vient de *Paramètres du projet → Comptes de service*.
2. **Crashlytics** et **Analytics** : activer dans la console.
3. **Hosting** : le site sert `hosting/public` (accueil, `/e/{id}`, retours
   `/pay/success` et `/pay/cancel`, `.well-known/assetlinks.json`).
   `make hosting-deploy` écrit d'abord `eventhub-config.js` depuis
   `env/prod.json`. Pour qu'Android ouvre ces liens dans l'app,
   `assetlinks.json` doit contenir l'empreinte **SHA-256** de chaque clé de
   signature : celle de la clé de debug de ce poste y est ; **ajouter celle de
   la clé release** avant publication.

### 3.3 Lancer

`env/dev.json` est **versionné** avec l'URL et la clé publique du projet de
développement (valeurs publiques par nature, la RLS protège les données) ; pour
un autre projet, copier `env/example.json` et le remplir
(URL et clé *anon / publishable* du projet, *Project Settings → API*), puis :

```sh
make run DEVICE=<id>            # flutter run --dart-define-from-file=env/dev.json
```

Sans `GOOGLE_SERVER_CLIENT_ID`, le bouton Google est masqué sur Android. Au
premier lancement il n'y a aucun compte : on s'inscrit depuis l'app. Sans
`SUPABASE_URL` / `SUPABASE_ANON_KEY`, l'écran de démarrage explique la
configuration manquante.

### 3.4 Release Android

Copier `android/key.properties.example` en `android/key.properties`, créer la
keystore, enregistrer son SHA-1 (client OAuth Android) et son SHA-256
(`assetlinks.json`), remplir `env/prod.json`, puis `make build-apk FLAVOR=prod`.
Sans `key.properties`, un build release est signé avec la clé de debug et **ne
doit pas être publié**.

---

## 4. Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.47 / Dart 3.13 |
| État | Riverpod 3 + `riverpod_generator` |
| Navigation | go_router 18 (`StatefulShellRoute` par rôle, guard pur) |
| Modèles | freezed 4 + json_serializable (DTO en snake_case, miroir des tables) |
| Backend | `supabase_flutter` 2 (PostgREST, Auth PKCE, Storage, Realtime, Functions) |
| Base | Postgres 17 : RLS, droits par colonne, fonctions `SECURITY DEFINER`, triggers, `pg_cron`, `pg_net`, Vault |
| Serveur | Edge Functions Deno 2 (TypeScript), `stripe` (Checkout, webhooks signés, remboursements), FCM HTTP v1 |
| Firebase | `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics` |
| Auth tierce | `google_sign_in` 7 (jeton d'identité natif) / redirection OAuth (web) |
| Appareil | `flutter_local_notifications`, `mobile_scanner`, `connectivity_plus`, `image_picker`, `qr_flutter`, `share_plus`, `url_launcher`, `shared_preferences` |
| UI | Material 3 clair/sombre, `google_fonts`, `cached_network_image` |
| Qualité | `flutter_lints` strict, `riverpod_lint`, `mocktail`, PGlite + `node:test` (base), `deno check`, GitHub Actions |

---

## 5. Architecture

Feature-first, en couches (`domain` · `data` · `application` · `presentation`).
Référence : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```
lib/
├── bootstrap.dart            Supabase (PKCE), Firebase (FCM, Crashlytics), handler FCM, ProviderScope
├── app/                      MaterialApp, thèmes, bandeau hors ligne, consentement, lien de récupération
├── routes/                   AppRoutes, RouteGuard (pur, testé), routeur, observateur → Analytics
├── core/
│   ├── supabase/             client, flux Realtime résilients, noms des tables / fonctions / buckets, dates
│   ├── errors/ · result/     Failure, ErrorMapper (PostgREST, Edge Functions, Auth, Storage), Result, guard
│   ├── analytics/ · connectivity/ · config/ · firebase/ · l10n/ · utils/
│   └── widgets/              design system, OfflineAware, feuille de consentement
└── features/
    ├── auth/                 email + confirmation, Google, récupération, profil, paramètres, suppression
    ├── events/               catalogue paginé, recherche, fiche, formulaire (save_event), bannières, preuve sociale
    ├── reservations/         reserve_seat, paiement Stripe, remboursement, portefeuille, billet
    ├── team/ · admin/        co-organisateurs · modération et administrateurs
    ├── favorites/ · waitlist/ · reviews/ · checkin/
    ├── organizer/            dashboard, stats, alertes, participants, export CSV
    ├── organizers/ · moderation/
    ├── notifications/        préférences, appareils (register_device), FCM, centre de notifications
    ├── participant/          coque participant, recommandations « Pour vous »
    └── onboarding/ · support/

supabase/
├── config.toml               Auth (confirmation, redirections, Google), JWT des Edge Functions
├── migrations/               11 migrations ordonnées (voir §6–8)
├── functions/                payments-checkout · payments-cancel · payments-refund · stripe-webhook
│                             · worker · public-event · _shared (middleware, Stripe, FCM)
├── tests/                    suite d'intégration de la base sur PGlite (Postgres 17, sans Docker)
└── snippets/                 premier administrateur, secrets du worker (SQL Editor)
hosting/public/               accueil, /e/{id}, pay/success · pay/cancel, .well-known/assetlinks.json
env/                          clés de build publiques par flavor (dev.json et example.json versionnés, jamais de secret)
```

Règle de dépendance : `presentation → application → domain ← data`. Seule
`data` importe `supabase_flutter` (ou `firebase_messaging` pour le push). Une
feature n'importe jamais la couche `data` d'une autre ; elle compose ses
providers.

---

## 6. Modèle de données

Schéma complet : `supabase/migrations/20260914120100_schema.sql`.

```
auth.users ─┐
            └─ profiles (privé)            id, name, email, role, bio, photo_url, suspended_at, created_at, updated_at
                ├─ notification_preferences  event_reminders, booking_alerts, followed_organizers
                ├─ devices                    device_id, token (unique), platform, locale
                ├─ notifications              type, title, body, event_id, reservation_id, read_at, expires_at (30 j)
                ├─ favorites                  event_id
                └─ follows                    organizer_id

organizers (public, maintenu par triggers)  name, bio, photo_url, member_since, follower_count, event_count,
                                            rating_sum, rating_count, suspended
administrators                              user_id, email, name, granted_by, granted_at

events                                      organizer_id, organizer_name, title, description, category, starts_at,
                                            location, image_url, capacity, available_places, currency (EUR·USD·MGA)
  ├─ event_tiers        [≤ 6]               name (≤ 40), description (≤ 160), price (unités mineures), capacity,
  │                                         available, position — capacity/available de l'événement = sommes
  ├─ event_staff        [≤ 10]              user_id
  ├─ staff_invitations                      user_id, email, name, invited_by(_name), event_title, event_starts_at,
  │                                         status (pending · accepted · declined), responded_at
  ├─ waitlist_entries                       user_id, user_name, created_at, notified_at
  └─ checkins                               reservation_id, scanned_by, scanned_at

reservations  UNIQUE (event_id, user_id)    user_name, user_email, event_title, event_starts_at, event_location,
                                            status (pending · confirmed · cancelled), reserved_at, cancelled_at,
                                            cancelled_by, tier_id, tier_name, price_paid, amount_due, currency,
                                            payment_status, checkout_session_id, checkout_url, hold_expires_at,
                                            payment_intent_id, refund_id, reminder_sent_at

reviews       UNIQUE (event_id, author_id)  organizer_id, author_name, rating (1–5), comment, hidden, moderated_at…
reports       UNIQUE (cible, signaleur)     target_type, target_id, reason, details
moderation_queue · moderation_decisions     report_count, last_reason, status, auto_hidden, decision…

private.jobs · private.audit_log · private.rate_limits   (jamais exposés par l'API)
```

Choix structurants :

- **Identifiants UUID** partout ; l'unicité (une réservation, un avis, un
  signalement par personne) est une contrainte `UNIQUE`, pas une convention
  d'identifiant. Le code billet reste dérivé de l'id, jamais stocké.
- **L'historique survit** : un événement ou un compte supprimé met
  `event_id` / `user_id` à `NULL` ; les colonnes instantanées (titre, date,
  lieu, nom anonymisé) gardent le billet prouvable.
- **Montants en unités mineures entières** (centimes ; ariary pour MGA, devise
  sans décimale chez Stripe) : aucun flottant ne touche un prix.
- **Dénormalisation assumée** : la réservation copie l'événement et le
  participant (portefeuille, liste d'invités, entrée sans jointure) ; un
  trigger la tient à jour si l'organisateur déplace l'événement.

---

## 7. Règles métier

Chaque règle est vérifiée **deux fois** : dans l'app pour une réponse
immédiate, puis dans la base, qui décide.

| Règle | App | Base |
|---|---|---|
| Une réservation par participant et par événement | `ReservationPolicy` | `UNIQUE` + `reserve_seat` |
| Pas de réservation sur un événement complet / commencé ; aucune survente | `ReservationPolicy` | `reserve_seat` (événement verrouillé) |
| Re-réservation après annulation | nouvelle date | `reserve_seat` réutilise la ligne, efface l'annulation |
| Publier un événement | email vérifié (`EventFormController`) | `save_event` : organisateur, email confirmé, date future |
| Supprimer un événement | `EventPolicy.canDelete` : aucune place prise | `delete_event` : principal seulement, aucune place prise |
| Types de billets | `EventDraft.validate`, `TierPlanner` | `save_event` : ≤ 6, noms uniques, ventes conservées, type vendu non supprimable, mode et devise figés après vente ; totaux par trigger |
| Réserver un type gratuit | `canReserve(tierId)` | `reserve_seat` : le type existe, est gratuit, a une place |
| Acheter un type payant | `canCheckout` | **jamais par l'app** : `payments-checkout` → `payments_hold_seat` tient la place 30 min ; le montant vient de la base |
| Confirmer un paiement | écran « Paiement en cours » en lecture seule | `stripe-webhook` (signature) → `payments_fulfill` ; place relâchée entre-temps : reprise s'il en reste, **sinon remboursement** |
| Place tenue abandonnée | « Abandonner » | `payments-cancel`, webhook `expired`, balayage `pg_cron` toutes les 10 min (5 min de marge après Stripe) |
| Annuler un billet payé | `canCancel` le refuse, `canRefund` : actif, payé, avant le début | `payments-refund` : Stripe rembourse d'abord, la place revient ensuite |
| Liste d'attente | `WaitlistPolicy` : participant, complet, à venir, sans place | `join_waitlist` ; trigger : une notification par place libérée, la plus ancienne d'abord |
| Avis | `ReviewPolicy` : inscrit confirmé, événement commencé, email vérifié, 1–5, ≤ 2 000 | RLS à l'insertion + triggers (auteur, nom, note de l'organisateur) |
| Entrée | `CheckInPolicy.precheck` : identifiant valide, code conforme | `check_in_ticket` : bon événement, payé, non annulé, non déjà scanné — décidé et enregistré ensemble |
| Suppression de compte | ré-authentification | `delete_my_account` : refus si événement à venir avec participants ; places libérées, payées remboursées ; anonymisation ; fichiers en file |
| Rôle | inchangeable | droits par colonne + trigger |
| S'abonner | `FollowPolicy` : pas à soi-même | `CHECK` + compteur par trigger |
| Signaler | `ReportPolicy` : motif de la liste, précisions si « Autre », ≤ 2 000 | `UNIQUE` (un par compte) + trigger : contenu existant, pas le sien |
| Masquer un avis | automatique à 3 signalements distincts, ou décision admin | trigger de seuil / `moderate_content` ; une décision humaine n'est jamais écrasée ; la RLS cache l'avis masqué |
| Profil public | le client ne l'écrit jamais | triggers depuis `profiles` |
| Équipe d'un événement | `EventPolicy`, `TeamPolicy` (email, pas soi-même, à venir, ≤ 10 invitations comprises) | `invite_co_organizer` (compte organisateur existant), `respond_to_staff_invite`, `remove_co_organizer` ; `is_event_team()` dans la RLS |
| Événement retiré par la modération | — | `moderate_content` : billets annulés, payés remboursés via la file (`refund_failed` si Stripe échoue après 8 essais) |

---

## 8. Sécurité

La base est le seul contrôle qui s'exécute réellement : la clé `anon` est
publique, n'importe quel compte peut appeler l'API avec une requête fabriquée.
Quatre couches se superposent : **middleware de requête** (compte suspendu,
limitation de débit), **droits par colonne**, **Row Level Security** sur chaque
table, **fonctions et triggers** en transaction avec un ordre de verrouillage
unique. Les fonctions de paiement et la file de jobs ne sont exécutables que par
le rôle serveur des Edge Functions. Tout est détaillé et testé sous les vrais
rôles : [`docs/SECURITY.md`](docs/SECURITY.md).

> ⚠️ Toute modification du modèle, d'une règle ou d'une fonction passe par une
> **nouvelle migration** (jamais par l'éditeur SQL), un test dans
> `supabase/tests/db`, puis `make db-push`.

---

## 9. Notifications push

| Notification | Destinataire | Déclencheur (base) | Tap ouvre | Préférence |
|---|---|---|---|---|
| Nouvelle réservation / annulation | organisateur **et co-organisateurs** | trigger `reservations_after_write` | liste des participants | `booking_alerts` (chacun la sienne) |
| Invitation à co-organiser · Nouveau co-organisateur · Retiré de l'équipe | invité · principal · membre retiré | `invite_co_organizer` · `respond_to_staff_invite` · `remove_co_organizer` | invitations · équipe · tableau de bord | — (transactionnel) |
| Paiement confirmé · Paiement remboursé | acheteur | `payments_fulfill` · `payments_mark_refunded` | billet · fiche | — (transactionnel) |
| Événement annulé · Avis masqué | détenteurs et organisateur · auteur | `moderate_content`, trigger de seuil | billets · fiche | — (transactionnel) |
| Demain : … | participant | `pg_cron` → `send_event_reminders` (horaire, un rappel par billet) | billet | `event_reminders` |
| Une place s'est libérée | participant en attente | trigger `events_after_update` | fiche de l'événement | `event_reminders` |
| « Mirindra publie un événement » | abonnés de l'organisateur | trigger `events_after_insert` (événement à venir) | fiche de l'événement | `followed_organizers` |
| « Bienvenue sur EventHub, Soa » (inscription confirmée, texte selon le rôle) | le nouveau compte, **une seule fois** | `register_device` au premier appareil enregistré, c'est-à-dire juste après la première connexion (`profiles.welcomed_at`) | écran de bienvenue → accueil du rôle | — (transactionnel) |

> Pourquoi pas au moment de l'inscription ? Un push vise un **appareil
> rattaché au compte**, et ce rattachement n'existe qu'une fois connecté ; avec
> la confirmation d'email obligatoire, il n'y a pas de session à l'inscription.
> L'email couvre l'inscription, le push de bienvenue la première connexion.

Chaque notification est une ligne de `notifications` (centre de notifications,
30 jours), écrite dans la transaction qui la cause. Un trigger met en file un
job `push` si le destinataire a un appareil ; le worker l'envoie par **FCM
HTTP v1** et oublie les jetons refusés. Côté app, `PushNotifications` suit la
session (permission, jeton, affichage au premier plan, tap) ; chaque
installation a son identifiant d'appareil, `register_device` retire un jeton
d'un autre compte, et le jeton est invalidé à la déconnexion. Web :
`web/firebase-messaging-sw.js` + clé VAPID.

---

## 10. Production : Crashlytics, Analytics, hors ligne

| Sujet | Mise en œuvre |
|---|---|
| Crashlytics | erreurs Flutter et plateforme (fatales) + `AppLogger.error` (non fatales), désactivé en debug, identifiant technique du compte |
| Analytics | **opt-in** (collecte coupée par défaut dans le manifeste et l'`Info.plist`), feuille de consentement unique, interrupteur dans les Paramètres ; vues d'écran via l'observateur de routes ; événements : `login`, `sign_up`, `event_published`, `reservation_confirmed/cancelled`, `checkout_started`, `share`, `add_to_wishlist`, `waitlist_joined`, `review_published`, `ticket_scanned`, `organizer_followed/unfollowed`, `content_reported` (type et motif seulement) |
| Journaux serveur | une ligne JSON par requête d'Edge Function (statut, durée, règle, identifiant de requête) ; `private.audit_log` pour chaque décision et mouvement d'argent (1 an) |
| Hors ligne | bandeau global via `connectivity_plus` ; ce qui est à l'écran reste consultable ; flux Realtime résilients (réabonnement automatique) ; pas de cache local de la base |
| Pagination | première page temps réel, pages suivantes par curseur `(starts_at, id)` |
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
| Mot de passe oublié / changement / récupération · Profil incomplet | `/forgot-password` · `/change-password` · `/change-password?recovery=1` · `/complete-profile` |
| Explorer · Recherche · Billets · Profil | `/events` · `/search` · `/reservations` · `/profile` |
| Fiche événement (favori, partage, liste d'attente, avis, signalement) | `/events/:eventId` |
| Lien partagé (App Links) → fiche | `/e/:eventId` |
| Profil organisateur public · Organisateurs suivis | `/organizers/:organizerId` · `/following` |
| Modération · Dossier · Administrateurs | `/admin/moderation` · `/admin/moderation/:entryId` · `/admin/roles` |
| Confirmation · Billet | `/reservations/:reservationId/confirmation` · `/reservations/:reservationId/ticket` |
| Paiement en cours · retours Stripe (App Links → écran de paiement) | `/reservations/:reservationId/payment` · `/pay/success` · `/pay/cancel` |
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

**Build** — `env/<flavor>.json` (`dev.json` versionné car il ne contient que des valeurs publiques ; les autres flavors restent locaux, modèle `env/example.json`),
passé par `make run` / `make build-apk` avec `--dart-define-from-file` :

| Clé | Effet |
|---|---|
| `FLAVOR` | `dev` (défaut), `staging`, `prod` (argument de `make`) |
| `SUPABASE_URL` · `SUPABASE_ANON_KEY` | projet Supabase ; clé publique par construction (la RLS protège) ; sans elles, écran de configuration |
| `GOOGLE_SERVER_CLIENT_ID` | ID client OAuth web ; requis pour Google Sign-In sur Android |
| `FIREBASE_WEB_VAPID_KEY` | clé Web Push ; sans elle, pas de push sur le web |

**Serveur** — secrets des Edge Functions (`supabase/functions/.env` →
`make secrets-push`) et Vault :

| Secret / paramètre | Où | À aligner avec |
|---|---|---|
| `STRIPE_SECRET_KEY` · `STRIPE_WEBHOOK_SECRET` | secrets des fonctions | compte Stripe, point de terminaison du webhook |
| `WORKER_SECRET` | secrets des fonctions **et** Vault `eventhub_worker_secret` | `supabase/snippets/wire_worker.sql` |
| `eventhub_functions_url` | Vault | `https://<ref>.supabase.co/functions/v1` |
| `FCM_SERVICE_ACCOUNT` | secrets des fonctions | projet Firebase de l'app (FCM) |
| `PUBLIC_ORIGIN` | secrets des fonctions | domaine Hosting (pages `/pay/*`, liens partagés) |
| `HOLD_MINUTES` (31) | `supabase/functions/payments-checkout` | minimum de 30 min imposé par Stripe |

**Constantes à garder alignées** :

| Constante | Où | Avec |
|---|---|---|
| `eventhub://auth-callback` | `AppConfig.authRedirectUrl` | `supabase/config.toml` (`additional_redirect_urls`), intent filter Android |
| `eventhub_default` | canal Android | manifeste, `_shared/fcm.ts`, app |
| limites des types de billets (6, 40, 160) | `EventTier`, `EventDraft` | migrations 5 et 11 |
| bloc `flutter` de `firebase.json` | `flutterfire configure` | régénère `lib/firebase_options.dart` (versionné) et `android/app/google-services.json` (non utilisé par le build, ignoré) |
| `applicationId` | `build.gradle.kts` | app Android Firebase, client OAuth Android |

---

## 14. Qualité : lint, tests, CI

- **Analyse** : zéro issue (`flutter_lints` strict, `riverpod_lint`).
- **Tests Dart** (`make test`, **232**) : policies (réservation gratuite,
  achat, annulation et remboursement, événement, équipe, modération, liste
  d'attente, avis, entrée), montants, types de billets (`TierPlanner`,
  validation, lecture des lignes, payload de `save_event`), chemins de
  bannières, code billet, CSV, stats (recettes) et alertes, catalogue paginé,
  recommandations, preuve sociale, profil public, notifications (lignes,
  préférences, routage des données FCM), **mapping de toutes les familles
  d'erreurs** (PostgREST, Edge Functions, Auth, Storage), logger, `RouteGuard` ;
  widgets et goldens.
- **Tests de la base** (`make test-db`, **39**) : les 11 migrations appliquées
  dans l'ordre sur **PGlite** (Postgres 17 en WebAssembly, sans Docker ni
  projet distant), puis des scénarios exécutés **sous les vrais rôles** :
  droits et RLS (rôle immuable, profils privés, API fermée à `anon`, fonctions
  serveur inaccessibles), suspension immédiate, jetons d'appareil, premier
  administrateur, profil créé à l'inscription, publication et types de billets
  (ventes protégées, descriptions, limites), survente impossible, liste des
  participants limitée à l'équipe, liste d'attente, verdict d'entrée atomique,
  prénoms courts, rappels uniques, push en file, paiements (place tenue et
  reprise, webhook rejoué, paiement tardif re-placé ou remboursé, balayage,
  remboursement, devise figée), avis réservés aux présents, signalements et
  seuil, décision humaine prioritaire, suspension, retrait d'un événement payé,
  équipe, suppression de compte, file de jobs et tâches planifiées.
- **Edge Functions** (`make functions-check`) : `deno check` strict des six
  fonctions et du middleware.
- **CI** : `quality` (format, analyse, tests Dart), `database` (PGlite),
  `edge-functions` (Deno), `android` (APK dev).

---

## 15. Commandes

| Commande | Rôle |
|---|---|
| `make setup` · `make gen` | dépendances, génération de code |
| `make analyze` · `make format` · `make test` | qualité Dart |
| `make db-setup` · `make test-db` | suite de la base (PGlite) |
| `make functions-check` | typage des Edge Functions |
| `make run DEVICE=<id>` · `make build-apk FLAVOR=prod` | lancer · APK release (`env/<flavor>.json`) |
| `make supabase-login` · `make supabase-link PROJECT_REF=<ref>` | relier la CLI au projet |
| `make db-push` | tests de la base puis migrations en attente |
| `make config-push` | réglages Auth de `supabase/config.toml` |
| `make secrets-push` · `make functions-deploy` | secrets puis déploiement des Edge Functions |
| `make hosting-deploy` | site public (écrit `eventhub-config.js` puis `firebase deploy --only hosting`) |
| `make deploy` | migrations, fonctions et Hosting |
| `make grant-admin EMAIL=…` | rappelle la requête SQL du premier administrateur |

---

## 16. Scénario de démonstration

Deux appareils Android, projet déployé (§3).

1. **Organisateur** : inscription (email) → lien de confirmation → connexion →
   notifications acceptées → publier *Flutter Meetup*, capacité 1.
2. **Participant A** : « Continuer avec Google » → rôle participant → cœur sur
   l'événement → **Réserver**. L'organisateur reçoit « Nouvelle réservation ».
3. **Participant B** : l'événement est complet → **Rejoindre la liste d'attente**.
4. **Participant A** annule → B reçoit « Une place s'est libérée » → réserve.
5. **Organisateur** : Participants → scanner le billet de B → **Entrée validée** ;
   rescanner → **Déjà scanné à HH:mm**.
6. Après le début : B laisse un avis 5 ★ ; la fiche affiche la moyenne.
7. Paramètres de A → **Supprimer mon compte** → mot de passe / Google → compte
   effacé, avis et historique anonymisés.
8. **Participant B** : fiche → nom de l'organisateur → **Suivre**. L'organisateur
   publie un second événement → B reçoit « Mirindra publie un événement » ;
   l'accueil de B affiche le rail **Pour vous**.
9. **Partage** : fiche → Partager… → WhatsApp. Le lien s'ouvre dans l'app sur
   un Android qui l'a installée, et en page web ailleurs.
10. **Signalement** : trois comptes signalent un avis → il disparaît de la
    fiche ; son auteur voit « Votre avis est masqué… ».
11. **Organisateur** : Participants → **Exporter le CSV** → Drive ; le fichier
    s'ouvre correctement dans Excel.
12. **Billet payant** (Stripe en mode test) : l'organisateur active « Plusieurs
    types de billets » → *Standard* gratuit (50) et *VIP* 25,00 € (10, « Accès
    backstage »). A choisit VIP → page Stripe → carte `4242 4242 4242 4242` →
    retour dans l'app : « Paiement en cours » puis le billet, « VIP · 25,00 € ».
    La fiche affiche « VIP · 9 places ».
13. A : billet → **Annuler et être remboursé** → le paiement apparaît remboursé
    dans le tableau de bord Stripe, la place VIP revient en vente.
14. **Modération** : un administrateur suspend un compte → la requête suivante
    de ce compte est refusée, sans attendre l'expiration de son jeton.

---

## 17. Décisions d'architecture (ADR)

| # | Décision | Motivation |
|---|---|---|
| 1 | **Supabase (Postgres) plutôt que Firebase pour les données, l'auth et la logique serveur** | intégrité relationnelle (clés étrangères, `UNIQUE`, `CHECK`), transactions multi-lignes, règles métier au plus près des données, migrations versionnées et testables ; Firebase garde FCM, Crashlytics et Analytics |
| 2 | Écritures métier par fonctions SQL `SECURITY DEFINER`, lectures directes sous RLS | une opération = une transaction qui revérifie tout ; les lectures profitent de PostgREST et de Realtime sans code serveur |
| 3 | Erreurs `PTnnn` + règle dans `hint`, même forme pour les Edge Functions | un seul chemin de mapping dans l'app ; messages français écrits côté serveur |
| 4 | `Result<T>` + `Failure` scellée | erreurs exhaustives, pas de `try/catch` dans l'UI |
| 5 | Aucun backend simulé ; tests de la base sur PGlite | un seul chemin de code ; les vraies migrations éprouvées en local et en CI sans Docker |
| 6 | Ordre de verrouillage unique (événement → réservation → type) | aucune survente, aucun interblocage entre réserver, payer, annuler et modifier |
| 7 | Rôle métier en colonne figée, admin en table sans droit d'écriture, recopiés dans `app_metadata` | la base relit la vérité ; le jeton ne sert qu'à l'affichage ; aucune écriture client ne confère de pouvoir |
| 8 | Confirmation d'email obligatoire, profil créé par trigger à l'inscription | contenu attribuable ; pas de session avant confirmation, donc la base écrit le profil après validation du rôle |
| 9 | Middleware `db_pre_request` | suspension effective immédiatement et limitation de débit sans code dans chaque fonction |
| 10 | Outbox `private.jobs` + worker, réveil `pg_net` après commit et `pg_cron` | un effet externe (push, remboursement) n'existe que si la transaction réussit ; reprise automatique, pas de perte |
| 11 | Push décidés par la base, livrés par FCM depuis une Edge Function | préférences lues à l'envoi, un seul endroit qui cible un appareil, jetons morts oubliés |
| 12 | QR non signé, verdict par `check_in_ticket` + code dérivé | rien à falsifier utilement ; un billet ne sert qu'une fois, même à deux portes |
| 13 | Liste d'attente sans réservation de place | premier arrivé, premier servi, annoncé comme tel ; pas d'expiration à gérer |
| 14 | Catalogue : page live + pages par curseur `(starts_at, id)` | Realtime pour ce qui compte, pagination bornée pour le reste |
| 15 | Flux combinés événements + types + équipe côté client | Realtime ne sait pas joindre ; un événement payant n'apparaît jamais gratuit le temps d'un chargement |
| 16 | Analytics opt-in, jamais bloquant | CNIL ; une mesure ne doit pas casser une réservation ni les tests |
| 17 | Stats et alertes calculées côté client | aucune requête en plus ; volumes MVP |
| 18 | Profil organisateur public dans une table distincte, maintenue par triggers | `profiles` reste privé (email, rôle) ; un compteur écrit par le client ne vaudrait rien |
| 19 | Preuve sociale par fonction (`event_attendance`) : compte exact, prénoms courts, clés hachées | aucune donnée d'inscrit publiée au-delà de « Prénom I. » |
| 20 | Signalements écriture seule, un par compte, masquage automatique des avis seulement | anonymat du signaleur ; seuil de personnes distinctes ; un événement a des billets, un humain tranche |
| 21 | Recommandations sur l'appareil, heuristique explicable | aucun profilage serveur ; chaque suggestion a une raison vraie |
| 22 | Page publique statique sur Hosting alimentée par une Edge Function, App Links vérifiés | lien unique pour app et web ; contenu rendu sans HTML injecté ; aperçus riches possibles avec un domaine personnalisé |
| 23 | Lien profond conservé dans `?from=` à travers splash et connexion, liste blanche de destinations | un lien ouvre souvent l'app à froid ; `from` vient de l'extérieur |
| 24 | Premier administrateur par l'éditeur SQL uniquement | pas de porte dérobée dans l'app ni dans l'API ; chaque décision ensuite journalisée |
| 25 | Co-organisateurs en table `event_staff`, invitations en table dédiée | l'appartenance se prouve par une jointure indexée dans la RLS ; une seule requête pour le principal et l'équipe |
| 26 | Types de billets en table, totaux de l'événement par trigger | contraintes par type (bornes, noms uniques) ; l'événement ne peut pas diverger de ses types |
| 27 | Stripe Checkout hébergé plutôt qu'un formulaire de carte dans l'app | aucune donnée de carte chez nous (PCI SAQ A), 3-D Secure et portefeuilles gérés par Stripe |
| 28 | Place tenue à la création de la session, confirmée par webhook seulement | pas de survente pendant le paiement ; le retour navigateur n'est jamais une preuve |
| 29 | Paiement arrivé sans place → remboursement automatique ; remboursements de masse en file | l'acheteur n'est jamais débité sans billet ; une annulation de masse ne s'arrête pas sur une erreur Stripe |
| 30 | Montants en unités mineures entières, devises fermées (EUR, USD, MGA) | pas d'arrondi flottant ; MGA sans décimale traité comme Stripe l'attend |

---

## 18. Périmètre : ce qui est fait, ce qui reste

**Fait** : tout le cahier des charges et les maquettes, sur un backend Supabase
versionné et testé ; email + Google avec confirmation ; récupération de mot de
passe dans l'app ; suppression de compte ; push (Android, web) et centre de
notifications ; favoris, liste d'attente, avis, contrôle à l'entrée ; stats et
alertes ; pagination ; Crashlytics, Analytics sur consentement ; signature
release ; profils organisateurs publics et abonnements (F-10) ; preuve sociale
(F-07) ; partage natif, page publique et App Links (F-08) ; export CSV (F-15) ;
recommandations (F-18) ; signalement et modération avec administration
(F-19) ; co-organisateurs (F-16) ; types de billets avec descriptions (F-12) ;
billetterie payante Stripe avec remboursements (F-11) ; tests Dart, base et
Edge Functions ; CI.

| Reste | Pourquoi / action |
|---|---|
| **Déploiement** | `make supabase-login`, `make supabase-link`, puis §3.1 (secrets, worker, Stripe, premier administrateur) |
| iOS | build sur Mac, clé APNs, capacités *Push* et *Background modes* dans Xcode, schéma `eventhub://` dans `Info.plist` |
| Clés à fournir | `env/<flavor>.json`, secrets des Edge Functions, keystore release |
| Aperçus riches des liens | domaine personnalisé pour les Edge Functions (la fonction rend déjà l'HTML Open Graph) |
| Cache hors ligne | stockage local des billets à venir pour une ouverture à froid sans réseau |
| CAPTCHA à l'inscription | `[auth.captcha]` si des inscriptions automatisées apparaissent (pas d'App Check sur Supabase) |
| « Add to Cal » | plugin natif de calendrier |
| Empreinte release dans `assetlinks.json` | à ajouter avec la keystore release, sinon les liens s'ouvrent dans le navigateur |
| Stripe Connect | reversement aux organisateurs non inclus : les fonds arrivent sur le compte de la plateforme |
| Séries (F-13), carte (F-14), discussion (F-17), multilingue (F-20) | lot par lot (voir `docs/ROADMAP.md`) |
| Revue juridique | notice de confidentialité et consentement à valider (DPO) |

---

## 19. Dépannage

| Symptôme | Cause / correctif |
|---|---|
| « Configuration Supabase manquante » au démarrage | `env/<flavor>.json` absent ou incomplet ; lancer avec `make run` |
| « Connexion à Firebase impossible » / push absents | `flutterfire configure --project=eventhub-d411f` |
| « Confirmez votre adresse » à la connexion | ouvrir le lien reçu par email (vérifier les indésirables) ; renvoyer depuis l'écran |
| Le lien de confirmation ou de réinitialisation ouvre le navigateur | `eventhub://auth-callback` absent de `additional_redirect_urls` (`make config-push`) ou de l'intent filter |
| Bouton Google absent (Android) | `GOOGLE_SERVER_CLIENT_ID` manquant dans `env/<flavor>.json` |
| Google : échec après le choix du compte | client OAuth Android sans le bon SHA-1, ou fournisseur Google non configuré dans Supabase |
| « Vous n'avez pas les droits pour cette action » | migrations non appliquées (`make db-push`) ou compte sans le rôle requis |
| « Trop de requêtes » | limitation de débit (240 écritures/min par compte, plus fine sur réserver/publier) : réessayer dans une minute |
| « Ce compte est suspendu par la modération » | décision d'un administrateur ; réactivation depuis le dossier |
| Aucune notification | permission refusée, appareil sans Google Play, `FCM_SERVICE_ACCOUNT` absent, worker non relié (`wire_worker.sql`), préférence coupée ; `select status, count(*) from private.jobs group by status` et journaux de la fonction `worker` |
| Suppression de compte refusée | événement à venir avec participants (message explicite) |
| Scanner : caméra indisponible | autoriser la caméra ; ou saisir le code du billet |
| `make test-db` échoue | `make db-setup` une fois (Node 22+) ; le message indique la migration et la ligne fautives |
| `make db-push` : « Access token not provided » | `make supabase-login`, puis `make supabase-link PROJECT_REF=<ref>` |
| Un lien `/e/…` s'ouvre dans le navigateur au lieu de l'app | empreinte SHA-256 absente de `assetlinks.json`, ou Hosting non déployé ; `adb shell pm get-app-links com.example.eventhub` |
| Page `/e/…` : « Cet événement n'existe plus » pour un événement existant | `eventhub-config.js` non régénéré (`make hosting-deploy`) ou fonction `public-event` non déployée |
| « Vous avez déjà signalé ce contenu » | normal : un signalement par compte et par contenu |
| Pas d'entrée « Modération » après `grant_admin.sql` | se déconnecter puis se reconnecter (le rôle d'affichage est dans le jeton) |
| « Le paiement est indisponible pour le moment » | `STRIPE_SECRET_KEY` absent ou invalide ; journaux de `payments-checkout` |
| Paiement effectué mais billet resté « en cours » | webhook non déclaré, mauvais `STRIPE_WEBHOOK_SECRET` (réponses 400 dans Stripe) ou événements manquants ; Stripe relivre automatiquement une fois corrigé |
| « Paiement remboursé » juste après avoir payé | le paiement a abouti après la libération de la place et l'événement était complet : remboursement automatique voulu |
| Réservation au statut `refund_failed` | remboursement de masse refusé 8 fois par Stripe : voir `private.audit_log` (`job.failed`) et rembourser depuis Stripe |
| Types de billets : « Des places ont été vendues… » | un type vendu ne se supprime pas ; le mode et la devise ne changent plus après la première vente |

---

## 20. Contribuer

Branches par tâche, Conventional Commits, CI verte. Toute évolution (écran,
route, dépendance, table, règle, fonction) met à jour **ce README et le
document `docs/` concerné dans la même PR** ; tout changement du modèle ou
d'une règle arrive avec **sa migration et son test de base**
([`docs/CONVENTIONS.md`](docs/CONVENTIONS.md)).
