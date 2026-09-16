import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/onboarding/application/onboarding_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _Slide {
  const _Slide({
    required this.kicker,
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
  });

  final String kicker;
  final String title;
  final String body;
  final IconData icon;
  final AppTone tone;
}

const _slides = <_Slide>[
  _Slide(
    kicker: AppStrings.onboarding1Kicker,
    title: AppStrings.onboarding1Title,
    body: AppStrings.onboarding1Body,
    icon: Icons.explore_outlined,
    tone: AppTone.brand,
  ),
  _Slide(
    kicker: AppStrings.onboarding2Kicker,
    title: AppStrings.onboarding2Title,
    body: AppStrings.onboarding2Body,
    icon: Icons.confirmation_number_outlined,
    tone: AppTone.accent,
  ),
  _Slide(
    kicker: AppStrings.onboarding3Kicker,
    title: AppStrings.onboarding3Title,
    body: AppStrings.onboarding3Body,
    icon: Icons.insights_outlined,
    tone: AppTone.success,
  ),
];

/// Carrousel de premier lancement.
///
/// **Pourquoi cette composition et pas une autre.** Cet écran est pris en
/// sandwich entre le splash et la connexion, et ces deux-là sont centrés : une
/// marque au trait posée sur un fond uni d'un côté, une carte de champs
/// centrée de l'autre. Une version alignée à gauche, si soignée soit-elle, se
/// lit alors comme un morceau d'une autre application. L'onboarding revient
/// donc au centre, et emprunte au splash son vocabulaire : un dessin **au
/// trait**, sans tuile ni pastille colorée derrière lui — le fond coloré était
/// précisément le réflexe de gabarit qu'il fallait abandonner.
///
/// La progression reste une **règle segmentée** plutôt qu'une rangée de
/// points : elle occupe la largeur et répond à la barre de chargement du
/// splash, ce qui prolonge la même idée d'avancement d'un écran à l'autre.
///
/// « Passer » est visible dès la première frame : un onboarding qu'on ne peut
/// pas sauter est un impôt prélevé sur l'utilisateur qui revient et réinstalle
/// l'application. Le drapeau est persisté quelle que soit la sortie empruntée.
///
/// **Pas de bascule d'apparence**, même raisonnement que pour le splash : le
/// chemin de démarrage suit le système, et la surcharge vit dans les réglages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isLast = _page == _slides.length - 1;
    final gutter = context.gutter;

    return AppScaffold(
      showBlooms: false,
      constrainWidth: false,
      body: SafeArea(
        child: ResponsiveColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // [espaceur] · marque · Passer — la marque reste optiquement
              // centrée malgré l'échappatoire à droite.
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, 0),
                // Une superposition, et non trois cases côte à côte : réserver
                // une largeur fixe à l'échappatoire la comprime au point de
                // couper le mot sur deux lignes, et fait dépendre le centrage
                // de la marque de la longueur d'un libellé. Ici le logo est
                // centré pour de bon, et « Passer » se dimensionne seul.
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const AppLogo(size: 32),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: t.textSecondary,
                          ),
                          child: const Text(
                            AppStrings.skip,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index], gutter: gutter),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.lg,
                  gutter,
                  context.responsive(medium: 32, small: 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressRule(page: _page, total: _slides.length),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton.primary(
                      label: isLast
                          ? AppStrings.getStarted
                          : AppStrings.continueLabel,
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avancement : trois segments qui remplissent la largeur.
///
/// Le segment courant prend la couleur de marque et les précédents une teinte
/// atténuée : on voit d'un coup d'œil ce qui est fait et ce qui reste, là où
/// des pastilles identiques ne signalent qu'une position. C'est aussi la même
/// forme que la barre de chargement du splash, un écran plus tôt.
class _ProgressRule extends StatelessWidget {
  const _ProgressRule({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              height: 3,
              decoration: BoxDecoration(
                color: switch (i) {
                  _ when i == page => t.brand,
                  _ when i < page => t.borderStrong,
                  _ => t.border,
                },
                borderRadius: AppRadius.brXs,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.gutter});

  final _Slide slide;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final colors = t.resolve(slide.tone);
    final text = Theme.of(context).textTheme;
    final topPad = context.responsive(medium: 24.0, small: 12.0);

    // Centré tant qu'il reste de la place, défilant dès qu'il n'y en a plus :
    // avec une police système très agrandie, mieux vaut une colonne qui glisse
    // qu'un titre tronqué.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(gutter, topPad, gutter, AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - topPad - AppSpacing.lg).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Le dessin au trait, sans fond : c'est le langage de la marque
              // tracée sur le splash, et non une icône posée dans un carré de
              // couleur.
              Icon(
                slide.icon,
                size: context.responsive(medium: 104, small: 84, expanded: 124),
                color: colors.fg,
              ),
              SizedBox(height: context.responsive(medium: 40, small: 28)),
              Text(
                slide.kicker.toUpperCase(),
                style: text.labelMedium?.copyWith(
                  color: colors.fg,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(
                  height: 1.14,
                  fontSize: context.responsive(
                    medium: 29,
                    small: 24,
                    expanded: 33,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: t.textSecondary,
                    height: 1.5,
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
