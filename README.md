# EventHub 🎫

EventHub est une application mobile permettant aux utilisateurs de **découvrir, consulter et réserver des événements**.

L'application met en relation deux types d'utilisateurs :

* **Participant** : recherche des événements, consulte leurs détails et réserve des places.
* **Organisateur** : crée et gère ses événements et consulte les réservations associées.

Le projet est développé dans le cadre d'un MVP avec une architecture pensée pour être maintenable, évolutive et facilement collaborative.

---

## 🎯 Objectifs du MVP

Le MVP d'EventHub a pour objectif de permettre :

### Participant

* Créer un compte
* Se connecter
* Consulter les événements disponibles
* Rechercher et filtrer des événements
* Consulter les détails d'un événement
* Réserver une ou plusieurs places
* Consulter ses réservations
* Gérer son profil

### Organisateur

* Créer un compte organisateur
* Créer un événement
* Modifier un événement
* Consulter ses événements
* Consulter les réservations associées
* Gérer les informations de ses événements

---

## 🛠️ Stack technique

### Mobile

* **Flutter**
* **Dart**

### Architecture

* **Clean Architecture**
* Architecture orientée fonctionnalités (*Feature-first*)
* Repository Pattern

### Backend / Services

* **Firebase**
* **Supabase**

> Les responsabilités exactes de Firebase et Supabase seront précisées dans la documentation technique du projet.

### Gestion du code

* Git
* GitHub
* Pull Requests
* Branches `main`, `develop` et `feature/*`

---

## 🏗️ Architecture

EventHub utilise une **Clean Architecture** organisée par fonctionnalités.

Chaque fonctionnalité est séparée en trois couches principales :

```text
Presentation
     ↓
Domain
     ↓
Data
```

### Presentation

Contient :

* Screens
* Widgets
* State management
* Controllers / Notifiers

### Domain

Contient la logique métier :

* Entities
* Use Cases
* Repository contracts

Cette couche ne dépend pas des technologies externes.

### Data

Contient l'accès aux données :

* Repository implementations
* Data sources
* API
* Firebase
* Supabase
* DTO / Models

La structure détaillée est disponible dans :

`docs/architecture.md`

---

## 📁 Structure du projet

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── router/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── events/
│   ├── reservations/
│   ├── profile/
│   └── organizer/
│
└── main.dart
```

---

## 🗄️ Base de données

Le modèle de données est actuellement **en cours de validation**.

Le MCD sera ajouté et documenté une fois validé par l'équipe.

Documentation :

* `docs/supabase.md`
* `docs/firebase.md`

---

## 🌿 Git Workflow

La branche principale du projet est organisée comme suit :

```text
main
  ↑
develop
  ↑
feature/*
```

### Branches principales

| Branche     | Utilisation                        |
| ----------- | ---------------------------------- |
| `main`      | Version stable                     |
| `develop`   | Intégration des fonctionnalités    |
| `feature/*` | Développement d'une fonctionnalité |
| `fix/*`     | Correction d'un bug                |
| `docs/*`    | Documentation                      |
| `design/*`  | Travail lié au design              |

Les règles détaillées sont disponibles dans :

`docs/git-conventions.md`

---

## 👥 Équipe

EventHub est développé en équipe.

Chaque membre travaille sur des branches dédiées et soumet ses modifications via Pull Request vers `develop`.

---

## 📚 Documentation

| Document                  | Description                     |
| ------------------------- | ------------------------------- |
| `docs/architecture.md`    | Architecture Clean Architecture |
| `docs/firebase.md`        | Utilisation de Firebase         |
| `docs/supabase.md`        | Utilisation de Supabase         |
| `docs/git-conventions.md` | Convention Git et workflow      |

---

## 🚧 État du projet

Le projet est actuellement en phase de mise en place du MVP.

### En cours

* [x] Création du repository
* [ ] Initialisation du projet Flutter
* [ ] Mise en place de la Clean Architecture
* [ ] Mise en place des conventions Git
* [ ] Validation du MCD
* [ ] Mise en place du backend
* [ ] Développement de l'authentification
* [ ] Développement de la gestion des événements
* [ ] Développement des réservations
* [ ] Développement de l'espace organisateur

---

## 📌 Documentation complémentaire

Les décisions techniques importantes doivent être documentées dans le dossier `docs/`.

Toute modification importante de l'architecture ou du fonctionnement du projet doit être discutée avec l'équipe avant d'être intégrée.
