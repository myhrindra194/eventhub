import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "ou continuer avec" + "Continuer avec Google".
///
/// Renders nothing where Google Sign-In is not configured (Android without
/// `GOOGLE_SERVER_CLIENT_ID`): a button that can only fail is worse than no
/// button. Navigation after success is the router's job, as for the password
/// sign-in — a first Google sign-in lands on the role choice.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      // Closing the picker is a choice, not an error.
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
          elevated: false,
          onPressed: _signIn,
        ),
      ],
    );
  }
}
