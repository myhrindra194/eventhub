# EventHub — Modèle de sécurité

> Les règles Firestore et Storage sont **le seul contrôle qui s'exécute
> réellement**. L'application Flutter est une commodité : n'importe qui peut
> obtenir un jeton d'authentification et appeler l'API directement avec une
> charge utile fabriquée. Ce document explique ce que le serveur garantit,
> comment, et ce qu'il ne garantit pas.

Fichiers concernés :

- `firebase/firestore.rules`
- `firebase/storage.rules`
- `firebase/firestore.indexes.json`

---

## 1. Modèle de menace

| Attaquant | Capacité | Contre-mesure |
|---|---|---|
| Utilisateur légitime curieux | Appelle l'API avec ses propres droits | Portée des lectures, `list` bornée |
| Utilisateur malveillant | Fabrique n'importe quelle charge utile | Validation de forme, whitelist de champs, immuabilité |
| Compte jetable | Crée des comptes en masse | `isVerified()` sur le contenu public, throttle |
| Client compromis / rétro-ingénierie | Contourne toute validation UI | Toute règle métier est répliquée côté serveur |
| Scraper | Aspire le catalogue | `request.query.limit` obligatoire |

---

## 2. Les huit invariants garantis

1. **Un document utilisateur appartient à un seul uid**, et son `role` et son
   `email` sont **immuables**. C'est la règle la plus importante du fichier :
   tout le modèle d'autorisation repose dessus. Aucune escalade de privilège
   n'est possible, car `update` sur `users/{uid}` n'accepte que
   `['name', 'photoUrl', 'bio', 'updatedAt']`.
2. **Seul un organisateur crée un événement**, et seul son propriétaire le
   modifie ou le supprime.
3. **`availablePlaces` reste dans `[0, capacity]`** en permanence, et un
   participant ne peut le déplacer que d'exactement **une** place.
4. **La capacité ne peut jamais descendre sous le nombre de places déjà
   vendues** — sinon des billets existants deviendraient invalides.
5. **Une réservation par (événement, participant)**, garantie
   *structurellement* par un identifiant déterministe `<eventId>_<uid>`, et
   non par une requête sujette aux courses.
6. **Les champs dénormalisés d'une réservation doivent correspondre à
   l'événement** dont ils sont copiés (`matchesEvent()`), sinon un participant
   pourrait forger un billet ou réécrire la liste que lit l'organisateur.
7. **Les horodatages sont contrôlés côté serveur.** `createdAt` doit valoir
   exactement `request.time`. Les horodatages nécessairement produits par le
   client (voir §4) sont bornés à une fenêtre.
8. **Tout ce qui n'est pas explicitement autorisé est refusé.** Une nouvelle
   collection est inaccessible tant que personne n'a écrit sa règle : le mode
   de défaillance est une fonctionnalité cassée, jamais une fuite de données.

---

## 3. Résolution du rôle : claims d'abord

```
role() = request.auth.token.role   (custom claim, gratuit)
       ↳ sinon get(users/{uid}).role  (un read, chemin de secours)
```

Le **custom claim est le chemin de production** : il ne consomme aucun des
10 `get()` autorisés par requête et ne peut pas être contourné en supprimant le
document de profil. Le repli documentaire garde l'émulateur et le client actuel
fonctionnels tant que la Cloud Function n'est pas déployée.

**Mis en œuvre (v1.2)** : la fonction `setRoleClaim` (déclenchée à la
création de `users/{uid}`) copie le rôle dans le claim ; un profil sans compte
Auth (import, console) est ignoré avec un avertissement. Côté client,
`AuthRepositoryImpl` attend le claim puis force le rafraîchissement du jeton
(`getIdToken(true)`).

`isAdmin()` est **exclusivement** un claim : il n'existe aucun document qu'un
utilisateur pourrait écrire pour se promouvoir administrateur.

---

## 4. Horodatages : deux régimes, et pourquoi

| Champ | Régime | Raison |
|---|---|---|
| `users.createdAt`, `events.createdAt`, `events.updatedAt` | `isServerTime()` — doit valoir `request.time` | Le client envoie `FieldValue.serverTimestamp()` ; infalsifiable |
| `reservations.reservedAt`, `reservations.cancelledAt` | `isRecentTime()` — fenêtre `[now − 5 min, now + 2 min]` | Ces valeurs sont **renvoyées de façon synchrone à l'interface** depuis l'intérieur de leur propre transaction. Un `serverTimestamp()` n'a pas de valeur lisible avant l'aller-retour |

La fenêtre tolère la dérive d'horloge des appareils tout en rendant impossible
l'antidatage comme le postdatage. C'est un compromis **assumé et documenté**,
pas un oubli.

---

## 5. Requêtes `list` bornées — le piège à connaître

```
allow list: if isSignedIn() && request.query.limit <= 100;
```

Dans les règles Firestore, une requête **sans `.limit()` explicite fait
échouer la comparaison** et se voit donc refusée. Ce n'est pas un effet de
bord : c'est le mécanisme qui empêche un scraper d'aspirer une collection en
une requête.

Conséquence côté client, appliquée dans ce dépôt :

- `EventRemoteDataSource.maxPageSize = 100`
- `ReservationRemoteDataSource.maxPageSize = 200`

Chaque requête liste porte un `.limit(maxPageSize)`. Bénéfice secondaire :
un listener non borné facture une lecture par document à **chaque** snapshot.

> ⚠️ Au-delà de 100 événements à venir, le catalogue est tronqué. La
> pagination réelle est la tâche **F-04** de la feuille de route.

---

## 6. Portée des lectures

| Collection | `get` | `list` |
|---|---|---|
| `users/{uid}` | propriétaire ou admin | **jamais** — énumérer la base d'utilisateurs passe par une Cloud Function auditée |
| `events` | tout compte authentifié | ≤ 100 |
| `reservations` | participant concerné **ou** organisateur de l'événement | ≤ 200 |
| `reviews` | authentifié | ≤ 100 |
| `reports` | admin uniquement | admin |
| `config` | public | public |
| `aggregates` | authentifié | lecture seule |
| `audit` | **personne** via l'API client | — |

Les deux branches de lecture des réservations (`userId ==` / `organizerId ==`)
sont **prouvables depuis un filtre de requête**, ce qui est exactement pourquoi
les requêtes du client portent ces égalités et pourquoi les index composites
`(eventId, organizerId, status, reservedAt)` et `(organizerId, reservedAt)`
existent.

> ⚠️ **Correctif v1.1.** La règle `list` des réservations ne vérifiait que
> `request.query.limit <= 200`. Une requête bornée mais **sans filtre**
> passait : n'importe quel compte connecté pouvait lire toutes les listes
> d'invités, noms et emails compris. La règle exige désormais
> `resource.data.userId == uid() || resource.data.organizerId == uid()`, que
> Firestore évalue contre les contraintes de la requête : une requête qui ne
> fixe pas l'une de ces égalités est refusée d'office. Deux tests de règles
> couvrent le cas (participant et organisateur).

### Correctifs v1.2 : ce que le backend simulé masquait

Le mode simulation n'appliquait pas les règles. Au branchement réel sur
Firebase, trois règles de `reservations` auraient bloqué le cœur du produit :

| Symptôme en production | Cause | Correctif |
|---|---|---|
| **Aucune réservation possible** ; erreur de permission sur toute fiche d'événement non réservé | la transaction lit `reservations/{eventId}_{uid}` avant qu'il existe ; `existing().userId` sur un document absent fait échouer la règle `get` | `resource == null` → autorisé seulement si l'id se termine par `_<uid>` : on ne peut sonder que ses propres réservations |
| Création refusée | le DTO sérialise `cancelledAt: null`, la règle interdisait la clé | la clé est acceptée si sa valeur est `null` |
| Re-réservation après annulation refusée | la règle figeait `reservedAt`, le client l'horodate au moment de la nouvelle réservation | `reservedAt` figé pour une annulation ; pour une re-réservation, heure récente, `cancelledAt` vidé, copie de l'événement revérifiée |

Quatre tests de règles couvrent ces cas. Côté application, la suppression d'un
événement qui a des réservations (refusée par `allow delete`) est désormais
anticipée par `EventPolicy.canDelete`, avec un message au lieu d'une erreur de
permission.

### v1.3 : fonctionnalités ajoutées et leurs garanties

| Surface | Garantie | Où |
|---|---|---|
| Publication d'un événement | email vérifié (`isVerified()`), en plus du rôle | règle `events` create + `EventFormController` |
| `users/{uid}/favorites/{eventId}` | privé ; id = eventId ; immuable | règles (tests F-05) |
| `events/{id}/waitlist/{uid}` | création par le participant lui-même, **seulement si l'événement est complet et à venir** ; lecture par lui ou l'organisateur ; position non modifiable | règles + `WaitlistPolicy` |
| `notifiedAt` sur la liste d'attente | écrit uniquement par la fonction (SDK Admin) | `notifyWaitlistOnSeatRelease` |
| `reviews/{eventId}_{uid}` | réservation confirmée, **événement commencé**, email vérifié, note 1–5, commentaire ≤ 2 000 (création **et** modification) | règles + `ReviewPolicy` |
| `events/{id}/checkins/{reservationId}` | organisateur de l'événement seul, append-only ; deux portes qui scannent le même billet : la seconde écriture est refusée | règles + `CheckInRepositoryImpl.record` |
| QR du billet | non signé : il désigne une réservation, le verdict vient de la lecture serveur et du code dérivé de l'id ; une réservation d'un autre organisateur est illisible → « introuvable » | `CheckInPolicy` |
| Suppression de compte | impossible depuis le client (règles) ; fonction callable authentifiée : refus si l'organisateur a un événement à venir avec participants, places libérées, réservations et avis anonymisés, sous-collections, fichiers et utilisateur Auth supprimés | `deleteAccount` |
| App Check | activé dans l'app ; appliqué aux fonctions callable quand `ENFORCE_APP_CHECK=true` ; à activer côté console pour Firestore et Storage après enregistrement des jetons de debug | `bootstrap.dart`, `functions/src/index.ts` |
| Google Sign-In | un compte Google sans profil passe par `ProfileMissing` : pas de rôle par défaut, le choix reste explicite | `AuthRepositoryImpl`, `RouteGuard` |
| Données personnelles dans les outils | Analytics et Crashlytics ne reçoivent que l'uid et le rôle ; Analytics seulement après consentement | `AppAnalytics`, `AnalyticsConsent` |

Tests : règles `make test-rules` (118), fonctions `make test-functions`.

### v1.4 : profils publics, preuve sociale, signalements, page publique

| Surface | Garantie | Où |
|---|---|---|
| `users/{uid}/following/{organizerId}` | privé au suiveur ; id = organizerId ; pas soi-même ; immuable (désabonnement = suppression) | règles + `FollowPolicy` |
| `organizers/{id}` | lecture pour tout compte connecté, **écriture refusée à tous les clients**, organisateur compris : nom et présentation copiés par `syncOrganizerProfile`, compteurs par triggers | règles |
| `organizers/{id}/followers` | illisible et non inscriptible depuis un client : qui suit qui n'est public pour personne | règles |
| Compteurs publics | triggers idempotents (`once()` : marqueur `audit/fx_{eventId}` écrit dans la même transaction) — un redéclenchement ne compte pas deux fois | `functions/src/index.ts` |
| `aggregates/event_{id}` | lecture connectée, écriture serveur ; noms réduits à « Prénom I. », entrées indexées par `sha256(uid)` tronqué : aucun uid publié ; retiré à l'annulation et à la suppression de compte | `aggregateAttendance`, `deleteAccount` |
| `reports/{type}_{cible}_{uid}` | écriture seule ; **un signalement par compte et par cible** (id déterministe vérifié) — sans cela, un seul compte masquerait n'importe quel avis ; motifs fermés ; pas son propre compte ni son propre avis | règles + `ReportPolicy` |
| Second signalement du même compte | tombe sur un document existant = mise à jour, réservée aux admins → refus ; le client le traduit en « déjà signalé » sans rien lire | `ReportRepositoryImpl` |
| Masquage d'un avis | automatique à 3 personnes distinctes ; une décision admin (`moderatedAt`) n'est jamais écrasée par le seuil ; l'auteur ne peut pas toucher `hidden` (`onlyChanged(['rating','comment','updatedAt'])`) | `onReportCreated`, règles `reviews` |
| Événements et comptes signalés | jamais supprimés automatiquement (des billets existent) : file `moderationQueue`, lecture admin, écriture serveur | règles + fonction |
| `moderateContent` | callable, **claim `admin` exigé**, arguments validés, App Check si `ENFORCE_APP_CHECK` ; chaque décision journalisée dans `audit` (TTL 1 an) | fonction |
| `publicEventPage` | lecture Admin SDK des seuls champs publiés par l'organisateur ; **tout contenu échappé** (titre, lieu, description) ; aucune donnée d'inscrit ; id validé (longueur, pas de `/`) ; `GET`/`HEAD` seulement ; `nosniff` et `Referrer-Policy` sur Hosting | fonction + `firebase.json` |
| App Links | `autoVerify` sur `/e/` ; `assetlinks.json` liste les empreintes autorisées — une app signée par une autre clé n'intercepte pas les liens | manifeste + Hosting |
| `?from=` (lien profond conservé) | liste blanche de destinations (`/e/`, `/events/`, `/organizers/`) : un `from` forgé ne peut ouvrir ni une URL externe ni un écran arbitraire ; la confinement par rôle s'applique ensuite | `RouteGuard` (testé) |
| Analytics de signalement | type de cible et motif seulement, jamais l'id ou le contenu signalé | `AppAnalytics.contentReported` |

### v1.5 : administration et décisions de modération

| Surface | Garantie | Où |
|---|---|---|
| Rôle administrateur | **custom claim `admin`** uniquement : aucun document ne le confère. Accordé par `setAdminRole` (admin requis) ou, pour le premier, par `make grant-admin EMAIL=…` avec les identifiants Google Cloud du poste. Un admin ne peut pas retirer son propre rôle : le dernier admin ne peut pas verrouiller le projet | `functions/src/index.ts`, `functions/scripts/grant-admin.mjs` |
| Écrans `/admin/**` | le guard exige `AppUser.isAdmin` (lu dans le jeton, jamais dans Firestore). **Confort seulement** : chaque lecture est refusée par les règles et chaque décision par la fonction sans le claim | `RouteGuard`, règles |
| `moderationQueue`, `…/decisions`, `admins`, `reports` | lecture admin, écriture serveur uniquement (même un admin n'écrit pas directement : tout passe par une fonction qui journalise) | règles (testées) |
| `moderateContent` | claim vérifié, App Check si activé, action validée **par type de cible** (`ACTIONS_BY_TARGET`), note obligatoire pour retirer un événement ou suspendre un compte (elle est envoyée à la personne), ≤ 500 caractères ; historique append-only + audit | fonction (tests d'intégration) |
| Retrait d'un événement | réservations annulées avec `cancelledBy: moderation` (l'organisateur reçoit un seul message, pas un par invité), chaque détenteur prévenu, événement, sous-collections et bannière supprimés | `removeEventByModeration` |
| Suspension | compte Auth désactivé + jetons de rafraîchissement révoqués ; le jeton d'accès en cours reste valable **jusqu'à une heure** (limite Firebase assumée) ; impossible sur soi-même | `moderateContent` |
| Identité des signaleurs | l'écran admin n'affiche qu'une clé courte (6 caractères de l'uid) pour repérer un compte qui signale en rafale, jamais le nom | `ModerationRemoteDataSource` |
| Erreurs des fonctions | `permission-denied`, `invalid-argument`, `not-found`, `failed-precondition` gardent le message français du serveur | `ErrorMapper` |

### Notifications push : ce qui est privé, ce qui est serveur

| Chemin | Client | Cloud Functions (SDK Admin, règles contournées) |
|---|---|---|
| `users/{uid}/devices/{deviceId}` | propriétaire seulement ; champs `token`, `platform`, `locale`, `updatedAt` (heure serveur) | lit les jetons, supprime ceux que FCM rejette |
| `users/{uid}/private/notifications` | propriétaire seulement | lit la préférence **avant chaque envoi** |
| `users/{uid}/notifications/{id}` | lecture et `readAt` par le propriétaire, **création interdite** | seule source d'écriture |

Deux conséquences voulues. Un client ne peut ni lire les jetons d'un autre
utilisateur, ni lui envoyer de notification : l'envoi n'existe que côté
serveur. Et à la déconnexion, l'app **invalide son jeton** (`deleteToken`)
plutôt que de supprimer le document appareil, ce que les règles refuseraient
une fois la session fermée ; le document orphelin est supprimé par la fonction
au premier envoi qui échoue.

`setRoleClaim` recopie le rôle du profil dans un custom claim à la création
du document `users/{uid}`. Le profil ne pouvant être ni supprimé ni changer
de rôle (règles), le claim ne peut pas diverger du document.

---

## 7. Transitions d'état autorisées

**Réservation** — deux transitions seulement :

```
confirmed ──cancel──▶ cancelled ──rebook──▶ confirmed
```

`create` exige : événement futur, places disponibles, statut `confirmed`,
identifiant déterministe, champs dénormalisés conformes.
`delete` est **toujours refusé** : l'organisateur doit pouvoir prouver qui
était inscrit, le participant qu'il a annulé.

**Événement** — deux branches d'`update` disjointes :

- *(a) le propriétaire édite le contenu* : forme complète validée,
  `organizerId` et `createdAt` figés, `capacity ≥ places vendues`, et
  `availablePlaces` recalculé pour **préserver** les places vendues.
- *(b) un participant prend ou libère une place* : uniquement
  `['availablePlaces', 'updatedAt']`, delta de ±1 exactement, bornes
  respectées, et **réservation impossible après le début** de l'événement
  (la libération, elle, reste permise).

`delete` n'est autorisé que si l'événement n'a **aucune** place vendue.

---

## 8. Cloud Storage — ce que les règles ne couvrent pas

Les règles Storage protègent l'**API authentifiée**. Elles ne protègent **pas**
une URL de téléchargement tokenisée : `getDownloadURL()` renvoie
`…?alt=media&token=<uuid>`, et quiconque détient cette URL récupère l'objet
quelles que soient les règles.

Les visuels d'événement sont intégrés à des documents publics : ils sont donc
**publics par conception**, ce qui convient à des images promotionnelles.

**La conséquence à retenir** : ne jamais stocker de contenu confidentiel dans
un chemin dont l'URL de téléchargement est remise à un client. Les artefacts
privés (exports de liste de participants, factures) vivent sous `private/`,
**fermé à tout client**, et sont servis via une URL signée de courte durée
émise par une Cloud Function.

Garanties côté écriture :

- propriété par le chemin (`events/{organizerId}/…`, `avatars/{userId}/…`) :
  aucune lecture de document n'est nécessaire pour autoriser l'écriture ;
- images matricielles uniquement — **`image/svg+xml` est exclu volontairement**
  (c'est du balisage exécutable dans un contexte navigateur) ;
- plafonds de taille : 5 Mo pour un visuel d'événement, 2 Mo pour un avatar ;
- noms de fichiers contraints (`[A-Za-z0-9._-]+`, pas de `..`).

---

## 9. Index : une dépendance dure, pas de la documentation

Firestore **refuse** une requête composite sans index correspondant.
`firebase deploy --only firestore:indexes` doit donc précéder la livraison de
l'écran concerné.

Ordre encodé dans chaque index : **égalités d'abord, puis l'inégalité, puis le
`orderBy`**. Un index construit dans un autre ordre n'est jamais utilisé — mais
reste facturé à chaque écriture.

Les `fieldOverrides` **désactivent** les index simples sur les champs de texte
long et ceux qui ne servent jamais de prédicat (`events.description`,
`reviews.comment`, `reservations.userEmail`, `devices.token`…). Chaque index
désactivé, c'est une écriture d'index en moins par écriture de document : sur
une collection en écriture intensive, c'est l'optimisation la moins chère qui
existe.

`notifications.expiresAt` porte `"ttl": true` : Firestore supprime lui-même les
notifications expirées, donc la collection ne peut pas croître indéfiniment et
aucun job de nettoyage n'est nécessaire.

---

## 10. Tester les règles

La suite vit dans `firebase/tests/` et s'exécute contre les émulateurs :

```bash
make rules-setup   # une seule fois : npm install
make test-rules    # démarre les émulateurs, exécute la suite, les arrête
```

**114 tests, 0 échec.** Elle tourne aussi en CI (job `Security rules`), sans
aucun secret : l'identifiant de projet `demo-eventhub` indique au SDK qu'aucun
projet réel n'existe derrière, donc les émulateurs ne demandent pas
d'identifiants — la suite passe même sur un fork.

| Fichier | Contenu |
|---|---|
| `helpers.js` | Environnement de test, contextes d'identité (claims), fixtures |
| `firestore.rules.test.js` | 56 tests — users, events, reservations, reviews, collections fermées |
| `storage.rules.test.js` | 14 tests — visuels d'événement, avatars, préfixes fermés |

Chaque test pilote l'émulateur via le **SDK client**, exactement comme le
ferait un attaquant : les charges utiles y sont fabriquées à la main, jamais
produites par les repositories Flutter. C'est tout l'intérêt — ces règles sont
le seul contrôle qui s'exécute, elles sont donc testées indépendamment de
l'application censée les respecter.

Les sept cas prioritaires sont marqués `[P-n]` dans leur intitulé :

1. `[P-1]` un participant ne peut pas se promouvoir organisateur ;
2. `[P-2]` un organisateur ne peut pas modifier l'événement d'un autre ;
3. `[P-3]` un participant ne peut pas déplacer `availablePlaces` de plus de 1 ;
4. `[P-4]` une réservation ne peut pas être créée avec un `organizerId` forgé ;
5. `[P-5]` une capacité ne peut pas descendre sous les places vendues ;
6. `[P-6]` une requête `list` sans `limit` est refusée ;
7. `[P-7]` un `delete` sur une réservation est toujours refusé.

S'y ajoutent notamment : identifiant de réservation déterministe, champs
dénormalisés vérifiés contre l'événement, horodatages antidatés/postdatés,
réservation sur événement complet ou passé, avis réservés aux présents avec
email vérifié, subtree privé de chaque utilisateur, `audit` invisible, et le
catch-all sur une collection inconnue.

### Ce que ces tests ont trouvé

Deux bugs réels au premier passage, ce qui est précisément leur raison d'être :

1. **`role()` évaluait le `get()` de secours même en présence du claim.**
   Écrit en `request.auth.token.get('role', <fallback avec get()>)`, l'argument
   par défaut est évalué **avant** l'appel : la lecture de document était donc
   payée systématiquement — exactement ce que le custom claim existe pour
   éviter. Réécrit en ternaire, qui n'évalue que la branche prise.
2. **Une course au chargement du ruleset Storage**, visible comme la première
   assertion de la suite qui échoue alors que la même plus loin passe. Une
   requête d'amorce dans le `before` rend la suite déterministe.

### Couverture

Toutes les collections consommées par l'app ont leurs tests de règles
(`firestore.rules.test.js`, `subcollections.rules.test.js`) : profils,
événements, réservations, avis, appareils, favoris, abonnements, profils
organisateurs et abonnés, notifications, liste d'attente, entrées, signalements,
file de modération, agrégats. Les effets serveur (compteurs, masquage,
cascade) sont couverts par les tests d'intégration des fonctions
(`make test-functions`). Règle d'équipe inchangée : une règle s'écrit et se
teste **en même temps** que la fonctionnalité qui la consomme.

---

## 11. Limites connues

- **Pas de rate limiting véritable.** `notTooFast()` est une protection
  grossière (une écriture par seconde et par document). Un vrai quota exige un
  document compteur ou App Check.
- **App Check est activé côté app mais pas encore *appliqué*.** L'application
  (Firestore, Storage, et `ENFORCE_APP_CHECK` pour les callables) se fait dans
  la console une fois les apps et les jetons de debug enregistrés ; d'ici là,
  un client non officiel reste limité par les règles, pas bloqué.
- **Suppression de compte : cascade côté serveur** (`deleteAccount`), refusée
  tant qu'un événement à venir de l'organisateur a des participants.
- **Suspension : jusqu'à une heure de latence.** Firebase ne révoque pas un
  jeton d'accès déjà émis ; les règles ne consultent pas l'état du compte.
- **La page publique est cachée 5 à 10 minutes** (CDN Hosting) : un événement
  supprimé ou modifié peut y apparaître encore quelques minutes.
- **La suppression d'un événement ne cascade pas.** Elle est simplement
  interdite tant que des places sont vendues.
