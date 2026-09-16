import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// « Charger plus d’événements », en bas d’une liste du catalogue.
///
/// Un bouton explicite plutôt qu’un défilement infini : les filtres et la
/// recherche portent sur ce qui est déjà chargé, l’utilisateur doit donc
/// savoir qu’il existe une suite et choisir de la charger. N’affiche rien
/// quand il n’y a plus rien à charger.
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
        onPressed: () =>
            ref.read(catalogueExtraPagesProvider.notifier).loadMore(),
      ),
    );
  }
}
