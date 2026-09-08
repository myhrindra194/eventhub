import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart'; // ◄-- On pointe vers home_screen.dart

class MainWrapperScreen extends ConsumerWidget {
  const MainWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const HomeScreen(), // ◄-- Onglet 0
      const Center(child: Text('Search Screen', style: TextStyle(color: Colors.white))),
      const Center(child: Text('Tickets Screen', style: TextStyle(color: Colors.white))),
      const Center(child: Text('Profile Screen', style: TextStyle(color: Colors.white))),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}