import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/features/auth/presentation/widgets/role_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sign-up, in two steps.
///
/// Identity first, role second. The role is a permanent, permission-bearing
/// choice: giving it its own step raises the odds it is made deliberately,
/// and it keeps the first screen down to four familiar fields in one card.
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
  UserRole _role = UserRole.participant;
  bool _terms = false;
  int _step = 0;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _next() {
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
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
        );
    if (result case Err(:final failure) when mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return PopScope(
      // Step 2 returns to step 1 rather than leaving the flow: losing a
      // filled-in form to a back gesture is the fastest way to lose a sign-up.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        child: _step == 0
            ? _IdentityStep(
                key: const ValueKey('identity'),
                formKey: _formKey,
                firstName: _firstName,
                lastName: _lastName,
                email: _email,
                password: _password,
                terms: _terms,
                onTermsChanged: (v) => setState(() => _terms = v),
                onContinue: _next,
                onSignIn: () => context.pop(),
              )
            : _RoleStep(
                key: const ValueKey('role'),
                role: _role,
                isLoading: isLoading,
                onRoleChanged: (r) => setState(() => _role = r),
                onSubmit: _submit,
                onBack: () => setState(() => _step = 0),
              ),
      ),
    );
  }
}

class _IdentityStep extends StatefulWidget {
  const _IdentityStep({
    required this.formKey,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.terms,
    required this.onTermsChanged,
    required this.onContinue,
    required this.onSignIn,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController password;
  final bool terms;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  @override
  State<_IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<_IdentityStep> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return AuthShell(
      title: AppStrings.registerTitle,
      lead: AppStrings.registerLead,
      step: (1, 2),
      footer: AuthFooterLink(
        prompt: AppStrings.haveAccount,
        action: AppStrings.login,
        onTap: widget.onSignIn,
      ),
      children: [
        Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldGroup(
                children: [
                  FieldRow(
                    icon: Icons.badge_outlined,
                    controller: widget.lastName,
                    label: AppStrings.lastName,
                    hint: 'Entrez votre nom',
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    validator: (v) =>
                        Validators.minLength(v, 2, label: 'Le nom'),
                  ),
                  FieldRow(
                    icon: Icons.person_outline_rounded,
                    controller: widget.firstName,
                    label: AppStrings.firstName,
                    hint: 'Entrez votre prénom',
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    validator: (v) =>
                        Validators.minLength(v, 2, label: 'Le prénom'),
                  ),
                  FieldRow(
                    icon: Icons.mail_outline_rounded,
                    controller: widget.email,
                    label: 'Email',
                    hint: 'Entrez votre adresse emailcl',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  PasswordFieldRow(
                    controller: widget.password,
                    label: AppStrings.password,
                    hint: AppStrings.passwordHint,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PasswordStrengthMeter(password: widget.password.text),
              const SizedBox(height: AppSpacing.xl),
              AppCheckbox(
                value: widget.terms,
                onChanged: widget.onTermsChanged,
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
                label: AppStrings.continueLabel,
                trailingIcon: Icons.arrow_forward_rounded,
                elevated: false,
                onPressed: widget.onContinue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    required this.role,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  final UserRole role;
  final bool isLoading;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: AppStrings.roleStepTitle,
      lead: AppStrings.roleStepLead,
      step: (2, 2),
      onBack: onBack,
      children: [
        RoleSelector(value: role, onChanged: onRoleChanged),
        const SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: AppStrings.createAccount,
          loadingLabel: 'Création du compte',
          isLoading: isLoading,
          elevated: false,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
