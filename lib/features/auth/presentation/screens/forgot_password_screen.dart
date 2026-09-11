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

/// Password reset request.
///
/// Two states in one screen — the form, then a confirmation. Bouncing the
/// user back to the login screen with a snack bar leaves them wondering
/// whether anything happened; a confirmation that repeats the address and
/// mentions the spam folder removes the most common support ticket a reset
/// flow generates.
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
            elevated: false,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: 'Renvoyer le lien',
            elevated: false,
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
                elevated: false,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
