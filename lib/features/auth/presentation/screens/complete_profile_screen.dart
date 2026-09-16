import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de rattrapage pour un compte dont le profil Firestore manque.
///
/// C’est là qu’atterrit une inscription interrompue (ou un document
/// `users/{uid}` supprimé). L’autre option — déconnecter l’utilisateur —
/// serait à la fois hostile et déroutante, puisque ses identifiants sont
/// parfaitement valides. Le router l’épingle ici tant que le profil n’existe
/// pas.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Première connexion Google : le compte a déjà un nom d’affichage.
    if (ref.read(authSessionProvider).value case ProfileMissing(
      :final displayName?,
    )) {
      _name.text = displayName;
    }
  }

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
        .completeProfile(name: _name.text.trim());

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
      footer: TextButton(
        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        style: TextButton.styleFrom(foregroundColor: t.textSecondary),
        child: const Text(AppStrings.logout),
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
              AppButton.primary(
                label: AppStrings.continueLabel,
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
