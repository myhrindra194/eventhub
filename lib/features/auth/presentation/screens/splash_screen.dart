import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:eventhub/routes/startup_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de démarrage.
///
/// Une seule séquence, courte et entièrement orchestrée — 1,3 seconde, puis
/// l'app arrive en fondu :
///
///  1. **0 – 0,45 s** : la marque entre en fondu en se posant (échelle
///     0,94 → 1), pendant que le billet commence à se tracer ;
///  2. **0,15 – 1,05 s** : billet, perforation, puis les trois étincelles, dans
///     cet ordre, chacun sur sa tranche de la timeline ;
///  3. **0,6 – 1,1 s** : « EventHub » monte de quelques points en fondu sous
///     la marque ;
///  4. **1,3 s** : l'intro se déclare terminée ([StartupIntro]) et le router
///     peut partir.
///
/// **Ce qui a été retiré, et pourquoi.** La barre de progression : elle ne
/// mesurait rien (on ne sait pas combien de temps prend la lecture de la
/// session), elle avançait puis s'arrêtait à 78 % — l'image même d'une
/// application qui cale. La légende sous la barre aussi : trois éléments qui
/// apparaissent chacun avec son mouvement, c'est ce qui rendait l'écran agité.
/// Il reste une marque, un nom, et un seul geste.
///
/// **Si le démarrage traîne** (réseau lent au premier lancement), une ligne
/// discrète apparaît après 2,5 s : l'écran ne reste jamais muet assez
/// longtemps pour avoir l'air figé, sans rien afficher quand tout va vite.
///
/// **Animations réduites** : la marque est affichée achevée dès la première
/// image, et l'intro est déclarée terminée aussitôt — personne n'attend une
/// animation qu'il a demandé à ne pas voir.
///
/// Le fond est la couleur de l'écran de lancement natif (Android, iOS, web) :
/// le passage du système à Flutter ne produit aucun flash.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Durée totale de la séquence.
  static const duration = Duration(milliseconds: 1300);

  /// Délai avant d'afficher la ligne « préparation ».
  static const slowHint = Duration(milliseconds: 2500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  );

  // Chaque mouvement a sa tranche de la timeline : ils s'enchaînent au lieu
  // de démarrer ensemble, ce qui se lit comme une séquence et non comme un
  // clignotement.
  late final Animation<double> _enter = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.35, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.12, 0.81, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.46, 0.85, curve: Curves.easeOutCubic),
  );

  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Différé d'une micro-tâche : avec « réduire les animations », la fin
        // survient pendant `didChangeDependencies`, où Riverpod interdit à
        // juste titre de modifier un provider (l'arbre est en construction).
        scheduleMicrotask(() {
          if (mounted) ref.read(startupIntroProvider.notifier).complete();
        });
      }
    });
    _slowTimer = Timer(SplashScreen.slowHint, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      // `value = 1` émet le statut « terminé » : l'intro est libérée
      // immédiatement par l'écouteur ci-dessus.
      if (!_controller.isCompleted) _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    // Un téléphone en paysage n'offre qu'environ 300 points de haut : la
    // hauteur décide aussi des tailles, pas seulement la largeur.
    final short = MediaQuery.sizeOf(context).height < 480;
    final markSize = short
        ? 88.0
        : context.responsive<double>(medium: 132, small: 112, expanded: 156);

    return AppScaffold(
      showBlooms: false,
      constrainWidth: false,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _enter,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.0).animate(_enter),
                      child: EventMark(
                        progress: _draw,
                        stroke: t.textPrimary,
                        accent: t.accent,
                        size: markSize,
                        strokeWidth: short
                            ? 4
                            : context.responsive<double>(medium: 5, small: 4),
                      ),
                    ),
                  ),
                  SizedBox(height: short ? AppSpacing.md : AppSpacing.xl),
                  FadeTransition(
                    opacity: _wordmark,
                    child: SlideTransition(
                      // Un quart de la hauteur du mot : assez pour se lire
                      // comme un mouvement, trop peu pour attirer l'œil.
                      position: Tween(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(_wordmark),
                      child: Text.rich(
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
                          fontSize: short
                              ? 26
                              : context.responsive<double>(
                                  medium: 32,
                                  small: 28,
                                  expanded: 38,
                                ),
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.gutter,
              right: AppSpacing.gutter,
              bottom: short ? AppSpacing.md : AppSpacing.xxxl,
              child: AnimatedOpacity(
                opacity: _slow ? 1 : 0,
                duration: AppMotion.slow,
                child: Text(
                  AppStrings.splashLoading,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: t.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
