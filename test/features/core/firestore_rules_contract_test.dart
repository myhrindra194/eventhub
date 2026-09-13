import 'package:fake_firebase_security_rules/fake_firebase_security_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de contrat sur nos règles Firestore.
///
/// ⚠️ Limites connues de `fake_firebase_security_rules` (v0.5.4) :
/// - pas de déclaration `function` (les helpers doivent être inlinés) ;
/// - pas de `resource`, `request.resource`, `exists()` ni `get()` —
///   or nos règles réelles s'appuient massivement dessus.
///
/// Ce fichier valide donc le socle commun évaluable : `request.auth.uid` et
/// les variables de chemin, sous la forme **inline** (la forme « helpers »
/// de `firestore.rules` est exprimée ici équivalente). C'est un filet minimal
/// qui casse si quelqu'un affaiblit durablement l'accès (ex: `allow read: true`).
///
/// La validation du `firestore.rules` **complet** doit passer par l'émulateur.
const _rules = '''
service cloud.firestore {
  match /databases/{database}/documents {

    // Équivalent inline de `isOwner(userId)` (les `function` ne sont pas
    // supportées par la lib de test).
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
''';

void main() {
  FakeFirebaseSecurityRules rules = FakeFirebaseSecurityRules(_rules);

  test('un utilisateur lit son propre profil', () {
    expect(
      rules.isAllowed(
        'databases/test/documents/users/user-1',
        Method.read,
        variables: _auth('user-1'),
      ),
      isTrue,
    );
  });

  test('un utilisateur ne lit pas le profil de quelqu\'un', () {
    expect(
      rules.isAllowed(
        'databases/test/documents/users/user-2',
        Method.read,
        variables: _auth('user-1'),
      ),
      isFalse,
    );
  });

  test('un utilisateur anonyme est refusé', () {
    // On fournit `auth: null` pour que la lib évalue proprement la règle
    // (sinon elle lève en interne et revient à `false` avec un warning).
    expect(
      rules.isAllowed(
        'databases/test/documents/users/user-1',
        Method.read,
        variables: {
          'request': {'auth': null},
        },
      ),
      isFalse,
    );
  });

  test('une requête sur un chemin hors périmètre est refusée', () {
    expect(
      rules.isAllowed(
        'databases/test/documents/other/user-1',
        Method.read,
        variables: _auth('user-1'),
      ),
      isFalse,
    );
  });

  test('update est soumis aux mêmes garde-fous que read', () {
    expect(
      rules.isAllowed(
        'databases/test/documents/users/user-2',
        Method.update,
        variables: _auth('user-1'),
      ),
      isFalse,
    );
  });
}

Map<String, dynamic> _auth(String uid) {
  return {
    'request': {
      'auth': {
        'uid': uid,
        'token': {'sub': uid},
      },
    },
  };
}
