import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/analytics/analytics_consent.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demande une seule fois le consentement à la mesure d’audience.
///
/// Les deux réponses tiennent en un appui et sont aussi visibles l’une que
/// l’autre — un consentement plus facile à donner qu’à refuser n’en est pas
/// un. Fermer la feuille vaut « pas maintenant » : elle est reproposée à la
/// prochaine connexion.
Future<void> showAnalyticsConsentSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const _ConsentSheet(),
  );
}

class _ConsentSheet extends ConsumerWidget {
  const _ConsentSheet();

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    bool granted,
  ) async {
    await ref.read(analyticsConsentProvider.notifier).set(granted);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSheet(
      title: AppStrings.consentTitle,
      subtitle: AppStrings.consentBody,
      actions: [
        AppButton.primary(
          label: AppStrings.consentAccept,
          onPressed: () => _answer(context, ref, true),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: AppStrings.consentRefuse,
          onPressed: () => _answer(context, ref, false),
        ),
      ],
      child: Text(
        AppStrings.consentDetails,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
      ),
    );
  }
}
