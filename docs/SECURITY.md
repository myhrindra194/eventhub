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

**À faire (F-03 de la feuille de route)** :

```js
exports.onUserCreated = functions.firestore
  .document('users/{uid}')
  .onCreate(async (snap, ctx) => {
    await admin.auth().setCustomUserClaims(ctx.params.uid, {
      role: snap.data().role,
    });
  });
```

Puis, côté client, forcer un rafraîchissement du jeton :
`FirebaseAuth.instance.currentUser?.getIdToken(true)`.

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
les requêtes du client portent ces égalités et pourquoi l'index composite
`(eventId, organizerId, status, reservedAt)` existe.

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

**70 tests, 0 échec.** Elle tourne aussi en CI (job `Security rules`), sans
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

### Reste à couvrir

Les sous-collections anticipées (`favorites`, `devices`, `notifications`,
`waitlist`, `checkins`, `reports`) ont des règles mais pas encore de tests :
elles n'ont pas de client. À écrire **en même temps** que la fonctionnalité qui
les consomme, jamais après.

---

## 11. Limites connues

- **Pas de rate limiting véritable.** `notTooFast()` est une protection
  grossière (une écriture par seconde et par document). Un vrai quota exige un
  document compteur ou App Check.
- **App Check n'est pas activé.** C'est la contre-mesure standard contre les
  clients non officiels ; à activer avant l'ouverture publique.
- **Suppression de compte non implémentée.** `delete` sur `users/{uid}` est
  refusé : réservations, événements et objets Storage doivent être réconciliés
  d'abord, ce qui relève d'une Cloud Function.
- **La suppression d'un événement ne cascade pas.** Elle est simplement
  interdite tant que des places sont vendues.
