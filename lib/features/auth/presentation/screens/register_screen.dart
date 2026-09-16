import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:eventhub/features/auth/presentation/widgets/role_choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inscription, en une seule carte.
///
/// Le rôle est demandé d'emblée — « Vous êtes participant ou
/// organisateur ? » —, puis les quatre champs familiers. Ce que le rôle
/// change réellement :
///  * **participant** : le compte est prêt, il découvre et réserve ;
///  * **organisateur** : l'espace organisateur est ouvert dès l'inscription,
///    et le compte garde l'espace participant (un compte, deux espaces). Seule
///    la publication attend une adresse confirmée — les règles l'exigent.
///
/// Aucun lien à cliquer n'est envoyé ici : le mail reçu est un mail de
/// bienvenue. La confirmation d'adresse est demandée au moment où elle sert.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _terms = false;

  /// Aucun rôle présélectionné : voir [RoleChoice].
  UserRole? _role;
  bool _showRoleError = false;

  /// Commun au bouton « Créer mon compte » et à « Continuer avec Google » :
  /// les deux créent un compte, les deux ont besoin du rôle.
  bool _ensureRole() {
    if (_role != null) return true;
    setState(() => _showRoleError = true);
    context.showToast(
      AppStrings.roleRequired,
      tone: AppTone.warning,
      icon: Icons.info_outline_rounded,
    );
    return false;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (!_ensureRole() || !formValid) return;
    if (!_terms) {
      context.showToast(
        AppStrings.acceptTermsRequired,
        tone: AppTone.warning,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
          email: _email.text.trim(),
          password: _password.text,
          intendedRole: _role!,
        );
    if (!mounted) return;
    switch (result) {
      case Err(:final failure):
        context.showFailure(failure);
      // Déjà connecté : le router emmène le compte dans l'app ; ce message
      // annonce seulement le mail de bienvenue.
      case Ok(:final value):
        context.showToast(
          AppStrings.welcomeEmailSent(value.email),
          tone: AppTone.success,
          icon: Icons.mark_email_read_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthShell(
      title: AppStrings.registerTitle,
      lead: AppStrings.registerLead,
      footer: AuthFooterLink(
        prompt: AppStrings.haveAccount,
        action: AppStrings.login,
        onTap: () => context.pop(),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.roleSignUpTitle,
                style: text.labelLarge?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              RoleChoice(
                value: _role,
                errorText: _showRoleError && _role == null
                    ? AppStrings.roleRequired
                    : null,
                onChanged: (role) => setState(() => _role = role),
              ),
              if (_role == UserRole.organizer) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.roleOrganizerNote,
                  style: text.bodySmall?.copyWith(
                    color: t.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FieldGroup(
                children: [
                  FieldRow(
                    icon: Icons.badge_outlined,
                    controller: _lastName,
                    label: AppStrings.lastName,
                    hint: 'Entrez votre nom',
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    validator: (v) =>
                        Validators.minLength(v, 2, label: 'Le nom'),
                  ),
                  FieldRow(
                    icon: Icons.person_outline_rounded,
                    controller: _firstName,
                    label: AppStrings.firstName,
                    hint: 'Entrez votre prénom',
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    validator: (v) =>
                        Validators.minLength(v, 2, label: 'Le prénom'),
                  ),
                  FieldRow(
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    label: 'Email',
                    hint: 'Entrez votre adresse email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  PasswordFieldRow(
                    controller: _password,
                    label: AppStrings.password,
                    hint: AppStrings.passwordHint,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PasswordStrengthMeter(password: _password.text),
              const SizedBox(height: AppSpacing.xl),
              AppCheckbox(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
                label: Text(
                  AppStrings.acceptTerms,
                  style: text.bodySmall?.copyWith(
                    color: t.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: AppStrings.createAccount,
                loadingLabel: 'Création du compte',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              GoogleSignInButton(
                intendedRole: _role,
                beforeSignIn: _ensureRole,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
