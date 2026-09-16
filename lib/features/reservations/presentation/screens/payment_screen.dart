import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// L’état d’un achat payant, lu en direct depuis la réservation (F-11).
///
/// La redirection Stripe ne décide jamais de rien : cet écran suit le
/// document que met à jour le webhook. Pending — la place est retenue, avec
/// son échéance, la page peut être rouverte ou l’achat abandonné.
/// Confirmed — le billet. Expired ou cancelled — rien n’a été débité.
/// Refunded — quand attendre l’argent.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({required this.reservationId, super.key});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservation = ref.watch(reservationByIdProvider(reservationId));

    return AppScaffold(
      dense: true,
      appBar: AppTopBar.subPage(
        title: AppStrings.paymentTitle,
        onBack: () => context.pop(),
      ),
      body: AsyncValueWidget(
        value: reservation,
        onRetry: () => ref.invalidate(reservationByIdProvider(reservationId)),
        isEmpty: (r) => r == null,
        empty: const EmptyStateView(
          icon: Icons.receipt_long_outlined,
          message: AppStrings.ticketNotFound,
        ),
        data: (r) => _Body(reservation: r!),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.reservation});

  final Reservation reservation;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// Maintient l’échéance de la place retenue exacte tant que
  /// l’utilisateur regarde l’écran.
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 30),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _resume() async {
    final url = Uri.tryParse(widget.reservation.checkoutUrl ?? '');
    final opened =
        url != null &&
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        ).catchError((_) => false);
    if (!opened && mounted) context.showToast(AppStrings.openPaymentFailed);
  }

  Future<void> _abandon() async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.remove_shopping_cart_outlined,
      title: AppStrings.cancelPurchaseTitle,
      message: AppStrings.cancelPurchaseMessage,
      confirmLabel: AppStrings.cancelPurchase,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(reservationControllerProvider.notifier)
        .cancelPendingCheckout(widget.reservation.eventId);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.purchaseCancelled);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final t = context.tokens;
    final text = context.textTheme;
    final busy = ref.watch(reservationControllerProvider).isLoading;
    final currency = r.currency ?? 'EUR';
    final amount = r.isPaid ? r.pricePaid : (r.amountDue ?? 0);

    final (tone, icon, title, lead) = switch (r.status) {
      ReservationStatus.pending => (
        AppTone.warning,
        Icons.hourglass_top_rounded,
        AppStrings.paymentPendingTitle,
        AppStrings.paymentPendingLead(
          r.holdExpiresAt == null
              ? '—'
              : AppDateFormats.time(
                  // Le serveur garde un court délai de grâce après
                  // l’expiration propre à Stripe ; on annonce l’échéance
                  // de Stripe.
                  r.holdExpiresAt!.subtract(const Duration(minutes: 5)),
                ),
        ),
      ),
      ReservationStatus.confirmed => (
        AppTone.success,
        Icons.check_circle_rounded,
        AppStrings.paymentConfirmedTitle,
        AppStrings.paymentConfirmedLead,
      ),
      ReservationStatus.cancelled when r.isRefunded => (
        AppTone.info,
        Icons.currency_exchange_rounded,
        AppStrings.paymentRefundedTitle,
        AppStrings.paymentRefundedLead,
      ),
      ReservationStatus.cancelled => (
        AppTone.neutral,
        Icons.event_seat_outlined,
        AppStrings.paymentExpiredTitle,
        AppStrings.paymentExpiredLead,
      ),
    };
    final colors = t.resolve(tone);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        AppSpacing.huge,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border(left: BorderSide(color: colors.solid, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.fg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: colors.fg),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      lead,
                      style: text.bodySmall?.copyWith(
                        color: colors.fg,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.brButton,
            border: Border.all(color: t.border),
          ),
          child: Column(
            children: [
              _Line(label: AppStrings.eventName, value: r.eventTitle),
              Divider(height: 1, color: t.borderSubtle),
              _Line(
                label: AppStrings.date,
                value: AppDateFormats.dayMonthTime(r.eventStartsAt),
              ),
              Divider(height: 1, color: t.borderSubtle),
              _Line(label: AppStrings.ticketTypes, value: r.accessLabel),
              Divider(height: 1, color: t.borderSubtle),
              _Line(
                label: AppStrings.amountPaid,
                value: amount > 0 ? Money.format(amount, currency) : '—',
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (r.isPending) ...[
          AppButton.primary(
            label: AppStrings.resumePayment,
            onPressed: busy || r.checkoutUrl == null ? null : _resume,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: AppStrings.cancelPurchase,
            isLoading: busy,
            onPressed: busy ? null : _abandon,
          ),
        ] else if (r.isActive)
          AppButton.primary(
            label: AppStrings.viewTicket,
            onPressed: () =>
                context.pushReplacement(AppRoutes.ticketPath(r.id)),
          )
        else
          AppButton.secondary(
            label: AppStrings.backToEvent,
            onPressed: () =>
                context.pushReplacement(AppRoutes.eventDetailPath(r.eventId)),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: (strong ? text.titleMedium : text.bodyMedium)?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
