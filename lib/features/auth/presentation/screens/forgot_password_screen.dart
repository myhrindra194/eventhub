import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Demande de réinitialisation du mot de passe.
///
/// Deux états dans un même écran — le formulaire, puis une confirmation.
/// Renvoyer l’utilisateur vers l’écran de connexion avec un snack bar le
/// laisse se demander s’il s’est passé quelque chose ; une confirmation qui
/// répète l’adresse et mentionne le dossier de spam supprime le ticket de
/// support le plus fréquent que génère un parcours de réinitialisation.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());

    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _sent = true);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final t = context.tokens;

    if (_sent) {
      return AuthShell(
        title: AppStrings.resetSentTitle,
        lead: AppStrings.resetSentHint,
        hero: const AuthHeroIcon(
          icon: Icons.mark_email_read_outlined,
          tone: AppTone.success,
        ),
        onBack: () => context.pop(),
        children: [
          FieldGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 19,
                      color: t.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _email.text.trim(),
                        style: context.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton.primary(
            label: AppStrings.backToLogin,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: 'Renvoyer le lien',
            onPressed: () => setState(() => _sent = false),
          ),
        ],
      );
    }

    return AuthShell(
      title: AppStrings.forgotPasswordTitle,
      lead: AppStrings.forgotPasswordLead,
      hero: const AuthHeroIcon(icon: Icons.lock_reset_rounded),
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldGroup(
                children: [
                  FieldRow(
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    hint: 'vous@exemple.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(
                label: AppStrings.sendResetLink,
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
