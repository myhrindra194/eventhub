import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OrganizerSettingsScreen extends ConsumerStatefulWidget {
  const OrganizerSettingsScreen({super.key});

  @override
  ConsumerState<OrganizerSettingsScreen> createState() =>
      _OrganizerSettingsScreenState();
}

class _OrganizerSettingsScreenState
    extends ConsumerState<OrganizerSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _publicProfile = true;
  bool _emailMarketing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(
          title: 'Organizer Settings',
          subtitle: 'Manage your account',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSection('Notifications'),
              SwitchListTile.adaptive(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive real-time updates'),
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              SwitchListTile.adaptive(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates via email'),
                value: _emailMarketing,
                onChanged: (value) => setState(() => _emailMarketing = value),
              ),
              const SizedBox(height: 24),

              _buildSection('Profile'),
              SwitchListTile.adaptive(
                title: const Text('Public Profile'),
                subtitle: const Text('Allow participants to view your profile'),
                value: _publicProfile,
                onChanged: (value) => setState(() => _publicProfile = value),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to edit profile
                },
              ),
              const SizedBox(height: 24),

              _buildSection('Account'),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to change password
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to help
                },
              ),
              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRouter.welcome, (route) => false);
  }
}
