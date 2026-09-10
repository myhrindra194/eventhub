import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/views/search_screen.dart';
import '../../../reservations/presentation/views/mes_billets_screen.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';

class MainWrapperScreen extends ConsumerWidget {
  const MainWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderStyle = AppTypography.bodyLarge(isDark);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    final List<Widget> screens = [
      const HomeScreen(), // Tab 0.
      const SearchScreen(), // Tab 1.
      const MesBilletsScreen(), // Tab 2.
      Column(
        children: [
          AppHeader(
            title: 'Profile',
            subtitle: 'Manage your account',
            onLogout: () => _logout(context, ref),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null) ...[
                    Text(user.name, style: AppTypography.display(isDark)),
                    const SizedBox(height: 8),
                    Text(user.email, style: placeholderStyle),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
      floatingActionButton: currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              tooltip: 'Log out',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.welcome, (route) => false);
  }
}
