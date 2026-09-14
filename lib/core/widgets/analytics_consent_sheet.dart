import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/analytics/analytics_consent.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks once for audience measurement.
///
/// Both answers are one tap and equally visible — a consent that is easier
/// to give than to refuse is not a consent. Dismissing the sheet counts as
/// "not now": it is offered again at the next sign-in.
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
          elevated: false,
          onPressed: () => _answer(context, ref, true),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: AppStrings.consentRefuse,
          elevated: false,
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
