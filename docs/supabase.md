# EventHub — Supabase Storage

## 1. Objectif

Supabase est utilisé dans EventHub pour le **stockage des images** nécessaires au fonctionnement du MVP.

L'utilisation de Supabase est limitée au service **Storage**.

### Service utilisé

* **Supabase Storage**
* **Buckets** pour organiser et stocker les fichiers

---

## 2. Utilisation dans EventHub

Supabase Storage pourra être utilisé pour stocker les images associées aux différentes fonctionnalités de l'application.

Exemples :

* images des événements ;
* images de couverture ;
* images de profil ;
* autres images nécessaires au MVP.

La liste définitive des fichiers stockés sera définie selon les besoins fonctionnels.

---

## 3. Organisation des Buckets

Les buckets seront définis selon les besoins du projet.

Exemple :

```text
Supabase Storage
│
├── event-images/
│   ├── event-001/
│   ├── event-002/
│   └── ...
│
└── profile-images/
    ├── user-001/
    ├── user-002/
    └── ...
```

> ⚠️ L'organisation définitive des buckets et des chemins sera définie avec l'équipe avant l'implémentation.

---

## 4. Intégration avec la Clean Architecture

Les appels à Supabase Storage doivent être réalisés dans la couche **Data**.

Exemple :

```text
Presentation
      ↓
Domain
      ↓
Data
      ↓
Supabase Storage
```

Pour l'upload d'une image :

```text
EventForm
    ↓
CreateEventUseCase
    ↓
EventRepository
    ↓
EventRepositoryImpl
    ↓
EventStorageDataSource
    ↓
Supabase Storage
```

La couche Domain ne doit pas dépendre directement du SDK Supabase.

---

## 5. Gestion des URLs

Après l'upload d'une image, l'application devra conserver la référence permettant d'accéder à cette image.

Exemple :

```text
Event
├── id
├── title
├── description
└── imageUrl
```

La donnée `imageUrl` pourra être enregistrée dans **Cloud Firestore**, tandis que le fichier image lui-même sera stocké dans **Supabase Storage**.

Le lien entre les données Firestore et les fichiers Supabase devra être défini lors de la conception du modèle de données.

---

## 6. Sécurité

L'accès aux buckets devra être configuré selon les besoins de l'application.

Les règles devront notamment prendre en compte :

* les utilisateurs authentifiés ;
* les droits d'upload ;
* les droits de lecture ;
* les droits de suppression ;
* les fichiers appartenant aux utilisateurs ou aux organisateurs.

Les politiques définitives seront définies avant la mise en production.

---

## 7. Configuration

Les informations de connexion nécessaires à Supabase ne doivent pas contenir de secrets directement dans le code source.

Les variables de configuration doivent être gérées de manière appropriée selon l'environnement.

Aucune clé secrète ne doit être commitée dans Git.

---

## 8. Périmètre MVP

| Service           | Utilisation         | MVP |
| ----------------- | ------------------- | --- |
| Supabase Storage  | Stockage des images | ✅   |
| Supabase Database | Base de données     | ❌   |
| Supabase Auth     | Authentification    | ❌   |
| Supabase Realtime | Données temps réel  | ❌   |

---

## 9. Architecture backend du MVP

```text
                    EventHub
                       │
          ┌────────────┴────────────┐
          │                         │
      Firebase                  Supabase
          │                         │
    ┌─────┴─────┐             ┌─────┴─────┐
    │           │             │           │
Authentication Firestore     Storage     Buckets
    │           │             │
    │           │             └── Images
    │           │
    │           └── Données métier
    │
    └── Utilisateurs / Sessions
```

Cette séparation permet de conserver **Firebase comme backend principal pour l'authentification et les données métier**, tout en utilisant Supabase comme solution dédiée au stockage des images.
