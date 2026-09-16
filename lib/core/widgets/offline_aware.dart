import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/connectivity/connectivity_providers.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pose un mince bandeau « hors ligne » au-dessus de toute l'application tant
/// que le réseau est absent.
///
/// Ce n'est pas un écran bloquant : Firestore sert les données du cache et met
/// les écritures en file, l'utilisateur peut donc continuer à consulter ses
/// billets. Le bandeau explique seulement pourquoi rien de neuf n'arrive. Il
/// prend lui-même la marge de la barre d'état et la retire à l'application
/// située dessous, de sorte qu'aucun écran ne se retrouve poussé sous
/// l'encoche.
class OfflineAware extends ConsumerWidget {
  const OfflineAware({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // État inconnu — greffon absent en test — traité comme « en ligne ».
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
