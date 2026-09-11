import 'package:flutter/material.dart';
import '../../../../core/widgets/app_header.dart';

class OrganizerAlertsScreen extends StatefulWidget {
  const OrganizerAlertsScreen({super.key});

  @override
  State<OrganizerAlertsScreen> createState() => _OrganizerAlertsScreenState();
}

class _OrganizerAlertsScreenState extends State<OrganizerAlertsScreen> {
  final Set<int> _readAlerts = {};
  final List<Map<String, String>> _alerts = [
    {
      'title': 'New registration',
      'message': 'A participant joined Tech Nexus 2024.',
      'time': '2 min ago',
    },
    {
      'title': 'Event reminder',
      'message': 'Your event starts in 3 days.',
      'time': '1 hour ago',
    },
    {
      'title': 'Profile update',
      'message': 'Your organizer profile is complete.',
      'time': 'Yesterday',
    },
    {
      'title': 'Capacity warning',
      'message': 'Tech Nexus 2024 is 80% full.',
      'time': '2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'Organizer Alerts', subtitle: 'Stay up to date'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _alerts.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              final isRead = _readAlerts.contains(index);
              return Card(
                child: ListTile(
                  leading: Icon(
                    isRead ? Icons.notifications_none : Icons.notifications,
                    color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(alert['title']!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['message']!),
                      const SizedBox(height: 4),
                      Text(
                        alert['time']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? const Icon(Icons.check, color: Colors.green)
                      : TextButton(
                          onPressed: () => setState(() => _readAlerts.add(index)),
                          child: const Text('Read'),
                        ),
                  onTap: () => setState(() => _readAlerts.add(index)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
