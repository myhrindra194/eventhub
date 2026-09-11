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
    kicker: 'Découvrir',
    title: AppStrings.onboarding1Title,
    body: AppStrings.onboarding1Body,
    icon: Icons.explore_rounded,
    tone: AppTone.brand,
  ),
  _Slide(
    kicker: 'Réserver',
    title: AppStrings.onboarding2Title,
    body: AppStrings.onboarding2Body,
    icon: Icons.confirmation_number_rounded,
    tone: AppTone.accent,
  ),
  _Slide(
    kicker: 'Organiser',
    title: AppStrings.onboarding3Title,
    body: AppStrings.onboarding3Body,
    icon: Icons.insights_rounded,
    tone: AppTone.success,
  ),
];

/// First-launch carousel.
///
/// Three slides, one promise each, and "Passer" visible from the first frame:
/// onboarding that cannot be skipped is a tax on returning users reinstalling
/// the app. The flag is persisted whichever exit the user takes.
///
/// **No appearance toggle**, same reasoning as the splash: the startup path
/// follows the system, and the override lives in Settings.
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
            children: [
              // [spacer] · mark · Passer — the mark stays optically centred.
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      const SizedBox(width: 64),
                      const Expanded(child: Center(child: AppLogo(size: 34))),
                      SizedBox(
                        width: 64,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: t.textSecondary,
                            ),
                            child: const Text(AppStrings.skip),
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
                  AppSpacing.xl,
                  gutter,
                  context.responsive(medium: 36, small: 24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: AppMotion.short,
                            curve: AppMotion.standard,
                            width: i == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? t.brand : t.borderStrong,
                              borderRadius: AppRadius.brPill,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton.primary(
                      label: isLast
                          ? AppStrings.getStarted
                          : AppStrings.continueLabel,
                      trailingIcon: Icons.arrow_forward_rounded,
                      elevated: false,
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.gutter});

  final _Slide slide;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final colors = t.resolve(slide.tone);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // The illustration takes whatever height is left: on a tall phone
          // it breathes, on a short one it yields to the copy rather than
          // pushing the button off-screen.
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: FractionallySizedBox(
                heightFactor: 0.46,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.bg,
                      shape: BoxShape.circle,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) => Icon(
                        slide.icon,
                        size: c.maxWidth * 0.42,
                        color: colors.fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.responsive(medium: 32, small: 22)),
          Text(
            slide.kicker.toUpperCase(),
            style: text.labelMedium?.copyWith(color: colors.fg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(
              height: 1.15,
              fontSize: context.responsive(medium: 28, small: 24, expanded: 32),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: t.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
