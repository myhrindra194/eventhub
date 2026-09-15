# EventHub — Modèle de sécurité

> **La base de données est le seul contrôle qui s'exécute réellement.**
> L'application Flutter est une commodité : la clé `anon` est publique par
> construction, et n'importe quel compte peut appeler l'API REST de Supabase
> avec une charge utile fabriquée à la main. Ce document explique ce que le
> serveur garantit, comment, où c'est testé — et ce qu'il ne garantit pas.

Fichiers concernés :

| Fichier | Rôle |
|---|---|
| `supabase/migrations/20260914120000_foundation.sql` | schéma `private`, enums, erreurs typées, audit, limitation de débit |
| `supabase/migrations/20260914120100_schema.sql` | tables, contraintes `CHECK` / `UNIQUE` / clés étrangères |
| `supabase/migrations/20260914120200_security.sql` | droits par colonne, RLS, middleware de requête |
| `supabase/migrations/20260914120300_triggers.sql` | invariants maintenus quel que soit l'auteur de l'écriture |
| `supabase/migrations/20260914120400_api.sql` · `…500_payments.sql` | fonctions métier et paiements |
| `supabase/migrations/20260914120600_jobs_and_schedules.sql` | file de jobs, tâches planifiées |
| `supabase/migrations/20260914120700_storage_realtime_grants.sql` | Storage, Realtime, droits d'exécution des fonctions |
| `supabase/functions/_shared/http.ts` | middleware des Edge Functions |
| `supabase/tests/db/*.test.mjs` | preuves : la suite exécute les attaques sous les vrais rôles |

---

## 1. Modèle de menace

| Attaquant | Capacité | Contre-mesure |
|---|---|---|
| Visiteur anonyme | possède la clé `anon` (elle est dans l'APK) | le rôle `anon` n'a **aucun** droit sur aucune table ni fonction métier |
| Utilisateur curieux | appelle PostgREST avec son propre jeton | RLS : il ne voit que ses lignes, ou celles de l'équipe d'un événement dont il fait partie |
| Utilisateur malveillant | fabrique n'importe quelle requête, colonne, filtre | droits **par colonne**, écritures sensibles uniquement par fonctions qui revérifient tout |
| Script d'abus | boucle d'écritures, comptes jetables | limitation de débit par compte (middleware + par fonction), email confirmé obligatoire pour se connecter |
| Client rétro-conçu | contourne toute validation de l'interface | chaque politique du domaine Dart est réécrite en SQL, dans la transaction |
| Compte suspendu | garde un jeton d'accès valide jusqu'à une heure | refus immédiat par le middleware, sessions révoquées, bannissement Auth |
| Fuite de la clé `service_role` | contournerait la RLS | la clé n'existe que dans l'environnement des Edge Functions, jamais dans l'app ni dans Git |
| Faux webhook Stripe | poste un `checkout.session.completed` inventé | signature vérifiée sur le corps brut, sinon 400 |

---

## 2. Trois couches qui se superposent

```
   requête REST / Realtime (jeton de l'utilisateur)
            │
            ▼
 ┌──────────────────────────────┐
 │ 0. middleware de requête     │  api_pre_request : compte suspendu → 403,
 │                              │  écritures > 240/min → 429
 ├──────────────────────────────┤
 │ 1. droits (GRANT)            │  quelles colonnes un rôle peut insérer / modifier ;
 │                              │  quelles fonctions il peut exécuter
 ├──────────────────────────────┤
 │ 2. Row Level Security        │  quelles lignes il voit et touche
 ├──────────────────────────────┤
 │ 3. fonctions et triggers     │  toutes les règles métier, en transaction,
 │                              │  verrous dans un ordre unique
 └──────────────────────────────┘
```

Chaque couche est suffisante pour son propre périmètre : une colonne non
accordée est refusée **avant** que la RLS soit évaluée ; une ligne hors
politique est invisible **même** si la colonne est accordée ; une réservation
n'existe **que** par une fonction qui verrouille l'événement. Aucune ne compte
sur une autre pour être correcte.

---

## 3. Invariants garantis

| # | Invariant | Mécanisme | Test |
|---|---|---|---|
| 1 | Le **rôle** d'un compte est choisi une fois et ne change jamais | colonne `role` non accordée en `UPDATE` + trigger `profiles_before_update` (même pour le code serveur) | `accounts` |
| 2 | L'**email** du profil est celui d'Auth, jamais celui envoyé par le client | trigger `profiles_before_insert` (lit `auth.users`), synchronisé à la confirmation d'un changement | `accounts` |
| 3 | Seul un organisateur **vérifié** publie ; seule l'équipe modifie ; seul le principal supprime, et seulement sans place prise | `save_event`, `delete_event` | `events` |
| 4 | `available_places ∈ [0, capacity]`, et **aucune survente**, même avec des réservations simultanées | `CHECK` + verrou `FOR UPDATE` sur l'événement dans `reserve_seat` / `payments_hold_seat` | `reservations` |
| 5 | La capacité ne descend jamais sous les places vendues ; un type de billet vendu ne se supprime pas ; le mode (capacité unique / types) et la devise se figent après la première vente | `save_event` | `events`, `payments` |
| 6 | Avec des types de billets, les totaux de l'événement sont **exactement** leurs sommes | trigger `event_tiers_sync_totals` dans la même instruction | `events` |
| 7 | **Une réservation par participant et par événement** | contrainte `UNIQUE (event_id, user_id)` | `reservations` |
| 8 | Aucun client ne crée une place tenue, ne confirme un paiement, n'écrit un montant | tables en lecture seule pour `authenticated` ; fonctions `payments_*` exécutables par `service_role` seulement | `accounts`, `payments` |
| 9 | Un billet ne sert **qu'une fois** à la porte, même scanné par deux téléphones au même instant | `check_in_ticket` : `INSERT … ON CONFLICT DO NOTHING` sur la clé primaire | `reservations` |
| 10 | La liste des participants ne sort **jamais** de l'équipe de l'événement | politique `reservations_select` : propriétaire de la ligne, `is_event_team`, ou admin | `reservations` |
| 11 | Un signalement par compte et par contenu ; un avis masqué ne réapparaît pas par le seuil après une décision humaine | `UNIQUE (target_type, target_id, reporter_id)` + `moderated_at` | `moderation` |
| 12 | Aucun pouvoir d'administration ne s'obtient par une écriture client | table `administrators` sans aucun droit d'écriture ; `set_admin_role` exige d'être admin ; premier admin par connexion de confiance seulement | `accounts` |
| 13 | L'historique survit : un billet reste prouvable après la suppression de l'événement ou du compte | clés étrangères `ON DELETE SET NULL` + colonnes instantanées, anonymisation | `team, account deletion` |
| 14 | Tout ce qui n'est pas accordé est refusé | `REVOKE ALL` sur `public` pour `anon` / `authenticated`, `REVOKE EXECUTE` par défaut, puis droits explicites | `accounts` |

---

## 4. Identité et rôles

- **Rôle métier** (`participant` / `organizer`) : colonne de `profiles`, lue par
  `private.my_role()`. Recopiée dans `app_metadata.role` du jeton — non
  modifiable par l'utilisateur — pour que l'app la connaisse dès la connexion,
  mais la base ne se fie **jamais** au jeton pour autoriser : elle relit la
  ligne (lecture par clé primaire, évaluée une fois par requête).
- **Administrateur** : présence dans `public.administrators`, lue par
  `private.is_admin()`. Recopiée dans `app_metadata.admin` pour l'affichage de
  l'entrée « Modération ». Le premier administrateur se crée dans l'éditeur SQL
  (`supabase/snippets/grant_admin.sql`) : `private.grant_admin` n'est exécutable
  par aucun rôle de l'API. Un administrateur ne peut pas retirer son propre
  rôle : le dernier ne peut pas verrouiller le projet.
- **Profil à l'inscription** : la confirmation d'email est obligatoire, il n'y a
  donc pas de session pour écrire le profil. Le nom et le rôle voyagent en
  métadonnées et `private.handle_new_auth_user` crée le profil dans la
  transaction qui crée le compte, **après revalidation** : un rôle inventé
  (`admin`) ou un nom invalide ne crée rien, et l'écran « Compléter le profil »
  prend le relais.
- **Email vérifié** : exigé pour publier un événement et pour laisser un avis
  (`private.is_verified()` lit `auth.users.email_confirmed_at`).

---

## 5. Fonctions `SECURITY DEFINER` : règles d'écriture

Une fonction `SECURITY DEFINER` s'exécute avec les droits de son propriétaire :
c'est ce qui lui permet de verrouiller un événement que l'appelant ne peut pas
modifier. C'est aussi la surface la plus dangereuse. Règles appliquées sans
exception :

1. `set search_path = ''` et **tous** les objets qualifiés (`public.events`,
   `auth.uid()`, `extensions.digest`) : un appelant ne peut pas masquer une
   table ou un opérateur par un objet de son propre schéma.
2. Droit `EXECUTE` **retiré par défaut** (`alter default privileges`), puis
   accordé fonction par fonction dans la migration 8/8 : `authenticated`
   n'exécute que l'API de l'application ; `service_role` seul exécute les
   paiements, la file de jobs et l'instantané public.
3. Les helpers vivent dans le schéma `private`, **non exposé** par PostgREST :
   ils sont appelables depuis une politique RLS, jamais par `/rpc/…`.
4. Chaque fonction de l'API commence par établir l'appelant
   (`private.require_user()`), puis revérifie **toutes** les règles, même celles
   que l'app a déjà vérifiées.
5. Aucune fonction ne reçoit un identifiant d'utilisateur de la part d'un
   client : il vient de `auth.uid()`. Les fonctions `payments_*` reçoivent
   `p_user_id`, mais seule une Edge Function qui a elle-même vérifié le jeton
   peut les appeler.

---

## 6. Portée des lectures

| Table | Qui voit quoi |
|---|---|
| `profiles` | sa propre ligne ; les administrateurs (dossiers de modération) |
| `notification_preferences`, `devices`, `favorites`, `follows`, `notifications` | le propriétaire seulement — qui suit qui n'est public pour personne, organisateur compris |
| `organizers` | tout compte connecté (page publique, compteurs calculés par triggers) |
| `events`, `event_tiers`, `event_staff` | tout compte connecté (le catalogue est le produit) |
| `staff_invitations` | l'invité et l'équipe de l'événement |
| `reservations` | le participant ; l'équipe de l'événement ; les administrateurs |
| `checkins` | l'équipe de l'événement |
| `waitlist_entries` | la personne en attente ; l'équipe de l'événement |
| `reviews` | tout compte connecté, **sauf les avis masqués** : visibles par leur auteur et la modération seulement |
| `reports`, `moderation_queue`, `moderation_decisions`, `administrators` | administrateurs |
| `private.*` (jobs, audit, limites) | personne via l'API |

Les politiques utilisent `(select auth.uid())` : la valeur est calculée une
fois par requête (init plan), pas une fois par ligne.

## 7. Écritures possibles depuis un client

| Table | Écriture directe autorisée | Tout le reste passe par |
|---|---|---|
| `profiles` | `INSERT (id, name, email, role, bio, photo_url)` sur sa ligne ; `UPDATE (name, bio, photo_url)` | trigger (email réel, horodatages) |
| `notification_preferences` | `UPDATE` des trois préférences | — |
| `devices` | `DELETE` de ses appareils | `register_device` (un jeton n'appartient qu'à un compte) |
| `follows` · `favorites` | `INSERT (organizer_id)` · `INSERT (event_id)`, `DELETE` des siennes | triggers (compteurs) |
| `reviews` | `INSERT (event_id, rating, comment)` si présent à un événement commencé et email vérifié ; `UPDATE (rating, comment)` des siens ; `DELETE` des siens | triggers (auteur, nom, note de l'organisateur) |
| `reports` | `INSERT (target_type, target_id, reason, details)` | trigger (signaleur, contenu existant, pas le sien, seuil) |
| `notifications` | `UPDATE (read_at)` (horodaté par le serveur, jamais « non lu » à nouveau), `DELETE` | — |
| `events`, `event_tiers` | **aucune** | `save_event`, `delete_event` |
| `reservations`, `checkins`, `waitlist_entries` | **aucune** | `reserve_seat`, `cancel_reservation`, `check_in_ticket`, `join_waitlist`, `leave_waitlist`, Edge Functions de paiement |
| `event_staff`, `staff_invitations` | **aucune** | `invite_co_organizer`, `respond_to_staff_invite`, `remove_co_organizer` |
| `moderation_*`, `administrators` | **aucune** | `moderate_content`, `set_admin_role` |

---

## 8. Middleware de requête

`public.api_pre_request()` est déclaré comme `pgrst.db_pre_request` : PostgREST
l'exécute **avant chaque requête** de l'API.

- **Compte suspendu → 403 immédiat.** Un jeton d'accès reste valable jusqu'à
  une heure après une suspension ; la base ne l'attend pas.
- **Écritures limitées à 240 par minute par compte** (fenêtre fixe, table non
  journalisée `private.rate_limits`). Les transactions en lecture seule ne
  comptent pas.
- Limites plus fines dans les fonctions sensibles : réserver 20/min, publier ou
  modifier un événement 30/min, inviter 30/min, scanner 240/min, enregistrer un
  appareil 20/min ; modifier un avis au plus une fois par seconde.

La connexion et l'inscription sont limitées en amont par Supabase Auth
(`[auth.rate_limit]` de `config.toml`).

## 9. Erreurs : informatives pour l'utilisateur, muettes pour l'attaquant

Toute erreur métier est levée avec `SQLSTATE PTnnn` (PostgREST en fait le
statut HTTP `nnn`), un `hint` égal à la règle (`eventFull`, `tiersLocked`…)
et un message français. Les erreurs de validation portent le détail par champ.
Rien d'autre ne sort : ni nom de contrainte, ni requête. Les Edge Functions
renvoient la même forme et **masquent** toute erreur inattendue derrière un
message générique (`500 unexpected`), la cause restant dans les journaux avec
l'identifiant de requête.

---

## 10. Concurrence

- **Ordre de verrouillage unique** : événement → réservation → type de billet,
  dans toutes les fonctions (réserver, annuler, tenir une place, confirmer,
  libérer, rembourser, modifier l'événement). Un seul ordre, pas d'interblocage.
- **Survente impossible** : la vérification des places et leur décrément se
  font sous le verrou de la ligne de l'événement.
- **Contrôle d'entrée** : la décision et l'enregistrement sont une seule
  instruction ; deux portes produisent un « entrée validée » et un « déjà
  scanné », jamais deux entrées.
- **Liste d'attente** : `FOR UPDATE SKIP LOCKED` ; chaque place libérée prévient
  une personne, une seule fois (`notified_at`).
- **Idempotence** : libérer une place déjà libérée, confirmer un paiement déjà
  confirmé, rembourser deux fois ne change rien (fonctions de paiement testées
  en rejouant les appels).

## 11. Paiements (F-11)

| Surface | Garantie |
|---|---|
| Montant | lu par `payments_hold_seat` dans le type de billet verrouillé, transmis à Stripe par l'Edge Function : **jamais** fourni par l'app |
| Données de carte | page Stripe Checkout hébergée : rien ne transite par l'app ni par EventHub (périmètre PCI SAQ A) |
| Place pendant le paiement | tenue en transaction (statut `pending`) ; relâchée par abandon, expiration Stripe ou balayage toutes les 10 minutes, avec une marge de 5 minutes après l'expiration de la session |
| Confirmation | **seul le webhook** confirme : signature `Stripe-Signature` vérifiée sur le corps brut (Web Crypto) ; le retour navigateur `/pay/success` n'est pas une preuve |
| Paiement tardif | si la place a été relâchée, elle est reprise s'il en reste, **sinon le paiement est remboursé** : jamais de débit sans billet |
| Remboursement demandé | Stripe rembourse **d'abord**, la place est libérée ensuite : un échec laisse le billet à son détenteur |
| Remboursements de masse (retrait d'un événement, suppression de compte) | mis en file, retentés 8 fois avec délai croissant, puis `refund_failed` et journal d'audit pour un humain |
| Clés d'idempotence Stripe | session : `checkout:<réservation>:<expiration>` ; remboursement : `refund:<réservation>:<paiement>` |
| Secrets | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` en secrets des Edge Functions, jamais dans Git |

## 12. Edge Functions

Toutes passent par `serve()` (`_shared/http.ts`) :

1. identifiant de requête, préflight CORS, méthode HTTP vérifiée ;
2. authentification selon la fonction :
   - **jeton utilisateur** vérifié auprès de Supabase Auth, compte banni refusé ;
   - **secret du worker** comparé en temps constant ;
   - **public** pour le webhook (signature) et l'instantané d'un événement ;
3. corps JSON plafonné (16 Ko par défaut), objet exigé ;
4. validation des identifiants (UUID) avant tout appel ;
5. erreurs au format de l'API, erreurs inattendues masquées, une ligne de
   journal JSON par requête (statut, durée, utilisateur, règle).

`verify_jwt = false` n'est déclaré que pour `stripe-webhook`, `worker` et
`public-event` (`supabase/config.toml`), chacune ayant sa propre
authentification.

## 13. File de jobs

Les effets hors base (push FCM, remboursements, suppression de fichiers) sont
écrits dans `private.jobs` **dans la transaction métier** : une réservation
annulée par un rollback n'envoie jamais de notification. `pg_net` réveille le
worker **après le commit** ; `pg_cron` le relance chaque minute. Les jobs sont
pris avec `FOR UPDATE SKIP LOCKED` (deux exécutions ne traitent jamais le même
job), verrouillés deux minutes (un worker mort n'immobilise rien), retentés avec
délai exponentiel. L'URL et le secret du worker sont dans **Vault**, jamais dans
une migration (`supabase/snippets/wire_worker.sql`).

## 14. Storage

- Buckets `event-covers` (5 Mo) et `avatars` (2 Mo) **publics par conception** :
  ce sont des images promotionnelles. Taille et types MIME sont imposés par le
  bucket lui-même, avant toute politique. **SVG exclu** (balisage exécutable).
- Propriété par le chemin : `<uid>/<fichier>`, un seul niveau, nom
  `[A-Za-z0-9._-]{1,128}`, pas de `..`. Seul un organisateur écrit dans
  `event-covers`.
- Conséquence à retenir : ne jamais stocker de contenu confidentiel dans ces
  buckets. Un export privé irait dans un bucket privé servi par URL signée.
- Les fichiers d'un événement retiré ou d'un compte supprimé sont effacés par le
  worker via l'API Storage.

## 15. Realtime

Realtime applique la RLS de l'abonné à chaque changement diffusé : un
participant abonné à `reservations` ne reçoit que ses billets. Pour les
suppressions, Realtime n'envoie que la clé primaire de l'ancienne ligne sur une
table protégée par RLS : aucune donnée ne fuit par un `DELETE`.

## 16. Données personnelles

| Donnée | Traitement |
|---|---|
| Email, rôle | `profiles`, privé ; jamais copiés sur `organizers` |
| Nom d'un participant visible par d'autres | réduit à « Prénom I. », entrées indexées par un SHA-256 tronqué de l'uid (`event_attendance`) : aucun uid publié |
| Signaleur | invisible pour tous sauf la modération, qui ne voit qu'une clé courte |
| Suppression de compte | `delete_my_account` : places à venir libérées (payées remboursées), réservations et avis anonymisés (« Compte supprimé »), fichiers mis en file, compte Auth supprimé — une seule transaction |
| Journal d'audit | `private.audit_log`, illisible par l'API, conservé un an |
| Notifications | supprimées après 30 jours |
| Outils Firebase | Crashlytics et Analytics ne reçoivent que l'uid et le rôle ; Analytics seulement après consentement |

---

## 17. Tester la sécurité

```bash
make db-setup   # une fois : npm ci dans supabase/tests
make test-db    # toutes les migrations + la suite, sur Postgres 17 (PGlite)
```

La suite applique **les migrations réelles, dans l'ordre**, sur PGlite (Postgres
17 compilé en WebAssembly : ni Docker ni projet distant), avec des remplaçants
minimaux de ce que fournit un projet Supabase (`supabase/tests/stubs.sql` :
rôles et leurs droits par défaut, `auth.users`, `auth.uid()`, Storage, Vault,
`pg_net`, `pg_cron`). Chaque test agit **sous le rôle réel** (`anon`,
`authenticated` avec un `sub`, `service_role`) et fabrique ses requêtes à la
main, exactement comme un attaquant : RLS, droits par colonne et fonctions sont
éprouvés indépendamment de l'application censée les respecter.

Couvert, entre autres : changement de rôle et suspension refusés, profils
privés, API fermée à `anon`, fonctions serveur inaccessibles aux comptes,
suspension immédiate, jeton déplacé entre comptes, premier administrateur,
publication réservée aux organisateurs vérifiés, erreurs par champ, types de
billets et ventes protégées, survente impossible, liste des participants
limitée à l'équipe, liste d'attente, verdict d'entrée atomique, prénoms courts,
rappels uniques, push en file, place tenue et reprise, webhook rejoué, paiement
tardif re-placé ou remboursé, balayage, remboursement, verrou de devise, avis
réservés aux présents, signalement unique et seuil, décision humaine
prioritaire, suspension et réintégration, retrait d'un événement payé, équipe,
suppression de compte, file de jobs et tâches planifiées.

Elle tourne en CI (job `database`) sans aucun secret.

---

## 18. Limites connues

- **Pas d'App Check.** Supabase n'a pas d'équivalent : un client non officiel
  est limité par la RLS, les fonctions et la limitation de débit, pas bloqué.
  Un CAPTCHA à l'inscription (`[auth.captcha]`, hCaptcha ou Turnstile) est la
  prochaine marche si des inscriptions automatisées apparaissent.
- **La suspension est immédiate pour l'API REST et les fonctions**, pas pour
  Storage et Realtime, qui n'exécutent pas le middleware : là, le jeton d'accès
  en cours reste valable jusqu'à son expiration (une heure au plus). Les
  sessions étant supprimées et le compte banni, il ne peut pas être renouvelé.
- **Limitation de débit par compte, pas par adresse IP**, côté base ; l'IP est
  limitée par Supabase Auth pour la connexion et l'inscription.
- **Aperçus de liens** : Supabase ne sert pas de HTML depuis une Edge Function
  sur `*.supabase.co`. La page `/e/<id>` est rendue dans le navigateur ; les
  robots d'aperçu (WhatsApp, Slack) voient un titre générique tant qu'un domaine
  personnalisé n'est pas configuré pour les fonctions.
- **Les suites de tests tournent sur PGlite**, pas sur l'image Postgres de
  Supabase : `pg_net`, `pg_cron`, Vault, Storage et Auth sont remplacés par des
  stubs. Leur comportement réel se vérifie après `make db-push` sur le projet.
- **Hors ligne** : sans le cache Firestore, les données déjà affichées restent à
  l'écran mais une ouverture à froid sans réseau n'a rien à montrer.
