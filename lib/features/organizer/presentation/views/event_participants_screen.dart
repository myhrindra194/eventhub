import 'package:flutter/material.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../../../core/widgets/app_header.dart';

class EventParticipantsScreen extends StatefulWidget {
  final String eventId;

  const EventParticipantsScreen({super.key, required this.eventId});

  @override
  State<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final EventRepositoryImpl _repository = EventRepositoryImpl();
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _filteredParticipants = [];
  Event? _event;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final event = await _repository.getEventById(widget.eventId);
    final participants = await _repository.getEventParticipants(widget.eventId);

    setState(() {
      _event = event;
      _participants = participants;
      _filteredParticipants = participants;
      _isLoading = false;
    });
  }

  void _filterParticipants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredParticipants = _participants;
      } else {
        _filteredParticipants = _participants.where((participant) {
          final name = participant['name'].toString().toLowerCase();
          final email = participant['email'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();
      }
    });
  }

  double _calculateRevenue() {
    if (_event == null) return 0.0;
    final paidParticipants = _participants
        .where((p) => p['status'] == 'confirmed')
        .length;
    return paidParticipants * _event!.price;
  }

  void _exportGuestList() {
    // Export functionality placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guest list exported successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: _event?.title ?? 'Participants',
            subtitle: 'Manage event attendees',
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Summary cards
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'BOOKED',
                                value:
                                    '${_event?.currentAttendees ?? 0}/${_event?.capacity ?? 0}',
                                icon: Icons.event_seat,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'REVENUE',
                                value:
                                    '\$${_calculateRevenue().toStringAsFixed(0)}',
                                icon: Icons.attach_money,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Material(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterParticipants,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: isDark
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.surfaceContainer,
                              hintStyle: TextStyle(color: secondaryTextColor),
                              prefixIconColor: secondaryTextColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Participants list
                      Expanded(
                        child: _filteredParticipants.isEmpty
                            ? const Center(child: Text('No participants found'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: _filteredParticipants.length,
                                itemBuilder: (context, index) {
                                  final participant =
                                      _filteredParticipants[index];
                                  return _ParticipantTile(
                                    participant: participant,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    secondaryTextColor: secondaryTextColor,
                                  );
                                },
                              ),
                      ),

                      // Export button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _exportGuestList,
                            icon: const Icon(Icons.download),
                            label: const Text('EXPORT GUEST LIST'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;

  const _ParticipantTile({
    required this.participant,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: const AssetImage(
                'assets/images/user_avatar.jpg',
              ),
              backgroundColor: secondaryTextColor.withValues(alpha: 0.18),
              child: participant['name'] != null
                  ? Text(participant['name'][0])
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participant['email'] ?? 'No email',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(participant['status']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                participant['status'].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.more_vert, color: secondaryTextColor),
              onPressed: () {
                // More options menu
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
