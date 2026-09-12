import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../domain/entities/user_role.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String redirectRoute;
  final UserRole? requiredRole;
  final String? forbiddenRedirectRoute;

  const AuthGuard({
    super.key,
    required this.child,
    required this.redirectRoute,
    this.requiredRole,
    this.forbiddenRedirectRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.value!;
    if (requiredRole != null && user.role != requiredRole) {
      final route = forbiddenRedirectRoute ?? redirectRoute;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
