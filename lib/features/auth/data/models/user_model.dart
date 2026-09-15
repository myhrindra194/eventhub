import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromFirebase(
    firebase_auth.User firebaseUser, {
    Map<String, dynamic>? profile,
  }) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: profile?['name'] as String? ?? firebaseUser.displayName ?? '',
      role: profile?['role'] as String? ?? UserRole.participant.name,
    );
  }

  User toEntity() {
    final userRole = UserRole.values.firstWhere(
      (value) => value.name == role,
      orElse: () => UserRole.participant,
    );

    return User(id: id, email: email, name: name, role: userRole);
  }
}
