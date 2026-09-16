# EventHub — Firebase

## 1. Objectif

Firebase est utilisé dans EventHub pour fournir les services backend nécessaires au MVP.

Les services retenus pour le MVP sont :

* **Firebase Authentication** : gestion des comptes et de l'authentification ;
* **Cloud Firestore** : stockage et gestion des données de l'application.

Les autres services Firebase ne font pas partie du périmètre initial du MVP.

---

## 2. Firebase Authentication

Firebase Authentication est utilisé pour gérer l'authentification des utilisateurs.

### Fonctionnalités prévues

* Inscription
* Connexion avec email et mot de passe, google auth
* Déconnexion
* Gestion de session
* Récupération de l'utilisateur connecté

Les utilisateurs peuvent avoir différents rôles dans l'application :

* Participant
* Organisateur

La gestion des rôles et des informations complémentaires du profil sera définie selon le modèle de données validé.

---

## 3. Cloud Firestore

Cloud Firestore est utilisé comme base de données NoSQL pour stocker les données nécessaires au fonctionnement du MVP.

Les données pourront notamment concerner :

* utilisateurs ;
* profils ;
* événements ;
* réservations ;
* informations liées aux organisateurs.

> ⚠️ La structure définitive des collections et des documents dépend du MCD et du modèle de données qui sont actuellement en cours de validation.

Une fois le modèle validé, cette documentation sera complétée avec :

* collections ;
* documents ;
* champs ;
* relations logiques ;
* règles d'accès.

---

## 4. Intégration avec la Clean Architecture

Les appels Firebase ne doivent pas être effectués directement depuis les Screens ou les Widgets.

Le principe est :

```text
Presentation
      ↓
Domain
      ↓
Data
      ↓
Firebase
```

### Exemple — Authentification

```text
LoginPage
    ↓
AuthProvider / Controller
    ↓
LoginUseCase
    ↓
AuthRepository
    ↓
AuthRepositoryImpl
    ↓
AuthRemoteDataSource
    ↓
Firebase Authentication
```

### Exemple — Événements

```text
EventsPage
    ↓
GetEventsUseCase
    ↓
EventRepository
    ↓
EventRepositoryImpl
    ↓
EventRemoteDataSource
    ↓
Cloud Firestore
```

Le Domain ne doit pas dépendre directement de Firebase.

---

## 5. Sécurité

L'accès aux données doit être protégé par les mécanismes de sécurité Firebase.

Les règles Firestore devront notamment prendre en compte :

* l'utilisateur authentifié ;
* son rôle ;
* les permissions nécessaires ;
* l'accès aux données personnelles ;
* les droits des organisateurs sur leurs événements.

Les règles définitives seront mises en place après validation du modèle de données et des règles métier.

---

## 6. Configuration

La configuration Firebase doit être séparée des informations sensibles du projet.

Les fichiers et informations sensibles ne doivent pas être exposés inutilement dans le repository.

La configuration devra être réalisée pour les environnements nécessaires au projet.

---

## 7. Services hors périmètre MVP

Les services suivants ne sont pas prévus dans le MVP initial :

* Firebase Cloud Messaging (FCM) ;
* notifications push ;
* autres services Firebase non nécessaires aux fonctionnalités principales.

Ils pourront être étudiés dans une version ultérieure.

---

## 8. État

### Services retenus

| Service                  | Utilisation                       | MVP |
| ------------------------ | --------------------------------- | --- |
| Firebase Authentication  | Authentification des utilisateurs | ✅   |
| Cloud Firestore          | Base de données                   | ✅   |
| Firebase Cloud Messaging | Notifications push                | ❌   |

La documentation sera mise à jour au fur et à mesure de l'avancement du projet et de la validation des choix techniques.
