import 'dart:async';

import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Suivre" / "Abonné ✓".
///
/// Two visually distinct states rather than one button whose label changes:
/// the primary fill asks for the action, the quiet secondary confirms it is
/// done. Renders nothing on one's own profile. No toast — the button is the
/// confirmation.
class FollowButton extends ConsumerWidget {
  const FollowButton({
    required this.organizerId,
    super.key,
    this.expand = true,
  });

  final String organizerId;
  final bool expand;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.selectionClick());
    final result = await ref
        .read(followControllerProvider.notifier)
        .toggle(organizerId);
    if (result case Err(:final failure) when context.mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.id == organizerId) return const SizedBox.shrink();

    final following = ref.watch(isFollowingProvider(organizerId));
    final busy = ref.watch(followControllerProvider).isLoading;

    return Semantics(
      toggled: following,
      child: following
          ? AppButton.secondary(
              label: AppStrings.followingState,
              size: AppButtonSize.medium,
              expand: expand,
              elevated: false,
              onPressed: busy ? null : () => _toggle(context, ref),
            )
          : AppButton.primary(
              label: AppStrings.followAction,
              size: AppButtonSize.medium,
              expand: expand,
              elevated: false,
              onPressed: busy ? null : () => _toggle(context, ref),
            ),
    );
  }
}
