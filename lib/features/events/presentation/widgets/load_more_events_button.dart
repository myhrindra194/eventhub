import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Charger plus d'événements" at the end of a catalogue list.
///
/// An explicit button rather than infinite scroll: filters and search run
/// over what is loaded, so the user should know when more exists and choose
/// to fetch it. Renders nothing when there is nothing more.
class LoadMoreEventsButton extends ConsumerWidget {
  const LoadMoreEventsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canLoadMoreEventsProvider)) return const SizedBox.shrink();
    final loading = ref.watch(catalogueExtraPagesProvider).loading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      child: AppButton.secondary(
        label: AppStrings.loadMoreEvents,
        isLoading: loading,
        elevated: false,
        onPressed: () =>
            ref.read(catalogueExtraPagesProvider.notifier).loadMore(),
      ),
    );
  }
}
