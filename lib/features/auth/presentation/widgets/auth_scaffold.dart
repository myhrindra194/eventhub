import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:flutter/material.dart';

/// Habillage commun aux écrans d’authentification.
///
/// Composition centrée, dans la direction de la référence : une barre
/// supérieure compacte (retour circulaire · marque · action optionnelle),
/// puis un glyphe héros centré, le titre et l’accroche, puis le formulaire.
/// Le centrage fonctionne ici — et seulement ici — parce que ces écrans
/// tiennent en une courte colonne portant une seule décision ; les écrans de
/// navigation, eux, restent alignés à gauche, là où un centre irrégulier
/// contrarierait le balayage visuel d’une liste.
///
/// Volontairement absente : une bascule d’apparence. Elle vit dans les
/// réglages.
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

  /// Action optionnelle en haut à droite (« Passer », un compteur d’étapes…).
  final Widget? trailing;

  /// Glyphe centré au-dessus du titre. Rien par défaut ; les écrans qui ont
  /// besoin d’un sujet (un cadenas pour la récupération) passent un
  /// [AuthHeroIcon].
  final Widget? hero;

  /// `(index, total)` — un compteur discret sous le titre.
  final (int, int)? step;
  final Widget? footer;

  /// La petite marque au centre de la barre supérieure.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final gutter = context.gutter;

    return AppScaffold(
      // Plat par choix : pas de halos d’ambiance, pas de surfaces en
      // élévation, pas d’ombres.
      showBlooms: false,
      constrainWidth: false,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsiveColumn(
          // « Coller le pied de page en bas quand il y a la place, faire
          // défiler l’ensemble sinon » — la forme à deux slivers.
          //
          // Les deux solutions évidentes échouent : `IntrinsicHeight` mesure
          // les enfants flex à zéro puis fige la colonne sur cette hauteur
          // sous-évaluée, et un `SliverFillRemaining(hasScrollBody: false)`
          // seul contenant un `Spacer` se voit imposer une hauteur de
          // viewport exacte qu’il ne peut pas dépasser. Ici le contenu garde
          // sa hauteur naturelle et le second sliver se contente d’avaler ce
          // qui reste — zéro sur un écran court, c’est-à-dire précisément
          // quand le défilement doit prendre le relais.
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

/// `[back] · mark · [action]` — les trois emplacements gardent la marque
/// optiquement centrée, que les emplacements latéraux soient remplis ou non.
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

/// Disque circulaire teinté qui porte le sujet de l’écran.
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

/// Jauge de robustesse du mot de passe, en quatre segments.
///
/// Notée sur ce qui compte vraiment — la longueur d’abord, puis la variété —
/// plutôt que sur une expression régulière qui rejetterait une phrase de
/// passe parfaitement solide au motif qu’il lui manque un signe de
/// ponctuation.
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
                borderRadius: AppRadius.brButton,
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

/// « Pas encore de compte ? S’inscrire ».
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

    // Wrap, et non Row : deux chaînes de longueur variable sur une même ligne
    // débordent dès que le texte ou son échelle change.
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
