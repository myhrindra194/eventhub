import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../providers/organizer_events_provider.dart';
import '../widgets/organizer_bottom_nav_bar.dart';
import 'event_detail_screen.dart';
import 'organizer_alerts_screen.dart';
import 'organizer_stats_screen.dart';

/// Main entry point for the Organizer section.
///
/// This screen replaces the previous OrganizerMainScreen.
/// It contains the bottom navigation and the different organizer sections.
class OrganizerEventsScreen extends ConsumerStatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  ConsumerState<OrganizerEventsScreen> createState() =>
      _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState
    extends ConsumerState<OrganizerEventsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    OrganizerEventsContent(),
    OrganizerStatsScreen(),
    OrganizerAlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0F1117)
        : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: OrganizerBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            _confirmLogout();
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unable to log out: ${authState.error ?? 'Please try again.'}',
          ),
        ),
      );
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      AppRouter.welcome,
      (route) => false,
    );
  }
}

/// Events tab content.
class OrganizerEventsContent extends ConsumerStatefulWidget {
  const OrganizerEventsContent({super.key});

  @override
  ConsumerState<OrganizerEventsContent> createState() =>
      _OrganizerEventsContentState();
}

class _OrganizerEventsContentState
    extends ConsumerState<OrganizerEventsContent> {
  List<Event> _events = [];
  bool _isLoading = true;
  ProviderSubscription<AsyncValue<List<Event>>>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    // Écoute réactive : la liste se met à jour après create/update/delete
    // sans setState manuel + invalidate.
    _eventsSubscription = ref.listenManual(organizerEventsStreamProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      next.when(
        data: (events) => setState(() {
          _events = events;
          _isLoading = false;
        }),
        loading: () => setState(() => _isLoading = true),
        error: (error, _) {
          // Une erreur peut arriver pendant la transition de déconnexion,
          // alors que l'ancien abonnement Firestore n'est pas encore fermé.
          if (ref.read(authProvider).value == null) return;

          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to load events: $error')),
          );
        },
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _eventsSubscription?.close();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    // Conservé pour le pull-to-refresh explicite si besoin futur.
    // Le stream met déjà à jour la liste automatiquement.
    ref.invalidate(organizerEventsStreamProvider);
  }

  Future<void> _publishEvent(Event event) async {
    try {
      await ref.read(organizerEventRepositoryProvider).publishEvent(event.id);
      // Pas de reload manuel : le stream Firestore pousse la mise à jour.
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish event: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1A1D26) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        const AppHeader(
          title: 'Organizer Events',
          subtitle: 'Manage your active listings',
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
              ? _buildEmptyState(context, textColor, subtextColor)
              : SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textColor, subtextColor),

                        const SizedBox(height: 24),

                        ..._events.map(
                          (event) => _buildEventCard(
                            context: context,
                            event: event,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtextColor: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color textColor,
    Color? subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E212A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              size: 38,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Ready to host something amazing? Create your first event and start selling tickets.',
            style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(AppRouter.organizerCreateEvent)
                    .then((_) => _loadEvents());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Create My First Event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color? subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Events',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Manage your active listings',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
          ],
        ),

        GestureDetector(
          onTap: () {
            Navigator.of(context)
                .pushNamed(AppRouter.organizerCreateEvent)
                .then((_) => _loadEvents());
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required Event event,
    required Color cardColor,
    required Color textColor,
    required Color? subtextColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.organizerEventDetail,
            arguments: {'eventId': event.id, 'eventTitle': event.title},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildEventImage(event),

                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(event.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildEventMeta(
                          icon: Icons.people_outline,
                          text: '${event.currentAttendees}/${event.capacity}',
                          color: subtextColor,
                        ),

                        _buildEventMeta(
                          icon: Icons.euro,
                          text: event.formattedPrice,
                          color: subtextColor,
                        ),

                        _buildEventMeta(
                          icon: Icons.calendar_today_outlined,
                          text:
                              '${event.date.month}/${event.date.day}/${event.date.year}',
                          color: subtextColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildActions(context, event, isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventImage(Event event) {
    if (event.imageUrl.startsWith('http')) {
      return Image.network(
        event.imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }

    return Image.asset(
      event.imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImageError();
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[800],
      child: const Icon(Icons.image, color: Colors.white54, size: 50),
    );
  }

  Widget _buildEventMeta({
    required IconData icon,
    required String text,
    required Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),

        const SizedBox(width: 6),

        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Event event, bool isDark) {
    if (event.status == EventStatus.draft) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: ElevatedButton(
          onPressed: () {
            _publishEvent(event);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'PUBLISH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        _buildIconButton(
          icon: Icons.edit_outlined,
          isDark: isDark,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      eventId: event.id,
                      eventTitle: event.title,
                    ),
                  ),
                )
                .then((_) => _loadEvents());
          },
        ),

        const SizedBox(width: 8),

        _buildIconButton(
          icon: Icons.bar_chart_rounded,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRouter.organizerEventParticipants,
              arguments: {'eventId': event.id},
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252936) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.live:
        return Colors.green;

      case EventStatus.draft:
        return Colors.orange;

      case EventStatus.completed:
        return Colors.blue;

      case EventStatus.cancelled:
        return Colors.red;
    }
  }
}
