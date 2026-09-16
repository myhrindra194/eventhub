import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/presentation/widgets/share_event_sheet.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Publication confirmation.
///
/// Referme la boucle de création par une preuve : l'événement tel que les
/// participants le verront, puis les deux gestes qu'un organisateur fait
/// réellement ensuite — le partager, ou revenir au tableau de bord et le
/// regarder se remplir.
class EventPublishedScreen extends ConsumerWidget {
  const EventPublishedScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId)).value;
    final text = context.textTheme;

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Center(
                child: SuccessHero(icon: Icons.rocket_launch_rounded),
              ),
              const SizedBox(height: AppSpacing.huge),
              Text(
                AppStrings.eventLive,
                style: text.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.eventLiveHint,
                style: text.bodyLarge?.copyWith(
                  color: context.tokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (event != null)
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: EventImage(
                          imageUrl: event.imageUrl,
                          seed: event.id,
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: text.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${AppDateFormats.dayMonthTime(event.startsAt)}'
                              ' · ${event.capacity} places',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const AppBadge(
                        label: AppStrings.live,
                        tone: AppTone.success,
                        style: BadgeStyle.solid,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              PublicLinkField(url: AppLinks.event(eventId)),
              const Spacer(flex: 2),
              AppButton.primary(
                label: AppStrings.viewDashboard,
                onPressed: () => context.go(AppRoutes.organizerEvents),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                label: AppStrings.share,
                onPressed: event == null
                    ? null
                    : () => showShareEventSheet(context, event),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
