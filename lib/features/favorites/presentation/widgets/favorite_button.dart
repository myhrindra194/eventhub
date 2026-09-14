import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/favorites/application/favorites_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Heart toggling an event in the participant's favourites.
///
/// Renders nothing for an organizer: favourites are a participant feature,
/// and a control that does nothing for the current role should not exist.
/// No toast on success — the filled heart *is* the confirmation.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    required this.eventId,
    super.key,
    this.onImage = true,
    this.size = 42,
  });

  final String eventId;

  /// Frosted round button over photography, or a 6 px square on a surface.
  final bool onImage;
  final double size;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.selectionClick());
    final result = await ref
        .read(favoriteControllerProvider.notifier)
        .toggle(eventId);
    if (result case Err(:final failure) when context.mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isParticipant) return const SizedBox.shrink();

    final active = ref.watch(isFavoriteProvider(eventId));
    final t = context.tokens;
    final icon = active
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;
    final tooltip = active ? AppStrings.removeFavorite : AppStrings.addFavorite;

    return Semantics(
      toggled: active,
      child: onImage
          ? OverlayIconButton(
              icon: icon,
              tooltip: tooltip,
              size: size,
              foreground: active ? t.danger.solid : Colors.white,
              onPressed: () => _toggle(context, ref),
            )
          : IconActionButton(
              icon: icon,
              tooltip: tooltip,
              size: size,
              color: active ? t.danger.fg : t.textSecondary,
              onPressed: () => _toggle(context, ref),
            ),
    );
  }
}
