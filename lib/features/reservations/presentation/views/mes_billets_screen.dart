import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_provider.dart';

class MesBilletsScreen extends ConsumerWidget {
  final List<Reservation>? reservations;

  const MesBilletsScreen({super.key, this.reservations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = reservations == null
        ? ref.watch(mesBilletsProvider)
        : AsyncValue.data(reservations!);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'My Tickets',
            subtitle: 'Your bookings and tickets',
          ),
          Expanded(
            child: reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Unable to load your tickets',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              data: (loadedReservations) => loadedReservations.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTicketsList(context, loadedReservations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Tickets Yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'It looks like you haven\'t booked any events yet.\nExplore the latest events around you and start your journey!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Navigate to event search or the event list.
                },
                child: const Text(
                  'Explore Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    BuildContext context,
    List<Reservation> loadedReservations,
  ) {
    // Séparation upcoming / past selon le statut de la réservation.
    // Adaptez cette condition si votre entité Reservation expose une
    // date exploitable (ex. reservation.eventDate.isBefore(DateTime.now())).
    final upcoming = loadedReservations
        .where((r) => r.status.toUpperCase() != 'PAST')
        .toList();
    final past = loadedReservations
        .where((r) => r.status.toUpperCase() == 'PAST')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        if (upcoming.isNotEmpty) ...[
          _sectionLabel(context, 'UPCOMING EVENTS'),
          const SizedBox(height: 14),
          for (final reservation in upcoming) ...[
            _buildTicketCard(context, reservation),
            const SizedBox(height: 16),
          ],
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionLabel(context, 'PAST EVENTS'),
          const SizedBox(height: 14),
          for (final reservation in past) ...[
            _buildPastTicketCard(context, reservation),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Reservation reservation) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.eventTitle,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reservation.date,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _dashedDivider(context),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF00C853),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      reservation.seatInfo,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastTicketCard(BuildContext context, Reservation reservation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.history,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.eventTitle,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reservation.date,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(dashCount, (_) {
            return Padding(
              padding: const EdgeInsets.only(right: dashSpace),
              child: Container(
                width: dashWidth,
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.25),
              ),
            );
          }),
        );
      },
    );
  }
}