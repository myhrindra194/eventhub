# EventHub — Conventions d'équipe

> Ces conventions existent pour une raison précise : sur le plan **Spark**, il
> n'y a pas de serveur. Le client écrit directement dans Firestore et les
> **règles de sécurité** sont le seul code qui s'exécute côté Google. Une
> écriture mal formée n'est pas « corrigée » par un backend : elle est refusée
> (`permission-denied`). La couche `data` doit donc produire exactement ce que
> `firebase/firestore.rules` attend — ni plus, ni moins.

---

## 1. Git

* Branche par défaut : `main` (toujours démontrable). Intégration : `develop`.
* Une branche par tâche : `feat/T-31-recherche-evenements`, `fix/T-61-…`,
  `chore/T-66-readme`.
* Commits **Conventional Commits** en anglais, scope = feature ou brique :

  ```
  feat(reservations): book a seat in one transaction proven by the rules
  fix(firestore): pin userId in the wallet query
  test(rules): a member reads only their own admin marker
  ci: build the web target on pull requests
  ```
* PR vers `develop`, CI verte (4 jobs, voir README §14), une review minimum,
  squash merge.
* `lib/firebase_options.dart` **est versionné** (identifiants client publics,
  voir `docs/SECURITY.md` §9). `google-services.json` et
  `GoogleService-Info.plist` ne le sont pas : le build Flutter n'en a pas
  besoin. Aucun secret, jamais (dépôt public).

## 2. Code

* `flutter analyze` sans warning, `dart format` appliqué (CI bloquante).
* Imports en `package:eventhub/...` (jamais relatifs entre features).
* Une feature n'importe **jamais** la couche `data` d'une autre feature ; elle
  passe par ses providers `application`.
* Seule la couche `data` importe `cloud_firestore` / `firebase_auth`. Le
  `domain` reste du Dart pur (testable sans émulateur).
* Les repositories retournent `Result<T>` ; les widgets consomment des
  providers, pas des repositories.
* Texte UI : uniquement via `AppStrings` (préparation i18n).
* Après modification d'un fichier annoté (`@freezed`, `@riverpod`,
  `@JsonSerializable`) : `make gen`. Les fichiers générés sont commités.
* Layout **responsive** : aucun écran ne suppose un téléphone portrait (le
  même code sert Android, iOS, web, Windows et macOS).

---

## 3. Couche de données Firestore

### 3.1 Chemins et identifiants : un seul endroit

Tous les noms de collections sont dans `Collections`, tous les identifiants
composés dans `DocIds` (`lib/core/firebase/firestore_paths.dart`). Aucune
chaîne `'reservations'` ni concaténation `'${eventId}_$uid'` ailleurs.

**Pourquoi.** Les règles **reconstruisent** ces identifiants pour prouver un
fait : `reservations/{eventId}_{uid}` prouve « une place par personne »,
`reports/{type}_{target}_{uid}` prouve « un signalement par personne ».
Un identifiant composé autrement n'est pas une variante : c'est un refus.

| Document | Identifiant | Ce que l'identifiant garantit |
|---|---|---|
| `reservations` | `{eventId}_{uid}` | une place par personne et par événement ; re-réserver réutilise le document (même code billet) |
| `reviews` | `{eventId}_{uid}` | un avis par personne et par événement |
| `reports` | `{targetType}_{targetId}_{uid}` | un signalement par personne et par contenu |
| `moderationQueue` | `{targetType}_{targetId}` | un dossier par contenu |
| `users/{uid}/favorites` · `following` | `{eventId}` · `{organizerId}` | pas de doublon, test « est-ce favori ? » en une lecture |
| `users/{uid}/notifications` | `{type}_{faits…}` (ex. `booking_{eventId}_{uid}_{reservedAtMillis}`) | une notification par fait : rejouer l'écriture ne crée pas de doublon, impossible d'inonder un destinataire |
| `organizerEmails` | `sha256(email en minuscules)` | recherche d'un co-organisateur sans lister les comptes |
| `events/{id}/attendees` | `sha256(uid)` | preuve sociale sans publier d'uid |
| `events`, `moderationQueue/{id}/decisions` | auto-id Firestore | aucun fait à prouver par l'identifiant |

`DocIds.splitPair` s'appuie sur le fait que les auto-ids Firestore ne
contiennent jamais de `_` : le **dernier** `_` sépare la paire.

### 3.2 Batch, transaction ou écriture simple

| Situation | Outil | Exemple |
|---|---|---|
| Un seul document, aucune dépendance | `set` / `update` | préférences, favori |
| Plusieurs documents dont les valeurs sont **connues** d'avance | `WriteBatch` | « Devenir organisateur » : `users/{uid}.role` + `organizers/{uid}` + `organizerEmails/{hash}` |
| Une valeur **dépend d'une lecture** (compteur, places) | `runTransaction` | réserver : lire l'événement, écrire `availablePlaces - 1` **et** la réservation |

Règle d'or : **tout ce que les règles vérifient avec `getAfter()` /
`existsAfter()` doit partir dans le même commit**. Un compteur écrit seul est
refusé, car la règle ne trouve pas le document qui le justifie. C'est le
mécanisme qui remplace les triggers serveur (voir `docs/ARCHITECTURE.md` §5).

Contraintes à respecter :

* 500 écritures maximum par batch/transaction ;
* les règles lisent au plus **20 documents** par requête dans un batch ou une
  transaction (10 hors batch) : un batch qui oblige chaque écriture à relire
  beaucoup de documents peut être refusé pour dépassement de budget ;
* une transaction lit **avant** d'écrire, et peut être rejouée : pas d'effet de
  bord (analytics, notification locale) à l'intérieur de la fonction.

### 3.3 Écritures « best-effort »

Les notifications in-app destinées à **autrui** (organisateur prévenu d'une
réservation, personne en liste d'attente, invitation) sont écrites **après**
le commit métier, dans un appel séparé dont l'échec est journalisé
(`AppLogger.warning`) mais **jamais** remonté comme un échec de l'action.

**Pourquoi.** L'action de l'utilisateur (réserver) ne doit pas échouer parce
qu'un effet secondaire (prévenir l'organisateur) a été refusé. Contrepartie
assumée : sans serveur, une notification peut manquer si l'app est tuée entre
les deux écritures. L'identifiant déterministe rend une nouvelle tentative
sans risque.

### 3.4 Requêtes : toujours bornées, toujours alignées sur les règles

Firestore évalue une règle `list` sur la **requête**, pas sur les documents
renvoyés : une requête qui *pourrait* renvoyer un document interdit est
refusée en entier.

| Collection | Borne imposée par les règles | Filtre que la requête doit épingler |
|---|---|---|
| `events` | `limit ≤ 200`, compte connecté | — (lecture publique d'un document par `get`) |
| `reservations` | `limit ≤ 500` | `userId == uid` (portefeuille), `organizerId == uid` (organisateur) ou `eventId ==` (équipe) |
| `reviews` | `limit ≤ 200` | `hidden == false` (sauf auteur / modération) |
| `events/{id}/waitlist` | `limit ≤ 20` | — (tête de file, ordre `createdAt`) |
| `invitations` (collection group) | — | `userId == uid` |
| `events/{id}/invitations` | — | `status == 'pending'`, tri `createdAt` (équipe de l'événement) |
| `users/{uid}/notifications` | `limit ≤ 100` par l'app | — (sous-collection privée) ; « tout marquer comme lu » épingle `readAt == null` |
| `reports` · `moderationQueue` · `admins` | `limit ≤ 100` par l'app | — : lecture réservée aux administrateurs, refusée à tout autre compte |

Toute requête a un `.limit()`. La pagination se fait par curseur
(`startAfterDocument`) sur un ordre stable, jamais par `offset` (facturé en
lectures sur le Spark : 50 000 lectures/jour).

Une requête composite (égalité + tri sur un autre champ) exige un index :
l'ajouter dans `firebase/firestore.indexes.json` **dans la même PR**, puis
`make deploy-rules`. En local l'émulateur n'exige pas d'index : l'erreur
`failed-precondition` n'apparaît qu'en cloud, d'où la discipline.

### 3.5 Horodatages

| Cas | Valeur envoyée | Vérification dans les règles |
|---|---|---|
| Date technique (`createdAt`, `updatedAt`, `readAt`…) | `FieldValue.serverTimestamp()` | `isServerTime(v)` : `v == request.time` |
| Date qui entre dans un **identifiant** (ex. `reservedAt` dans l'id de la notification de réservation) | `Timestamp.now()` côté client, connu avant le commit | `isRecentTime(v)` : entre −5 min et +2 min de l'horloge serveur |
| Date métier (`startsAt`) | `Timestamp.fromDate(dateUtc)` | `startsAt > request.time` à la création |
| Expiration (`expiresAt`) | `now + 30 jours` | `≤ request.time + 400 jours` ; purge par TTL |

Tout est stocké en `Timestamp` (UTC) et converti à l'affichage dans le fuseau
de l'appareil, en `fr-FR` (`AppDateFormats`). Les DTO passent par le
convertisseur `timestamp_converter.dart`. Un `serverTimestamp()` vaut `null`
dans le cache local jusqu'à la confirmation du serveur : les DTO le tolèrent.

### 3.6 Forme des documents

* Champs en **camelCase**, noms identiques à ceux des règles (`availablePlaces`,
  `organizerId`) : le DTO est le miroir du bloc de commentaire en tête de
  chaque `match` dans `firestore.rules`.
* Les règles utilisent `keys().hasOnly([...])` : **n'envoyer aucun champ
  supplémentaire**, même `null`. Un champ ajouté dans le DTO sans la règle
  correspondante est un refus en production.
* `update` n'envoie que les champs modifiés (`onlyChanged`).
* Montants en **unités mineures entières** (centimes ; MGA sans décimale).
  Aucun `double` ne touche un prix.

### 3.7 Erreurs

Les repositories ne lèvent jamais : `guard()` convertit toute exception via
`ErrorMapper` en `Failure`.

| Code `FirebaseException` | `Failure` | Lecture pour l'utilisateur |
|---|---|---|
| `permission-denied` | `PermissionFailure` (ou règle métier traduite localement : `eventFull`, `alreadyReported`…) | « Vous n'avez pas les droits pour cette action » |
| `not-found` | `NotFoundFailure` | contenu supprimé |
| `already-exists` | succès idempotent quand l'intention est déjà réalisée (favori, suivi) | — |
| `aborted` | nouvelle tentative de la transaction, puis `actionRefused` | « Réessayez » |
| `failed-precondition` | `UnexpectedFailure` + log (index manquant) | message générique |
| `unavailable`, `deadline-exceeded` | `NetworkFailure` | bandeau hors ligne |
| `resource-exhausted` | `QuotaFailure` / `actionRefused` | quota Spark du jour atteint |
| `FirebaseAuthException` (`invalid-credential`, `email-already-in-use`, `weak-password`, `user-disabled`, `too-many-requests`, `requires-recent-login`…) | `AuthFailure` | messages dédiés |

`permission-denied` ne dit pas **quelle** condition a échoué. La couche
`data` vérifie donc d'abord la politique du domaine (`ReservationPolicy`…)
pour donner un message précis, et ne garde le refus des règles que comme
dernier rempart.

---

## 4. Definition of Done (par tâche)

1. Comportement conforme au cahier des charges (section citée dans la PR).
2. Tests : règle métier ⇒ test unitaire ; écran ⇒ test widget minimal.
3. Toute nouvelle écriture Firestore, collection ou champ ⇒ **règle dans
   `firebase/firestore.rules` et test dans `firebase/tests/*.rules.test.js`**
   (le cas autorisé **et** au moins une attaque refusée) ; `make rules-test`
   vert.
4. Nouvelle requête composite ⇒ index dans `firebase/firestore.indexes.json`.
5. README et `docs/` concernés mis à jour dans la même PR.
6. Colonne « Statut » du tableau de suivi passée en *En review* avec le lien PR.
