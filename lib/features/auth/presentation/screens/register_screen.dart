import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inscription, en une seule carte.
///
/// Aucun rôle à choisir : comme chez Eventbrite ou Airbnb, tout compte
/// démarre en participant et ouvre plus tard son espace organisateur, depuis
/// le profil, une fois qu’il a quelque chose à publier. Quatre champs
/// familiers, puis l’application — le router fait atterrir le nouveau compte
/// sur l’écran de bienvenue.
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

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
        );
    if (!mounted) return;
    switch (result) {
      case Err(:final failure):
        context.showFailure(failure);
      // Déjà connecté ; le bandeau de vérification suit la personne jusqu’à
      // ce qu’elle ouvre le lien.
      case Ok(:final value) when !value.emailVerified:
        context.showToast(
          AppStrings.confirmEmailSent(value.email),
          tone: AppTone.success,
          icon: Icons.mark_email_read_outlined,
        );
      case Ok():
        break;
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
              const GoogleSignInButton(),
            ],
          ),
        ),
      ],
    );
  }
}
