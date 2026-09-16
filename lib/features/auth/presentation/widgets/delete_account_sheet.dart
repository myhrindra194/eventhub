import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille de suppression du compte.
///
/// La confirmation est un identifiant, pas un « Êtes-vous sûr ? » : le mot de
/// passe pour un compte à mot de passe, le sélecteur Google sinon. C’est de
/// toute façon ce que Firebase exige pour une opération sensible, et cela
/// empêche un téléphone déverrouillé d’effacer le compte de quelqu’un en deux
/// appuis.
Future<void> showDeleteAccountSheet(BuildContext context) {
  // Capturé maintenant : en cas de succès, le router quitte cet écran
  // (déconnexion), donc le message de confirmation ne doit pas dépendre de
  // son context.
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet<void>(
    context: context,
    builder: (_) => _DeleteAccountSheet(messenger: messenger),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet({required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _password = TextEditingController();
  late final bool _usesPassword = ref
      .read(authRepositoryProvider)
      .usesPasswordSignIn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Saisissez votre mot de passe.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: _usesPassword ? _password.text : null);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        widget.messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.accountDeleted)),
        );
      case Err(:final failure):
        setState(() {
          _busy = false;
          // Les erreurs s’affichent dans la feuille : un toast glisserait
          // derrière elle.
          _error =
              failure is AuthFailure &&
                  failure.code == AuthFailureCode.cancelled
              ? null
              : failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return AppSheet(
      title: AppStrings.deleteAccountTitle,
      subtitle: AppStrings.deleteAccountBody,
      actions: [
        AppButton.danger(
          label: AppStrings.deleteAccount,
          loadingLabel: AppStrings.deletingAccount,
          isLoading: _busy,
          onPressed: _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _usesPassword
                ? AppStrings.deleteAccountPasswordLead
                : AppStrings.deleteAccountGoogleLead,
            style: text.bodyMedium,
          ),
          if (_usesPassword) ...[
            const SizedBox(height: AppSpacing.md),
            FieldGroup(
              children: [
                PasswordFieldRow(
                  controller: _password,
                  hint: AppStrings.password,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: text.bodySmall?.copyWith(color: t.danger.fg, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
