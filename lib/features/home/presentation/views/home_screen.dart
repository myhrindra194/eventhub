import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/widgets/event_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsFutureProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final categories = ['All', 'Music', 'Tech', 'Sport'];

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // En-tête avec Mode Sombre/Clair & Profil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPLORE',
                        style: theme.textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Today in Paris',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Contrôle visible et animé du thème global.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            onPressed: () {
                              ref.read(themeModeProvider.notifier).state =
                                  isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                            icon: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark
                                  ? Colors.amber
                                  : theme.colorScheme.primary,
                            ),
                            tooltip: isDark ? 'Activer le mode clair' : 'Activer le mode sombre',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Photo de profil
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          radius: 20,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Barre de recherche
              TextField(
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Search music, tech, art...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              // Filtres de catégories
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
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(selectedCategoryProvider.notifier).setCategory(category);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Liste des événements
              Expanded(
                child: eventsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Erreur: $err',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  data: (events) {
                    if (events.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun événement disponible',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
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
    );
  }
}