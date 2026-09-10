import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../events/presentation/views/search_screen.dart';
import '../../../reservations/presentation/views/mes_billets_screen.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart'; // ◄-- On pointe vers home_screen.dart

class MainWrapperScreen extends ConsumerWidget {
  const MainWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderStyle = AppTypography.bodyLarge(isDark);

    final List<Widget> screens = [
      const HomeScreen(), // Tab 0.
      const SearchScreen(), // Tab 1.
      const MesBilletsScreen(), // Tab 2.
      Column(
        children: [
          const AppHeader(title: 'Profile', subtitle: 'Manage your account'),
          Expanded(
            child: Center(child: Text('Profile', style: placeholderStyle)),
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
    );
  }
}
