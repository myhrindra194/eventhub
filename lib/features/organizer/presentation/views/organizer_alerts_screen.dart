import 'package:flutter/material.dart';
import '../../../../core/widgets/app_header.dart';

class OrganizerAlertsScreen extends StatefulWidget {
  const OrganizerAlertsScreen({super.key});

  @override
  State<OrganizerAlertsScreen> createState() => _OrganizerAlertsScreenState();
}

class _OrganizerAlertsScreenState extends State<OrganizerAlertsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'Organizer Alerts', subtitle: 'Stay up to date'),
        const Expanded(child: Center(child: Text('No alerts yet.'))),
      ],
    );
  }
}
