import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sign-in.
///
/// Navigation on success is *not* handled here: the router's guard reacts to
/// the new session and moves the user to their role home. A screen that both
/// authenticates and navigates ends up fighting the redirect.
///
/// There is no "Se souvenir de moi" checkbox. Firebase persists the session
/// by default, so the control would do nothing — and a switch that does
/// nothing is worse than no switch at all.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);

    if (result case Err(:final failure) when mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final t = context.tokens;

    return AuthShell(
      title: AppStrings.signInTitle,
      lead: AppStrings.signInLead,
      footer: AuthFooterLink(
        prompt: AppStrings.noAccount,
        action: AppStrings.register,
        onTap: () => context.push(AppRoutes.register),
      ),
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
                    hint: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  PasswordFieldRow(
                    controller: _password,
                    hint: AppStrings.password,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.forgotPassword),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: t.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: AppStrings.login,
                loadingLabel: AppStrings.signingIn,
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
