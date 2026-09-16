import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ouvre l'espace organisateur du compte connecté (« un compte, deux
/// espaces », le modèle d'Eventbrite et d'Airbnb).
///
/// Pourquoi une feuille et non un écran : activer l'espace n'est pas une
/// inscription, c'est une décision unique prise depuis le profil. La feuille
/// reste au-dessus du profil, et un retour en arrière ne coûte rien.
Future<void> showBecomeOrganizerSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      builder: (_) => _BecomeOrganizerSheet(pageContext: context),
    );

class _BecomeOrganizerSheet extends ConsumerStatefulWidget {
  const _BecomeOrganizerSheet({required this.pageContext});

  /// L'écran sous la feuille : le message de confirmation y est levé une fois
  /// la feuille refermée, sinon il glisserait derrière elle.
  final BuildContext pageContext;

  @override
  ConsumerState<_BecomeOrganizerSheet> createState() =>
      _BecomeOrganizerSheetState();
}

class _BecomeOrganizerSheetState extends ConsumerState<_BecomeOrganizerSheet> {
  /// Reprend `isString(bio, 0, 500)` des règles Firestore.
  static const _bioMax = 500;

  final _bio = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _error = null);
    final result = await ref
        .read(authControllerProvider.notifier)
        .becomeOrganizer(bio: _bio.text);

    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        if (!widget.pageContext.mounted) return;
        widget.pageContext.showSuccess(AppStrings.becomeOrganizerDone);
        // L'espace s'ouvre immédiatement sur son tableau de bord : c'est la
        // preuve visible que l'activation a marché.
        widget.pageContext.go(AppRoutes.organizerEvents);
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final user = ref.watch(currentUserProvider);
    final busy = ref.watch(authControllerProvider).isLoading;
    // Les règles lisent `email_verified` dans le jeton : le dire avant le
    // clic évite un refus serveur que l'utilisateur ne peut pas interpréter.
    final verified = user?.emailVerified ?? false;

    return AppSheet(
      title: AppStrings.becomeOrganizer,
      subtitle: user?.email ?? '',
      actions: [
        AppButton.primary(
          label: AppStrings.becomeOrganizerCta,
          isLoading: busy,
          loadingLabel: AppStrings.becomeOrganizerLoading,
          onPressed: busy || !verified ? null : _activate,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.becomeOrganizerLead,
              style: text.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final point in const [
              AppStrings.becomeOrganizerPoint1,
              AppStrings.becomeOrganizerPoint2,
              AppStrings.becomeOrganizerPoint3,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        color: t.brand,
                        borderRadius: AppRadius.brButton,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        point,
                        style: text.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            if (!verified) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: t.warning.bg,
                  border: Border(
                    left: BorderSide(color: t.warning.solid, width: 3),
                  ),
                ),
                child: Text(
                  AppStrings.becomeOrganizerVerifyFirst,
                  style: text.bodySmall?.copyWith(
                    color: t.warning.fg,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FieldGroup(
              children: [
                TextField(
                  controller: _bio,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: _bioMax,
                  textCapitalization: TextCapitalization.sentences,
                  style: text.bodyLarge,
                  decoration: InputDecoration(
                    labelText: AppStrings.becomeOrganizerBioLabel,
                    hintText: AppStrings.becomeOrganizerBioHint,
                    alignLabelWithHint: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    counterStyle: text.labelSmall?.copyWith(
                      color: t.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.becomeOrganizerOneWay,
              style: text.bodySmall?.copyWith(height: 1.45),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: t.danger.fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
