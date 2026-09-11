import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/widgets/app_header.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'event_participants_screen.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  final EventRepositoryImpl _repository = EventRepositoryImpl();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _repository.getEvents();
    setState(() {
      _events = events;
      _isLoading = false;
    });
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
                            horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(textColor, subtextColor),
                            const SizedBox(height: 24),
                            ..._events.map((event) => _buildEventCard(
                                  context: context,
                                  event: event,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                )),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, Color textColor, Color? subtextColor) {
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
            style: TextStyle(
              fontSize: 14,
              color: subtextColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateEventScreen(),
                  ),
                );
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateEventScreen(),
              ),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                eventId: event.id,
                eventTitle: event.title,
              ),
            ),
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
                  event.isBase64
                      ? Image.memory(
                          base64Decode(event.imageUrl),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image,
                                color: Colors.white54, size: 50),
                          ),
                        )
                      : Image.asset(
                          event.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image,
                                color: Colors.white54, size: 50),
                          ),
                        ),
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
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                size: 18, color: subtextColor),
                            const SizedBox(width: 6),
                            Text(
                              '${event.currentAttendees}/${event.capacity}',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.euro, size: 16, color: subtextColor),
                            const SizedBox(width: 6),
                            Text(
                              event.formattedPrice,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: subtextColor),
                            const SizedBox(width: 6),
                            Text(
                              '${event.date.month}/${event.date.day}/${event.date.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        _buildActions(context, event, isDark),
                      ],
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

  Widget _buildActions(BuildContext context, Event event, bool isDark) {
    if (event.status == EventStatus.draft) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: ElevatedButton(
          onPressed: () {
            // Publish action
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
            // Edit action
          },
        ),
        const SizedBox(width: 8),
        _buildIconButton(
          icon: Icons.bar_chart_rounded,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventParticipantsScreen(
                  eventId: event.id,
                ),
              ),
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