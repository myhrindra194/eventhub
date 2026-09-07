**# Contributing to EventHub

Merci de contribuer au projet **EventHub** 🎫

Ce document présente les règles à suivre pour contribuer au projet, afin de maintenir une organisation claire, un code cohérent et une bonne collaboration entre les membres de l'équipe.

---

## 1. Avant de commencer

Avant de commencer une tâche :

1. Consulter le Sheet de suivi du projet.
2. Vérifier que la tâche est bien attribuée.
3. Vérifier les éventuelles dépendances avec d'autres tâches.
4. Mettre à jour sa branche locale.
5. Créer une branche dédiée à la tâche.

---

## 2. Organisation des branches

Les branches principales sont :

```text
main
develop
```

### `main`

Contient uniquement les versions stables du projet.

### `develop`

Branche principale de développement et d'intégration de l'équipe.

Les fonctionnalités doivent être développées dans des branches dédiées puis intégrées à `develop`.

---

## 3. Créer une branche

Avant de créer une branche, récupérer la dernière version de `develop` :

```bash
git checkout develop
git pull origin develop
```

Créer ensuite une branche dédiée :

```bash
git checkout -b feature/nom-de-la-tache
```

Exemples :

```bash
git checkout -b feature/auth
git checkout -b feature/event-list
git checkout -b feature/reservation
```

---

## 4. Une tâche = une branche

Chaque tâche doit avoir sa propre branche.

Exemple :

```text
EH-015 — Créer la liste des événements
        ↓
feature/event-list
```

Éviter de mélanger plusieurs fonctionnalités indépendantes dans une même branche.

---

## 5. Convention de nommage des branches

### Fonctionnalité

```text
feature/<nom>
```

Exemple :

```text
feature/event-details
```

### Correction

```text
fix/<nom>
```

Exemple :

```text
fix/login-validation
```

### Documentation

```text
docs/<nom>
```

Exemple :

```text
docs/architecture
```

### Design

```text
design/<nom>
```

Exemple :

```text
design/event-card
```

### Refactoring

```text
refactor/<nom>
```

Exemple :

```text
refactor/auth-module
```

---

## 6. Convention des commits

Les commits doivent être courts, explicites et liés au travail réalisé.

Format :

```text
type: description
```

Types utilisés :

| Type       | Utilisation                    |
| ---------- | ------------------------------ |
| `feat`     | Nouvelle fonctionnalité        |
| `fix`      | Correction d'un bug            |
| `refactor` | Refactoring du code            |
| `docs`     | Documentation                  |
| `design`   | Modification UI/UX             |
| `test`     | Ajout ou modification de tests |
| `chore`    | Configuration ou maintenance   |

### Exemples

```bash
git commit -m "feat: add event listing"
```

```bash
git commit -m "fix: correct reservation validation"
```

```bash
git commit -m "docs: update clean architecture"
```

```bash
git commit -m "test: add event repository tests"
```

---

## 7. Développement

Avant de pousser son travail, chaque contributeur doit vérifier que le projet fonctionne correctement.

Pour Flutter :

```bash
flutter analyze
```

Puis exécuter les tests :

```bash
flutter test
```

Les erreurs introduites par la modification doivent être corrigées avant la Pull Request.

---

## 8. Pull Request

Une fonctionnalité terminée doit être proposée via une Pull Request.

Le workflow est :

```text
feature/*
    ↓
Push
    ↓
Pull Request
    ↓
Code Review
    ↓
develop
```

La Pull Request doit contenir :

* un titre clair ;
* une description des modifications ;
* la référence de la tâche concernée ;
* les tests effectués ;
* les éventuels points nécessitant une attention particulière.

### Exemple

```text
Title:
feat: implement event listing

Description:

## Changes
- Added Event entity
- Added EventRepository
- Added GetEventsUseCase
- Added event list screen

## Task
EH-XXX

## Tests
- flutter analyze
- flutter test
```

---

## 9. Code Review

Avant la fusion d'une Pull Request, les membres de l'équipe doivent vérifier notamment :

* la qualité du code ;
* le respect de la Clean Architecture ;
* le respect des conventions ;
* l'absence de code inutile ;
* la gestion des erreurs ;
* les tests nécessaires ;
* l'impact sur les autres fonctionnalités.

Les discussions concernant le code doivent être faites directement dans la Pull Request lorsque possible.

---

## 10. Clean Architecture

Les nouvelles fonctionnalités doivent respecter l'architecture définie dans :

```text
docs/architecture.md
```

Le principe général est :

```text
Presentation
      ↓
Domain
      ↓
Data
      ↓
External Services
```

Les Screens et Widgets ne doivent pas effectuer directement des appels à :

* Firebase Authentication ;
* Cloud Firestore ;
* Supabase Storage.

Les interactions avec ces services doivent passer par les couches appropriées.

---

## 11. Backend

Pour le MVP :

### Firebase

Utilisé pour :

* Firebase Authentication ;
* Cloud Firestore.

### Supabase

Utilisé uniquement pour :

* Supabase Storage ;
* Buckets ;
* stockage des images.

Les informations détaillées sont disponibles dans :

```text
docs/firebase.md
docs/supabase.md
```

---

## 12. Gestion des secrets

Ne jamais commit :

* mots de passe ;
* clés privées ;
* tokens ;
* secrets API ;
* fichiers de configuration contenant des informations sensibles.

Avant chaque commit, vérifier qu'aucune information sensible n'est présente.

---

## 13. Synchronisation avec `develop`

Pendant le développement, la branche peut prendre du retard par rapport à `develop`.

Avant de finaliser une Pull Request, vérifier que la branche est à jour avec `develop`.

Exemple :

```bash
git checkout develop
git pull origin develop

git checkout feature/ma-tache
git merge develop
```

Les conflits doivent être résolus avant la fusion.

---

## 14. Documentation

Toute modification importante du fonctionnement du projet doit être documentée.

La documentation se trouve dans :

```text
docs/
```

Les documents actuellement disponibles :

```text
docs/
├── architecture.md
├── firebase.md
├── supabase.md
└── git-conventions.md
```

Si une décision technique importante est prise, la documentation correspondante doit être mise à jour.

---

## 15. Modèle de données

Le MCD et le modèle de données sont actuellement en cours de validation.

Il ne faut donc pas considérer une structure de données comme définitive avant validation par l'équipe.

Une fois le MCD validé, les documents et implémentations concernés devront être mis à jour.

---

## 16. Checklist avant Pull Request

Avant de créer une Pull Request :

* [ ] La tâche est terminée.
* [ ] La branche correspond à la tâche.
* [ ] Le code respecte la Clean Architecture.
* [ ] `flutter analyze` ne retourne pas d'erreur.
* [ ] Les tests passent.
* [ ] Aucun secret n'est présent dans les fichiers commités.
* [ ] La documentation est mise à jour si nécessaire.
* [ ] La branche est synchronisée avec `develop`.
* [ ] La Pull Request contient la référence de la tâche.

---

## 17. Règle générale

> **Une tâche claire, une branche claire, un commit clair, une Pull Request claire.**

L'objectif est de permettre à toute l'équipe de comprendre facilement ce qui a été développé, pourquoi cela a été développé et comment l'intégrer au reste du projet.
**
