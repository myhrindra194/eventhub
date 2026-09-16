import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter/material.dart';

/// Carte de billet.
///
/// Dessinée exprès comme un billet physique — une souche colorée qui porte
/// la date, une perforation, puis les détails. La métaphore travaille
/// vraiment : dans une liste de billets passés et à venir, c’est la souche
/// que l’œil accroche, et un billet utilisé visuellement « déchiré »
/// (atténué, souche grisée) se lit comme périmé sans la moindre étiquette.
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
                            reservation.accessLabel.toUpperCase(),
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

/// La ligne de déchirure en pointillés entre la souche et le corps.
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

/// Libellé en ligne « ● Confirmée » / « ● Annulée ».
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
      ReservationStatus.pending => (
        AppTone.warning,
        Icons.hourglass_top_rounded,
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
