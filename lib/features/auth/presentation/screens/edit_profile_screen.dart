import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Edit the signed-in user's profile.
///
/// The name for everyone, and for organizers the presentation shown on their
/// public profile. Email and role are shown — greyed, with a padlock and one
/// sentence of why — rather than hidden: a user looking for "change my
/// email" should learn it is not possible here instead of wondering whether
/// they missed a menu.
///
/// The avatar above the form follows the name as it is typed; it is the
/// cheapest possible preview of what the change will look like elsewhere.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Mirrors `isString(bio, 0, 500)` in firestore.rules.
  static const _bioMax = 500;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name);
    _bio = TextEditingController(text: user?.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _isOrganizer => ref.read(currentUserProvider)?.isOrganizer ?? false;

  bool get _isDirty {
    final user = ref.read(currentUserProvider);
    final nameChanged = _name.text.trim() != (user?.name ?? '');
    final bioChanged =
        _isOrganizer && _bio.text.trim() != (user?.bio ?? '').trim();
    return nameChanged || bioChanged;
  }

  String? _validate(String? value) {
    final base = Validators.minLength(value, 2, label: 'Le nom');
    if (base != null) return base;
    // Mirrors `isString(name, 2, 80)` in firestore.rules: fail here with a
    // sentence rather than on the server with a permission error.
    if (value!.trim().length > 80) return '80 caractères maximum.';
    return null;
  }

  String? _validateBio(String? value) =>
      (value ?? '').trim().length > _bioMax ? AppStrings.bioTooLong : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (!_isDirty) {
      context.showToast(AppStrings.nameUnchanged);
      return;
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _name.text,
          bio: _isOrganizer ? _bio.text.trim() : null,
        );

    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.profileUpdated);
        context.pop();
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final preview = _name.text.trim().isEmpty ? (user?.name ?? '') : _name.text;

    return AuthShell(
      title: AppStrings.editProfileTitle,
      lead: AppStrings.editProfileLead,
      showMark: false,
      hero: AppAvatar(name: preview, size: 84),
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
                    icon: Icons.person_outline_rounded,
                    controller: _name,
                    label: AppStrings.name,
                    hint: 'Elvis Rakoto',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: (user?.isOrganizer ?? false)
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    validator: _validate,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (user?.isOrganizer ?? false)
                        ? null
                        : (_) => _submit(),
                  ),
                ],
              ),
              if (user?.isOrganizer ?? false) ...[
                const SizedBox(height: AppSpacing.xxl),
                const SectionLabel(AppStrings.publicProfileSection),
                const SizedBox(height: AppSpacing.md),
                FieldGroup(
                  children: [
                    TextFormField(
                      controller: _bio,
                      minLines: 3,
                      maxLines: 7,
                      maxLength: _bioMax,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _validateBio,
                      onChanged: (_) => setState(() {}),
                      style: context.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: AppStrings.bioLabel,
                        hintText: AppStrings.bioHint,
                        alignLabelWithHint: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                        counterStyle: context.textTheme.labelSmall?.copyWith(
                          color: t.textTertiary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.publicProfileHelp,
                  style: context.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SectionLabel(AppStrings.lockedFields),
        const SizedBox(height: AppSpacing.md),
        FieldGroup(
          children: [
            _LockedRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user?.email ?? '',
            ),
            _LockedRow(
              icon: Icons.badge_outlined,
              label: AppStrings.role,
              value: user?.role.label ?? '',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.lockedFieldsHint,
          style: context.textTheme.bodySmall?.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: AppStrings.save,
          loadingLabel: 'Enregistrement…',
          isLoading: isLoading,
          elevated: false,
          onPressed: _isDirty ? _submit : null,
        ),
      ],
    );
  }
}

/// A read-only row with the same geometry as [FieldRow], so the two groups
/// line up column for column.
class _LockedRow extends StatelessWidget {
  const _LockedRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 19, color: t.textTertiary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 86, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: text.bodyLarge?.copyWith(color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: t.textTertiary),
        ],
      ),
    );
  }
}
