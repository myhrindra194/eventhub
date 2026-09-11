# EventHub — Feuille de route fonctionnelle

> Ce document répond à une question précise : **que construire ensuite, et
> pourquoi**. Chaque fonctionnalité est justifiée par ce que font les grandes
> plateformes du secteur, puis traduite en impact produit, coût technique et
> dépendances (règles Firestore, index, écrans). Rien n'est listé « parce que
> ça se fait » : si une ligne n'a pas de raison d'être, elle n'est pas ici.

---

## 1. Benchmark — ce que font les leaders

| Plateforme | Positionnement | Ce qu'on en retient |
|---|---|---|
| **Eventbrite** | Marketplace généraliste, billetterie payante | Découverte par ville + catégorie, pages organisateur, billets PDF/QR, gestion des remboursements |
| **Luma (lu.ma)** | Événements communautaires, tech | Création ultra-rapide (< 60 s), page publique élégante, invitations par lien, calendrier d'organisateur suivi par ses fans |
| **Meetup** | Communautés récurrentes | Groupes, adhésion, événements récurrents, discussions, « qui vient ? » (preuve sociale forte) |
| **Dice** | Concerts, culture jeune | File d'attente automatique (waitlist), billets non transférables, notifications de dernière minute, esthétique éditoriale |
| **Shotgun** | Clubbing, festivals | Rareté explicite (« il reste 8 places »), vagues de prix, partage social natif |
| **Airbnb** | Réservation d'expériences | Filtres riches, favoris, calendrier, notes et avis, photographie plein cadre |
| **Partiful** | Événements privés | RSVP sans compte, rappels automatiques, ton chaleureux |
| **Ticketmaster** | Billetterie à grande échelle | Contrôle d'accès (scan), sièges numérotés, anti-fraude |

**Les quatre constantes** que ces produits partagent et qu'EventHub doit tenir :

1. **La rareté est visible.** Le nombre de places restantes est affiché
   partout, avec une couleur qui change quand ça devient urgent. *(déjà
   implémenté : `CapacityMeter`)*
2. **La preuve sociale précède la décision.** Qui vient, combien de personnes,
   quelle note. *(à faire : `AvatarStack` existe, les données non)*
3. **Le rappel appartient à la plateforme.** Un billet réservé mais oublié est
   un échec produit, pas un échec utilisateur.
4. **L'entrée est un moment technique.** Scanner un billet doit fonctionner
   hors ligne, en 300 ms, avec les mains qui tremblent.

---

## 2. Ce qui est déjà livré (v1.0)

| Domaine | Fonctionnalité | État |
|---|---|---|
| Auth | Inscription 2 étapes, connexion, rôle immuable, récupération de profil incomplet | ✅ |
| Auth | **Mot de passe oublié** (écran dédié + confirmation) | ✅ nouveau |
| Découverte | Fil éditorialisé : carrousel « À la une », rails « Ça se remplit vite » / « Cette semaine », catalogue complet | ✅ nouveau |
| Découverte | Recherche multi-champs (titre, lieu, organisateur, catégorie) | ✅ nouveau |
| Découverte | Filtres avancés : période, tri, masquer les complets, compteur de filtres actifs | ✅ nouveau |
| Découverte | Grille de catégories avec compteurs à l'état vide | ✅ nouveau |
| Réservation | Transaction atomique place + réservation, annulation, re-réservation | ✅ |
| Billets | Portefeuille segmenté À venir / Passés / Annulés, carte-billet perforée | ✅ nouveau |
| Organisateur | Dashboard avec KPI (à venir, participants, taux de remplissage) | ✅ nouveau |
| Organisateur | Création / édition, publication, liste des participants avec recherche | ✅ |
| Système | **Thème clair + sombre + automatique**, persisté | ✅ nouveau |
| Système | Écran Paramètres, préférences de notification (UI) | ✅ nouveau |

---

## 3. Backlog priorisé

Légende — **P0** : bloquant pour une mise en production crédible · **P1** :
différenciant à court terme · **P2** : valeur à moyen terme · **P3** : pari.

### 3.1 P0 — Crédibilité produit

#### F-01 · Billet QR + contrôle d'accès
*Inspiré de : Ticketmaster, Dice*

Un billet sans preuve vérifiable n'est pas un billet. Générer un QR signé
(HMAC du `reservationId` + secret serveur), l'afficher plein écran avec
luminosité forcée, et donner à l'organisateur un scanner qui écrit dans
`events/{id}/checkins/{reservationId}`.

- **Impact** : ferme la boucle métier. C'est ce qui sépare une maquette d'un produit.
- **Technique** : `mobile_scanner`, Cloud Function de signature, règles
  `checkins` (déjà écrites : append-only, organisateur uniquement).
- **Point d'attention** : le scan doit marcher hors ligne — mettre la liste
  des participants en cache local et réconcilier au retour du réseau.

#### F-02 · Notifications push et rappels
*Inspiré de : Dice, Partiful*

Rappel J-1 et H-2, alerte d'annulation, place libérée sur liste d'attente.

- **Impact** : c'est **le** levier de rétention. Un utilisateur qui n'est pas
  rappelé ne revient pas ; les toggles de l'écran Paramètres attendent déjà ce backend.
- **Technique** : FCM, collection `users/{uid}/devices` (règles écrites),
  `users/{uid}/notifications` avec **TTL sur `expiresAt`** (déjà déclaré dans
  `firestore.indexes.json`), Cloud Function planifiée qui interroge l'index
  `reservations(status, eventStartsAt)` — également déjà déclaré.

#### F-03 · Vérification d'email et rôles par custom claims
*Inspiré de : toutes les plateformes*

Aujourd'hui le rôle est lu dans le document `users/{uid}`, ce qui coûte un
`get()` par requête. Une Cloud Function `onUserCreate` doit poser
`role` en custom claim.

- **Impact** : sécurité et coût. Les règles gèrent déjà les deux chemins
  (claim prioritaire, document en secours) — il ne reste que la fonction.
- **Technique** : Cloud Function + `auth.currentUser.getIdToken(true)` côté client.

#### F-04 · Pagination réelle du catalogue
Les requêtes sont bornées à 100 documents (`maxPageSize`), imposé par les
règles. Au-delà, il faut un `startAfterDocument` et un scroll infini.

- **Impact** : sans cela, le 101ᵉ événement est invisible.
- **Technique** : `EventRemoteDataSource.watchUpcoming` → `Notifier` paginé.

---

### 3.2 P1 — Différenciation

#### F-05 · Favoris et « ça m'intéresse »
*Inspiré de : Airbnb, Luma*

Un cœur sur chaque carte, un onglet dédié. Les favoris alimentent ensuite les
recommandations et les notifications (« l'événement que vous suiviez ouvre ses
réservations »).

- **Technique** : `users/{uid}/favorites/{eventId}` — **règles et index déjà
  écrits**. Le `doc id == eventId` rend le doublon impossible et le test
  « est-ce favori ? » gratuit.

#### F-06 · Liste d'attente automatique
*Inspiré de : Dice*

Quand un événement est complet, on s'inscrit sur liste d'attente ; à la
première annulation, la première personne de la file reçoit une notification
avec 30 minutes d'exclusivité.

- **Impact** : transforme un « Complet » (cul-de-sac) en engagement.
- **Technique** : `events/{id}/waitlist/{userId}` (règles + index FIFO écrits),
  Cloud Function déclenchée sur la mise à jour de `availablePlaces`.

#### F-07 · Preuve sociale sur la fiche
*Inspiré de : Meetup, Partiful*

« 42 personnes y vont », avec les avatars des premiers inscrits.

- **Technique** : compteur dénormalisé maintenu par Cloud Function
  (`aggregates/` est déjà déclaré en lecture seule côté client). Le composant
  `AvatarStack` existe et attend ses données.

#### F-08 · Partage et lien public
*Inspiré de : Luma, Shotgun*

Deep link `eventhub.app/e/{id}`, aperçu Open Graph, bouton natif de partage.

- **Impact** : premier canal d'acquisition gratuit d'une plateforme d'événements.
- **Technique** : `share_plus`, Firebase Hosting + Dynamic Links, route
  `/events/:eventId` déjà compatible deep link (GoRouter).

#### F-09 · Avis après l'événement
*Inspiré de : Airbnb, Eventbrite*

Note 1–5 + commentaire, réservés à ceux qui détenaient un billet confirmé.

- **Technique** : collection `reviews` — **règles écrites**, y compris la
  vérification de présence et l'email vérifié contre le spam. Index prêts.

#### F-10 · Profil organisateur public
*Inspiré de : Luma, Eventbrite*

Une page par organisateur : bio, événements passés et à venir, note moyenne,
bouton « suivre ».

- **Impact** : fidélise autour d'un organisateur plutôt que d'un événement isolé.

---

### 3.3 P2 — Montée en gamme

| Réf | Fonctionnalité | Inspiration | Note |
|---|---|---|---|
| F-11 | Billetterie payante (Stripe Connect, remboursements) | Eventbrite | Change le modèle économique : nécessite Cloud Functions, webhooks, conformité |
| F-12 | Types de billets multiples (early bird, VIP, gratuit) | Shotgun | Sous-collection `events/{id}/tiers` |
| F-13 | Événements récurrents et séries | Meetup | Modèle `series` + génération d'occurrences |
| F-14 | Carte et géolocalisation (« près de moi ») | Airbnb | Geohash + `geoflutterfire`; l'index `location + startsAt` est déjà là |
| F-15 | Export CSV de la liste des participants | Eventbrite | Cloud Function + URL signée, prefix `private/` (Storage déjà fermé au client) |
| F-16 | Co-organisateurs / équipe | Eventbrite | Passage d'un `organizerId` à un tableau `staffIds` — impacte les règles |
| F-17 | Chat ou fil de discussion par événement | Meetup | Coût de modération élevé : à ne lancer qu'avec F-19 |
| F-18 | Recommandations personnalisées | Luma, Airbnb | À partir des favoris et de l'historique ; commencer par des heuristiques |
| F-19 | Signalement et modération | Toutes | Collection `reports` — **règles déjà écrites** (write-only côté client) |
| F-20 | Multilingue (fr / en / mg) | Toutes | `AppStrings` est déjà centralisé : migration ARB mécanique |

---

### 3.4 P3 — Paris

- **Mode hors ligne complet** — cache Firestore persistant + file d'attente
  d'écritures. Pertinent à Madagascar où la connectivité est intermittente.
- **Widget d'accueil / Live Activity** — le prochain billet sur l'écran de
  verrouillage (Dice le fait, c'est spectaculaire).
- **Apple / Google Wallet** — le billet dans le portefeuille système.
- **Analytique organisateur** — courbe de remplissage dans le temps, taux de
  no-show, sources de trafic.

---

## 4. Séquencement proposé

```
v1.1  ── F-03 claims  ── F-02 push  ── F-01 QR + scan          « le billet devient réel »
v1.2  ── F-05 favoris ── F-06 waitlist ── F-08 partage          « le produit devient viral »
v1.3  ── F-04 pagination ── F-07 preuve sociale ── F-09 avis    « le produit devient crédible »
v2.0  ── F-10 profils ── F-11 paiement ── F-12 types de billets « le produit devient un business »
```

**Justification de l'ordre.** F-03 vient en premier parce que tout le reste en
dépend côté sécurité et coût. F-02 avant F-01 parce qu'une notification sans
QR reste utile, alors qu'un QR sans rappel sert rarement. F-04 est classée
après les fonctionnalités virales : tant que le catalogue tient sous 100
événements, la pagination est un travail invisible — mais elle devient
bloquante juste après, et c'est exactement le moment où le trafic arrive.

---

## 5. Ce que l'infrastructure anticipe déjà

Les règles et les index livrés couvrent **plus** que ce que l'application
utilise aujourd'hui. C'est délibéré : écrire une règle après avoir livré la
fonctionnalité, c'est livrer une faille pendant l'intervalle.

| Prêt côté serveur | Utilisé par le client | Fonctionnalité cible |
|---|---|---|
| `users/{uid}/favorites` | ❌ | F-05 |
| `users/{uid}/devices` | ❌ | F-02 |
| `users/{uid}/notifications` (+ TTL) | ❌ | F-02 |
| `events/{id}/waitlist` | ❌ | F-06 |
| `events/{id}/checkins` | ❌ | F-01 |
| `reviews` | ❌ | F-09 |
| `reports` | ❌ | F-19 |
| `aggregates` (lecture seule) | ❌ | F-07 |
| `config` (lecture publique) | ❌ | remote config |
| `audit` (fermé au client) | ❌ | conformité |
