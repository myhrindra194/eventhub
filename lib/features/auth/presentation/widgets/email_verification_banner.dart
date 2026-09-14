import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reminder shown until the signed-in user confirms their address.
///
/// Two actions, both honest about what they do: "C'est fait" reloads the
/// account (the link is opened in a mail app, outside EventHub, so the app
/// cannot know by itself), "Renvoyer le lien" is throttled to once a minute
/// because Firebase rate-limits it anyway and a silent failure would look
/// like a broken button. Disappears on its own once verified.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  static const _cooldown = Duration(seconds: 60);

  DateTime? _lastSent;
  Timer? _cooldownEnd;
  bool _checking = false;

  bool get _coolingDown =>
      _lastSent != null && DateTime.now().difference(_lastSent!) < _cooldown;

  @override
  void dispose() {
    _cooldownEnd?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendEmailVerification();
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _lastSent = DateTime.now());
        _cooldownEnd?.cancel();
        _cooldownEnd = Timer(_cooldown, () {
          if (mounted) setState(() {});
        });
        context.showSuccess(AppStrings.verificationSent);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .refreshEmailVerification();
    if (!mounted) return;
    setState(() => _checking = false);
    switch (result) {
      case Ok(value: true):
        context.showSuccess(AppStrings.emailVerified);
      case Ok():
        context.showToast(
          AppStrings.stillNotVerified,
          tone: AppTone.warning,
          icon: Icons.mark_email_unread_outlined,
        );
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.emailVerified) return const SizedBox.shrink();

    final t = context.tokens;
    final text = context.textTheme;
    final tone = t.warning;

    return Padding(
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tone.bg,
          border: Border(left: BorderSide(color: tone.solid, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 18,
                  color: tone.fg,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.verifyEmailTitle,
                    style: text.titleSmall?.copyWith(color: t.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.verifyEmailBody(user.email),
              style: text.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton.tonal(
                  label: AppStrings.iVerifiedEmail,
                  size: AppButtonSize.small,
                  isLoading: _checking,
                  elevated: false,
                  onPressed: _check,
                ),
                TextButton(
                  onPressed: _coolingDown ? null : _resend,
                  style: TextButton.styleFrom(
                    foregroundColor: t.textSecondary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brButton,
                    ),
                  ),
                  child: const Text(AppStrings.resendVerification),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
