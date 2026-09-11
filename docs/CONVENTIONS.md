# EventHub — Conventions d'équipe

## Git

* Branche par défaut : `main` (toujours démontrable). Intégration : `develop`.
* Une branche par tâche du tableau de suivi :
  `feat/T-31-recherche-evenements`, `fix/T-61-…`, `chore/T-66-readme`.
* Commits **Conventional Commits** en anglais, scope = feature :

  ```
  feat(reservations): atomic reserve transaction (T-36, T-37)
  fix(auth): tolerate profile write delay after sign-up
  chore(ci): cache flutter sdk
  ```
* PR obligatoire vers `develop`, CI verte, 1 review minimum. Squash merge.
* Jamais de `google-services.json` / `firebase_options.dart` versionnés.

## Code

* `flutter analyze` sans warning, `dart format` appliqué (CI bloquante).
* Imports en `package:eventhub/...` (jamais relatifs entre features).
* Une feature n'importe **jamais** la couche `data` d'une autre feature ;
  elle passe par ses providers `application`.
* Les repositories retournent `Result<T>`; les widgets consomment des
  providers, pas des repositories.
* Texte UI : uniquement via `AppStrings` (préparation i18n).
* Après modification d'un fichier annoté (`@freezed`, `@riverpod`,
  `@JsonSerializable`) : `make gen`. Les fichiers générés sont commités.

## Definition of Done (par tâche)

1. Comportement conforme au cahier des charges (section citée dans la PR).
2. Tests : règle métier => test unitaire ; écran => test widget minimal.
3. Règles Firestore mises à jour si le modèle change.
4. Colonne « Statut » du tableau de suivi passée en *En review* avec le lien PR.
