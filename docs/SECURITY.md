# EventHub — Modèle de sécurité

> **Les règles Firestore sont le seul contrôle qui s'exécute réellement.**
> Sur le plan Spark, il n'y a aucun code serveur : l'application Flutter est
> une commodité. Les identifiants Firebase sont dans chaque build, et
> n'importe qui peut créer un compte puis appeler Firestore directement avec
> une charge utile fabriquée. Ce document explique ce que les règles
> garantissent, comment, où c'est testé — et, surtout, **ce qu'elles ne
> peuvent pas garantir**.

| Fichier | Rôle |
|---|---|
| `firebase/firestore.rules` | droits, formes des documents, invariants inter-documents |
| `firebase/firestore.indexes.json` | index composites, TTL des notifications |
| `firebase/tests/*.rules.test.js` | preuves : chaque attaque est rejouée contre l'émulateur |
| `lib/core/firebase/firestore_paths.dart` | identifiants déterministes reconstruits par les règles |

---

## 1. Modèle de menace

| Attaquant | Capacité | Contre-mesure |
|---|---|---|
| Visiteur anonyme | possède la clé API (elle est dans l'APK et sur le site) | n'obtient qu'un `get` d'événement par identifiant ; tout le reste exige un compte, puis un droit |
| Utilisateur curieux | lit avec son propre jeton | profils privés, `list` refusé sur `users`, `admins`, `organizerEmails` ; requêtes bornées qui doivent épingler le filtre prouvant le droit |
| Utilisateur malveillant | écrit n'importe quel champ, identifiant, batch | `keys().hasOnly`, bornes et types sur chaque champ ; identifiants reconstruits ; **preuves** `getAfter` / `existsAfter` sur tout compteur |
| Client rétro-conçu | ignore toute validation de l'interface | chaque politique du domaine Dart est réécrite dans les règles |
| Compte suspendu | garde un jeton valide jusqu'à une heure | `isActive()` relit `users/{uid}.suspended` à chaque écriture concernée : refus immédiat |
| Élévation de privilège | tente de devenir admin ou organisateur | `admins/*` : `write: if false` ; rôle `participant` imposé à la création, passage organisateur sens unique, email vérifié, batch complet |
| Spam de notifications | écrit dans la boîte d'autrui | type connu, acteur = appelant, identifiant déterministe par fait, fait prouvé |
| Scraper / épuisement de quota | boucle de lectures pour épuiser les 50 000 lectures/jour | `list` bornés et authentifiés ; **App Check recommandé** (§8) ; limite non couverte par les règles (§7) |

---

## 2. Identité

* **Rôle** : `users/{uid}.role`. Création forcée à `participant` (modèle
  Eventbrite/Airbnb : un compte, deux espaces). Passage `organizer` : sens
  unique, email vérifié, **dans le batch** qui crée `organizers/{uid}` et
  `organizerEmails/{hash}`. Un organisateur garde tous les droits participant.
* **Administrateur** : existence de `admins/{uid}`. **Aucune écriture client**
  ne peut le créer (`allow write: if false`) : il se crée dans la console
  Firebase (Firestore → Données). Chacun peut demander « suis-je admin ? »
  sur **son** uid seulement (le `get` d'un document inexistant est autorisé et
  ne révèle rien) ; seul un admin liste la collection.
* **Suspension** : `users/{uid}.suspended`, écrit par un admin, jamais sur
  lui-même. Un compte suspendu lit encore, mais toute écriture qui passe par
  `isActive()` est refusée.
* **Email vérifié** : `request.auth.token.email_verified == true`, exigé pour
  devenir organisateur, publier, laisser un avis, s'inscrire dans
  `organizerEmails`.

---

## 3. Parcours des règles, collection par collection

### `users/{uid}`
* `get` : soi ou admin. `list` : **jamais**, admins compris (pas d'annuaire).
* `create` : soi, clés exactes, `email` = celui du jeton, `role = participant`,
  `createdAt` serveur.
* `update` : trois branches exclusives — présentation (nom, bio, `welcomedAt`
  posé une fois) ; passage organisateur prouvé par `existsAfter(organizers/uid)` ;
  suspension par un admin (`onlyChanged(['suspended','updatedAt'])`).
* `delete` : soi (suppression de compte).
* Sous-collections `private`, `devices`, `favorites` : propriétaire seul,
  formes strictes (`private/notifications` est le seul document autorisé).
* `following/{organizerId}` : privé ; création/suppression **seulement** si
  `followerCount` de l'organisateur bouge de ±1 dans le même batch ; pas de
  suivi de soi-même.
* `notifications` : lecture et suppression par le destinataire ; création par
  l'acteur sous preuve (8 types : bienvenue, réservation, annulation, liste
  d'attente, invitation, arrivée / retrait d'équipe, modération) ; seule mise à
  jour possible : `readAt` posé une fois à l'heure serveur.

### `admins/{uid}`
Lecture de soi, liste par les admins, **aucune écriture**.

### `organizers/{uid}`
* Lecture : comptes connectés.
* Création : par soi, email vérifié, compteurs à **zéro**, rôle `organizer`
  et entrée `organizerEmails` présents après le batch.
* Mise à jour : cinq branches — nom/bio alignés sur `users` ; `followerCount ±1`
  prouvé par le document `following` de l'appelant ; `eventCount ±1` prouvé
  par `lastEventId` (créé ou supprimé dans ce batch, par son propriétaire) ;
  note prouvée par `lastReviewId` (écrit, modifié, supprimé, masqué ou rétabli
  dans ce batch) ; `suspended` par un admin.

### `organizerEmails/{sha256}`
`get` d'un hash exact par un organisateur ; `list` interdit ; création
uniquement du hash de **sa propre** adresse vérifiée.

### `events/{id}`
* `get` : **public** (page `/e/{id}`). `list` : connecté, `limit ≤ 200`.
* `create` : organisateur actif et vérifié, forme valide, `availablePlaces =
  capacity`, équipe vide, date future, `eventCount + 1` sur sa page dans le
  même batch.
* `update` : contenu par l'équipe (capacité jamais sous les places prises,
  `organizerId`, `createdAt`, `staffIds` intouchables) ; **une** place prise ou
  rendue par un non-membre de l'équipe, prouvée par sa réservation et, avec
  des types de billets, par le type exact ; entrée ou sortie d'équipe prouvée
  par l'invitation acceptée (≤ 10 membres).
* `delete` : propriétaire si aucune place prise (et `eventCount - 1`), ou admin.
* `waitlist` : inscription seulement si complet et à venir, hors équipe ;
  `notifiedAt` posé une fois quand une place s'est libérée.
* `checkins` : équipe, ajout seul, réservation confirmée **du même événement**.
* `invitations` : créées par le propriétaire pour un organisateur existant,
  retrouvé par le hash de son email ; réponse (acceptée/refusée) par l'invité.
* `attendees` : clé = `sha256(uid)`, nom court, **seulement** si la
  réservation de l'appelant est confirmée après le batch.

### `reservations/{eventId}_{uid}`
* `get` : un document inexistant n'est sondable que sur **son propre** id
  (« ai-je réservé ? ») ; sinon participant, organisateur, équipe, admin.
* `list` : `limit ≤ 500` et filtre prouvant le droit.
* `create` / re-réservation : id = `eventId_uid`, email du jeton, copie
  conforme de l'événement, type gratuit, hors équipe, place libre, date
  future, `reservedAt` récent, **`availablePlaces - 1` dans la même
  transaction**. `pricePaid` doit valoir 0.
* Annulation : par le participant, `cancelledAt` récent, place rendue dans la
  transaction (sauf événement déjà supprimé).
* Anonymisation (suppression de compte) et annulation de masse par la
  modération : branches dédiées.
* `delete` : **jamais** (l'historique survit).

### `reviews/{eventId}_{uid}`
Création par un présent (réservation confirmée, événement commencé), email
vérifié, note 1–5, `hidden = false`, **note de l'organisateur mise à jour dans
le batch**. Les avis masqués ne sont visibles que de leur auteur et de la
modération ; masquer/rétablir fait suivre la note.

### `reports` et `moderationQueue`
Signalement en écriture seule, un par personne et par contenu, pas sur soi ni
sur son propre avis, motif fermé (précisions obligatoires pour « Autre ») ; le
dossier de modération est ouvert ou incrémenté **dans le même batch**. Seuls
les admins lisent et décident ; les décisions sont un journal en ajout seul.

### Filet final
`match /{document=**} { allow read, write: if false; }` : tout chemin non
déclaré est refusé.

---

## 4. Ce que les règles prouvent

| # | Invariant | Mécanisme |
|---|---|---|
| 1 | Aucune survente, même en simultané | transaction + `getAfter(events).availablePlaces == avant - 1` ; la transaction concurrente est rejouée et échoue |
| 2 | Une réservation, un avis, un signalement par personne | identifiants déterministes reconstruits |
| 3 | Aucun compteur public (abonnés, événements, note) ne bouge sans sa cause | `lastEventId`, `lastReviewId`, document `following` exigés dans le batch |
| 4 | Aucun pouvoir d'administration par une écriture client | `admins/*` sans écriture |
| 5 | Personne ne s'inscrit directement organisateur ; le passage exige un email vérifié | création `participant`, branche de mise à jour dédiée |
| 6 | La liste des participants ne sort jamais de l'équipe | `get`/`list` des réservations |
| 7 | Un billet ne sert qu'une fois à la porte | `checkins/{reservationId}` en création seule : le second scan est une mise à jour, refusée |
| 8 | Une notification par fait, prouvé | identifiant déterministe + preuve par type |
| 9 | L'historique survit à la suppression | `reservations` sans `delete`, anonymisation encadrée |
| 10 | Rien n'est payant sans serveur | `pricePaid == 0`, types gratuits seuls |

---

## 5. Données personnelles

| Donnée | Traitement |
|---|---|
| Email, rôle | `users/{uid}`, privé ; jamais copiés sur `organizers` |
| Email d'un participant | copié sur sa réservation, visible de l'**équipe** de l'événement (liste d'invités, export CSV) : besoin métier explicite |
| Recherche d'un co-organisateur | `organizerEmails/{sha256(email)}`. Un hash d'email se devine par dictionnaire : contrepartie acceptée, car seul un organisateur peut faire un `get`, un hash à la fois, sans jamais lister |
| Preuve sociale | `attendees/{sha256(uid)}` + nom court : aucun uid publié |
| Événement public | `get` anonyme autorisé ; le document contient `organizerId` et `staffIds` (des uid). Un uid n'est pas un secret et ne donne aucun droit ; la page `/e/{id}` applique un masque de champs par sobriété |
| Notifications | purgées par TTL (`expiresAt`, 30 jours) |
| Suppression de compte | places libérées, historique anonymisé, sous-collections, page organisateur et compte Auth supprimés (`ARCHITECTURE.md` §5.6) |
| Crashlytics · Analytics | uid technique ; Analytics seulement après consentement |

---

## 6. Tester la sécurité

```sh
make rules-setup   # une fois : npm ci (inclut la CLI Firebase), Java 21 requis
make rules-test    # émulateur Firestore + suite complète
```

La suite (`node:test` + `@firebase/rules-unit-testing`) charge **le vrai
fichier de règles** dans l'émulateur, projet `demo-eventhub` (aucune
connexion au cloud, aucun identifiant). Chaque test agit sous une identité
(`as(env, 'p1')`, anonyme, email non vérifié) et fabrique ses écritures à la
main, exactement comme un attaquant : batch amputé d'une moitié, compteur
gonflé à 5 000, identifiant forgé, adresse d'autrui, second scan, etc. Les
fixtures sont posées règles désactivées (`seed`).

| Fichier | Couvre |
|---|---|
| `accounts.rules.test.js` | profils, passage organisateur, `organizerEmails`, sous-collections privées, `admins` |
| `events.rules.test.js` | publication, édition, suppression, types de billets, équipe, invitations |
| `reservations.rules.test.js` | réserver, annuler, re-réserver, survente, liste d'attente, entrée, anonymisation |
| `social.rules.test.js` | abonnements, avis et note, signalements, modération, notifications, preuve sociale |

Elle tourne en CI (job `firestore-rules`) sans aucun secret. **Toute
modification des règles arrive avec son test** (cas autorisé et attaque
refusée).

---

## 7. Ce que les règles ne peuvent pas garantir

Les règles décident « oui / non » pour **une** requête. Tout ce qui demande de
la mémoire entre requêtes, un secret ou une action sortante leur échappe.

| Limite | Conséquence | Atténuation actuelle | Solution avec serveur (Blaze) |
|---|---|---|---|
| **Limitation de débit** | un compte peut enchaîner des écritures valides (favori/défavori en boucle) et consommer le quota de 20 000 écritures/jour | identifiants déterministes (pas de multiplication de documents), App Check, alertes d'usage | compteur par compte dans une Cloud Function / Firestore côté serveur |
| **Épuisement des quotas Spark** | un scraper authentifié peut épuiser 50 000 lectures/jour : l'app devient indisponible jusqu'à minuit (heure du Pacifique) | `list` bornés, App Check | passage Blaze (facturation au-delà, plus d'arrêt) + alertes budgétaires |
| **Envoi d'emails** | seuls les emails de Firebase Auth (vérification, réinitialisation, changement d'adresse) partent | modèles personnalisés dans la console | extension *Trigger Email* ou fonction |
| **Push app fermée** | aucune notification système quand l'app est fermée | centre de notifications, rappels J-1 locaux | Cloud Function + FCM HTTP v1 |
| **Paiements** | aucun encaissement : un secret Stripe et un webhook signé ne peuvent pas vivre dans le client | types payants non réservables (`pricePaid == 0`) | Cloud Functions Stripe (F-11) |
| **Contenu des URL d'images** | une URL https peut pointer vers une image inappropriée ou changer après validation | signalement + retrait par la modération | upload Cloud Storage + contrôle |
| **Désactivation Auth d'un compte suspendu** | le compte suspendu peut encore se connecter et **lire** | écritures refusées par `isActive()` | Admin SDK (`disabled: true`, révocation des jetons) ; manuellement : console → Authentication → Désactiver |
| **Atomicité des effets secondaires** | une notification best-effort peut manquer si l'app meurt entre deux commits | identifiant déterministe, nouvelle tentative sûre | trigger `onDocumentWritten` |
| **Suppression de compte interrompue** | des données peuvent rester si l'app est tuée en cours | étapes idempotentes, relançables tant que le compte Auth existe | fonction `onUserDeleted` |
| **Écritures de ses propres sous-collections par un compte suspendu** | favoris, préférences, `readAt` restent possibles (vérifient `isSelf` seulement) | impact limité à ses propres données | — (choix : ne pas payer une lecture de profil de plus sur ces écritures) |

---

## 8. App Check (recommandé)

**Pourquoi.** App Check atteste que la requête vient de **votre** app sur un
appareil ou un navigateur réel (Play Integrity sur Android, App Attest /
DeviceCheck sur iOS, reCAPTCHA Enterprise sur le web). C'est la seule parade,
sans serveur, contre un script qui réutilise la clé API pour scraper ou
épuiser les quotas. Il n'exige pas le plan Blaze (quotas gratuits de Play
Integrity et reCAPTCHA Enterprise à surveiller).

**Déploiement conseillé, en deux temps :**

1. intégrer `firebase_app_check` (fournisseur *debug* en développement et sur
   les émulateurs), publier, puis observer **plusieurs jours** les métriques
   *App Check → Firestore* (requêtes vérifiées / non vérifiées) ;
2. activer l'**application** (enforcement) pour Firestore et Auth quand les
   vieilles versions de l'app ont disparu.

**Contreparties à connaître.**

* Une fois l'enforcement actif sur Firestore, la page publique `e.html`
  (API REST + clé seule) sera **refusée** : il faudra qu'elle obtienne un
  jeton App Check web (SDK JS Firebase + reCAPTCHA), donc charger un script
  supplémentaire servi par Hosting.
* Windows et macOS n'ont pas de fournisseur natif équivalent dans FlutterFire :
  ces builds utiliseraient un jeton debug (réservé au développement) ou
  resteraient hors enforcement — à trancher avant d'activer.
* Un appareil rooté ou un émulateur échoue à l'attestation.

---

## 9. Politique des secrets

**Rien de secret n'est dans le dépôt, et rien ne doit l'être** (dépôt public).

| Élément | Statut | Pourquoi |
|---|---|---|
| `lib/firebase_options.dart` | **versionné, public par conception** | `apiKey`, `appId`, `projectId` identifient le projet ; ils sont extraits de n'importe quel APK ou page web. Ils n'autorisent rien : les règles et App Check le font |
| `hosting/public/eventhub-config.js` | public | mêmes identifiants que l'entrée `web` |
| `env/dev.json`, `env/example.json` | versionnés | interrupteur d'émulateur, client OAuth *web*, clé VAPID **publique** |
| `android/app/google-services.json`, `GoogleService-Info.plist` | ignorés | régénérables par `flutterfire configure`, inutiles au build Flutter |
| `android/key.properties`, keystores | **secrets**, ignorés | signature release |
| comptes de service, clés Admin SDK | **interdits** dans le dépôt et dans l'app | un compte de service contourne toutes les règles |
| `secrets/` | ignoré en entier | fichiers d'identifiants locaux |

Bonnes pratiques complémentaires :

* **Restreindre les clés API** dans Google Cloud Console → *API et services →
  Identifiants* : restrictions d'application (empreintes Android, bundle iOS,
  référents HTTP `eventhub-d411f.web.app/*` et `localhost` pour le web) et
  restriction aux API Firebase utilisées (Identity Toolkit, Token Service,
  Firestore, FCM, Installations, Crashlytics, Analytics). Ne pas restreindre
  la clé web au point de casser `e.html` (même domaine : autorisé).
* La CI n'a **besoin d'aucun secret**. Les secrets facultatifs
  `FIREBASE_OPTIONS_DART` / `GOOGLE_SERVICES_JSON` ne servent qu'à viser un
  autre projet.
* Un secret commité par erreur est **révoqué**, pas seulement supprimé de
  l'historique.

---

## 10. Limites connues (hors règles)

* **Aperçus de liens** : la page `/e/{id}` est rendue dans le navigateur ; les
  robots d'aperçu voient un titre générique (rendu Open Graph = serveur).
* **L'émulateur n'est pas le cloud** : il n'exige pas les index composites et
  applique les limites de lectures des règles de façon approchée. Vérifier
  après `make deploy-rules` sur le projet réel.
* **Heure de l'appareil** : les dates connues du client (`reservedAt`,
  `cancelledAt`) sont tolérées entre −5 et +2 minutes de l'heure serveur ; un
  appareil très déréglé voit ses réservations refusées.
