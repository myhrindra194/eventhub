import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/state_card.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../widgets/home_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsFutureProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categories = ['All', 'Music', 'Tech', 'Sport'];

    final theme = Theme.of(context);

    // Show the skeleton loader while data is loading.
    if (eventsAsync.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Column(
          children: [
            AppHeader(title: 'Home', subtitle: 'Discover the best events'),
            Expanded(child: HomeSkeleton()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const AppHeader(title: 'Home', subtitle: 'Discover the best events'),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Search bar.
                    const AppSearchField(
                      hintText: 'Search music, tech, art...',
                    ),
                    const SizedBox(height: 16),
                    // Category filters.
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppFilterChip(
                              label: category,
                              isSelected: isSelected,
                              onTap: () {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .setCategory(category);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Event list.
                    Expanded(
                      child: eventsAsync.when(
                        loading: () => const HomeSkeleton(),
                        error: (err, stack) => Center(
                          child: StateCard.connectionLost(
                            onRetry: () => ref.refresh(eventsFutureProvider),
                          ),
                        ),
                        data: (events) {
                          if (events.isEmpty) {
                            return Center(
                              child: StateCard.noEvents(
                                onClearFilters: () {
                                  ref
                                      .read(selectedCategoryProvider.notifier)
                                      .setCategory('All');
                                },
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return EventCard(
                                title: event.title,
                                month: event.month,
                                day: event.day,
                                location: event.location,
                                time: event.time,
                                imagePath: event.imageUrl,
                                category: event.category,
                                categoryColor: theme.colorScheme.primary,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.eventDetail,
                                    arguments: event.id,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
