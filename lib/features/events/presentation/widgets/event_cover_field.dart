import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/event_image.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:flutter/material.dart';

/// Cover of an event: a link to an image hosted elsewhere, with a preview.
///
/// Without Cloud Storage (Spark plan) there is nothing to upload to, so the
/// organizer pastes an `https://` link — the way Luma or a Notion cover
/// accepts one. The preview answers the only question that matters ("is this
/// the right picture?") before publishing; while the field is blank or the
/// link is not yet valid, it shows the generated visual the event will keep,
/// so an event without a cover never looks broken.
class EventCoverField extends StatefulWidget {
  const EventCoverField({
    required this.controller,
    required this.seed,
    super.key,
    this.errorText,
  });

  final TextEditingController controller;

  /// Seed of the generated fallback visual (the event id, or the title).
  final String seed;

  /// A server-side error mapped back onto this field.
  final String? errorText;

  @override
  State<EventCoverField> createState() => _EventCoverFieldState();
}

class _EventCoverFieldState extends State<EventCoverField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(EventCoverField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = widget.controller.text.trim();
    final previewUrl = url.isNotEmpty && EventDraft.imageUrlError(url) == null
        ? url
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.brButton,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brButton,
              border: Border.all(color: t.border),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: EventImage(
                // Keyed by URL: a new link replaces the preview instead of
                // cross-fading from the previous picture.
                key: ValueKey(previewUrl),
                imageUrl: previewUrl,
                seed: widget.seed,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'https://…/affiche.jpg',
            prefixIcon: const Icon(Icons.link_rounded, size: 20),
            errorText: widget.errorText,
            suffixIcon: url.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Retirer l’image',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: widget.controller.clear,
                  ),
          ),
          validator: EventDraft.imageUrlError,
        ),
        if (previewUrl == null && url.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sans image, l’événement garde ce visuel généré.',
            style: context.textTheme.bodySmall?.copyWith(
              color: t.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
