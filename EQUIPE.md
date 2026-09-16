# Équipe et répartition des tâches

> Ce document dit **qui a fait quoi** sur EventHub, et surtout **comment on le
> sait**. Le détail fonctionnel et technique du projet est dans
> [`README.md`](README.md) ; on ne le répète pas ici, on s'y réfère.

---

## 1. Le projet en une phrase

EventHub est une application Flutter multiplateforme de découverte, de
réservation et d'organisation d'événements, **entièrement adossée à Firebase** :
Firebase Auth pour les comptes, Cloud Firestore pour les données, Hosting pour
la page publique d'un événement, FCM, Crashlytics et Analytics pour
l'exploitation. Il n'y a **pas de serveur applicatif** : les règles de sécurité
`firebase/firestore.rules` sont le seul code exécuté côté Google et portent
tous les invariants métier (voir [`docs/SECURITY.md`](docs/SECURITY.md)).

Aucune autre base de données n'est utilisée. Le dépôt a connu une parenthèse
Supabase en v2.0, close et intégralement retirée en v2.1 ; elle n'est
mentionnée que dans l'historique des livraisons de
[`docs/ROADMAP.md`](docs/ROADMAP.md), à titre de mémoire.

---

## 2. L'équipe

| Personne | Identités Git | Commits |
|---|---|---|
| **Ravotiona RANAIVOSON** | `ravo29 <ravotiana39@gmail.com>` | 22 |
| **Mirindra RANDRIAMBOLAMANJATA** | `myhrindra194 <myhrindra194@gmail.com>` · `Mirindra RANDRIAMBOLAMANJATO <145148402+myhrindra194@users.noreply.github.com>` | 35 |
| **Kabore Callist** | `KABORE-c-elie <201442798+KABORE-c-elie@users.noreply.github.com>` · `KABORE Calliste Elie <callisteeliek@gmail.com>` | 44 |

Une même personne apparaît sous plusieurs identités Git selon la machine et le
client utilisés ; les lignes ci-dessus les regroupent.

### Comment cette répartition a été établie

Elle n'est pas déclarative : elle est **relevée dans l'historique Git**, toutes
branches confondues, en comptant pour chaque auteur les fichiers touchés par
répertoire. La commande qui produit ce relevé :

```bash
git log --all --author="<auteur>" --name-only --format="" \
  | grep . | cut -d/ -f1-3 | sort | uniq -c | sort -rn | head -12
```

Deux limites à garder en tête, parce qu'un chiffre sans ses réserves est
trompeur :

1. **Toucher un fichier n'est pas le concevoir.** Un remaniement large gonfle
   le compteur sans créer de fonctionnalité ; à l'inverse, une règle de
   sécurité tient en dix lignes et représente une journée de réflexion.
2. **Le travail partagé se voit mal.** Les revues, les décisions
   d'architecture et le pilotage n'apparaissent pas dans un compte de fichiers.
   Ils sont listés en [§4](#4-travail-collectif).

Si la répartition réelle diffère de ce relevé, ce fichier est à corriger : il
décrit ce que l'historique montre, pas un contrat de répartition.

---

## 3. Qui a porté quoi

### Ravotiona RANAIVOSON — parcours d'entrée, thème et plateformes

Principaux répertoires touchés : `lib/features/events` (27 fichiers),
`lib/features/organizer` (22), `lib/features/auth` (21),
`ios/Runner/Assets.xcassets` (21), `lib/features/reservations` (18),
`lib/core/widgets` (13), `lib/features/home` (12),
`lib/features/onboarding` (11), `lib/core/theme` (10), `android/app/src` (5).

Ce que cela recouvre :

- **Le premier contact avec l'application** : l'écran d'accueil et le parcours
  d'onboarding, c'est-à-dire les écrans qui décident si quelqu'un reste ou
  ferme l'application. C'est aussi ce qui est verrouillé par les goldens de
  `test/features/startup` : trois largeurs d'écran, aucun sélecteur
  d'apparence sur le chemin de démarrage.
- **Le socle visuel** : le thème et une partie des composants partagés de
  `lib/core/widgets`, donc la cohérence des couleurs, des rayons et des
  espacements d'un écran à l'autre (voir
  [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)).
- **Les cibles natives** : les jeux d'icônes et ressources iOS et Android,
  sans lesquels une application Flutter reste un prototype qui ne s'installe
  nulle part.
- Des contributions substantielles au catalogue d'événements, à l'espace
  organisateur et aux réservations.

### Mirindra RANDRIAMBOLAMANJATA — Firebase, authentification et documentation

Principaux répertoires touchés : `lib/features/auth` (36),
`lib/features/organizer` (34), `lib/features/events` (24),
`.agents/skills/firebase-*` (54 au total : `firebase-basics`,
`firebase-firestore`, `firebase-data-connect`), `ios/Runner/Assets.xcassets`
(21), `lib/features/reservations` (17), `android/app/src` (14),
`macos/Runner/Assets.xcassets` (8), `pubspec.yaml` (7). Cette personne a
également écrit les premiers documents d'équipe du dépôt — `CONTRIBUTING.md`,
`docs/architecture.md`, `docs/firebase.md`, `docs/git-conventions.md` — depuis
refondus dans les documents actuels de [`docs/`](docs/).

Ce que cela recouvre :

- **L'authentification** : inscription, connexion, Google, vérification
  d'adresse, mots de passe — le domaine le plus dense en cas limites, et celui
  dont dépendent toutes les règles de sécurité, puisque c'est le jeton qui
  porte `email_verified` et l'identité que Firestore relit.
- **La base de connaissances Firebase du projet** : les fiches
  `.agents/skills/firebase-*` qui fixent la façon dont l'équipe utilise
  Firestore et les services Firebase. C'est ce qui évite que trois personnes
  inventent trois conventions d'accès aux données.
- **La documentation d'équipe et les conventions Git**, c'est-à-dire la partie
  du travail qui ne se voit pas dans l'application mais sans laquelle une
  équipe de trois diverge en deux semaines.
- Des contributions importantes à l'espace organisateur et aux réservations.

### Kabore Callist — cœur métier, couche de données Firestore et qualité

Principaux répertoires touchés : `lib/features/events` (163 fichiers),
`lib/features/auth` (138), `lib/features/reservations` (94),
`lib/core/widgets` (45), `lib/features/notifications` (38),
`lib/features/organizer` (37), `lib/features/reviews` (32),
`lib/features/organizers` (30), `lib/features/checkin` (28),
`test/features/auth` (24), `lib/core/firebase` (23), `lib/app/theme` (22).

Ce que cela recouvre :

- **La réservation et sa preuve** : la transaction qui déplace une place et
  crée le billet dans le même commit, avec les règles qui la valident. C'est
  l'invariant central du produit — deux personnes ne peuvent pas obtenir la
  dernière place — et il n'existe que parce que le client et les règles
  disent la même chose (voir `README.md` §7).
- **La couche de données Firestore** (`lib/core/firebase`) : chemins,
  identifiants déterministes, conversion des horodatages, providers. C'est
  elle qui rend les règles applicables côté client.
- **Les domaines fonctionnels qui suivent** : avis, favoris, liste d'attente,
  contrôle à l'entrée, profils publics d'organisateurs, notifications,
  modération.
- **La qualité** : la suite de tests Dart et la suite de règles de sécurité
  exécutée sur l'émulateur Firestore, qui éprouve chaque règle *en tant
  qu'attaquant* — batch amputé, compteur gonflé, identifiant forgé.

---

## 4. Travail collectif

Certaines décisions n'appartiennent à personne en particulier et se lisent dans
le dépôt plutôt que dans un commit :

| Sujet | Où c'est tranché |
|---|---|
| Tout le projet sur **Firebase**, plan Spark, sans service payant | [`README.md`](README.md) §1 et §10, [`docs/ROADMAP.md`](docs/ROADMAP.md) §2 |
| Les **règles Firestore** comme unique backend | [`docs/SECURITY.md`](docs/SECURITY.md) |
| Architecture en couches (presentation / application / domain / data) | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Conventions de la couche de données | [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) |
| Langage visuel : rayons à 6 px, aucune ombre, texte seul dans les boutons | [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) |
| Conventions Git et de contribution | d'abord `CONTRIBUTING.md` et `docs/git-conventions.md`, aujourd'hui refondus dans [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) et le §21 du [`README.md`](README.md) |

---

## 5. Vérifier ce document

```bash
# Le relevé des auteurs et de leur volume de commits
git shortlog -sne --all

# Les répertoires touchés par une personne
git log --all --author="ravo29" --name-only --format="" | grep . | sort | uniq -c | sort -rn

# L'état de santé du dépôt
flutter analyze && flutter test        # analyse + tests Dart
make rules-test                        # règles de sécurité sur émulateur
```

Le jour où la répartition évolue, c'est ce fichier qu'on met à jour — au même
titre que le README, et dans le même commit que le travail qu'il décrit.
