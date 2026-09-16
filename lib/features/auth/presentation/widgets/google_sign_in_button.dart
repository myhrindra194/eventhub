import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// « ou continuer avec » + « Continuer avec Google ».
///
/// N’affiche rien là où Google Sign-In n’est pas configuré (Android sans
/// `GOOGLE_SERVER_CLIENT_ID`) : un bouton qui ne peut qu’échouer est pire que
/// pas de bouton du tout. La navigation après succès revient au router, comme
/// pour la connexion par mot de passe — une première connexion Google
/// atterrit sur le choix du rôle.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key, this.intendedRole, this.beforeSignIn});

  /// Rôle choisi sur l'écran d'inscription, appliqué si la connexion Google
  /// crée le compte. Sans objet sur l'écran de connexion.
  final UserRole? intendedRole;

  /// Garde facultative : l'inscription s'en sert pour exiger le rôle avant
  /// d'ouvrir le sélecteur Google. Renvoie `false` pour ne rien faire.
  final bool Function()? beforeSignIn;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (!(widget.beforeSignIn?.call() ?? true)) return;
    setState(() => _busy = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(
          intendedRole: widget.intendedRole ?? UserRole.participant,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      // Fermer le sélecteur est un choix, pas une erreur.
      if (failure is AuthFailure && failure.code == AuthFailureCode.cancelled) {
        return;
      }
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(appConfigProvider).isGoogleSignInAvailable) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const LabelledDivider(label: AppStrings.continueWith),
        const SizedBox(height: AppSpacing.xl),
        AppButton.secondary(
          label: AppStrings.continueWithGoogle,
          loadingLabel: AppStrings.googleSigningIn,
          isLoading: _busy,
          onPressed: _signIn,
        ),
      ],
    );
  }
}
