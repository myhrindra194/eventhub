import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../events/domain/entities/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../../home/presentation/widgets/custom_bottom_nav_bar.dart';

class ConfirmationReservationScreen extends ConsumerWidget {
  final Event event;

  const ConfirmationReservationScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Booking Confirmed',
            subtitle: 'Your ticket is ready',
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated Green Check Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00C853),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title & Description
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We've sent the ticket and receipt to your email. Get ready for an amazing experience!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Event Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              event.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.event,
                                      color: Colors.white54,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${event.date} • ${event.time}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Primary action button redirects to the tickets screen.
                    AppButton(
                      text: 'View My Tickets',
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).state = 2;
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      height: 54,
                    ),

                    const SizedBox(height: 16),

                    // Secondary action button returns to the first page in the stack.
                    TextButton(
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).state = 0;
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Text(
                        'Return to Home',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
