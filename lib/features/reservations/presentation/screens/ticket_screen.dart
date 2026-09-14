import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/presentation/widgets/reservation_tile.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The ticket, as it is shown at the door.
///
/// Built for the ten seconds it is actually used: someone in a queue, phone
/// held out, a volunteer with a scanner. So the QR code is large and on pure
/// white whatever the theme (scanners struggle with inverted codes), and the
/// short code under it is set in wide tracking so it can be read aloud when
/// the scan fails. Everything else — date, place, holder — is secondary and
/// laid out like a printed pass, fields separated by hairlines.
class TicketScreen extends ConsumerWidget {
  const TicketScreen({required this.reservationId, super.key});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservation = ref.watch(reservationByIdProvider(reservationId));

    return AppScaffold(
      dense: true,
      extendBody: false,
      appBar: AppBar(title: const Text(AppStrings.ticketTitle)),
      body: AsyncValueWidget(
        value: reservation,
        onRetry: () => ref.invalidate(reservationByIdProvider(reservationId)),
        isEmpty: (r) => r == null,
        empty: const EmptyStateView(
          icon: Icons.link_off_rounded,
          message: AppStrings.ticketNotFound,
        ),
        data: (r) => _TicketBody(reservation: r!),
      ),
    );
  }
}

class _TicketBody extends ConsumerWidget {
  const _TicketBody({required this.reservation});

  final Reservation reservation;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: reservation.ticketCode));
    if (context.mounted) context.showSuccess(AppStrings.codeCopied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final isPast = !reservation.eventStartsAt.isAfter(now);
    final valid = reservation.isActive && !isPast;

    final notice = reservation.isPending
        ? (
            AppTone.warning,
            Icons.hourglass_top_rounded,
            AppStrings.ticketPendingNotice,
          )
        : reservation.isCancelled
        ? (
            AppTone.danger,
            Icons.block_rounded,
            AppStrings.ticketCancelledNotice,
          )
        : isPast
        ? (AppTone.neutral, Icons.history_rounded, AppStrings.ticketPastNotice)
        : (
            AppTone.brand,
            Icons.brightness_high_rounded,
            AppStrings.ticketEntrance,
          );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.lg,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: [
              _Pass(reservation: reservation, valid: valid),
              const SizedBox(height: AppSpacing.lg),
              _Notice(tone: notice.$1, icon: notice.$2, message: notice.$3),
            ],
          ),
        ),
        FrostedBar(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: AppStrings.copyCode,
                  icon: Icons.content_copy_rounded,
                  size: AppButtonSize.medium,
                  elevated: false,
                  onPressed: () => _copyCode(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                  label: AppStrings.viewEvent,
                  trailingIcon: Icons.arrow_forward_rounded,
                  size: AppButtonSize.medium,
                  elevated: false,
                  onPressed: () => context.push(
                    AppRoutes.eventDetailPath(reservation.eventId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The printed pass: header, a grid of fields, a tear line, the code.
class _Pass extends StatelessWidget {
  const _Pass({required this.reservation, required this.valid});

  final Reservation reservation;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final r = reservation;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: t.border),
        boxShadow: t.shadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReservationStatusLabel(status: r.status),
                    const Spacer(),
                    Text(r.accessLabel.toUpperCase(), style: text.labelSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  r.eventTitle,
                  style: text.headlineMedium?.copyWith(height: 1.15),
                ),
              ],
            ),
          ),
          const AppDivider(height: 1),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Field(
                    label: AppStrings.date,
                    value: AppDateFormats.weekdayDate(r.eventStartsAt),
                  ),
                ),
                VerticalDivider(width: 1, color: t.borderSubtle),
                SizedBox(
                  width: 104,
                  child: _Field(
                    label: AppStrings.time,
                    value: AppDateFormats.time(r.eventStartsAt),
                  ),
                ),
              ],
            ),
          ),
          const AppDivider(height: 1),
          _Field(label: AppStrings.location, value: r.eventLocation),
          const AppDivider(height: 1),
          _Field(
            label: AppStrings.ticketHolder,
            value: r.userName,
            sub: r.userEmail,
          ),
          if (r.isPaid) ...[
            const AppDivider(height: 1),
            _Field(
              label: AppStrings.amountPaid,
              value: Money.format(r.pricePaid, r.currency ?? 'EUR'),
              sub: r.isRefunded ? AppStrings.paymentRefundedTitle : null,
            ),
          ],
          const _TearLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              children: [
                _Code(reservation: r, valid: valid),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  r.ticketCode,
                  style: text.headlineSmall?.copyWith(
                    letterSpacing: 2.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: valid ? t.textPrimary : t.textTertiary,
                    decoration: r.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                const SectionLabel(AppStrings.ticketCode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: text.titleMedium, maxLines: 2),
          if (sub != null)
            Text(
              sub!,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Dashed tear line with a notch bitten out of each edge — the pass is
/// clipped, so the notches read as holes rather than as circles.
class _TearLine extends StatelessWidget {
  const _TearLine();

  static const _notch = 22.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget notch() => Container(
      width: _notch,
      height: _notch,
      decoration: BoxDecoration(
        color: t.canvas,
        shape: BoxShape.circle,
        border: Border.all(color: t.border),
      ),
    );

    return SizedBox(
      height: _notch + AppSpacing.lg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _notch),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashPainter(color: t.borderStrong),
            ),
          ),
          Positioned(left: -_notch / 2, child: notch()),
          Positioned(right: -_notch / 2, child: notch()),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 6.0;
    const gap = 5.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// The QR code, always dark-on-white. An invalid ticket keeps its code on
/// screen (the holder may still need the reference) but faded behind a
/// "no entry" glyph, so nobody at a door mistakes it for a valid pass.
class _Code extends StatelessWidget {
  const _Code({required this.reservation, required this.valid});

  final Reservation reservation;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    const ink = AppPalette.neutral900;

    return Semantics(
      image: true,
      label: 'QR code du billet ${reservation.ticketCode}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brXs,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: valid ? 1 : 0.12,
              child: QrImageView(
                data: reservation.ticketPayload,
                size: 196,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: ink,
                ),
              ),
            ),
            if (!valid)
              Icon(
                reservation.isCancelled
                    ? Icons.block_rounded
                    : Icons.history_rounded,
                size: 56,
                color: ink.withValues(alpha: 0.55),
              ),
          ],
        ),
      ),
    );
  }
}

/// A rule on the left edge and a tinted strip — no rounded card, the pass
/// above is already the card.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.tone,
    required this.icon,
    required this.message,
  });

  final AppTone tone;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(left: BorderSide(color: colors.solid, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.fg,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
