import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:flutter/material.dart';

/// Écran de démarrage.
///
/// Purement présentationnel : il est affiché pendant que le flux de session
/// et le drapeau d’onboarding se résolvent, et c’est le guard du router qui
/// décide quand le quitter.
///
/// La marque se dessine toute seule — billet, perforation, puis trois
/// étincelles — pendant qu’une barre de progression se remplit en dessous.
/// Les deux disent honnêtement la même chose : l’application démarre. Sur un
/// démarrage à froid, un logo statique se lit comme un gel.
///
/// **Pas de bascule d’apparence ici.** Un écran de démarrage n’est pas une
/// surface de réglages : il suit le système, et la surcharge vit dans les
/// réglages, là où l’utilisateur va effectivement la chercher.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.82, curve: Curves.easeInOut),
  );

  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.72, 1, curve: AppMotion.decelerate),
  );

  late final Animation<double> _bar = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 1, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // Respecte le réglage système « réduire les animations » : on montre la
    // marque terminée au lieu de la tracer.
    if (MediaQuery.disableAnimationsOf(context) && !_controller.isCompleted) {
      _controller.value = 1;
    }

    return AppScaffold(
      showBlooms: false,
      constrainWidth: false,
      body: SafeArea(
        child: ResponsiveColumn(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: Column(
              children: [
                const Spacer(flex: 3),
                EventMark(
                  progress: _draw,
                  stroke: t.textPrimary,
                  accent: t.accent,
                  size: context.responsive(
                    medium: 150,
                    small: 116,
                    expanded: 184,
                  ),
                  strokeWidth: context.responsive(medium: 5, small: 4),
                ),
                SizedBox(height: context.responsive(medium: 28, small: 20)),
                FadeTransition(
                  opacity: _text,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(_text),
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Event'),
                              TextSpan(
                                text: 'Hub',
                                style: TextStyle(color: t.brand),
                              ),
                            ],
                          ),
                          style: text.displaySmall?.copyWith(
                            fontSize: context.responsive(
                              medium: 34,
                              small: 28,
                              expanded: 40,
                            ),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppStrings.splashTagline,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                _BootBar(progress: _bar),
                SizedBox(height: context.responsive(medium: 48, small: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fine barre déterminée, accompagnée d’une légende. Déterminée à dessein :
/// un spinner dit « il se passe quelque chose », une barre dit « c’est
/// presque fini ».
class _BootBar extends StatelessWidget {
  const _BootBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.brButton,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) => LinearProgressIndicator(
              // Ne part jamais de zéro et ne prétend jamais atteindre la
              // fin : le vrai travail est un aller-retour réseau que l’on ne
              // sait pas mesurer.
              value: 0.08 + progress.value * 0.7,
              minHeight: 4,
              backgroundColor: t.surfaceSunken,
              color: t.brand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.splashLoading,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}
