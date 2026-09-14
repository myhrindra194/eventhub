import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/connectivity/connectivity_providers.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puts a thin "hors ligne" band above the whole app while the network is
/// down.
///
/// Not a blocking screen: Firestore serves cached data and queues writes, so
/// the user can keep browsing their tickets. The band only explains why fresh
/// data is not arriving. It takes the status-bar inset itself and removes it
/// from the app below, so no screen is pushed under the notch.
class OfflineAware extends ConsumerWidget {
  const OfflineAware({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unknown (plugin missing in tests) is treated as online.
    final online = ref.watch(isOnlineProvider).value ?? true;
    final t = context.tokens;
    final colors = t.neutralTone;

    return Column(
      children: [
        AnimatedSize(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: colors.solid,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: colors.onSolid,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              AppStrings.offlineBanner,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSolid),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: online
              ? child
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                ),
        ),
      ],
    );
  }
}
