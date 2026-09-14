import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/favorites/application/favorites_providers.dart';
import 'package:eventhub/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Mes favoris" — events starred, most recent first.
///
/// Each row watches its event by id rather than filtering the catalogue: a
/// favourite may be sold out, past or far in the future, none of which the
/// upcoming-events feed is guaranteed to contain. A favourite whose event was
/// deleted stays visible, labelled, with the way to remove it.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.myFavorites)),
      body: AsyncValueWidget(
        value: ids,
        onRetry: () => ref.invalidate(favoriteIdsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: EmptyStateView(
          icon: Icons.favorite_border_rounded,
          title: AppStrings.noFavoritesTitle,
          message: AppStrings.noFavorites,
          action: AppButton.primary(
            label: AppStrings.exploreEvents,
            icon: Icons.explore_rounded,
            expand: false,
            elevated: false,
            onPressed: () => context.go(AppRoutes.events),
          ),
        ),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.huge,
          ),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) =>
              _FavoriteRow(key: ValueKey(list[index]), eventId: list[index]),
        ),
      ),
    );
  }
}

class _FavoriteRow extends ConsumerWidget {
  const _FavoriteRow({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));
    final t = context.tokens;

    return event.when(
      loading: () => const Skeleton(height: 110, radius: AppRadius.button),
      error: (_, __) => const SizedBox.shrink(),
      data: (e) {
        if (e == null) {
          return AppSurface(
            elevation: SurfaceElevation.flat,
            radius: AppRadius.button,
            child: Row(
              children: [
                Icon(Icons.link_off_rounded, color: t.textTertiary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.deletedEvent,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
                FavoriteButton(eventId: eventId, onImage: false, size: 36),
              ],
            ),
          );
        }
        return Stack(
          children: [
            EventResultTile(
              event: e,
              onTap: () => context.push(AppRoutes.eventDetailPath(e.id)),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: FavoriteButton(eventId: e.id, onImage: false, size: 34),
            ),
          ],
        );
      },
    );
  }
}
