import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:flutter/material.dart';

/// Shared chrome for the authentication screens.
///
/// Centre-weighted, following the reference direction: a compact top bar
/// (circular back · mark · optional action), then a centred hero glyph,
/// title and lead, then the form. Centring works here — and only here —
/// because these screens hold one short column with a single decision; the
/// browsing screens stay left-aligned, where a ragged centre would fight the
/// scan pattern of a list.
///
/// Deliberately absent: an appearance toggle. It lives in Settings.
class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.lead,
    required this.children,
    super.key,
    this.onBack,
    this.trailing,
    this.hero,
    this.step,
    this.footer,
    this.showMark = true,
  });

  final String title;
  final String lead;
  final List<Widget> children;
  final VoidCallback? onBack;

  /// Optional top-right action ("Passer", a step counter…).
  final Widget? trailing;

  /// Centred glyph above the title. Defaults to nothing; screens that need a
  /// subject (a padlock for recovery) pass [AuthHeroIcon].
  final Widget? hero;

  /// `(index, total)` — a discreet counter under the title.
  final (int, int)? step;
  final Widget? footer;

  /// The small brand mark in the middle of the top bar.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final gutter = context.gutter;

    return AppScaffold(
      // Flat by intent: no ambient blooms, no elevated surfaces, no shadows.
      showBlooms: false,
      constrainWidth: false,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsiveColumn(
          // "Pin the footer to the bottom when there is room, scroll the
          // whole thing when there is not" — the two-sliver form.
          //
          // The obvious solutions both break: `IntrinsicHeight` measures flex
          // children as zero and then pins the column to that under-measured
          // height, and a lone `SliverFillRemaining(hasScrollBody: false)`
          // containing a `Spacer` is handed an exact viewport height it
          // cannot exceed. Here the content keeps its natural height and the
          // second sliver simply eats whatever is left — zero on a short
          // screen, which is exactly when scrolling should take over.
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.md,
                    gutter,
                    footer == null ? AppSpacing.xxl : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        onBack: onBack,
                        trailing: trailing,
                        showMark: showMark,
                      ),
                      SizedBox(
                        height: context.responsive(medium: 28, small: 18),
                      ),
                      if (hero != null) ...[
                        Center(child: hero),
                        SizedBox(
                          height: context.responsive(medium: 24, small: 18),
                        ),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          height: 1.12,
                          fontSize: context.responsive(
                            medium: 29,
                            small: 25,
                            expanded: 33,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            lead,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge?.copyWith(
                              color: t.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      if (step != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: _StepDots(index: step!.$1, total: step!.$2),
                        ),
                      ],
                      SizedBox(
                        height: context.responsive(medium: 30, small: 22),
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.xxl,
                      gutter,
                      AppSpacing.xxl,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: footer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `[back] · mark · [action]` — the three slots keep the mark optically
/// centred whether or not the side slots are filled.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.trailing,
    required this.showMark,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    const slot = 44.0;

    return SizedBox(
      height: slot,
      child: Row(
        children: [
          SizedBox(
            width: slot,
            child: onBack == null ? null : CircleBackButton(onPressed: onBack!),
          ),
          Expanded(
            child: Center(
              child: showMark
                  ? const AppLogo(size: 34)
                  : const SizedBox.shrink(),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: slot),
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox(width: slot),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular tinted disc holding the subject of the screen.
class AuthHeroIcon extends StatelessWidget {
  const AuthHeroIcon({
    required this.icon,
    super.key,
    this.tone = AppTone.brand,
  });

  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    final size = context.responsive(medium: 92.0, small: 76.0);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.42, color: colors.fg),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.standard,
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? t.brand : t.borderStrong,
              borderRadius: AppRadius.brPill,
            ),
          ),
        ],
      ],
    );
  }
}

/// Four-segment password strength meter.
///
/// Scored on what actually matters — length first, then variety — rather
/// than on a regex that rejects a perfectly good passphrase for lacking a
/// punctuation mark.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp('[A-Z]').hasMatch(password) &&
        RegExp('[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp('[0-9]').hasMatch(password) ||
        RegExp('[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final score = _score;

    final (tone, label) = switch (score) {
      0 => (AppTone.neutral, ''),
      1 => (AppTone.danger, AppStrings.passwordWeak),
      2 => (AppTone.warning, AppStrings.passwordFair),
      3 => (AppTone.info, AppStrings.passwordGood),
      _ => (AppTone.success, AppStrings.passwordStrong),
    };
    final colors = t.resolve(tone);

    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.standard,
              height: 4,
              decoration: BoxDecoration(
                color: i <= score ? colors.solid : t.borderStrong,
                borderRadius: AppRadius.brPill,
              ),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.fg),
          ),
        ),
      ],
    );
  }
}

/// "Pas encore de compte ? S'inscrire".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // Wrap, not Row: two variable-length strings on one line overflow the
    // moment the copy or the text scale changes.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        Text(prompt, style: text.bodyMedium),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: text.bodyMedium?.copyWith(
              color: t.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
