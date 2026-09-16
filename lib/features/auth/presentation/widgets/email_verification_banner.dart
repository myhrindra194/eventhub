import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ce que la confirmation d'adresse va débloquer, là où le bandeau s'affiche.
enum VerificationPurpose {
  /// Publier un événement (espace organisateur).
  organizer,

  /// Publier un avis sur un événement.
  review,
}

/// Invitation à confirmer son adresse, **au moment où elle sert**.
///
/// L'inscription n'envoie plus de lien à cliquer, seulement un mail de
/// bienvenue : un compte neuf peut tout de suite découvrir et réserver. La
/// confirmation n'est demandée que pour ce que les règles réservent aux
/// adresses vérifiées — publier un événement, laisser un avis —, et c'est ce
/// bandeau qui la demande, là où l'action se prépare.
/// C'est le parcours d'Eventbrite : on ne fait pas payer un effort avant
/// qu'il ait une raison d'être.
///
/// Trois temps, honnêtes sur ce qu'ils font :
///  1. « Envoyer le lien » — rien n'est parti tant que la personne ne le
///     demande pas ;
///  2. « C'est fait » recharge le compte : le lien s'ouvre dans une
///     messagerie, hors d'EventHub, l'app ne peut donc pas le savoir seule ;
///  3. « Renvoyer le lien », limité à une fois par minute parce que Firebase
///     le plafonne de toute façon.
///
/// Un organisateur a son espace dès l'inscription ; le bandeau ne lui
/// rappelle la confirmation que parce qu'elle conditionne la publication.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({
    super.key,
    this.padding = EdgeInsets.zero,
    this.purpose = VerificationPurpose.organizer,
  });

  final EdgeInsetsGeometry padding;
  final VerificationPurpose purpose;

  /// Le bandeau n'a de sens que si l'adresse bloque effectivement quelque
  /// chose pour ce compte, à cet endroit. Un participant qui ne laisse pas
  /// d'avis n'a jamais à le voir.
  static bool isRelevant(AppUser user, VerificationPurpose purpose) {
    if (user.emailVerified) return false;
    return switch (purpose) {
      VerificationPurpose.organizer => user.isOrganizer,
      VerificationPurpose.review => true,
    };
  }

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
  bool _sending = false;

  bool get _coolingDown =>
      _lastSent != null && DateTime.now().difference(_lastSent!) < _cooldown;

  @override
  void dispose() {
    _cooldownEnd?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendEmailVerification();
    if (!mounted) return;
    setState(() => _sending = false);
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
    if (user == null ||
        !EmailVerificationBanner.isRelevant(user, widget.purpose)) {
      return const SizedBox.shrink();
    }

    final t = context.tokens;
    final text = context.textTheme;
    final tone = t.warning;
    final sent = _lastSent != null;

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
              sent
                  ? AppStrings.verifyEmailSentBody(user.email)
                  : switch (widget.purpose) {
                      VerificationPurpose.organizer =>
                        AppStrings.verifyEmailForOrganizer(user.email),
                      VerificationPurpose.review =>
                        AppStrings.verifyEmailForReview(user.email),
                    },
              style: text.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: sent
                  ? [
                      AppButton.tonal(
                        label: AppStrings.iVerifiedEmail,
                        size: AppButtonSize.small,
                        isLoading: _checking,
                        onPressed: _check,
                      ),
                      TextButton(
                        onPressed: _coolingDown ? null : _send,
                        style: TextButton.styleFrom(
                          foregroundColor: t.textSecondary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brButton,
                          ),
                        ),
                        child: const Text(AppStrings.resendVerification),
                      ),
                    ]
                  : [
                      AppButton.tonal(
                        label: AppStrings.sendVerificationLink,
                        size: AppButtonSize.small,
                        isLoading: _sending,
                        onPressed: _send,
                      ),
                      // Le lien a pu être ouvert depuis une autre session :
                      // on laisse vérifier sans rien renvoyer.
                      TextButton(
                        onPressed: _checking ? null : _check,
                        style: TextButton.styleFrom(
                          foregroundColor: t.textSecondary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brButton,
                          ),
                        ),
                        child: const Text(AppStrings.alreadyVerified),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
