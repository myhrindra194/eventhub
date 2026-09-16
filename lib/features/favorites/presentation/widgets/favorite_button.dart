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

/// Cœur qui bascule un événement dans les favoris du participant.
///
/// N’affiche rien pour un organisateur : les favoris sont une
/// fonctionnalité participant, et un contrôle qui ne fait rien pour le rôle
/// courant n’a pas lieu d’exister. Aucun toast en cas de succès — le cœur
/// plein *est* la confirmation.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    required this.eventId,
    super.key,
    this.onImage = true,
    this.size = 42,
  });

  final String eventId;

  /// Bouton rond dépoli au-dessus d’une photo, ou carré de 6 px sur une
  /// surface.
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
    // Les organisateurs gardent tous les droits participant, favoris compris.
    if (user == null) return const SizedBox.shrink();

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
