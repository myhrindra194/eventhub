import 'package:flutter/material.dart';
import '../../../../core/widgets/app_header.dart';
import '../../data/repositories/event_repository_impl.dart';

class OrganizerStatsScreen extends StatefulWidget {
  const OrganizerStatsScreen({super.key});

  @override
  State<OrganizerStatsScreen> createState() => _OrganizerStatsScreenState();
}

class _OrganizerStatsScreenState extends State<OrganizerStatsScreen> {
  final EventRepositoryImpl _repository = EventRepositoryImpl();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final events = await _repository.getEvents();
    
    final totalEvents = events.length;
    final liveEvents = events.where((e) => e.status.name == 'live').length;
    final totalParticipants = events.fold<int>(0, (sum, e) => sum + e.currentAttendees);
    final totalCapacity = events.fold<int>(0, (sum, e) => sum + e.capacity);
    final attendanceRate = totalCapacity > 0 ? (totalParticipants / totalCapacity * 100).toStringAsFixed(1) : '0.0';

    setState(() {
      _stats = {
        'totalEvents': totalEvents.toString(),
        'liveEvents': liveEvents.toString(),
        'totalParticipants': totalParticipants.toString(),
        'attendanceRate': '$attendanceRate%',
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'Organizer Stats', subtitle: 'Track your performance'),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _StatTile(
                      icon: Icons.event,
                      label: 'Total Events',
                      value: _stats['totalEvents'] ?? '0',
                      onTap: () => _showDetails(context, 'Total Events: ${_stats['totalEvents']}'),
                    ),
                    _StatTile(
                      icon: Icons.play_circle,
                      label: 'Live Events',
                      value: _stats['liveEvents'] ?? '0',
                      onTap: () => _showDetails(context, 'Live Events: ${_stats['liveEvents']}'),
                    ),
                    _StatTile(
                      icon: Icons.people,
                      label: 'Total Participants',
                      value: _stats['totalParticipants'] ?? '0',
                      onTap: () => _showDetails(context, 'Total Participants: ${_stats['totalParticipants']}'),
                    ),
                    _StatTile(
                      icon: Icons.trending_up,
                      label: 'Attendance Rate',
                      value: _stats['attendanceRate'] ?? '0%',
                      onTap: () => _showDetails(context, 'Attendance Rate: ${_stats['attendanceRate']}'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(value), const SizedBox(width: 8), const Icon(Icons.chevron_right)],
        ),
        onTap: onTap,
      ),
    );
  }
}
