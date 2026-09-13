import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/state_card.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/providers/search_provider.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../widgets/home_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Converts an [EventCategory] enum value to a human-readable label
  /// matching the filter chips shown in the UI.
  String _categoryName(EventCategory category) {
    return category.name.isNotEmpty
        ? category.name[0].toUpperCase() +
            category.name.substring(1).toLowerCase()
        : category.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchEventsNotifierProvider);

    // On utilise la recherche si le query est non vide, sinon le flux temps réel.
    final displayAsync = searchQuery.isNotEmpty
        ? searchResults
        : ref.watch(eventsStreamProvider).whenData(
            (events) => events.where((event) {
              final categoryName = _categoryName(event.category);
              return selectedCategory == 'All' ||
                  categoryName == selectedCategory;
            }).toList(),
          );

    // Aligné avec EventCategory : conference, concert, sport, workshop,
    // festival, other. On garde des labels lisibles.
    final categories = [
      'All',
      'Concert',
      'Conference',
      'Sport',
      'Workshop',
      'Festival',
    ];

    final theme = Theme.of(context);

    // Show the skeleton loader while data is loading.
    if (displayAsync.isLoading) {
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
                      child: displayAsync.when(
                        loading: () => const HomeSkeleton(),
                        error: (err, stack) => Center(
                          child: StateCard.connectionLost(
                            onRetry: () {
                              if (searchQuery.isNotEmpty) {
                                ref
                                    .read(searchEventsNotifierProvider.notifier)
                                    .search(searchQuery);
                              } else {
                                ref.invalidate(eventsStreamProvider);
                              }
                            },
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
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .setQuery('');
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
                                category: event.category.name,
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
