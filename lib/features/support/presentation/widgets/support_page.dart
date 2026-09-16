import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mise en page éditoriale partagée par les pages aide, confidentialité et à
/// propos.
///
/// Ce sont des pages que l’on *lit* : elles sont donc composées comme un
/// article plutôt que comme une liste de réglages — un surtitre coloré, un
/// titre qui affirme quelque chose, un chapô, un filet, puis le corps de
/// texte. Alignées à gauche, sans cartes autour des paragraphes : une carte
/// par paragraphe transforme de la prose en tableau de bord.
class SupportPage extends StatelessWidget {
  const SupportPage({
    required this.title,
    required this.headline,
    required this.lead,
    required this.children,
    super.key,
    this.eyebrow,
  });

  /// Titre de l’app bar — le nom de la page.
  final String title;
  final String? eyebrow;
  final String headline;
  final String lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return AppScaffold(
      dense: true,
      appBar: AppTopBar.subPage(title: title, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.giant,
        ),
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: text.labelMedium?.copyWith(color: t.brand),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(headline, style: text.headlineMedium?.copyWith(height: 1.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            lead,
            style: text.bodyLarge?.copyWith(
              color: t.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: t.border),
          const SizedBox(height: AppSpacing.xxl),
          ...children,
        ],
      ),
    );
  }
}

/// `01  Titre` / corps — un paragraphe numéroté. Le numéro occupe sa propre
/// colonne pour que les titres s’alignent sur un bord commun, comme sur une
/// page de sommaire imprimée.
class NumberedSection extends StatelessWidget {
  const NumberedSection({
    required this.number,
    required this.title,
    required this.body,
    super.key,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                number,
                style: text.labelMedium?.copyWith(
                  color: t.brand,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: text.bodyMedium?.copyWith(
                    color: t.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

/// Des questions entre filets, une seule ouverte à la fois par appui. Pas de
/// cadre autour du groupe : les filets au-dessus et en dessous suffisent à le
/// tenir.
class FaqGroup extends StatelessWidget {
  const FaqGroup({required this.entries, super.key});

  final List<FaqEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.border),
          bottom: BorderSide(color: t.border),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.borderSubtle),
            _FaqTile(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.entry});

  final FaqEntry entry;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Semantics(
      expanded: _open,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.question,
                      style: text.titleMedium?.copyWith(
                        color: _open ? t.brand : t.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Un plus qui se change en croix : le glyphe annonce ce que
                  // fera le prochain appui.
                  AnimatedRotation(
                    turns: _open ? 0.125 : 0,
                    duration: AppMotion.short,
                    curve: AppMotion.standard,
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: _open ? t.brand : t.textTertiary,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          right: AppSpacing.xxxl,
                        ),
                        child: Text(
                          widget.entry.answer,
                          style: text.bodyMedium?.copyWith(
                            color: t.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Toujours bloqué ? » — la porte de sortie d’une page d’aide qui n’a pas
/// aidé. Elle mène au formulaire « Nous contacter », qui envoie un vrai email
/// à l'équipe, plutôt qu'à une adresse à recopier.
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return AppSurface(
      child: Row(
        children: [
          const IconTile(icon: Icons.mail_outline_rounded, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toujours bloqué ?', style: text.titleMedium),
                Text('Réponse sous 48 h ouvrées', style: text.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.contact),
            style: TextButton.styleFrom(
              foregroundColor: t.brand,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brButton,
              ),
            ),
            child: const Text('Écrire'),
          ),
        ],
      ),
    );
  }
}
