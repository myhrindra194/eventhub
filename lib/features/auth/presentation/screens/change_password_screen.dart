import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Change le mot de passe du compte connecté.
///
/// Trois champs, dans l’ordre où l’utilisateur y pense : prouvez que c’est
/// bien vous, choisissez le nouveau, confirmez-le. Le mot de passe actuel
/// n’est pas un cérémonial — c’est en se réauthentifiant avec lui que le
/// « requires-recent-login » du fournisseur, sur lequel on ne peut rien,
/// devient un banal « mot de passe incorrect » ; et c’est la seule chose qui
/// sépare un téléphone déverrouillé d’un compte volé.
///
/// En mode [recovery] — ouvert par un lien de réinitialisation — le lien a
/// déjà prouvé la possession de l’adresse : le mot de passe actuel n’est pas
/// demandé.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.recovery = false});

  final bool recovery;

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
    if (!widget.recovery && value == _current.text) {
      return AppStrings.passwordSameAsOld;
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _next.text) return AppStrings.passwordMismatch;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = ref.read(authControllerProvider.notifier);
    final result = widget.recovery
        ? await controller.setNewPassword(_next.text)
        : await controller.changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );

    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.passwordChanged);
        if (widget.recovery || !context.canPop()) {
          context.go(AppRoutes.splash);
        } else {
          context.pop();
        }
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthShell(
      title: widget.recovery
          ? AppStrings.recoveryPasswordTitle
          : AppStrings.changePasswordTitle,
      lead: widget.recovery
          ? AppStrings.recoveryPasswordLead
          : AppStrings.changePasswordLead,
      hero: const AuthHeroIcon(icon: Icons.lock_outline_rounded),
      onBack: widget.recovery
          ? () => context.go(AppRoutes.splash)
          : () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deux groupes, et non un seul : « prouvez que c’est vous » et
              // « choisissez le nouveau » sont deux intentions distinctes, et
              // l’écart entre les cartes le dit sans avoir besoin d’un titre.
              if (!widget.recovery) ...[
                FieldGroup(
                  children: [
                    PasswordFieldRow(
                      controller: _current,
                      label: 'Actuel',
                      hint: AppStrings.currentPassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Champ obligatoire.'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
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
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
