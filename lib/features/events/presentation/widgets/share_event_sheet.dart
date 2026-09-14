import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Share an event.
///
/// Clipboard-based on purpose. The native share sheet (`share_plus`) needs
/// per-platform setup and behaves differently on web and desktop; copying a
/// link works identically everywhere, and the two things people actually
/// paste — a bare link or a ready-made invitation — are both one tap away.
Future<void> showShareEventSheet(BuildContext context, Event event) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) {
      // The toast is raised on the *page* context once the sheet is gone:
      // shown from inside the sheet, it would slide in behind it.
      void done(String message) {
        Navigator.of(sheetContext).pop();
        if (context.mounted) context.showSuccess(message);
      }

      return AppSheet(
        title: AppStrings.shareTitle,
        subtitle: AppStrings.shareLead,
        actions: [
          AppButton.secondary(
            label: AppStrings.copyInvitation,
            icon: Icons.notes_rounded,
            elevated: false,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _invitation(event)));
              done(AppStrings.invitationCopied);
            },
          ),
        ],
        child: PublicLinkField(
          url: AppLinks.event(event.id),
          onCopied: () => done(AppStrings.linkCopied),
        ),
      );
    },
  );
}

/// Plain text, no emoji and no markdown: it has to survive SMS, WhatsApp
/// and an email client alike.
String _invitation(Event event) {
  final seats = event.isFull
      ? 'Complet pour le moment.'
      : '${event.availablePlaces} places sur ${event.capacity} encore libres.';
  return '${event.title}\n'
      '${AppDateFormats.date(event.startsAt)} à '
      '${AppDateFormats.time(event.startsAt)}\n'
      '${event.location}\n'
      '\n'
      'Entrée gratuite. $seats\n'
      'Réserver : ${AppLinks.event(event.id)}';
}

/// "Lien public · eventhub.app/e/… · Copier" — the field from the 002
/// success board, reused by the share sheet.
class PublicLinkField extends StatelessWidget {
  const PublicLinkField({required this.url, super.key, this.onCopied});

  final String url;

  /// Called after the copy. When null, the field confirms with its own
  /// toast.
  final VoidCallback? onCopied;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (onCopied != null) return onCopied!();
    if (context.mounted) context.showSuccess(AppStrings.linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: t.brand),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(AppStrings.publicLink),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppLinks.displayable(url),
                  style: text.bodyMedium?.copyWith(color: t.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _copy(context),
            style: TextButton.styleFrom(
              foregroundColor: t.brand,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brButton,
              ),
            ),
            child: const Text(AppStrings.copy),
          ),
        ],
      ),
    );
  }
}
