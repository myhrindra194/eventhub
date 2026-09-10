import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/events_provider.dart';
import '../../../reservations/presentation/providers/reservation_provider.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../../home/presentation/widgets/custom_bottom_nav_bar.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity(int availablePlaces) {
    setState(() {
      if (_quantity < availablePlaces) _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
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

          const String? userStatus = null;
          final int availablePlaces = event.availablePlaces;

          if (_quantity > availablePlaces && availablePlaces > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _quantity = availablePlaces);
            });
          }

          final double unitPrice = event.price;
          final double totalPrice = unitPrice * _quantity;
          final bool canOrder =
              availablePlaces > 0 && userStatus != 'CONFIRMED';

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
                            // --- Ligne du haut : badge dispo + panier ---
                            Row(
                              children: [
                                if (availablePlaces > 0) ...[
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
                                  Flexible(
                                    child: Text(
                                      '• $availablePlaces seats left',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(isDark)
                                          .copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ] else
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
                                const Spacer(),
                                if (canOrder)
                                  _CartStepper(
                                    quantity: _quantity,
                                    isDark: isDark,
                                    onIncrement: () =>
                                        _incrementQuantity(availablePlaces),
                                    onDecrement: _decrementQuantity,
                                    canIncrement: _quantity < availablePlaces,
                                    canDecrement: _quantity > 1,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              event.title,
                              style: AppTypography.heading1(isDark),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentIndigo,
                                  ),
                                ),
                                if (canOrder && _quantity > 1) ...[
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '· Total \$${totalPrice.toStringAsFixed(2)} for $_quantity',
                                      style: AppTypography.body(isDark)
                                          .copyWith(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                          ),
                                    ),
                                  ),
                                ],
                              ],
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
                    final reservation = ref
                        .read(createReservationUseCaseProvider)
                        .call(event: event, quantity: _quantity);

                    await ref
                        .read(effectuerReservationUseCaseProvider)
                        .call(reservation);
                    ref.invalidate(mesBilletsProvider);

                    if (!context.mounted) return;
                    Navigator.pushNamed(
                      context,
                      AppRouter.reservationConfirmation,
                      arguments: event,
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
    required String? status,
    required int availablePlaces,
    required VoidCallback onReserve,
    required VoidCallback onCancel,
    required VoidCallback onWaitlist,
  }) {
    if (status == 'CONFIRMED') {
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

    if (status == 'WAITLIST') {
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

    return AppButton(text: 'Book Ticket Now', onPressed: onReserve, height: 50);
  }
}

/// Panier compact (+/-) à afficher en haut, à côté du badge de
/// disponibilité — design pilule moderne avec dégradé indigo.
class _CartStepper extends StatelessWidget {
  final int quantity;
  final bool isDark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;
  final bool canDecrement;

  const _CartStepper({
    required this.quantity,
    required this.isDark,
    required this.onIncrement,
    required this.onDecrement,
    required this.canIncrement,
    required this.canDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppColors.accentIndigo.withValues(alpha: 0.14),
            AppColors.accentIndigo.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIcon(
            icon: Icons.remove_rounded,
            onTap: canDecrement ? onDecrement : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
          _StepperIcon(
            icon: Icons.add_rounded,
            onTap: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? AppColors.accentIndigo
                : AppColors.accentIndigo.withValues(alpha: 0.25),
          ),
          child: Icon(
            icon,
            size: 15,
            color: enabled ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}
