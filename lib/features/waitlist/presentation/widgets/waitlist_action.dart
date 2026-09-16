import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/waitlist/application/waitlist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remplace le bouton « Complet » désactivé d’un événement complet.
///
/// Une impasse devient un engagement : rejoindre la file, et être prévenu
/// quand une place se libère. Une fois en file, la barre le dit en toutes
/// lettres et propose la sortie — l’état doit se lire sans avoir à se
/// souvenir d’avoir appuyé sur quoi que ce soit.
class WaitlistAction extends ConsumerWidget {
  const WaitlistAction({required this.event, super.key});

  final Event event;

  Future<void> _run(
    BuildContext context,
    Future<Result<void>> Function() action,
    String success,
  ) async {
    final result = await action();
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(success);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(isOnWaitlistProvider(event.id)).value ?? false;
    final busy = ref.watch(waitlistControllerProvider).isLoading;
    final controller = ref.read(waitlistControllerProvider.notifier);
    final text = context.textTheme;

    if (!waiting) {
      return AppButton.primary(
        label: AppStrings.joinWaitlist,
        isLoading: busy,
        onPressed: () => _run(
          context,
          () => controller.join(event),
          AppStrings.waitlistJoined,
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.hourglass_top_rounded, color: context.tokens.warning.fg),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.onWaitlist, style: text.titleSmall),
              Text(
                AppStrings.waitlistHint,
                style: text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton.secondary(
          label: AppStrings.leaveWaitlist,
          size: AppButtonSize.medium,
          expand: false,
          isLoading: busy,
          onPressed: () => _run(
            context,
            () => controller.leave(event.id),
            AppStrings.waitlistLeft,
          ),
        ),
      ],
    );
  }
}
