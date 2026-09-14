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

/// Opens the account deletion sheet.
///
/// The confirmation is a credential, not a "Êtes-vous sûr ?": the password
/// for a password account, the Google picker otherwise. It is what Firebase
/// requires for a sensitive operation anyway, and it stops an unlocked phone
/// from erasing someone's account in two taps.
Future<void> showDeleteAccountSheet(BuildContext context) {
  // Captured now: on success the router leaves this screen (signed out), so
  // the confirmation toast must not depend on its context.
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
          // Errors are shown inside the sheet: a toast would slide in
          // behind it.
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
          elevated: false,
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
