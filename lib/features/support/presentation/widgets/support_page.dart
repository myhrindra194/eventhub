import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editorial layout shared by the help, privacy and about pages.
///
/// These are pages people *read*, so they are set like an article rather
/// than like a settings list: a coloured eyebrow, a headline that makes a
/// claim, a lead paragraph, a hairline rule, then the body. Left-aligned,
/// no cards around paragraphs — a card per paragraph turns prose into a
/// dashboard.
class SupportPage extends StatelessWidget {
  const SupportPage({
    required this.title,
    required this.headline,
    required this.lead,
    required this.children,
    super.key,
    this.eyebrow,
  });

  /// App bar title — the name of the page.
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
      appBar: AppBar(title: Text(title)),
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

/// `01  Title` / body — a numbered paragraph. The number sits in its own
/// column so titles align on a common edge, like a printed contents page.
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

/// Questions between hairlines, one open at a time per tap. No box around
/// the group: the rules above and below are enough to hold it together.
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
                  // A plus that turns into a cross: the glyph states what the
                  // next tap will do.
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

/// "Toujours bloqué ?" — the way out of a help page that did not help.
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppLinks.supportEmail));
    if (context.mounted) context.showSuccess('Adresse copiée.');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return AppSurface(
      elevation: SurfaceElevation.flat,
      child: Row(
        children: [
          const IconTile(icon: Icons.mail_outline_rounded, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toujours bloqué ?', style: text.titleMedium),
                Text(
                  '${AppLinks.supportEmail} · réponse sous 48 h ouvrées',
                  style: text.bodySmall,
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
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}
