import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clears every filter in one call — the escape hatch every empty result
/// offers, so a user is never stuck staring at a list they filtered away.
extension EventFilterReset on WidgetRef {
  void resetEventFilters() {
    read(eventSearchQueryProvider.notifier).clear();
    read(eventCategoryFilterProvider.notifier).select(null);
    read(eventPeriodFilterProvider.notifier).select(EventPeriod.any);
    read(eventSortOrderProvider.notifier).select(EventSort.dateAsc);
    read(hideSoldOutProvider.notifier).set(false);
  }
}

/// Search input bound to `eventSearchQueryProvider`.
///
/// In [readOnly] mode it is a decoy that navigates to the search tab: the
/// home screen keeps the affordance without paying for a live query on
/// every keystroke of the feed.
class EventSearchField extends ConsumerStatefulWidget {
  const EventSearchField({
    super.key,
    this.hint = AppStrings.searchEvents,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  ConsumerState<EventSearchField> createState() => _EventSearchFieldState();
}

class _EventSearchFieldState extends ConsumerState<EventSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(eventSearchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(eventSearchQueryProvider);
    // Keep the field in sync when the query is cleared from elsewhere
    // (empty-state button, filter sheet reset).
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return AppSearchField(
      hint: widget.hint,
      controller: _controller,
      value: query,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: ref.read(eventSearchQueryProvider.notifier).set,
      onClear: () {
        _controller.clear();
        ref.read(eventSearchQueryProvider.notifier).clear();
      },
    );
  }
}

/// Horizontal category rail.
///
/// A selected pill takes the category's own hue rather than the brand
/// colour: after two uses, the colour *is* the category, and users start
/// aiming at the colour instead of reading the label.
class CategoryFilterRail extends ConsumerWidget {
  const CategoryFilterRail({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(eventCategoryFilterProvider);
    final notifier = ref.read(eventCategoryFilterProvider.notifier);
    final t = context.tokens;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        children: [
          _Pill(
            label: AppStrings.allCategories,
            icon: Icons.grid_view_rounded,
            color: t.brand,
            selected: selected == null,
            onTap: () => notifier.select(null),
          ),
          for (final category in EventCategory.values) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: category.label,
              icon: category.icon,
              color: category.color(context),
              selected: selected == category,
              onTap: () => notifier.toggle(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: selected ? color : t.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: selected ? color : t.border),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : t.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button opening the advanced filter sheet, badged with the number of
/// active filters.
class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(activeFilterCountProvider);
    final t = context.tokens;
    final active = count > 0;

    return Material(
      color: active ? t.brand : t.surface,
      borderRadius: AppRadius.brSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEventFilterSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(color: active ? t.brand : t.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: active ? t.textOnBrand : t.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppStrings.filters,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active ? t.textOnBrand : t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: t.textOnBrand,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Advanced filters: period, sort order, availability.
///
/// Applied **live** while the sheet is open, so the result count updates as
/// the user tweaks. There is no "Apply" that could be forgotten — the
/// primary button simply closes the sheet.
Future<void> showEventFilterSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  builder: (context) => const _FilterSheet(),
);

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(eventPeriodFilterProvider);
    final sort = ref.watch(eventSortOrderProvider);
    final hideSoldOut = ref.watch(hideSoldOutProvider);
    final count = ref.watch(filteredEventsProvider).value?.length ?? 0;
    final t = context.tokens;

    return AppSheet(
      title: AppStrings.filters,
      subtitle: '$count ${AppStrings.results.toLowerCase()}',
      actions: [
        AppButton.primary(
          label: AppStrings.applyFilters,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.ghost(
          label: AppStrings.resetFilters,
          expand: true,
          onPressed: () => ref.resetEventFilters(),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel(AppStrings.period),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in EventPeriod.values)
                  _Choice(
                    label: p.label,
                    selected: p == period,
                    onTap: () =>
                        ref.read(eventPeriodFilterProvider.notifier).select(p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(AppStrings.sortBy),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in EventSort.values)
                  _Choice(
                    label: s.label,
                    selected: s == sort,
                    onTap: () =>
                        ref.read(eventSortOrderProvider.notifier).select(s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              elevation: SurfaceElevation.flat,
              color: t.surfaceSunken,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: hideSoldOut,
                onChanged: (_) =>
                    ref.read(hideSoldOutProvider.notifier).toggle(),
                title: Text(
                  AppStrings.onlyAvailable,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: selected ? t.brandSoft : t.surfaceSunken,
      borderRadius: AppRadius.brPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 15, color: t.brand),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? t.brand : t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
