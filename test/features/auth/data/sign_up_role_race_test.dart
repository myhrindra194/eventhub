import 'dart:async';

import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:eventhub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuthDataSource {}

class _MockUsers extends Mock implements UserRemoteDataSource {}

class _MockAccount extends Mock implements AccountRemoteDataSource {}

class _MockUser extends Mock implements User {}

/// Régression : le rôle « Organisateur » choisi à l'inscription était perdu.
///
/// Dès que Firebase crée le compte, `userChanges()` émet et le flux de session
/// écrit lui-même le profil manquant — avant que `signUp` n'ait repris la
/// main. Ce profil partait avec le rôle par défaut, et l'écriture de
/// l'inscription, arrivée après sur un document existant, était refusée par
/// les règles. Ce test rejoue exactement cet ordre d'événements.
void main() {
  setUpAll(() => registerFallbackValue(UserRole.participant));

  test(
    'le flux de session plus rapide écrit quand même le rôle choisi',
    () async {
      final auth = _MockAuth();
      final users = _MockUsers();
      final user = _MockUser();
      final changes = StreamController<User?>.broadcast();
      addTearDown(changes.close);

      when(() => user.uid).thenReturn('u1');
      when(() => user.email).thenReturn('elie@example.com');
      when(() => user.emailVerified).thenReturn(false);
      when(() => user.displayName).thenReturn(null);
      when(auth.userChanges).thenAnswer((_) => changes.stream);
      when(() => users.watch('u1')).thenAnswer((_) => Stream.value(null));
      when(
        () => users.watchIsAdmin('u1'),
      ).thenAnswer((_) => Stream.value(false));
      when(
        () => users.create(
          any(),
          name: any(named: 'name'),
          email: any(named: 'email'),
          intendedRole: any(named: 'intendedRole'),
        ),
      ).thenAnswer((_) async {});

      // Firebase crée le compte : le flux de session le voit *avant* que
      // l'inscription ne récupère la main.
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async {
        changes.add(user);
        await Future<void>.delayed(Duration.zero);
        return user;
      });

      final repo = AuthRepositoryImpl(
        authDataSource: auth,
        userDataSource: users,
        accountDataSource: _MockAccount(),
        profileGracePeriod: const Duration(seconds: 3),
        clock: DateTime.now,
      );
      final session = repo.watchSession().listen((_) {});
      addTearDown(session.cancel);

      final result = await repo.signUp(
        name: 'Elie Rakoto',
        email: 'elie@example.com',
        password: 'secret123',
        intendedRole: UserRole.organizer,
      );

      expect(result, isA<Ok<Object?>>());
      // Une seule écriture, avec le nom saisi et le rôle choisi.
      verify(
        () => users.create(
          'u1',
          name: 'Elie Rakoto',
          email: 'elie@example.com',
          intendedRole: UserRole.organizer,
        ),
      ).called(1);
      // Le flux de session a bien vu le compte avant la fin de l'inscription :
      // c'est la course que ce test doit reproduire.
      verify(() => users.watch('u1')).called(greaterThanOrEqualTo(1));
    },
  );

  test('le profil lu reprend le rôle choisi', () {
    const dto = UserDto(
      name: 'Elie Rakoto',
      email: 'elie@example.com',
      role: UserRole.organizer,
      intendedRole: UserRole.organizer,
    );
    final user = dto.toDomain('u1');
    expect(user.isOrganizer, isTrue);
    expect(user.intendedRole, UserRole.organizer);
  });
}
