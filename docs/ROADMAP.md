# EventHub — Feuille de route fonctionnelle

> Ce document répond à une question précise : **que construire ensuite, et
> pourquoi**. Chaque fonctionnalité est justifiée par ce que font les grandes
> plateformes du secteur, puis traduite en impact produit, coût technique et
> dépendances (collections, règles, écrans). Depuis septembre 2026, une
> contrainte s'ajoute à chaque ligne : **le plan Spark** (Firebase Auth +
> Firestore, aucun code serveur). Ce qui ne tient pas dans ce cadre est
> explicitement rangé dans ce que le **plan Blaze** débloquerait (§6).

---

## 1. Benchmark — ce que font les leaders

| Plateforme | Positionnement | Ce qu'on en retient |
|---|---|---|
| **Eventbrite** | Marketplace généraliste, billetterie payante | Découverte par ville + catégorie, pages organisateur, billets QR, un compte pour acheter **et** organiser |
| **Luma (lu.ma)** | Événements communautaires, tech | Création ultra-rapide (< 60 s), page publique élégante, invitations par lien, calendrier d'organisateur suivi par ses fans |
| **Meetup** | Communautés récurrentes | Groupes, événements récurrents, discussions, « qui vient ? » (preuve sociale forte) |
| **Dice** | Concerts, culture jeune | Liste d'attente automatique, billets non transférables, notifications de dernière minute |
| **Shotgun** | Clubbing, festivals | Rareté explicite (« il reste 8 places »), vagues de prix, partage social natif |
| **Airbnb** | Réservation d'expériences | Filtres riches, favoris, notes et avis, un compte voyageur qui devient hôte |
| **Partiful** | Événements privés | RSVP simple, rappels automatiques, ton chaleureux |
| **Ticketmaster** | Billetterie à grande échelle | Contrôle d'accès (scan), anti-fraude |

**Les quatre constantes** qu'EventHub doit tenir :

1. **La rareté est visible** — places restantes partout (`CapacityMeter`).
2. **La preuve sociale précède la décision** — qui vient, combien, quelle note.
3. **Le rappel appartient à la plateforme** — un billet oublié est un échec
   produit.
4. **L'entrée est un moment technique** — le scan doit marcher vite, et hors
   ligne pour le billet.

---

## 2. Historique des livraisons

> **Le backend du projet est Firebase** — Firebase Auth et Cloud Firestore, sur
> le plan Spark. La ligne v2.0 ci-dessous est une parenthèse close, conservée
> pour mémoire : plus aucune ligne de Supabase ne subsiste dans le dépôt, ni
> dans le code, ni dans les dépendances, ni dans la configuration.

| Version | Livraison |
|---|---|
| v1.0 | Inscription, catalogue éditorialisé, recherche et filtres, réservation atomique, portefeuille, tableau de bord organisateur, thème clair/sombre |
| v1.1 | Billet QR + code court, partage par lien, export CSV (presse-papiers), stats et alertes organisateur |
| v1.2 | Branchement réel sur Firebase (`eventhub-d411f`), push Android par Cloud Functions |
| v1.3 | Google, vérification d'email, suppression de compte, centre de notifications, favoris (F-05), liste d'attente (F-06), avis (F-09), contrôle à l'entrée (F-01), pagination (F-04) |
| v1.4 | Profils organisateurs et abonnements (F-10), preuve sociale (F-07), page publique et App Links (F-08), export CSV fichier (F-15), « Pour vous » (F-18), signalement et modération (F-19) |
| v1.5 – v1.6 | Co-organisateurs (F-16), types de billets (F-12), billetterie Stripe (F-11) |
| v2.0 | *Parenthèse Supabase* (Postgres, RLS, fonctions SQL, Edge Functions) — **abandonnée**, puis intégralement retirée en v2.1 |
| **v2.1** | **Retour à Firebase Auth + Cloud Firestore sur le plan Spark** : Supabase retiré ; règles Firestore comme unique backend (preuves `getAfter`/`existsAfter`, identifiants déterministes), notifications écrites par l'acteur, rappels J-1 locaux, suppression de compte côté client, images par URL, TTL des notifications, page `/e/{id}` par l'API REST, « un compte, deux espaces » (bouton « Devenir organisateur »), layout responsive multiplateforme (Android, iOS, web, Windows, macOS), suite de règles sur émulateur en CI. **Désactivés faute de serveur** : paiements (F-11), push app fermée (F-02 partiel) |
| **v2.2** | **Images sur Cloudinary** : photo et couverture de profil, affiche d'événement importées depuis l'appareil (envoi non signé, compression locale, variantes WebP redimensionnées à l'affichage) ; règles limitées aux liens Cloudinary, anciennes valeurs conservées |
| **v2.3** | **Push FCM app fermée** : Worker Cloudflare `eventhub-api` (vérification de l'ID token, notification existante écrite par l'appelant, reçus d'envoi idempotents, préférences, nettoyage des jetons morts), appelé par les trois écrivains de notifications ; règle `pushReceipts`, purge horaire des reçus par le Worker |
| **v2.4** | Rôle demandé à l'inscription (`intendedRole`), **mail de bienvenue** au lieu du lien de vérification (vérification au moment de publier), « Nous contacter » qui envoie un vrai email à l'entreprise (Brevo par le Worker `eventhub-api`), barre d'onglets façon iOS de la même matière que les barres du haut, thème depuis Profil, filtres en menu déroulant, demande d'autorisation caméra |
| **v2.5** | Démarrage refait (lancement natif à la couleur de l'app, intro de 1,3 s attendue par le router) ; rôle organisateur accordé dès l'inscription (publication toujours soumise à l'adresse vérifiée) ; correctif de la course d'écriture du profil ; billet affiché juste après une réservation ; scanner accessible depuis la barre de l'espace organisateur ; thème en tête de Profil ; barres opaques (le fond transparent d'une AppBar est rendu noir par certains GPU Android) |
| **v2.6** | Rôles **exclusifs et définitifs** : « Devenir organisateur » et la bascule d'espace retirés ; chaque rôle confiné à son espace (router) ; réservation, liste d'attente et avis réservés aux participants (règles) |

**Pourquoi ce retour.** Le critère décisif est le coût : aucun service payant.
Sur Firebase, ce sont Cloud Functions, Cloud Storage et Cloud Scheduler qui
exigent Blaze ; Auth et Firestore tiennent sur Spark. Les fonctionnalités qui
dépendent d'un secret ou d'une exécution planifiée sont donc suspendues, pas
supprimées : le modèle de données les anticipe (§7).

---

## 3. État des fonctionnalités (F-01 à F-20)

Légende — ✅ livré sur Spark · 🟡 livré avec une limite Spark · ⏸ suspendu
(exige Blaze) · ⬜ à faire.

| Réf | Fonctionnalité | Inspiration | État v2.1 |
|---|---|---|---|
| F-01 | Billet QR + contrôle d'accès | Ticketmaster, Dice | 🟡 scan et anti-doublon multi-portes (`checkins` en création seule) ; QR **non signé** (signature HMAC = secret serveur) |
| F-02 | Notifications et rappels | Dice, Partiful | ✅ centre de notifications temps réel, **push FCM app fermée** (Worker Cloudflare), rappels J-1 **locaux** |
| F-03 | Vérification d'email et rôles | toutes | ✅ email vérifié exigé (organisateur, publication, avis) ; rôle dans `users/{uid}` relu par les règles |
| F-04 | Pagination du catalogue | — | ✅ page temps réel + curseurs, `limit ≤ 200` imposé |
| F-05 | Favoris | Airbnb, Luma | ✅ `users/{uid}/favorites/{eventId}` |
| F-06 | Liste d'attente | Dice | ✅ FIFO, notification in-app par la personne qui libère la place |
| F-07 | Preuve sociale | Meetup, Partiful | ✅ `events/{id}/attendees/{sha256(uid)}` |
| F-08 | Partage et lien public | Luma, Shotgun | 🟡 page `/e/{id}` par l'API REST, App Links Android ; pas d'aperçu Open Graph dynamique, pas d'Universal Links iOS |
| F-09 | Avis après l'événement | Airbnb, Eventbrite | ✅ note prouvée dans le batch |
| F-10 | Profil organisateur public | Luma, Eventbrite | ✅ compteurs prouvés ; photo hébergée sur Cloudinary |
| F-11 | Billetterie payante | Eventbrite | ⏸ **suspendue** : secret Stripe et webhook signé impossibles sans serveur ; les types payants s'affichent mais ne se réservent pas |
| F-12 | Types de billets | Shotgun | ✅ map `tiers` (≤ 6), types gratuits réservables ; dates de vente à faire |
| F-13 | Événements récurrents et séries | Meetup | ⬜ modèle `series` + génération d'occurrences côté client (batch) |
| F-14 | Carte et « près de moi » | Airbnb | ⬜ geohash dans l'événement + requêtes par plage (faisable sur Spark) |
| F-15 | Export CSV | Eventbrite | ✅ fichier généré sur l'appareil |
| F-16 | Co-organisateurs | Eventbrite | ✅ `staffIds` ≤ 10, invitation acceptée prouvée |
| F-17 | Discussion par événement | Meetup | ⬜ faisable sur Spark (sous-collection bornée), mais coût de modération : seulement avec F-19 mûr |
| F-18 | Recommandations | Luma, Airbnb | ✅ heuristique locale explicable |
| F-19 | Signalement et modération | toutes | 🟡 file, dossier, décisions ; la suspension bloque les écritures mais ne désactive pas le compte Auth |
| F-20 | Multilingue (fr / en / mg) | toutes | ⬜ `AppStrings` centralisé : migration ARB mécanique |

---

## 4. Backlog priorisé (réalisable sur Spark)

**P0 — crédibilité**
* **App Check** en mode observation puis enforcement (`SECURITY.md` §8) :
  première protection contre l'épuisement des quotas.
* **Clés API restreintes** (applications et API autorisées).
* **Empreinte release** dans `assetlinks.json`, Universal Links iOS.

**P1 — différenciation**
* F-14 carte et « près de moi » (geohash).
* F-12 dates de vente par type (early bird) : champs `salesStart`/`salesEnd`
  dans `tiers`, vérifiés par `tierBookable()`.
* « Ajouter au calendrier » (fichier `.ics` généré sur l'appareil).

**P2 — montée en gamme**
* F-13 séries, F-20 multilingue, F-17 discussion (après modération outillée).

**P3 — paris**
* Widget d'accueil / Live Activity avec le prochain billet.
* Apple / Google Wallet (exige une signature de pass : serveur, voir §6).

---

## 5. Limites assumées du plan Spark

| Sujet | Ce qui se passe aujourd'hui | Pourquoi c'est acceptable pour le MVP |
|---|---|---|
| Push app fermée | envoyé par un Worker Cloudflare sur appel de l'auteur, pas par un déclencheur | le centre in-app garde toute notification dont le push n'est pas parti |
| Rappels | planifiés sur l'appareil qui a réservé | couvre le cas nominal ; pas de coût serveur |
| Paiements | événements gratuits seulement | le cahier des charges MVP est centré sur la réservation gratuite |
| Images | Cloudinary, envoi non signé depuis l'app | pas de Cloud Storage payant ; preset restrictif, suppression impossible sans serveur |
| Compteurs | dénormalisés et prouvés dans les batchs | exacts sans trigger ; coûtent une écriture de plus par action |
| Notifications à autrui | best-effort après le commit | l'action principale ne dépend jamais de l'effet secondaire |
| Quotas | 50 k lectures, 20 k écritures, 20 k suppressions / jour ; 1 Gio | largement suffisant pour une démonstration et un pilote ; au-delà, l'app s'arrête jusqu'au lendemain |
| Limitation de débit | aucune par compte | App Check + identifiants déterministes limitent l'abus |
| Aperçus de liens | titre générique | un rendu serveur n'apporte que du confort |

---

## 6. Ce que le plan Blaze débloquerait

Blaze est un plan **à l'usage** : mêmes quotas gratuits que Spark, facturation
au-delà, compte de facturation obligatoire. Avant tout passage : **alertes
budgétaires** dans Google Cloud et plafonds de dépense surveillés.

| Capacité | Brique Blaze | Fonctionnalité | Ce que ça change dans le code |
|---|---|---|---|
| **Paiements Stripe** | Cloud Functions (Checkout, webhook signé, remboursements) + Secret Manager | **F-11** | la fonction tient la place (`pending`) et seul le webhook confirme ; les règles gardent `pricePaid` en lecture seule côté client |
| **Push déclenché par Firestore** | Cloud Functions (`onDocumentCreated` sur `notifications`) | **F-02** | remplace l'appel du client au Worker ; plus de push perdu si l'app meurt entre deux étapes |
| **Rappels serveur** | Cloud Scheduler + fonction planifiée | **F-02** | rappels J-1 garantis même sans l'appareil qui a réservé ; index `reservations(status, eventStartsAt)` |
| **Envoi d'images signé** | Cloud Functions (signature Cloudinary) | F-10, création d'événement | le preset redevient privé et les images remplacées peuvent être supprimées ; Cloudinary reste l'hébergeur |
| **Compteurs agrégés** | triggers Firestore | F-07, F-10, stats | les preuves `lastEventId`/`lastReviewId` deviennent inutiles ; écritures client plus simples |
| **Notifications atomiques** | triggers | toutes | plus de best-effort : l'effet suit le commit |
| **Suppression de compte serveur** | trigger `onUserDeleted` / fonction appelable | RGPD | nettoyage garanti même si l'app est interrompue |
| **Suspension complète** | Admin SDK | F-19 | compte Auth désactivé, jetons révoqués |
| **Limitation de débit** | fonction appelable + compteur serveur | anti-abus | quotas par compte |
| **QR signé** | fonction de signature HMAC | F-01 | billet infalsifiable hors ligne |
| **Aperçus Open Graph** | fonction ou rendu Hosting dynamique | F-08 | titre, image et date dans WhatsApp/Slack |
| **Emails transactionnels** | extension *Trigger Email* | F-02, F-16 | confirmation de réservation, invitation par email |

**Séquencement proposé en cas de passage Blaze** : alertes budgétaires → push
serveur (rétention, coût faible) → rappels planifiés → paiements Stripe
(revenu, coût de conformité plus élevé) → envoi d'images signé.

---

## 7. Ce que le modèle de données anticipe déjà

Écrire une règle après avoir livré la fonctionnalité, c'est livrer une faille
pendant l'intervalle. Le modèle couvre donc plus que ce que Spark permet
d'utiliser.

| Prêt dans les règles / le modèle | Utilisé aujourd'hui | Fonctionnalité cible |
|---|---|---|
| `users/{uid}/devices` (jeton, plateforme) | ✅ enregistrement, push par le Worker, jetons morts supprimés | — |
| `reservations.pricePaid`, `tiers[].price`, `events.currency` | affichage seul | F-11 (Blaze) |
| `notifications.expiresAt` + TTL | ✅ | rétention 30 jours |
| `organizers.suspended` | écrit par la modération | badge « compte suspendu » |
| `moderationQueue/{id}/decisions` | ✅ | audit des décisions |
| index `reservations(eventId, status, reservedAt)` | ✅ | rappels serveur, statistiques |
