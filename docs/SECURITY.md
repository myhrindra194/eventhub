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

* **Rôle** : `users/{uid}.role`, `participant` ou `organizer`, choisi à la
  création et **définitif** (aucune branche d'update ne le modifie). Un
  organisateur naît avec `organizers/{uid}` dans le même batch ; la page
  n'est acceptée que pour un compte qui n'existait pas encore. Les rôles sont
  exclusifs : réservation, liste d'attente et avis exigent `isParticipant()`,
  publication `isOrganizer()` + adresse vérifiée.
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
* `update` : trois branches exclusives — présentation (nom, bio, photos,
  `welcomedAt` posé une fois) ; passage organisateur prouvé par
  `existsAfter(organizers/uid)` ; suspension par un admin
  (`onlyChanged(['suspended','updatedAt'])`).
* **Photos** : `photoUrl` et `coverUrl` n'acceptent qu'un lien de livraison
  Cloudinary (`isCloudinaryImage`, 2048 caractères max), ou la valeur déjà
  enregistrée laissée intacte (`validImageField`). Restreindre l'hôte évite
  qu'un profil fasse charger à chaque lecteur une image posée sur un serveur
  tiers, qui verrait passer leurs adresses IP. Les images `data:` d'avant
  Cloudinary restent lisibles mais ne peuvent plus être écrites. Voir §11.
* `delete` : soi (suppression de compte).
* Sous-collections `private`, `devices`, `favorites` : propriétaire seul,
  formes strictes (`private/notifications` est le seul document autorisé).
* `following/{organizerId}` : privé ; création/suppression **seulement** si
  `followerCount` de l'organisateur bouge de ±1 dans le même batch ; pas de
  suivi de soi-même.
* `notifications` : lecture et suppression par le destinataire ; création par
  l'acteur sous preuve (bienvenue, réservation, annulation, liste d'attente,
  invitation, arrivée / retrait d'équipe, et les cinq avis de modération :
  événement retiré, avis masqué, avis rétabli, compte suspendu, compte
  réactivé — ces cinq-là réservés aux admins) ; seule mise à jour possible :
  `readAt` posé une fois à l'heure serveur.

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
| `team.rules.test.js` | entrée et sortie d'équipe (invitation acceptée dans le même commit), annulation d'invitation, décisions de modération (retrait d'événement, suspension), compte suspendu |

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
| **Push app fermée** | envoyé par le Worker Cloudflare, sur appel de l'auteur : perdu si l'app meurt entre l'écriture et l'appel | le Worker ne relaie qu'une notification existante, écrite par l'appelant, de moins de 10 min, une seule fois (§12) | déclencheur `onDocumentCreated` |
| **Paiements** | aucun encaissement : un secret Stripe et un webhook signé ne peuvent pas vivre dans le client | types payants non réservables (`pricePaid == 0`) | Cloud Functions Stripe (F-11) |
| **Contenu des images** | une image inappropriée peut être importée : l'envoi non signé ne passe par aucun contrôle | signalement + retrait par la modération ; `context uid` et étiquettes pour retrouver les images d'un compte dans Cloudinary | modération Cloudinary ou fonction de contrôle |
| **Envoi non signé** | le nom du cloud et le preset sont publics : un tiers peut déposer des images sur le compte et consommer le quota gratuit | preset restrictif (§11) ; rien n'est affiché qui n'ait été écrit par un compte légitime | envoi signé par une fonction détentrice du secret |
| **Images orphelines** | une image remplacée ou abandonnée reste dans la médiathèque | nettoyage manuel par dossier et étiquette | suppression par l'API d'administration depuis une fonction |
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

---

## 11. Images : Cloudinary en envoi non signé

**Pourquoi Cloudinary.** Cloud Storage exige le plan Blaze. Cloudinary offre
un hébergement d'images gratuit avec CDN et redimensionnement à la volée, et
accepte des envois directement depuis un client.

**Pourquoi non signé.** Un envoi signé exige la clé secrète du compte, qui ne
peut vivre que sur un serveur — il n'y en a pas. L'app n'embarque donc que
deux valeurs publiques : `CLOUDINARY_CLOUD_NAME` et
`CLOUDINARY_UPLOAD_PRESET`. **La clé API et le secret Cloudinary ne doivent
jamais apparaître dans le dépôt ni dans `env/*.json`.**

**Réglages du preset** (*Settings → Upload → Upload presets*). Chacun borne ce
qu'un tiers pourrait faire avec ces valeurs publiques :

| Réglage | Valeur | Ce qu'il empêche |
|---|---|---|
| Signing mode | **Unsigned** | — (mode imposé par l'absence de serveur) |
| Asset folder | `eventhub` | dispersion des fichiers dans la médiathèque |
| Overwrite | **désactivé**, `unique_filename` activé | remplacer l'image d'un autre compte en réutilisant son `public_id` |
| Allowed formats | `jpg, png, webp, heic` | dépôt de PDF, de SVG (qui peut porter du script) ou de vidéos |
| Max file size | 10 Mo (plafond de l'offre gratuite, repris par l'app) | épuisement du quota par de gros fichiers |
| Incoming transformation | `c_limit,w_2048,h_2048` | stockage d'images démesurées : la version stockée est déjà réduite |
| Moderation (facultatif) | *Manual* | publication d'une image avant contrôle |

**Défense côté Firestore.** Les règles (`isCloudinaryImage`) n'acceptent
qu'un lien `https://res.cloudinary.com/n9urnfhj/image/upload/…`. Le nom du
cloud y est figé parce que les règles ne lisent pas la configuration de build :
changer de compte Cloudinary impose de modifier cette ligne en même temps que
`CLOUDINARY_CLOUD_NAME`, puis `make deploy-rules`.

**Le preset est du code.** `tools/cloudinary/setup-preset.mjs` crée ou remet
en conformité le preset `eventhub_unsigned` par l'API d'administration
(`cd tools/cloudinary && npm install && npm run setup-preset`). Ce script est
le **seul** endroit où le secret API sert : il le lit dans
`tools/cloudinary/.env` (`CLOUDINARY_URL=cloudinary://<clé>:<secret>@<cloud>`),
fichier ignoré par git. Le paquet npm `cloudinary` n'a rien à faire dans
l'application Flutter. Si le secret a circulé ailleurs (message, capture,
ticket), le régénérer : console Cloudinary → *Settings → API Keys*, puis
mettre à jour ce `.env`.

**Retrouver les images d'un compte.** Chaque envoi porte les étiquettes
`eventhub` et le type d'image (`avatar`, `profileCover`, `eventCover`), ainsi
que le contexte `uid=<uid Firebase>` : depuis la console Cloudinary, une
recherche sur ce contexte liste tout ce qu'un compte signalé a importé.

---

## 12. Push FCM : le Worker `eventhub-api`

**Le secret.** Le Worker détient le JSON d'un compte de service Firebase
(`FIREBASE_SERVICE_ACCOUNT`, secret Cloudflare posé par `wrangler secret put`).
Ce compte contourne les règles Firestore : sa clé ne doit jamais entrer dans le
dépôt, dans `env/*.json` ni dans l'app. S'il fuit, le révoquer dans Google Cloud
→ *IAM → Comptes de service → Clés*, en générer un autre et le reposer.

**Ce que le Worker vérifie avant d'envoyer**, dans l'ordre :

| Contrôle | Ce qu'il empêche |
|---|---|
| ID token Firebase valide (signature RS256, `aud` = projet, `iss`, `exp`, `iat`, `sub`) | un appel anonyme, ou avec un jeton d'un autre projet |
| identifiants sans `/`, 400 caractères au plus | sortir de `users/{uid}/notifications` |
| la notification existe | pousser un texte arbitraire |
| `actorId` == appelant | déclencher le push d'un fait provoqué par quelqu'un d'autre |
| créée il y a moins de 10 minutes | rejouer une ancienne notification |
| reçu `pushReceipts` créé une seule fois | envoyer deux fois la même notification |
| préférence du destinataire (`bookingAlerts`, `eventReminders`, `followedOrganizers`) | un push que le destinataire a coupé |

**CORS.** Seules les origines de `ALLOWED_ORIGINS` (`wrangler.toml`) reçoivent
les en-têtes CORS ; les apps mobiles n'en ont pas besoin. Le CORS n'est pas
une protection : c'est l'ID token qui en est une.

**Ce qu'il ne garantit pas.** Le push n'est pas déclenché par Firestore : si
l'app meurt entre l'écriture et l'appel, la notification reste dans le centre
in-app mais ne part pas en push. Le Worker ne limite pas le débit par compte :
le nombre de notifications qu'un compte peut écrire est déjà borné par les
règles (une par fait prouvé).

---

## 13. Emails transactionnels (Brevo, par le Worker)

**Secrets.** `BREVO_API_KEY` est un secret Cloudflare : la clé permet d'écrire
à n'importe qui au nom de l'entreprise, elle n'entre jamais dans l'app ni dans
le dépôt. `COMPANY_EMAIL` est une variable publique, vérifiée dans Brevo comme
expéditeur.

| Route | Contrôle | Ce qu'il empêche |
|---|---|---|
| `POST /v1/welcome` | adresse lue dans l'ID token, jamais dans le corps ; reçu `mailReceipts/welcome:{uid}` créé une seule fois | faire écrire l'entreprise à une adresse choisie ; renvoyer le mail en boucle |
| `POST /v1/contact` | ID token ; objet 3–120 et message 10–5 000 caractères ; un message par compte toutes les 2 min (`contactThrottle/{uid}`) ; texte échappé avant insertion en HTML ; `replyTo` = adresse du jeton | transformer le formulaire en canon à spam ; injecter des liens dans la boîte de l'équipe |

`mailReceipts` et `contactThrottle` sont fermés à tout client par les règles
(un reçu forgé bloquerait le mail d'autrui ou contournerait la limite).

**Limite connue.** Un compte créé avec l'adresse d'un tiers déclenche un mail
de bienvenue vers ce tiers, une seule fois — le même risque que l'email de
vérification de Firebase Auth, et sans lien à cliquer.

