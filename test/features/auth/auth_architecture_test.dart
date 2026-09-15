import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eventhub/core/di/auth_dependencies.dart';
import 'package:eventhub/features/auth/data/mappers/auth_failure_mapper.dart';
import 'package:eventhub/features/auth/domain/entities/user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/failures/auth_failure.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/auth/domain/usecases/login_usecase.dart';
import 'package:eventhub/features/auth/domain/usecases/register_usecase.dart';
import 'package:eventhub/features/auth/presentation/providers/auth_provider.dart';

void main() {
  const user = User(
    id: 'user-1',
    email: 'user@example.com',
    name: 'Event User',
    role: UserRole.participant,
  );

  test('login use case delegates to the domain repository', () async {
    final repository = FakeAuthRepository(user: user);
    final login = LoginUseCase(repository);

    final result = await login(
      email: 'user@example.com',
      password: 'password123',
    );

    expect(result, user);
    expect(repository.lastEmail, 'user@example.com');
  });

  test('register use case forwards profile data', () async {
    final repository = FakeAuthRepository(user: user);
    final register = RegisterUseCase(repository);

    await register(
      email: 'user@example.com',
      password: 'password123',
      name: 'Event User',
      role: 'participant',
    );

    expect(repository.lastName, 'Event User');
    expect(repository.lastRole, 'participant');
  });

  test('Firebase auth errors are converted to domain failures', () {
    final failure = mapAuthException(
      firebase_auth.FirebaseAuthException(code: 'wrong-password'),
    );

    expect(failure, isA<InvalidCredentialsFailure>());
  });

  test('auth notifier exposes domain users without Firebase types', () async {
    final repository = FakeAuthRepository(user: user);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(authProvider.notifier)
        .login(email: 'user@example.com', password: 'password123');

    expect(container.read(authProvider).value, user);
  });
}

class FakeAuthRepository implements AuthRepository {
  final User user;
  String? lastEmail;
  String? lastName;
  String? lastRole;

  FakeAuthRepository({required this.user});

  @override
  Future<User> login({required String email, required String password}) async {
    lastEmail = email;
    return user;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    lastEmail = email;
    lastName = name;
    lastRole = role;
    return user;
  }

  @override
  Future<User?> loginWithGoogle() async => user;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}
