import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter/material.dart';

/// Ticket card.
///
/// Shaped like a physical ticket on purpose — a coloured stub carrying the
/// date, a perforation, then the details. The metaphor does real work: in a
/// list of past and upcoming tickets, the stub is what the eye locks onto,
/// and a used ticket that is visually "torn" (dimmed, greyed stub) needs no
/// label to read as expired.
class TicketCard extends StatelessWidget {
  const TicketCard({
    required this.reservation,
    super.key,
    this.onTap,
    this.isPast = false,
  });

  final Reservation reservation;
  final VoidCallback? onTap;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final active = reservation.isActive && !isPast;

    return Opacity(
      opacity: active ? 1 : 0.62,
      child: AppSurface.bare(
        radius: AppRadius.lg,
        elevation: active ? SurfaceElevation.low : SurfaceElevation.flat,
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Stub(date: reservation.eventStartsAt, active: active),
              const _Perforation(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.eventTitle,
                                  style: text.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 12,
                                      color: t.textTertiary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        '${AppDateFormats.time(reservation.eventStartsAt)}'
                                        ' · ${reservation.eventLocation}',
                                        style: text.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          if (isPast)
                            Icon(
                              Icons.history_rounded,
                              color: t.textTertiary,
                              size: 22,
                            )
                          else
                            const _QrTile(),
                        ],
                      ),
                      const AppDivider(height: AppSpacing.xl),
                      Row(
                        children: [
                          ReservationStatusLabel(status: reservation.status),
                          const Spacer(),
                          Text(
                            AppStrings.generalAccess.toUpperCase(),
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  const _Stub({required this.date, required this.active});

  final DateTime date;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      width: 76,
      decoration: BoxDecoration(
        gradient: active ? t.brandGradient : null,
        color: active ? null : t.surfaceSunken,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppDateFormats.monthAbbr(date),
            style: text.labelSmall?.copyWith(
              color: active ? Colors.white70 : t.textTertiary,
            ),
          ),
          Text(
            '${date.day}',
            style: text.headlineMedium?.copyWith(
              color: active ? Colors.white : t.textSecondary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.year}',
            style: text.labelSmall?.copyWith(
              color: active ? Colors.white70 : t.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed tear line between stub and body.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 1,
    child: CustomPaint(painter: _DashPainter(color: context.tokens.border)),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

class _QrTile extends StatelessWidget {
  const _QrTile();

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadius.brXs,
    ),
    child: const Icon(
      Icons.qr_code_2_rounded,
      color: AppPalette.neutral900,
      size: 30,
    ),
  );
}

/// "● Confirmée" / "● Annulée" inline label.
class ReservationStatusLabel extends StatelessWidget {
  const ReservationStatusLabel({required this.status, super.key});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      ReservationStatus.confirmed => (
        AppTone.success,
        Icons.check_circle_rounded,
      ),
      ReservationStatus.cancelled => (AppTone.danger, Icons.cancel_rounded),
    };
    final colors = context.tokens.resolve(tone);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.fg),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status.label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.fg),
        ),
      ],
    );
  }
}
