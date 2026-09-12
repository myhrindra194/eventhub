import 'package:flutter/material.dart';
import '../widgets/organizer_bottom_nav_bar.dart';
import 'organizer_events_screen.dart';
import 'organizer_alerts_screen.dart';
import 'organizer_stats_screen.dart';
import 'organizer_settings_screen.dart';

class OrganizerMainScreen extends StatefulWidget {
  const OrganizerMainScreen({super.key});

  @override
  State<OrganizerMainScreen> createState() => _OrganizerMainScreenState();
}

class _OrganizerMainScreenState extends State<OrganizerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OrganizerEventsScreen(),
    const OrganizerStatsScreen(),
    const OrganizerAlertsScreen(),
    const OrganizerSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: OrganizerBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
