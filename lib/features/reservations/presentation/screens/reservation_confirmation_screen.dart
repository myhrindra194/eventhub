import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Booking confirmation.
///
/// A deliberate full screen rather than a toast: the moment a reservation
/// succeeds is the emotional peak of the participant journey, and it is
/// also where the two follow-up actions belong ("voir mon billet",
/// "continuer à explorer"). A snack bar would waste both.
class ReservationConfirmationScreen extends ConsumerWidget {
  const ReservationConfirmationScreen({required this.reservationId, super.key});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservation = ref.watch(reservationByIdProvider(reservationId));

    return AppScaffold(
      body: SafeArea(
        child: AsyncValueWidget(
          value: reservation,
          isEmpty: (r) => r == null,
          empty: const EmptyStateView(message: 'Réservation introuvable.'),
          data: (r) => _Body(reservation: r!),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(reservation.eventId)).value;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Center(child: SuccessHero()),
          const SizedBox(height: AppSpacing.huge),
          Text(
            AppStrings.bookingConfirmed,
            style: text.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.bookingConfirmedHint,
            style: text.bodyLarge?.copyWith(
              color: context.tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AppSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: EventImage(
                    imageUrl: event?.imageUrl,
                    seed: reservation.eventId,
                    borderRadius: AppRadius.brSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.eventTitle,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppDateFormats.dayMonthTime(reservation.eventStartsAt),
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        reservation.eventLocation,
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          AppButton.primary(
            label: AppStrings.viewMyTickets,
            icon: Icons.confirmation_number_rounded,
            onPressed: () => context.go(AppRoutes.reservations),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.ghost(
            label: AppStrings.returnHome,
            expand: true,
            onPressed: () => context.go(AppRoutes.events),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
