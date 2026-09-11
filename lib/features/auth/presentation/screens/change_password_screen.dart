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

/// Change the password of the signed-in account.
///
/// Three fields, in the order the user thinks about them: prove it is you,
/// choose the new one, confirm it. The current password is not ceremony —
/// re-authenticating with it is what turns the provider's unactionable
/// "requires-recent-login" into a plain "wrong password", and it is the only
/// thing between an unlocked phone and a stolen account.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    final base = Validators.password(value);
    if (base != null) return base;
    if (value == _current.text) return AppStrings.passwordSameAsOld;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _next.text) return AppStrings.passwordMismatch;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authControllerProvider.notifier)
        .changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );

    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.passwordChanged);
        context.pop();
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthShell(
      title: AppStrings.changePasswordTitle,
      lead: AppStrings.changePasswordLead,
      hero: const AuthHeroIcon(icon: Icons.lock_outline_rounded),
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Two groups, not one: "prove it is you" and "choose the new
              // one" are separate intentions, and the gap between the cards
              // says so without a heading.
              FieldGroup(
                children: [
                  PasswordFieldRow(
                    controller: _current,
                    label: 'Actuel',
                    hint: AppStrings.currentPassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Champ obligatoire.' : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FieldGroup(
                children: [
                  PasswordFieldRow(
                    controller: _next,
                    label: 'Nouveau',
                    hint: AppStrings.passwordHint,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateNew,
                    onChanged: (_) => setState(() {}),
                  ),
                  PasswordFieldRow(
                    controller: _confirm,
                    label: 'Confirmer',
                    hint: AppStrings.confirmPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateConfirm,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PasswordStrengthMeter(password: _next.text),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(
                label: AppStrings.changePassword,
                loadingLabel: 'Mise à jour…',
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
