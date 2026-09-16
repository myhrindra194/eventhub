# EventHub — Git Conventions

## 1. Branches principales

Le repository utilise deux branches principales :

```text
main
develop
```

### main

Contient uniquement les versions stables du projet.

### develop

Branche d'intégration de l'équipe.

Les nouvelles fonctionnalités sont intégrées dans `develop` avant d'être éventuellement fusionnées vers `main`.

---

## 2. Branches de travail

Chaque tâche doit être développée dans une branche dédiée.

### Feature

```text
feature/<nom>
```

Exemples :

```text
feature/auth
feature/event-list
feature/event-details
feature/reservation
```

### Bug fix

```text
fix/<nom>
```

Exemples :

```text
fix/login-validation
fix/reservation-error
```

### Documentation

```text
docs/<nom>
```

Exemples :

```text
docs/readme
docs/architecture
docs/firebase
```

### Design

```text
design/<nom>
```

Exemples :

```text
design/login
design/event-details
```

---

## 3. Workflow

Le workflow recommandé est :

```text
develop
   ↓
feature/ma-tache
   ↓
Pull Request
   ↓
Code Review
   ↓
develop
```

Une fonctionnalité terminée ne doit pas être fusionnée directement dans `main`.

---

## 4. Commits

Les commits doivent être courts et explicites.

Format :

```text
type: description
```

Types principaux :

| Type       | Utilisation                 |
| ---------- | --------------------------- |
| `feat`     | Nouvelle fonctionnalité     |
| `fix`      | Correction d'un bug         |
| `refactor` | Refactoring                 |
| `docs`     | Documentation               |
| `design`   | Modification UI/UX          |
| `test`     | Tests                       |
| `chore`    | Configuration / maintenance |

Exemples :

```text
feat: add event listing
fix: correct login validation
docs: update architecture documentation
refactor: reorganize event repository
test: add reservation tests
chore: configure flutter project
```

---

## 5. Pull Requests

Chaque Pull Request doit :

* avoir un titre clair ;
* expliquer les modifications ;
* référencer la tâche correspondante ;
* être testée avant soumission ;
* être relue par au moins un autre membre lorsque possible.

Exemple :

```text
feat: implement event listing
```

Description :

```text
## Changes
- Added Event entity
- Added GetEvents use case
- Added EventRepository
- Added event list UI

## Task
EH-XXX
```

---

## 6. Synchronisation

Avant de commencer une nouvelle tâche :

```bash
git checkout develop
git pull origin develop
```

Puis créer une nouvelle branche :

```bash
git checkout -b feature/nom-de-la-tache
```

Après le travail :

```bash
git add .
git commit -m "feat: description"
git push origin feature/nom-de-la-tache
```

Puis créer une Pull Request vers :

```text
develop
```

---

## 7. Règles importantes

* Ne jamais travailler directement sur `main`.
* Éviter de travailler directement sur `develop`.
* Une tâche = une branche.
* Ne pas mélanger plusieurs fonctionnalités dans une même Pull Request.
* Ne jamais commit de secrets ou clés privées.
* Garder les commits compréhensibles.
* Résoudre les conflits avant la fusion lorsque nécessaire.
