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

/// Recovery screen for an account whose Firestore profile is missing.
///
/// This is what an interrupted sign-up (or a deleted `users/{uid}`
/// document) lands on. The alternative — signing the user out — would be
/// both hostile and confusing, since their credentials are perfectly valid.
/// The router pins them here until the profile exists.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  UserRole _role = UserRole.participant;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authControllerProvider.notifier)
        .completeProfile(name: _name.text.trim(), role: _role);

    if (result case Err(:final failure) when mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final t = context.tokens;

    return AuthShell(
      title: AppStrings.completeProfile,
      lead: AppStrings.completeProfileHint,
      hero: const AuthHeroIcon(icon: Icons.person_add_alt_rounded),
      footer: TextButton.icon(
        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text(AppStrings.logout),
        style: TextButton.styleFrom(foregroundColor: t.textSecondary),
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
                    icon: Icons.person_outline_rounded,
                    controller: _name,
                    label: AppStrings.name,
                    hint: 'Elvis Rakoto',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        Validators.minLength(v, 2, label: 'Le nom'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              RoleSelector(
                value: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(
                label: AppStrings.continueLabel,
                isLoading: isLoading,
                trailingIcon: Icons.arrow_forward_rounded,
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
