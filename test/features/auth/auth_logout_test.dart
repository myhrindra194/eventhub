import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' show MockFirebaseAuth, MockUser;
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:eventhub/features/auth/data/models/user_model.dart';
import 'package:eventhub/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('AuthRemoteDataSource.logout', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth firebaseAuth;
    late AuthRemoteDataSource dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      firebaseAuth = MockFirebaseAuth(signedIn: true);
      dataSource = AuthRemoteDataSource(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );
      firestore.collection('users').doc('user-1').set({
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'participant',
      });
    });

    test('logout Firebase réussit sans exception', () async {
      await dataSource.logout();
    });

    test('authStateChanges émet null après logout', () async {
      final states = <UserModel?>[];
      final subscription = dataSource.authStateChanges().listen(states.add);
      try {
        firebaseAuth = MockFirebaseAuth(signedIn: false);
        final dsAfter = AuthRemoteDataSource(
          firebaseAuth: firebaseAuth,
          firestore: firestore,
        );
        final snapshot = await dsAfter.authStateChanges().first;
        expect(snapshot, isNull);
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('AuthRepositoryImpl.logout', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth firebaseAuth;
    late AuthRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      firebaseAuth = MockFirebaseAuth(signedIn: true);
      final dataSource = AuthRemoteDataSource(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );
      repository = AuthRepositoryImpl(dataSource: dataSource);
      firestore.collection('users').doc('user-1').set({
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'participant',
      });
    });

    test('logout ne lève pas d\'erreur', () async {
      await repository.logout();
    });
  });

  group('AuthRemoteDataSource.login crée le profil si absent', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth firebaseAuth;
    late AuthRemoteDataSource dataSource;
    late MockUser mockUser;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'user-1',
        email: 'newuser@example.com',
        displayName: 'New User',
      );
      firebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      dataSource = AuthRemoteDataSource(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );
    });

    test('crée le document users/{uid} si inexistant', () async {
      final user = await dataSource.login(
        email: 'newuser@example.com',
        password: 'password123',
      );
      final snapshot = await firestore.collection('users').doc(user.id).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.get('email'), 'newuser@example.com');
      expect(snapshot.get('role'), 'participant');
    });

    test('ne écrase pas un profil existant lors du login', () async {
      firestore.collection('users').doc('user-1').set({
        'name': 'Existing User',
        'email': 'existing@example.com',
        'role': 'organizer',
      });
      final user = await dataSource.login(
        email: 'existing@example.com',
        password: 'password123',
      );
      final snapshot = await firestore.collection('users').doc(user.id).get();
      expect(snapshot.get('role'), 'organizer');
    });
  });

  group('AuthRemoteDataSource.authStateChanges est résilient', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth firebaseAuth;
    late AuthRemoteDataSource dataSource;
    late MockUser mockUser;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      mockUser = MockUser(uid: 'user-1');
      firebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      dataSource = AuthRemoteDataSource(
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );
    });

    test('ne casse pas si le document utilisateur est absent', () async {
      final user = await dataSource.authStateChanges().first;
      expect(user, isNotNull);
      expect(user!.id, 'user-1');
      expect(user.name, isEmpty);
    });
  });
}
