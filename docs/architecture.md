# EventHub — Clean Architecture

## 1. Introduction

EventHub utilise une **Clean Architecture** afin de séparer clairement :

* l'interface utilisateur ;
* la logique métier ;
* l'accès aux données ;
* les services externes.

L'objectif est de rendre le projet :

* maintenable ;
* testable ;
* évolutif ;
* compréhensible par toute l'équipe.

---

## 2. Principe général

L'application est organisée par fonctionnalité (*Feature-first*).

Chaque fonctionnalité possède ses propres couches :

```text
feature/
├── data/
├── domain/
└── presentation/
```

Le flux général est :

```text
UI
 ↓
Presentation
 ↓
Domain
 ↓
Data
 ↓
External Services
```

Exemple :

```text
EventScreen
    ↓
EventController
    ↓
GetEventsUseCase
    ↓
EventRepository
    ↓
EventRepositoryImpl
    ↓
EventRemoteDataSource
    ↓
Supabase / Firebase / API
```

---

## 3. Les trois couches

### 3.1 Presentation

La couche Presentation est responsable de l'interface utilisateur et de la gestion de l'état.

Elle peut contenir :

```text
presentation/
├── pages/
├── widgets/
└── providers/
```

Exemple :

```text
events/
└── presentation/
    ├── pages/
    │   ├── events_page.dart
    │   └── event_detail_page.dart
    │
    ├── widgets/
    │   └── event_card.dart
    │
    └── providers/
        └── events_provider.dart
```

La Presentation ne doit pas contenir directement les appels à Firebase ou Supabase.

---

### 3.2 Domain

Le Domain contient la logique métier.

Structure :

```text
domain/
├── entities/
├── repositories/
└── usecases/
```

#### Entities

Représentent les objets métier.

Exemples :

```text
Event
Reservation
User
Organizer
```

#### Repositories

Définissent les contrats nécessaires à la récupération ou modification des données.

Exemple :

```dart
abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<Event> getEventById(String id);
}
```

Le Domain ne connaît pas l'implémentation concrète du repository.

#### Use Cases

Chaque action métier importante possède son propre Use Case.

Exemples :

```text
GetEvents
GetEventDetails
CreateEvent
UpdateEvent
CreateReservation
CancelReservation
```

---

### 3.3 Data

La couche Data implémente l'accès aux données.

Structure :

```text
data/
├── datasources/
├── models/
└── repositories/
```

#### Data Sources

Responsables de communiquer avec les services externes.

Exemples :

```text
EventRemoteDataSource
EventLocalDataSource
```

#### Models

Permettent de convertir les données externes vers les objets utilisés par le Domain.

Exemple :

```text
EventModel
ReservationModel
UserModel
```

#### Repository Implementations

Implémentent les contrats définis dans le Domain.

Exemple :

```text
EventRepository
       ↑
EventRepositoryImpl
```

---

## 4. Core

Le dossier `core` contient les éléments communs à plusieurs fonctionnalités.

```text
core/
├── constants/
├── errors/
├── network/
├── router/
├── theme/
└── utils/
```

### constants

Constantes globales de l'application.

### errors

Gestion des exceptions et failures.

### network

Configuration réseau et clients HTTP si nécessaires.

### router

Configuration de la navigation.

### theme

Thème global de l'application.

### utils

Fonctions utilitaires partagées.

---

## 5. Règles de dépendance

Les dépendances doivent respecter :

```text
Presentation → Domain ← Data
```

Le Domain doit rester indépendant des frameworks et services externes.

Par exemple, le Domain ne doit pas importer directement :

```dart
import 'package:firebase_...';
```

ou :

```dart
import 'package:supabase_flutter/...';
```

Les services externes sont utilisés dans la couche Data ou dans les composants techniques appropriés.

---

## 6. Structure cible

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
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── events/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── reservations/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── organizer/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

---

## 7. Évolution

Cette architecture pourra évoluer selon les besoins du MVP.

Les fonctionnalités et responsabilités exactes seront ajustées après validation du MCD et des choix backend.
