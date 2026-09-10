import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../data/models/reservation_model.dart';
import '../providers/events_provider.dart';
import '../../../reservations/presentation/views/confirmation_reservation_screen.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../../reservations/presentation/providers/reservation_provider.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../../home/presentation/widgets/custom_bottom_nav_bar.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: eventAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentIndigo),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: AppTypography.body(isDark)),
        ),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          const ReservationStatus? userStatus = null;
          final int availablePlaces = event.availablePlaces;

          return Column(
            children: [
              const AppHeader(
                title: 'Event Details',
                subtitle: 'Discover event information',
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.asset(
                            event.imageUrl,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 280,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white38,
                                    size: 60,
                                  ),
                                ),
                          ),
                          if (availablePlaces <= 0)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    'SOLD OUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.5,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (availablePlaces > 0) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'AVAILABLE',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• $availablePlaces seats left',
                                    style: AppTypography.body(isDark).copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (availablePlaces <= 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'NO VACANCY',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              event.title,
                              style: AppTypography.heading1(isDark),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.accentIndigo,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${event.date} • ${event.time}',
                                  style: AppTypography.body(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.accentIndigo,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event.location,
                                  style: AppTypography.body(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'About this event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: AppTypography.body(
                                isDark,
                              ).copyWith(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                color: theme.colorScheme.surface,
                child: _buildActionButton(
                  context: context,
                  status: userStatus,
                  availablePlaces: availablePlaces,
                  onReserve: () async {
                    final reservation = Reservation(
                      id: event.id,
                      eventTitle: event.title,
                      date: '${event.date} • ${event.time}',
                      status: 'CONFIRMED',
                      seatInfo: 'GENERAL ACCESS',
                    );

                    await ref
                        .read(effectuerReservationUseCaseProvider)
                        .call(reservation);
                    ref.invalidate(mesBilletsProvider);

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConfirmationReservationScreen(event: event),
                      ),
                    );
                  },
                  onCancel: () {},
                  onWaitlist: () {},
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ReservationStatus? status,
    required int availablePlaces,
    required VoidCallback onReserve,
    required VoidCallback onCancel,
    required VoidCallback onWaitlist,
  }) {
    // Type 1: confirmed reservation -> cancel
    if (status == ReservationStatus.confirmed) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onCancel,
          child: const Text(
            'Registered (Cancel)',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Type 2: sold out -> disabled action
    if (availablePlaces <= 0) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF20242B),
            disabledBackgroundColor: const Color(0xFF20242B),
            disabledForegroundColor: Colors.white38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: null,
          child: const Text(
            'Not Available',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    // Type 3: already on the waitlist
    if (status == ReservationStatus.waitlist) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: null,
          child: const Text(
            'On the waitlist',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Type 4: standard registration
    return AppButton(text: 'Book Ticket Now', onPressed: onReserve, height: 50);
  }
}
