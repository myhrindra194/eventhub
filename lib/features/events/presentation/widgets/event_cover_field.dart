import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/event_image.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:flutter/material.dart';

/// Couverture d’un événement : un lien vers une image hébergée ailleurs,
/// avec un aperçu.
///
/// Sans Cloud Storage (plan Spark), il n’y a nulle part où envoyer un
/// fichier : l’organisateur colle donc un lien `https://`, comme Luma ou
/// une couverture Notion l’acceptent. L’aperçu répond avant publication à
/// la seule question qui compte (« est-ce la bonne image ? ») ; tant que le
/// champ est vide ou que le lien n’est pas encore valide, il montre le
/// visuel généré que l’événement conservera, pour qu’un événement sans
/// couverture n’ait jamais l’air cassé.
class EventCoverField extends StatefulWidget {
  const EventCoverField({
    required this.controller,
    required this.seed,
    super.key,
    this.errorText,
  });

  final TextEditingController controller;

  /// Graine du visuel généré de repli (l’id de l’événement, ou son titre).
  final String seed;

  /// Une erreur venue du serveur, rapportée sur ce champ.
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
                // Clé sur l’URL : un nouveau lien remplace l’aperçu au lieu
                // de fondre depuis l’image précédente.
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
